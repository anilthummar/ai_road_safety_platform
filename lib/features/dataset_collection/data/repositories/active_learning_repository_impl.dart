import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/active_learning_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/active_learning_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/annotation_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/dataset_collection_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/active_learning_engine.dart';
import 'package:uuid/uuid.dart';

class ActiveLearningRepositoryImpl implements ActiveLearningRepository {
  final ActiveLearningLocalDataSource _local;
  final ActiveLearningEngine _engine;
  final AnnotationRepository _annotations;
  final DatasetCollectionRepository _sessions;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final Uuid _uuid;

  ActiveLearningRepositoryImpl({
    required ActiveLearningLocalDataSource localDataSource,
    required ActiveLearningEngine engine,
    required AnnotationRepository annotationRepository,
    required DatasetCollectionRepository collectionRepository,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    Uuid? uuid,
  })  : _local = localDataSource,
        _engine = engine,
        _annotations = annotationRepository,
        _sessions = collectionRepository,
        _errorHandler = errorHandler,
        _logger = logger,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<ActiveLearningSnapshot>> loadSnapshot() {
    return _guard(() async {
      final selections = await _local.loadSelections();
      return ActiveLearningSnapshot(
        selections: selections,
        generatedAt: DateTime.now().toUtc(),
      );
    });
  }

  @override
  Future<Result<ActiveLearningSelection>> getSelection(String selectionId) {
    return _guard(() async {
      final selections = await _local.loadSelections();
      final match = selections.where((s) => s.id == selectionId);
      if (match.isEmpty) {
        throw const CacheException(message: 'Selection not found');
      }
      return match.first;
    });
  }

  @override
  Future<Result<ActiveLearningSelection>> runSelection({
    List<String> sessionIds = const [],
    ActiveLearningStrategyConfig config = ActiveLearningStrategyConfig.defaults,
  }) {
    return _guard(() async {
      var ids = sessionIds.where((s) => s.trim().isNotEmpty).toList();
      if (ids.isEmpty) {
        final all = await _sessions.getSessions();
        ids = all.fold(
          onOk: (list) => list.map((s) => s.id).toList(),
          onErr: (f) => throw CacheException(message: f.message),
        );
      }
      if (ids.isEmpty) {
        throw const CacheException(
          message: 'No sessions available for sample selection',
        );
      }

      final inputs = <ActiveLearningFrameInput>[];
      for (final sessionId in ids) {
        final gtResult =
            await _annotations.loadSessionGroundTruth(sessionId);
        final gts = gtResult.fold(
          onOk: (v) => v,
          onErr: (_) => const <GroundTruth>[],
        );
        if (gts.isNotEmpty) {
          for (final gt in gts) {
            inputs.add(_engine.fromGroundTruth(gt));
          }
          continue;
        }
        // Fallback: image/listFrames without GT JSON detail.
        final framesResult = await _annotations.listFrames(sessionId);
        final frames = framesResult.fold(
          onOk: (v) => v,
          onErr: (_) => const <AnnotatableFrame>[],
        );
        for (final f in frames) {
          inputs.add(_engine.fromAnnotatableFrame(f));
        }
      }

      if (inputs.isEmpty) {
        throw const CacheException(
          message: 'No frames found to rank for active learning',
        );
      }

      final freqs = _engine.labelFrequencies(inputs);
      final candidates = _engine.rank(frames: inputs, config: config);
      final selection = ActiveLearningSelection(
        id: _uuid.v4(),
        sessionIds: ids,
        config: config,
        candidates: candidates,
        framesConsidered: inputs.length,
        labelFrequencies: freqs,
        notes: candidates.isEmpty
            ? 'No priority samples (all frames look well-labeled)'
            : 'Ranked ${candidates.length} of ${inputs.length} frames',
        createdAt: DateTime.now().toUtc(),
      );

      final existing = await _local.loadSelections();
      await _local.saveSelections([selection, ...existing]);
      _logger.info(
        'Active learning ${selection.id} selected=${selection.selectedCount} '
        'of ${selection.framesConsidered}',
        tag: 'ActiveLearning',
      );
      return selection;
    });
  }

  @override
  Future<Result<void>> deleteSelection(String selectionId) {
    return _guard(() async {
      final selections = await _local.loadSelections();
      if (!selections.any((s) => s.id == selectionId)) {
        throw const CacheException(message: 'Selection not found');
      }
      await _local.saveSelections(
        selections.where((s) => s.id != selectionId).toList(),
      );
      _logger.info('Selection deleted $selectionId', tag: 'ActiveLearning');
    });
  }

  @override
  Future<Result<ActiveLearningSelection>> createDemoSelection() {
    return _guard(() async {
      const config = ActiveLearningStrategyConfig(topK: 10);
      final frames = <ActiveLearningFrameInput>[
        const ActiveLearningFrameInput(
          sessionId: 'demo-session',
          frameNumber: 1,
          frameStatus: 'unannotated',
          annotationCount: 0,
        ),
        const ActiveLearningFrameInput(
          sessionId: 'demo-session',
          frameNumber: 2,
          frameStatus: 'draft',
          annotationCount: 2,
          aiAnnotationCount: 2,
          humanAnnotationCount: 0,
          minAiConfidence: 0.32,
          labelIds: ['pothole', 'obstacle'],
        ),
        const ActiveLearningFrameInput(
          sessionId: 'demo-session',
          frameNumber: 3,
          frameStatus: 'needsReview',
          annotationCount: 1,
          humanAnnotationCount: 1,
          labelIds: ['flooded_road'],
        ),
        const ActiveLearningFrameInput(
          sessionId: 'demo-session',
          frameNumber: 4,
          frameStatus: 'approved',
          annotationCount: 3,
          humanAnnotationCount: 3,
          labelIds: ['pothole', 'pothole', 'pothole'],
        ),
        const ActiveLearningFrameInput(
          sessionId: 'demo-session',
          frameNumber: 5,
          frameStatus: 'draft',
          annotationCount: 1,
          humanAnnotationCount: 1,
          labelIds: ['edge_damage'],
        ),
      ];
      final freqs = _engine.labelFrequencies(frames);
      final candidates = _engine.rank(frames: frames, config: config);
      final selection = ActiveLearningSelection(
        id: _uuid.v4(),
        sessionIds: const ['demo-session'],
        config: config,
        candidates: candidates,
        framesConsidered: frames.length,
        labelFrequencies: freqs,
        notes: 'Demo smart sample selection',
        isDemo: true,
        createdAt: DateTime.now().toUtc(),
      );
      final existing = await _local.loadSelections();
      await _local.saveSelections([selection, ...existing]);
      _logger.info('Demo selection ${selection.id}', tag: 'ActiveLearning');
      return selection;
    });
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (f) {
      return Err(f);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}
