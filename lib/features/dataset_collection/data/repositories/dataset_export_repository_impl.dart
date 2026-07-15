import 'dart:convert';

import 'package:ai_road_safety_platform/core/constants/app_config.dart';
import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_export_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_export_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_storage_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_export_factory.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/export_document_generators.dart';
import 'package:uuid/uuid.dart';

/// Orchestrates strategy-based research exports (Phase 12.8).
class DatasetExportRepositoryImpl implements DatasetExportRepository {
  final DatasetCollectionRepository _collection;
  final DatasetStorageRepository _storage;
  final DatasetFileManager _files;
  final DatasetExportLocalDataSource _local;
  final DatasetExportFactory _factory;
  final ExportManifestGenerator _manifestGenerator;
  final ExportReadmeGenerator _readmeGenerator;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final Uuid _uuid;

  /// Creates [DatasetExportRepositoryImpl].
  DatasetExportRepositoryImpl({
    required DatasetCollectionRepository collectionRepository,
    required DatasetStorageRepository storageRepository,
    required DatasetFileManager fileManager,
    required DatasetExportLocalDataSource localDataSource,
    required DatasetExportFactory factory,
    required ExportManifestGenerator manifestGenerator,
    required ExportReadmeGenerator readmeGenerator,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    Uuid? uuid,
  })  : _collection = collectionRepository,
        _storage = storageRepository,
        _files = fileManager,
        _local = localDataSource,
        _factory = factory,
        _manifestGenerator = manifestGenerator,
        _readmeGenerator = readmeGenerator,
        _errorHandler = errorHandler,
        _logger = logger,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<ExportResult>> exportDataset(
    ExportSettings settings, {
    ExportProgressCallback? onProgress,
  }) {
    return _guard(() => _runExport(settings, onProgress: onProgress));
  }

  @override
  Future<Result<ExportResult>> exportSession(
    String sessionId,
    ExportSettings settings, {
    ExportProgressCallback? onProgress,
  }) {
    return _guard(() {
      final scoped = settings.copyWith(sessionIds: [sessionId]);
      return _runExport(scoped, onProgress: onProgress);
    });
  }

  @override
  Future<Result<String>> exportStatistics(String exportFolderPath) {
    return _guard(() async {
      final sessions = await _sessionsFromFolder(exportFolderPath);
      final frames =
          sessions.fold<int>(0, (a, s) => a + s.frameCount);
      final payload = {
        'totalSessions': sessions.length,
        'totalFrames': frames,
        'refreshedAt': DateTime.now().toUtc().toIso8601String(),
      };
      final writer = _local.writerFor(exportFolderPath);
      await writer.ensureDir('statistics');
      await writer.writeText(
        'statistics/statistics.json',
        const JsonEncoder.withIndent('  ').convert(payload),
      );
      return '$exportFolderPath/statistics/statistics.json';
    });
  }

  @override
  Future<Result<ExportManifest>> generateManifest(String exportFolderPath) {
    return _guard(() async {
      final sessions = await _sessionsFromFolder(exportFolderPath);
      final settings = await _settingsFromFolder(exportFolderPath);
      final size = await _local.directorySize(exportFolderPath);
      final imageCount = await _files.fileCount('$exportFolderPath/images');
      final metaCount = await _files.fileCount('$exportFolderPath/metadata');
      final model = sessions.isEmpty
          ? 'unknown'
          : sessions.first.modelVersion;
      final manifest = _manifestGenerator.build(
        settings: settings,
        sessions: sessions,
        imageCount: imageCount,
        metadataCount: metaCount,
        storageSizeBytes: size,
        applicationVersion: AppConfig.appVersion,
        aiModelVersion: model,
      );
      await _local.writeManifest(exportFolderPath, manifest);
      return manifest;
    });
  }

  @override
  Future<Result<String>> generateReadme(String exportFolderPath) {
    return _guard(() async {
      final manifestResult = await generateManifest(exportFolderPath);
      final manifest = await _unwrap(Future.value(manifestResult));
      final sessions = await _sessionsFromFolder(exportFolderPath);
      final settings = await _settingsFromFolder(exportFolderPath);
      final md = _readmeGenerator.build(
        manifest: manifest,
        settings: settings,
        sessions: sessions,
      );
      await _local.writeReadme(exportFolderPath, md);
      return '$exportFolderPath/README.md';
    });
  }

  @override
  Future<Result<String>> compressDataset(String exportFolderPath) {
    return _guard(() async {
      final zip = await _local.compressFolder(exportFolderPath);
      return zip;
    });
  }

  @override
  Future<Result<ExportValidation>> validateExport(String exportFolderPath) {
    return _guard(() => _local.validateExport(exportFolderPath));
  }

  @override
  Future<Result<List<ExportHistoryEntry>>> loadExportHistory() {
    return _guard(_local.loadHistory);
  }

  Future<ExportResult> _runExport(
    ExportSettings settings, {
    ExportProgressCallback? onProgress,
  }) async {
    final started = DateTime.now();
    final logs = <String>['Export Started'];
    void report({
      required double progress,
      required String step,
      Duration? remaining,
      String? log,
    }) {
      if (log != null) logs.add(log);
      onProgress?.call(
        ExportProgress(
          progress: progress.clamp(0.0, 1.0),
          currentStep: step,
          elapsed: DateTime.now().difference(started),
          remainingEstimate: remaining,
          logs: List.unmodifiable(logs),
        ),
      );
    }

    _logger.info('Export Started format=${settings.format.name}',
        tag: 'DatasetExport');
    report(progress: 0.02, step: 'Preparing', log: 'Validating environment');

    await _files.ensureRootLayout();
    final criticallyLow = await _storage.calculateStorage();
    criticallyLow.fold(
      onOk: (u) {
        if (u.isLowStorage) {
          throw const CacheException(
            message: 'Storage critically low — free space before exporting.',
          );
        }
      },
      onErr: (_) {},
    );

    final allSessions = await _unwrap(_collection.getSessions());
    if (allSessions.isEmpty) {
      throw const CacheException(message: 'No sessions available to export.');
    }
    final selected = settings.sessionIds.isEmpty
        ? allSessions
        : allSessions
            .where((s) => settings.sessionIds.contains(s.id))
            .toList();
    if (selected.isEmpty) {
      throw const CacheException(
        message: 'Selected sessions were not found.',
      );
    }

    report(
      progress: 0.08,
      step: 'Creating export folder',
      log: 'Selected ${selected.length} session(s)',
    );
    final exportRoot =
        await _local.createExportFolder(settings.datasetName);
    final writer = _local.writerFor(exportRoot);

    final modelVersion = selected
        .map((s) => s.modelVersion)
        .firstWhere((m) => m.isNotEmpty, orElse: () => 'unknown');

    final context = ExportContext(
      exportRoot: exportRoot,
      settings: settings,
      sessions: selected,
      applicationVersion: AppConfig.appVersion,
      defaultModelVersion: modelVersion,
    );

    report(progress: 0.15, step: 'Running ${settings.format.label} strategy');
    final strategy = _factory.create(settings.format);
    final strategyResult = await strategy.export(
      context,
      writer,
      onProgress: onProgress,
    );

    report(
      progress: 0.72,
      step: 'Writing documents',
      log: strategyResult.notes,
    );

    final size = await _local.directorySize(exportRoot);
    var imageCount = strategyResult.imageCount;
    var metadataCount = strategyResult.metadataCount;
    if (imageCount == 0 && settings.includeImages) {
      imageCount = await _files.fileCount('$exportRoot/images');
    }
    if (metadataCount == 0 && settings.includeMetadata) {
      metadataCount = await _files.fileCount('$exportRoot/metadata');
    }

    final manifest = _manifestGenerator.build(
      settings: settings,
      sessions: selected,
      imageCount: imageCount,
      metadataCount: metadataCount,
      storageSizeBytes: size,
      applicationVersion: AppConfig.appVersion,
      aiModelVersion: modelVersion,
    );

    if (settings.generateManifest) {
      await _local.writeManifest(exportRoot, manifest);
      report(progress: 0.8, step: 'Manifest generated', log: 'Manifest Generated');
    }
    if (settings.generateReadme) {
      final md = _readmeGenerator.build(
        manifest: manifest,
        settings: settings,
        sessions: selected,
      );
      await _local.writeReadme(exportRoot, md);
      report(progress: 0.86, step: 'README generated', log: 'README Generated');
    }

    String? zipPath;
    final shouldZip =
        settings.compressOutput || settings.format == ExportFormat.zip;
    if (shouldZip) {
      report(progress: 0.9, step: 'Compressing ZIP');
      zipPath = await _local.compressFolder(exportRoot);
      logs.add('ZIP Created');
    }

    report(progress: 0.95, step: 'Validating export');
    final validation = await _local.validateExport(exportRoot);
    if (!validation.isValid) {
      throw CacheException(
        message: 'Export validation failed: ${validation.errors.join('; ')}',
      );
    }

    final exportId = _uuid.v4();
    final result = ExportResult(
      exportId: exportId,
      exportFolderPath: exportRoot,
      zipPath: zipPath,
      manifest: manifest,
      settings: settings,
      completedAt: DateTime.now().toUtc(),
      createdFiles: [
        ...strategyResult.createdRelativePaths,
        if (settings.generateManifest) 'manifest.json',
        if (settings.generateReadme) 'README.md',
        ?zipPath,
      ],
      isPlaceholderFormat: settings.format.isPlaceholder,
    );

    await _local.appendHistory(
      ExportHistoryEntry(
        exportId: exportId,
        datasetName: settings.datasetName,
        format: settings.format,
        folderPath: exportRoot,
        zipPath: zipPath,
        completedAt: result.completedAt,
        sessionCount: selected.length,
        frameCount: manifest.frameCount,
        success: true,
      ),
    );

    report(
      progress: 1,
      step: 'Completed',
      log: 'Export Completed',
    );
    _logger.info('Export Completed id=$exportId path=$exportRoot',
        tag: 'DatasetExport');
    return result;
  }

  Future<List<DatasetSession>> _sessionsFromFolder(String exportRoot) async {
    final writer = _local.writerFor(exportRoot);
    final path = '$exportRoot/sessions/sessions.json';
    if (!await writer.existsAbsolute(path)) return const [];
    try {
      final raw = jsonDecode(await writer.readAbsoluteText(path));
      if (raw is! List) return const [];
      // Prefer live Hive sessions matched by id when available.
      final all = await _unwrap(_collection.getSessions());
      final ids = <String>{
        for (final item in raw)
          if (item is Map && item['id'] is String) item['id'] as String,
      };
      final matched = all.where((s) => ids.contains(s.id)).toList();
      return matched.isNotEmpty ? matched : all;
    } catch (_) {
      return _unwrap(_collection.getSessions());
    }
  }

  Future<ExportSettings> _settingsFromFolder(String exportRoot) async {
    final path = '$exportRoot/config/export_config.json';
    final writer = _local.writerFor(exportRoot);
    if (!await writer.existsAbsolute(path)) {
      return const ExportSettings();
    }
    try {
      final raw = jsonDecode(await writer.readAbsoluteText(path));
      if (raw is! Map) return const ExportSettings();
      final map = Map<String, dynamic>.from(raw);
      final formatName = map['format'] as String?;
      final format = ExportFormat.values.firstWhere(
        (f) => f.name == formatName,
        orElse: () => ExportFormat.json,
      );
      return ExportSettings(
        datasetName: map['datasetName'] as String? ?? 'Dataset',
        format: format,
        includeImages: map['includeImages'] as bool? ?? true,
        includeMetadata: map['includeMetadata'] as bool? ?? true,
        includeStatistics: map['includeStatistics'] as bool? ?? true,
        compressOutput: map['compressOutput'] as bool? ?? false,
      );
    } catch (_) {
      return const ExportSettings();
    }
  }

  Future<T> _unwrap<T>(Future<Result<T>> future) async {
    final result = await future;
    return result.fold(
      onOk: (v) => v,
      onErr: (f) => throw CacheException(message: f.message),
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (failure) {
      _logger.warning('Export Failed: ${failure.message}',
          tag: 'DatasetExport');
      return Err(failure);
    } on AppException catch (e, st) {
      _logger.warning('Export Failed: ${e.message}', tag: 'DatasetExport');
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      _logger.warning('Export Failed: $e', tag: 'DatasetExport');
      return Err(_errorHandler.handle(e, st));
    }
  }
}
