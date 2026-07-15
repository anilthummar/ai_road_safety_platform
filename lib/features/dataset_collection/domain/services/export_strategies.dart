import 'dart:convert';

import 'package:ai_road_safety_platform/features/dataset_collection/data/models/dataset_collection_models.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/export_strategy.dart';

/// Shared helpers for concrete strategies.
mixin ExportStrategyHelpers on ExportStrategy {
  Future<void> writeCommonTree(
    ExportContext context,
    ExportFileWriter writer,
  ) async {
    await writer.ensureDir('images');
    await writer.ensureDir('metadata');
    await writer.ensureDir('statistics');
    await writer.ensureDir('sessions');
    await writer.ensureDir('config');
  }

  Future<void> writeSessionsJson(
    ExportContext context,
    ExportFileWriter writer,
  ) async {
    final payload = [
      for (final s in context.sessions)
        DatasetSessionModel.fromDomain(s).toJson(),
    ];
    await writer.writeText(
      'sessions/sessions.json',
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  Future<void> writeStatisticsJson(
    ExportContext context,
    ExportFileWriter writer,
  ) async {
    if (!context.settings.includeStatistics) return;
    final frames =
        context.sessions.fold<int>(0, (a, s) => a + s.frameCount);
    final floods =
        context.sessions.fold<int>(0, (a, s) => a + s.floodEventCount);
    final storage =
        context.sessions.fold<int>(0, (a, s) => a + s.totalStorage);
    final avgConf = context.sessions.isEmpty
        ? 0.0
        : context.sessions.fold<double>(0, (a, s) => a + s.averageConfidence) /
            context.sessions.length;
    final stats = {
      'totalSessions': context.sessions.length,
      'totalFrames': frames,
      'totalFloodEvents': floods,
      'totalStorage': storage,
      'averageConfidence': avgConf,
      'format': context.settings.format.pathTag,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    await writer.writeText(
      'statistics/statistics.json',
      const JsonEncoder.withIndent('  ').convert(stats),
    );
  }

  Future<void> writeConfigJson(
    ExportContext context,
    ExportFileWriter writer,
  ) async {
    final config = {
      'datasetName': context.settings.datasetName,
      'format': context.settings.format.name,
      'includeImages': context.settings.includeImages,
      'includeMetadata': context.settings.includeMetadata,
      'includeStatistics': context.settings.includeStatistics,
      'compressOutput': context.settings.compressOutput,
      'applicationVersion': context.applicationVersion,
      'exportVersion': '12.8.0',
    };
    await writer.writeText(
      'config/export_config.json',
      const JsonEncoder.withIndent('  ').convert(config),
    );
  }

  Future<(int images, int metadata)> copySessionAssets({
    required ExportContext context,
    required ExportFileWriter writer,
    required String Function(String sessionId) imagesSource,
    required String Function(String sessionId) metadataSource,
    ExportProgressCallback? onProgress,
    required DateTime startedAt,
    required List<String> logs,
  }) async {
    var images = 0;
    var metadata = 0;
    if (!context.settings.includeImages && !context.settings.includeMetadata) {
      return (0, 0);
    }

    final total = context.sessions.length.clamp(1, 1 << 20);
    for (var i = 0; i < context.sessions.length; i++) {
      final s = context.sessions[i];
      if (context.settings.includeImages) {
        final src = imagesSource(s.id);
        if (await writer.existsAbsolute(src)) {
          images += await writer.copyDirectory(src, 'images/${s.id}');
        }
      }
      if (context.settings.includeMetadata) {
        final src = metadataSource(s.id);
        if (await writer.existsAbsolute(src)) {
          metadata += await writer.copyDirectory(src, 'metadata/${s.id}');
        }
      }
      final elapsed = DateTime.now().difference(startedAt);
      final p = (i + 1) / total;
      onProgress?.call(
        ExportProgress(
          progress: 0.25 + p * 0.45,
          currentStep: 'Copying assets · ${s.sessionName}',
          elapsed: elapsed,
          remainingEstimate: p > 0.05
              ? Duration(
                  milliseconds:
                      ((elapsed.inMilliseconds / p) * (1 - p)).round(),
                )
              : null,
          logs: [
            ...logs,
            'Copied assets for session ${s.id}',
          ],
        ),
      );
    }
    return (images, metadata);
  }
}

/// JSON research bundle.
class JsonExportStrategy extends ExportStrategy with ExportStrategyHelpers {
  final DatasetPaths Function() _paths;

  /// Creates [JsonExportStrategy].
  JsonExportStrategy({required DatasetPaths Function() paths}) : _paths = paths;

  @override
  ExportFormat get format => ExportFormat.json;

  @override
  Future<ExportStrategyResult> export(
    ExportContext context,
    ExportFileWriter writer, {
    ExportProgressCallback? onProgress,
  }) async {
    final started = DateTime.now();
    final logs = <String>['JSON export started'];
    await writeCommonTree(context, writer);
    await writeSessionsJson(context, writer);
    await writeStatisticsJson(context, writer);
    await writeConfigJson(context, writer);

    final p = _paths();
    final counts = await copySessionAssets(
      context: context,
      writer: writer,
      imagesSource: p.imagesOriginal,
      metadataSource: p.frameMetadataDir,
      onProgress: onProgress,
      startedAt: started,
      logs: logs,
    );

    // Per-session JSON summary.
    for (final s in context.sessions) {
      await writer.writeText(
        'sessions/${s.id}.json',
        const JsonEncoder.withIndent('  ')
            .convert(DatasetSessionModel.fromDomain(s).toJson()),
      );
    }

    return ExportStrategyResult(
      createdRelativePaths: const [
        'sessions/sessions.json',
        'statistics/statistics.json',
        'config/export_config.json',
      ],
      imageCount: counts.$1,
      metadataCount: counts.$2,
      notes: 'JSON research bundle',
    );
  }
}

/// CSV tabular export.
class CsvExportStrategy extends ExportStrategy with ExportStrategyHelpers {
  final DatasetPaths Function() _paths;

  /// Creates [CsvExportStrategy].
  CsvExportStrategy({required DatasetPaths Function() paths}) : _paths = paths;

  @override
  ExportFormat get format => ExportFormat.csv;

  @override
  Future<ExportStrategyResult> export(
    ExportContext context,
    ExportFileWriter writer, {
    ExportProgressCallback? onProgress,
  }) async {
    final started = DateTime.now();
    await writeCommonTree(context, writer);
    await writeConfigJson(context, writer);
    await writeStatisticsJson(context, writer);

    final buf = StringBuffer()
      ..writeln(
        'id,sessionName,status,createdAt,durationSeconds,frameCount,'
        'floodEventCount,totalStorage,averageSpeed,averageConfidence,'
        'averageFloodCoverage',
      );
    for (final s in context.sessions) {
      buf.writeln(
        [
          _esc(s.id),
          _esc(s.sessionName),
          _esc(s.status.name),
          _esc(s.createdAt.toUtc().toIso8601String()),
          s.duration.inSeconds,
          s.frameCount,
          s.floodEventCount,
          s.totalStorage,
          s.averageSpeed.toStringAsFixed(3),
          s.averageConfidence.toStringAsFixed(4),
          s.averageFloodCoverage.toStringAsFixed(3),
        ].join(','),
      );
    }
    await writer.writeText('sessions/sessions.csv', buf.toString());
    await writeSessionsJson(context, writer);

    final p = _paths();
    final counts = await copySessionAssets(
      context: context,
      writer: writer,
      imagesSource: p.imagesOriginal,
      metadataSource: p.frameMetadataDir,
      onProgress: onProgress,
      startedAt: started,
      logs: const ['CSV export'],
    );

    return ExportStrategyResult(
      createdRelativePaths: const [
        'sessions/sessions.csv',
        'sessions/sessions.json',
      ],
      imageCount: counts.$1,
      metadataCount: counts.$2,
      notes: 'CSV tabular export',
    );
  }

  String _esc(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}

/// ZIP-oriented strategy: writes JSON tree (ZIP created by repository).
class ZipExportStrategy extends ExportStrategy {
  final JsonExportStrategy _json;

  /// Creates [ZipExportStrategy].
  ZipExportStrategy({required JsonExportStrategy jsonStrategy})
      : _json = jsonStrategy;

  @override
  ExportFormat get format => ExportFormat.zip;

  @override
  Future<ExportStrategyResult> export(
    ExportContext context,
    ExportFileWriter writer, {
    ExportProgressCallback? onProgress,
  }) async {
    // Force compression intent for this format if caller forgot.
    final zipContext = ExportContext(
      exportRoot: context.exportRoot,
      settings: context.settings.copyWith(compressOutput: true),
      sessions: context.sessions,
      applicationVersion: context.applicationVersion,
      defaultModelVersion: context.defaultModelVersion,
    );
    final result = await _json.export(
      zipContext,
      writer,
      onProgress: onProgress,
    );
    return ExportStrategyResult(
      createdRelativePaths: result.createdRelativePaths,
      imageCount: result.imageCount,
      metadataCount: result.metadataCount,
      notes: 'ZIP package base (folder written; archive by pipeline)',
    );
  }
}

/// Placeholder layout writer for future annotation formats.
abstract class PlaceholderExportStrategy extends ExportStrategy
    with ExportStrategyHelpers {
  /// Short format name for docs.
  String get placeholderName;

  /// Relative stub folders.
  List<String> get stubFolders;

  @override
  Future<ExportStrategyResult> export(
    ExportContext context,
    ExportFileWriter writer, {
    ExportProgressCallback? onProgress,
  }) async {
    await writeCommonTree(context, writer);
    await writeSessionsJson(context, writer);
    await writeStatisticsJson(context, writer);
    await writeConfigJson(context, writer);

    for (final folder in stubFolders) {
      await writer.ensureDir(folder);
    }
    await writer.writeText(
      '${format.pathTag}/PLACEHOLDER.md',
      '# $placeholderName export (placeholder)\n\n'
      'This layout is reserved for Phase 13+ annotation interoperability.\n'
      'Session summaries are available under `sessions/`.\n',
    );

    onProgress?.call(
      ExportProgress(
        progress: 0.7,
        currentStep: 'Placeholder · $placeholderName',
        elapsed: Duration.zero,
        logs: ['Wrote $placeholderName placeholder scaffold'],
      ),
    );

    return ExportStrategyResult(
      createdRelativePaths: [
        '${format.pathTag}/PLACEHOLDER.md',
        'sessions/sessions.json',
      ],
      imageCount: 0,
      metadataCount: 0,
      notes: '$placeholderName placeholder scaffold',
    );
  }
}

/// YOLO placeholder.
class YoloExportStrategy extends PlaceholderExportStrategy {
  @override
  ExportFormat get format => ExportFormat.yolo;

  @override
  String get placeholderName => 'YOLO';

  @override
  List<String> get stubFolders =>
      const ['yolo/images', 'yolo/labels', 'yolo/data'];
}

/// COCO placeholder.
class CocoExportStrategy extends PlaceholderExportStrategy {
  @override
  ExportFormat get format => ExportFormat.coco;

  @override
  String get placeholderName => 'COCO';

  @override
  List<String> get stubFolders => const ['coco/annotations', 'coco/images'];
}

/// Pascal VOC placeholder.
class VocExportStrategy extends PlaceholderExportStrategy {
  @override
  ExportFormat get format => ExportFormat.voc;

  @override
  String get placeholderName => 'Pascal VOC';

  @override
  List<String> get stubFolders =>
      const ['voc/Annotations', 'voc/JPEGImages', 'voc/ImageSets'];
}

/// Label Studio placeholder.
class LabelStudioExportStrategy extends PlaceholderExportStrategy {
  @override
  ExportFormat get format => ExportFormat.labelStudio;

  @override
  String get placeholderName => 'Label Studio';

  @override
  List<String> get stubFolders => const ['label_studio/tasks'];
}

/// CVAT placeholder.
class CvatExportStrategy extends PlaceholderExportStrategy {
  @override
  ExportFormat get format => ExportFormat.cvat;

  @override
  String get placeholderName => 'CVAT';

  @override
  List<String> get stubFolders => const ['cvat/tasks'];
}

/// Roboflow placeholder.
class RoboflowExportStrategy extends PlaceholderExportStrategy {
  @override
  ExportFormat get format => ExportFormat.roboflow;

  @override
  String get placeholderName => 'Roboflow';

  @override
  List<String> get stubFolders => const ['roboflow/train', 'roboflow/valid'];
}
