import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/pipeline_entities.dart';

/// Independent pipeline stage (Strategy + Pipeline Pattern).
abstract class PipelineStage {
  PipelineStageKind get kind;
  String get name;
  bool get isPlaceholder => kind.isPlaceholder;

  /// Executes work for [task]. Must not block the UI isolate forever —
  /// heavy work should be dispatched via [BackgroundWorker] later.
  Future<StageResult> process(PipelineTask task);
}

/// Camera / frame intake stage.
class FrameAcquisitionStage implements PipelineStage {
  final AppLogger? logger;

  FrameAcquisitionStage({this.logger});

  @override
  PipelineStageKind get kind => PipelineStageKind.frameAcquisition;

  @override
  String get name => kind.label;

  @override
  bool get isPlaceholder => false;

  @override
  Future<StageResult> process(PipelineTask task) async {
    logger?.debug('FrameAcquisition ${task.id}', tag: 'Pipeline');
    await Future<void>.delayed(const Duration(milliseconds: 8));
    return StageResult.ok({
      'frameId': task.payload['frameId'] ?? task.id,
      'acquiredAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

/// Metadata synchronization stage.
class MetadataStage implements PipelineStage {
  final AppLogger? logger;

  MetadataStage({this.logger});

  @override
  PipelineStageKind get kind => PipelineStageKind.metadata;

  @override
  String get name => kind.label;

  @override
  bool get isPlaceholder => false;

  @override
  Future<StageResult> process(PipelineTask task) async {
    logger?.debug('Metadata ${task.id}', tag: 'Pipeline');
    await Future<void>.delayed(const Duration(milliseconds: 6));
    return StageResult.ok({
      'metadataSynced': true,
      'sessionId': task.sessionId,
    });
  }
}

/// Local storage write stage.
class StorageStage implements PipelineStage {
  final AppLogger? logger;

  StorageStage({this.logger});

  @override
  PipelineStageKind get kind => PipelineStageKind.storage;

  @override
  String get name => kind.label;

  @override
  bool get isPlaceholder => false;

  @override
  Future<StageResult> process(PipelineTask task) async {
    logger?.debug('Storage ${task.id}', tag: 'Pipeline');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return StageResult.ok(const {'persisted': true});
  }
}

/// Lightweight dataset validation stage.
class DatasetValidationStage implements PipelineStage {
  final AppLogger? logger;

  DatasetValidationStage({this.logger});

  @override
  PipelineStageKind get kind => PipelineStageKind.datasetValidation;

  @override
  String get name => kind.label;

  @override
  bool get isPlaceholder => false;

  @override
  Future<StageResult> process(PipelineTask task) async {
    final corrupt = task.payload['corrupt'] == true;
    if (corrupt) {
      return StageResult.fail('Dataset validation failed: corrupt payload');
    }
    await Future<void>.delayed(const Duration(milliseconds: 4));
    return StageResult.ok(const {'valid': true});
  }
}

/// Analytics counter / insights refresh stage.
class AnalyticsStage implements PipelineStage {
  final AppLogger? logger;

  AnalyticsStage({this.logger});

  @override
  PipelineStageKind get kind => PipelineStageKind.analytics;

  @override
  String get name => kind.label;

  @override
  bool get isPlaceholder => false;

  @override
  Future<StageResult> process(PipelineTask task) async {
    logger?.debug('Analytics ${task.id}', tag: 'Pipeline');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return StageResult.ok(const {'analyticsUpdated': true});
  }
}

/// Export queue placeholder (future Phase).
class ExportStage implements PipelineStage {
  @override
  PipelineStageKind get kind => PipelineStageKind.export;

  @override
  String get name => kind.label;

  @override
  bool get isPlaceholder => true;

  @override
  Future<StageResult> process(PipelineTask task) async {
    return StageResult.ok(const {'placeholder': true, 'queuedForExport': false});
  }
}

/// Cloud sync placeholder — intentionally no remote I/O.
class CloudSyncStage implements PipelineStage {
  @override
  PipelineStageKind get kind => PipelineStageKind.cloudSync;

  @override
  String get name => kind.label;

  @override
  bool get isPlaceholder => true;

  @override
  Future<StageResult> process(PipelineTask task) async {
    return StageResult.ok(const {'placeholder': true, 'synced': false});
  }
}

/// Factory that builds default stage set (Open/Closed for new stages).
class PipelineStageFactory {
  final AppLogger? logger;

  PipelineStageFactory({this.logger});

  List<PipelineStage> createDefaultChain() => [
        FrameAcquisitionStage(logger: logger),
        MetadataStage(logger: logger),
        StorageStage(logger: logger),
        DatasetValidationStage(logger: logger),
        AnalyticsStage(logger: logger),
        ExportStage(),
        CloudSyncStage(),
      ];

  PipelineStage create(PipelineStageKind kind) {
    return switch (kind) {
      PipelineStageKind.frameAcquisition =>
        FrameAcquisitionStage(logger: logger),
      PipelineStageKind.metadata => MetadataStage(logger: logger),
      PipelineStageKind.storage => StorageStage(logger: logger),
      PipelineStageKind.datasetValidation =>
        DatasetValidationStage(logger: logger),
      PipelineStageKind.analytics => AnalyticsStage(logger: logger),
      PipelineStageKind.export => ExportStage(),
      PipelineStageKind.cloudSync => CloudSyncStage(),
    };
  }
}
