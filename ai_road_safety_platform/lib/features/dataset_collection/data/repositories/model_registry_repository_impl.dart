import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/model_registry_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_registry_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_registry_validator.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ModelRegistryRepositoryImpl implements ModelRegistryRepository {
  final ModelRegistryLocalDataSource _local;
  final ModelRegistryValidator _validator;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final Uuid _uuid;

  ModelRegistryRepositoryImpl({
    required ModelRegistryLocalDataSource localDataSource,
    required ModelRegistryValidator validator,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    Uuid? uuid,
  })  : _local = localDataSource,
        _validator = validator,
        _errorHandler = errorHandler,
        _logger = logger,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<ModelRegistrySnapshot>> loadRegistry() {
    return seedBundledModels();
  }

  @override
  Future<Result<RegisteredModel>> getModel(String modelId) {
    return _guard(() async {
      final models = await _local.loadModels();
      final match = models.where((m) => m.id == modelId);
      if (match.isEmpty) {
        throw const CacheException(message: 'Model not found');
      }
      return match.first;
    });
  }

  @override
  Future<Result<RegisteredModel>> registerModel(RegisteredModel model) {
    return _guard(() async {
      final issues = _validator.validate(model);
      if (issues.isNotEmpty) {
        throw CacheException(message: issues.first.message);
      }
      final models = await _local.loadModels();
      if (models.any((m) => m.id == model.id)) {
        throw const CacheException(message: 'Model id already registered');
      }
      final now = DateTime.now().toUtc();
      final saved = model.copyWith(
        status: model.status == ModelStatus.draft
            ? ModelStatus.registered
            : model.status,
        createdAt: model.createdAt.millisecondsSinceEpoch == 0
            ? now
            : model.createdAt,
        updatedAt: now,
      );
      await _local.saveModels([...models, saved]);
      _logger.info('Model registered ${saved.id}', tag: 'ModelRegistry');
      return saved;
    });
  }

  @override
  Future<Result<RegisteredModel>> updateModel(RegisteredModel model) {
    return _guard(() async {
      final issues = _validator.validate(model);
      if (issues.isNotEmpty) {
        throw CacheException(message: issues.first.message);
      }
      final models = await _local.loadModels();
      final idx = models.indexWhere((m) => m.id == model.id);
      if (idx < 0) throw const CacheException(message: 'Model not found');
      final updated = model.copyWith(updatedAt: DateTime.now().toUtc());
      final next = [...models]..[idx] = updated;
      await _local.saveModels(next);
      _logger.info('Model updated ${updated.id}', tag: 'ModelRegistry');
      return updated;
    });
  }

  @override
  Future<Result<void>> deleteModel(String modelId) {
    return _guard(() async {
      final models = await _local.loadModels();
      final target = models.where((m) => m.id == modelId);
      if (target.isEmpty) {
        throw const CacheException(message: 'Model not found');
      }
      if (target.first.isBundled) {
        throw const CacheException(message: 'Cannot delete bundled models');
      }
      await _local.saveModels(models.where((m) => m.id != modelId).toList());
      await _local.deleteModelDirectory(modelId);
      var active = await _local.loadActivePointers();
      active = _clearPointerIfMatch(active, modelId);
      await _local.saveActivePointers(active);
      _logger.info('Model deleted $modelId', tag: 'ModelRegistry');
    });
  }

  @override
  Future<Result<RegisteredModel>> activateModel(String modelId) {
    return _guard(() async {
      final models = await _local.loadModels();
      final idx = models.indexWhere((m) => m.id == modelId);
      if (idx < 0) throw const CacheException(message: 'Model not found');
      final target = models[idx];
      final issues = _validator.validate(target);
      if (issues.isNotEmpty) {
        throw CacheException(message: issues.first.message);
      }

      final now = DateTime.now().toUtc();
      final next = <RegisteredModel>[];
      for (final m in models) {
        if (m.id == modelId) {
          next.add(m.copyWith(status: ModelStatus.active, updatedAt: now));
        } else if (m.taskType == target.taskType &&
            m.status == ModelStatus.active) {
          next.add(m.copyWith(status: ModelStatus.registered, updatedAt: now));
        } else {
          next.add(m);
        }
      }
      await _local.saveModels(next);

      var pointers = await _local.loadActivePointers();
      pointers = switch (target.taskType) {
        ModelTaskType.objectDetection =>
          pointers.copyWith(detectionModelId: modelId, updatedAt: now),
        ModelTaskType.semanticSegmentation =>
          pointers.copyWith(segmentationModelId: modelId, updatedAt: now),
        ModelTaskType.classification =>
          pointers.copyWith(classificationModelId: modelId, updatedAt: now),
        ModelTaskType.unknown => pointers.copyWith(updatedAt: now),
      };
      await _local.saveActivePointers(pointers);
      _logger.info('Model activated $modelId', tag: 'ModelRegistry');
      return next.firstWhere((m) => m.id == modelId);
    });
  }

  @override
  Future<Result<RegisteredModel>> archiveModel(String modelId) {
    return _guard(() async {
      final models = await _local.loadModels();
      final idx = models.indexWhere((m) => m.id == modelId);
      if (idx < 0) throw const CacheException(message: 'Model not found');
      if (models[idx].isBundled && models[idx].status == ModelStatus.active) {
        // Allow archive of bundled only after deactivate via status change.
      }
      final archived = models[idx].copyWith(
        status: ModelStatus.archived,
        updatedAt: DateTime.now().toUtc(),
      );
      final next = [...models]..[idx] = archived;
      await _local.saveModels(next);
      var active = await _local.loadActivePointers();
      active = _clearPointerIfMatch(active, modelId);
      await _local.saveActivePointers(active);
      return archived;
    });
  }

  @override
  Future<Result<ActiveModelPointers>> getActivePointers() {
    return _guard(_local.loadActivePointers);
  }

  @override
  Future<Result<RegisteredModel>> importLocalArtifact({
    required String name,
    required String version,
    required ModelTaskType taskType,
    required String tfliteSourcePath,
    String? labelsSourcePath,
    String? description,
  }) {
    return _guard(() async {
      final id = _uuid.v4();
      final now = DateTime.now().toUtc();
      final tfliteName = p.basename(tfliteSourcePath);
      final artifact = await _local.copyArtifactIntoRegistry(
        modelId: id,
        sourcePath: tfliteSourcePath,
        fileName: tfliteName.endsWith('.tflite') ? tfliteName : '$tfliteName.tflite',
      );
      final artifacts = <ModelArtifact>[artifact];
      if (labelsSourcePath != null && labelsSourcePath.isNotEmpty) {
        artifacts.add(
          await _local.copyArtifactIntoRegistry(
            modelId: id,
            sourcePath: labelsSourcePath,
            fileName: p.basename(labelsSourcePath),
          ),
        );
      }
      final model = RegisteredModel(
        id: id,
        name: name,
        version: version,
        taskType: taskType,
        status: ModelStatus.registered,
        description: description ?? 'Imported local artifact',
        artifacts: artifacts,
        createdAt: now,
        updatedAt: now,
        tags: const {'source': 'import'},
      );
      return (await registerModel(model)).fold(
        onOk: (v) => v,
        onErr: (f) => throw CacheException(message: f.message),
      );
    });
  }

  @override
  Future<Result<ModelRegistrySnapshot>> seedBundledModels() {
    return _guard(() async {
      final existing = await _local.loadModels();
      final byId = {for (final m in existing) m.id: m};
      var changed = false;
      for (final bundled in BundledModelCatalog.defaults()) {
        if (!byId.containsKey(bundled.id)) {
          byId[bundled.id] = bundled;
          changed = true;
        }
      }
      if (changed) {
        await _local.saveModels(byId.values.toList());
        _logger.info('Bundled models seeded', tag: 'ModelRegistry');
      }
      final active = await _local.loadActivePointers();
      // Activate defaults if none selected.
      var pointers = active;
      final models = byId.values.toList();
      if (pointers.detectionModelId == null) {
        final yolo = models.where((m) => m.id == 'bundled-yolov8n');
        if (yolo.isNotEmpty) {
          await activateModel(yolo.first.id);
          pointers = await _local.loadActivePointers();
        }
      }
      if (pointers.segmentationModelId == null) {
        final flood = models.where((m) => m.id == 'bundled-flood-seg');
        if (flood.isNotEmpty) {
          await activateModel(flood.first.id);
          pointers = await _local.loadActivePointers();
        }
      }
      return ModelRegistrySnapshot(
        models: await _local.loadModels(),
        active: pointers,
        generatedAt: DateTime.now().toUtc(),
      );
    });
  }

  ActiveModelPointers _clearPointerIfMatch(
    ActiveModelPointers active,
    String modelId,
  ) {
    return active.copyWith(
      updatedAt: DateTime.now().toUtc(),
      clearDetection: active.detectionModelId == modelId,
      clearSegmentation: active.segmentationModelId == modelId,
      clearClassification: active.classificationModelId == modelId,
    );
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
