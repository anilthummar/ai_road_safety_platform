import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:equatable/equatable.dart';

/// Supported research export formats (Phase 12.8).
enum ExportFormat {
  /// Session + metadata JSON bundles.
  json,

  /// Tabular session / frame CSV.
  csv,

  /// Folder tree + ZIP package of JSON export.
  zip,

  /// YOLO layout (placeholder).
  yolo,

  /// COCO JSON layout (placeholder).
  coco,

  /// Pascal VOC XML layout (placeholder).
  voc,

  /// Label Studio tasks (placeholder).
  labelStudio,

  /// CVAT tasks (placeholder).
  cvat,

  /// Roboflow package (placeholder).
  roboflow,
}

/// Display helpers for [ExportFormat].
extension ExportFormatX on ExportFormat {
  /// UI label.
  String get label => switch (this) {
        ExportFormat.json => 'JSON',
        ExportFormat.csv => 'CSV',
        ExportFormat.zip => 'ZIP',
        ExportFormat.yolo => 'YOLO (placeholder)',
        ExportFormat.coco => 'COCO (placeholder)',
        ExportFormat.voc => 'Pascal VOC (placeholder)',
        ExportFormat.labelStudio => 'Label Studio (placeholder)',
        ExportFormat.cvat => 'CVAT (placeholder)',
        ExportFormat.roboflow => 'Roboflow (placeholder)',
      };

  /// Whether this format is a stub for future annotation interoperability.
  bool get isPlaceholder => switch (this) {
        ExportFormat.yolo ||
        ExportFormat.coco ||
        ExportFormat.voc ||
        ExportFormat.labelStudio ||
        ExportFormat.cvat ||
        ExportFormat.roboflow =>
          true,
        _ => false,
      };

  /// Folder / file tag used in export paths.
  String get pathTag => switch (this) {
        ExportFormat.json => 'json',
        ExportFormat.csv => 'csv',
        ExportFormat.zip => 'zip',
        ExportFormat.yolo => 'yolo',
        ExportFormat.coco => 'coco',
        ExportFormat.voc => 'voc',
        ExportFormat.labelStudio => 'label_studio',
        ExportFormat.cvat => 'cvat',
        ExportFormat.roboflow => 'roboflow',
      };
}

/// User-selected export options.
class ExportSettings extends Equatable {
  /// Dataset display name.
  final String datasetName;

  /// Target format.
  final ExportFormat format;

  /// Session ids to include (`empty` = all sessions).
  final List<String> sessionIds;

  /// Copy / reference images into export.
  final bool includeImages;

  /// Include frame / session metadata files.
  final bool includeMetadata;

  /// Include statistics JSON.
  final bool includeStatistics;

  /// Produce ZIP after folder export.
  final bool compressOutput;

  /// Write README.md.
  final bool generateReadme;

  /// Write manifest.json.
  final bool generateManifest;

  /// Creates [ExportSettings].
  const ExportSettings({
    this.datasetName = 'AI_Road_Safety_Dataset',
    this.format = ExportFormat.json,
    this.sessionIds = const [],
    this.includeImages = true,
    this.includeMetadata = true,
    this.includeStatistics = true,
    this.compressOutput = false,
    this.generateReadme = true,
    this.generateManifest = true,
  });

  /// Copy helper.
  ExportSettings copyWith({
    String? datasetName,
    ExportFormat? format,
    List<String>? sessionIds,
    bool? includeImages,
    bool? includeMetadata,
    bool? includeStatistics,
    bool? compressOutput,
    bool? generateReadme,
    bool? generateManifest,
  }) {
    return ExportSettings(
      datasetName: datasetName ?? this.datasetName,
      format: format ?? this.format,
      sessionIds: sessionIds ?? this.sessionIds,
      includeImages: includeImages ?? this.includeImages,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      includeStatistics: includeStatistics ?? this.includeStatistics,
      compressOutput: compressOutput ?? this.compressOutput,
      generateReadme: generateReadme ?? this.generateReadme,
      generateManifest: generateManifest ?? this.generateManifest,
    );
  }

  @override
  List<Object?> get props => [
        datasetName,
        format,
        sessionIds,
        includeImages,
        includeMetadata,
        includeStatistics,
        compressOutput,
        generateReadme,
        generateManifest,
      ];
}

/// Export package `manifest.json` payload.
class ExportManifest extends Equatable {
  final String datasetName;
  final DateTime exportDate;
  final String exportVersion;
  final int sessionCount;
  final int frameCount;
  final int imageCount;
  final int metadataCount;
  final int storageSizeBytes;
  final String applicationVersion;
  final String aiModelVersion;
  final String format;
  final List<String> sessionIds;

  /// Creates [ExportManifest].
  const ExportManifest({
    required this.datasetName,
    required this.exportDate,
    required this.exportVersion,
    required this.sessionCount,
    required this.frameCount,
    required this.imageCount,
    required this.metadataCount,
    required this.storageSizeBytes,
    required this.applicationVersion,
    required this.aiModelVersion,
    required this.format,
    required this.sessionIds,
  });

  /// JSON map.
  Map<String, dynamic> toJson() => {
        'datasetName': datasetName,
        'exportDate': exportDate.toUtc().toIso8601String(),
        'exportVersion': exportVersion,
        'sessionCount': sessionCount,
        'frameCount': frameCount,
        'imageCount': imageCount,
        'metadataCount': metadataCount,
        'storageSize': storageSizeBytes,
        'applicationVersion': applicationVersion,
        'aiModelVersion': aiModelVersion,
        'format': format,
        'sessionIds': sessionIds,
      };

  @override
  List<Object?> get props => [
        datasetName,
        exportDate,
        exportVersion,
        sessionCount,
        frameCount,
        imageCount,
        metadataCount,
        storageSizeBytes,
        applicationVersion,
        aiModelVersion,
        format,
        sessionIds,
      ];
}

/// Live export progress.
class ExportProgress extends Equatable {
  /// 0.0–1.0.
  final double progress;

  /// Human step label.
  final String currentStep;

  /// Elapsed wall time.
  final Duration elapsed;

  /// Remaining estimate (`null` when unknown).
  final Duration? remainingEstimate;

  /// Rolling log lines (newest last).
  final List<String> logs;

  /// Creates [ExportProgress].
  const ExportProgress({
    required this.progress,
    required this.currentStep,
    required this.elapsed,
    this.remainingEstimate,
    this.logs = const [],
  });

  const ExportProgress.initial()
      : progress = 0,
        currentStep = 'Idle',
        elapsed = Duration.zero,
        remainingEstimate = null,
        logs = const [];

  ExportProgress copyWith({
    double? progress,
    String? currentStep,
    Duration? elapsed,
    Duration? remainingEstimate,
    List<String>? logs,
    bool clearRemaining = false,
  }) {
    return ExportProgress(
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      elapsed: elapsed ?? this.elapsed,
      remainingEstimate: clearRemaining
          ? null
          : (remainingEstimate ?? this.remainingEstimate),
      logs: logs ?? this.logs,
    );
  }

  @override
  List<Object?> get props =>
      [progress, currentStep, elapsed, remainingEstimate, logs];
}

/// Result of a finished export.
class ExportResult extends Equatable {
  final String exportId;
  final String exportFolderPath;
  final String? zipPath;
  final ExportManifest manifest;
  final ExportSettings settings;
  final DateTime completedAt;
  final List<String> createdFiles;
  final bool isPlaceholderFormat;

  /// Creates [ExportResult].
  const ExportResult({
    required this.exportId,
    required this.exportFolderPath,
    required this.manifest,
    required this.settings,
    required this.completedAt,
    required this.createdFiles,
    this.zipPath,
    this.isPlaceholderFormat = false,
  });

  @override
  List<Object?> get props => [
        exportId,
        exportFolderPath,
        zipPath,
        manifest,
        settings,
        completedAt,
        createdFiles,
        isPlaceholderFormat,
      ];
}

/// Validation outcome.
class ExportValidation extends Equatable {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final bool imagesPresent;
  final bool metadataPresent;
  final bool sessionsPresent;
  final bool manifestPresent;
  final bool readmePresent;
  final bool zipPresent;
  final bool zipIntegrityOk;

  /// Creates [ExportValidation].
  const ExportValidation({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.imagesPresent,
    required this.metadataPresent,
    required this.sessionsPresent,
    required this.manifestPresent,
    required this.readmePresent,
    required this.zipPresent,
    required this.zipIntegrityOk,
  });

  @override
  List<Object?> get props => [
        isValid,
        errors,
        warnings,
        imagesPresent,
        metadataPresent,
        sessionsPresent,
        manifestPresent,
        readmePresent,
        zipPresent,
        zipIntegrityOk,
      ];
}

/// Persisted export history row.
class ExportHistoryEntry extends Equatable {
  final String exportId;
  final String datasetName;
  final ExportFormat format;
  final String folderPath;
  final String? zipPath;
  final DateTime completedAt;
  final int sessionCount;
  final int frameCount;
  final bool success;

  /// Creates [ExportHistoryEntry].
  const ExportHistoryEntry({
    required this.exportId,
    required this.datasetName,
    required this.format,
    required this.folderPath,
    required this.completedAt,
    required this.sessionCount,
    required this.frameCount,
    required this.success,
    this.zipPath,
  });

  Map<String, dynamic> toJson() => {
        'exportId': exportId,
        'datasetName': datasetName,
        'format': format.name,
        'folderPath': folderPath,
        'zipPath': zipPath,
        'completedAt': completedAt.toUtc().toIso8601String(),
        'sessionCount': sessionCount,
        'frameCount': frameCount,
        'success': success,
      };

  factory ExportHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ExportHistoryEntry(
      exportId: json['exportId'] as String? ?? '',
      datasetName: json['datasetName'] as String? ?? '',
      format: ExportFormat.values.firstWhere(
        (f) => f.name == json['format'],
        orElse: () => ExportFormat.json,
      ),
      folderPath: json['folderPath'] as String? ?? '',
      zipPath: json['zipPath'] as String?,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
      frameCount: (json['frameCount'] as num?)?.toInt() ?? 0,
      success: json['success'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        exportId,
        datasetName,
        format,
        folderPath,
        zipPath,
        completedAt,
        sessionCount,
        frameCount,
        success,
      ];
}

/// Context passed into export strategies (immutable snapshot).
class ExportContext extends Equatable {
  final String exportRoot;
  final ExportSettings settings;
  final List<DatasetSession> sessions;
  final String applicationVersion;
  final String defaultModelVersion;

  /// Creates [ExportContext].
  const ExportContext({
    required this.exportRoot,
    required this.settings,
    required this.sessions,
    required this.applicationVersion,
    required this.defaultModelVersion,
  });

  @override
  List<Object?> get props => [
        exportRoot,
        settings,
        sessions,
        applicationVersion,
        defaultModelVersion,
      ];
}

/// Strategy output after writing format-specific files.
class ExportStrategyResult extends Equatable {
  final List<String> createdRelativePaths;
  final int imageCount;
  final int metadataCount;
  final String notes;

  /// Creates [ExportStrategyResult].
  const ExportStrategyResult({
    required this.createdRelativePaths,
    required this.imageCount,
    required this.metadataCount,
    this.notes = '',
  });

  @override
  List<Object?> get props =>
      [createdRelativePaths, imageCount, metadataCount, notes];
}

/// Progress callback for export pipelines.
typedef ExportProgressCallback = void Function(ExportProgress progress);
