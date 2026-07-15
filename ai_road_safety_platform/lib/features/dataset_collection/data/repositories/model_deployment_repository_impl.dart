import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/model_deployment_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_deployment_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/model_registry_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/model_deployment_engine.dart';
import 'package:uuid/uuid.dart';

class ModelDeploymentRepositoryImpl implements ModelDeploymentRepository {
  final ModelDeploymentLocalDataSource _local;
  final ModelDeploymentEngine _engine;
  final ModelRegistryRepository _models;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final Uuid _uuid;

  ModelDeploymentRepositoryImpl({
    required ModelDeploymentLocalDataSource localDataSource,
    required ModelDeploymentEngine engine,
    required ModelRegistryRepository modelRegistryRepository,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    Uuid? uuid,
  })  : _local = localDataSource,
        _engine = engine,
        _models = modelRegistryRepository,
        _errorHandler = errorHandler,
        _logger = logger,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<DeploymentSnapshot>> loadSnapshot() {
    return _guard(() async {
      return DeploymentSnapshot(
        packages: await _local.loadPackages(),
        active: await _local.loadActivePointers(),
        generatedAt: DateTime.now().toUtc(),
      );
    });
  }

  @override
  Future<Result<DeploymentPackage>> getPackage(String deploymentId) {
    return _guard(() async {
      final packages = await _local.loadPackages();
      final match = packages.where((p) => p.id == deploymentId);
      if (match.isEmpty) {
        throw const CacheException(message: 'Deployment not found');
      }
      return match.first;
    });
  }

  @override
  Future<Result<DeploymentPackage>> stageFromModel(String modelId) {
    return _guard(() async {
      final modelResult = await _models.getModel(modelId);
      final model = modelResult.fold(
        onOk: (m) => m,
        onErr: (f) => throw CacheException(message: f.message),
      );
      final issues = _engine.validateForStage(model);
      if (issues.isNotEmpty) {
        throw CacheException(message: issues.first);
      }

      final id = _uuid.v4();
      final now = DateTime.now().toUtc();
      final dir = await _local.packageDir(id);
      final artifacts = <DeploymentArtifact>[];
      for (final a in model.artifacts) {
        final role = a.fileName.endsWith('.tflite') ? 'model' : 'sidecar';
        artifacts.add(
          await _local.materializeArtifact(
            deploymentId: id,
            fileName: a.fileName,
            absoluteSourcePath: a.absolutePath,
            assetPath: a.assetPath,
            role: role,
          ),
        );
      }

      final package = DeploymentPackage(
        id: id,
        modelId: model.id,
        modelVersion: model.version,
        displayName: '${model.name} · ${model.version}',
        taskType: model.taskType,
        status: DeploymentStatus.staged,
        artifacts: artifacts,
        packageDir: dir,
        notes: 'Staged from model registry',
        createdAt: now,
      );
      final validate = _engine.validatePackage(package);
      if (validate.isNotEmpty) {
        throw CacheException(message: validate.first);
      }

      final packages = await _local.loadPackages();
      await _local.savePackages([package, ...packages]);
      _logger.info('Staged deployment $id for ${model.id}', tag: 'Deploy');
      return package;
    });
  }

  @override
  Future<Result<DeploymentPackage>> activateDeployment(String deploymentId) {
    return _guard(() async {
      final packages = await _local.loadPackages();
      final idx = packages.indexWhere((p) => p.id == deploymentId);
      if (idx < 0) {
        throw const CacheException(message: 'Deployment not found');
      }
      final target = packages[idx];
      if (target.status == DeploymentStatus.failed) {
        throw const CacheException(message: 'Cannot activate a failed package');
      }
      if (target.status == DeploymentStatus.archived) {
        throw const CacheException(
          message: 'Cannot activate an archived package',
        );
      }

      final now = DateTime.now().toUtc();
      var pointers = await _local.loadActivePointers();
      final previousActiveId = pointers.idForTask(target.taskType);

      final rebuilt = <DeploymentPackage>[];
      for (final p in packages) {
        if (p.id == deploymentId) {
          rebuilt.add(
            p.copyWith(
              status: DeploymentStatus.active,
              previousDeploymentId: previousActiveId == deploymentId
                  ? p.previousDeploymentId
                  : previousActiveId,
              activatedAt: now,
              clearRolledBackAt: true,
            ),
          );
        } else if (p.taskType == target.taskType &&
            p.status == DeploymentStatus.active) {
          rebuilt.add(p.copyWith(status: DeploymentStatus.staged));
        } else {
          rebuilt.add(p);
        }
      }

      await _local.savePackages(rebuilt);
      pointers = _engine.setActivePointer(
        current: pointers,
        taskType: target.taskType,
        deploymentId: deploymentId,
        now: now,
      );
      await _local.saveActivePointers(pointers);

      // Keep model registry in sync for the same task family.
      final activateModel = await _models.activateModel(target.modelId);
      activateModel.fold(
        onOk: (_) {},
        onErr: (f) => _logger.warning(
          'Registry activate skipped: ${f.message}',
          tag: 'Deploy',
        ),
      );

      _logger.info('Activated deployment $deploymentId', tag: 'Deploy');
      return rebuilt.firstWhere((p) => p.id == deploymentId);
    });
  }

  @override
  Future<Result<DeploymentPackage>> rollbackDeployment(String deploymentId) {
    return _guard(() async {
      final packages = await _local.loadPackages();
      final currentIdx = packages.indexWhere((p) => p.id == deploymentId);
      if (currentIdx < 0) {
        throw const CacheException(message: 'Deployment not found');
      }
      final current = packages[currentIdx];
      final previousId = current.previousDeploymentId;
      if (previousId == null || previousId.isEmpty) {
        throw const CacheException(
          message: 'No previous deployment to roll back to',
        );
      }
      if (!packages.any((p) => p.id == previousId)) {
        throw const CacheException(
          message: 'Previous deployment package is missing',
        );
      }

      final now = DateTime.now().toUtc();
      // Mark current as rolled back first, then activate previous.
      final marked = [
        for (final p in packages)
          if (p.id == deploymentId)
            p.copyWith(
              status: DeploymentStatus.rolledBack,
              rolledBackAt: now,
            )
          else
            p,
      ];
      await _local.savePackages(marked);

      final activated = await activateDeployment(previousId);
      return activated.fold(
        onOk: (pkg) {
          _logger.info(
            'Rolled back $deploymentId → ${pkg.id}',
            tag: 'Deploy',
          );
          return pkg;
        },
        onErr: (f) => throw CacheException(message: f.message),
      );
    });
  }

  @override
  Future<Result<void>> deletePackage(String deploymentId) {
    return _guard(() async {
      final packages = await _local.loadPackages();
      final target = packages.where((p) => p.id == deploymentId);
      if (target.isEmpty) {
        throw const CacheException(message: 'Deployment not found');
      }
      if (target.first.status == DeploymentStatus.active) {
        throw const CacheException(
          message: 'Cannot delete the active deployment — roll back first',
        );
      }
      await _local.savePackages(
        packages.where((p) => p.id != deploymentId).toList(),
      );
      await _local.deletePackageDirectory(deploymentId);
      var pointers = await _local.loadActivePointers();
      final now = DateTime.now().toUtc();
      pointers = pointers.copyWith(
        updatedAt: now,
        clearDetection: pointers.detectionDeploymentId == deploymentId,
        clearSegmentation: pointers.segmentationDeploymentId == deploymentId,
        clearClassification:
            pointers.classificationDeploymentId == deploymentId,
      );
      await _local.saveActivePointers(pointers);
      _logger.info('Deleted deployment $deploymentId', tag: 'Deploy');
    });
  }

  @override
  Future<Result<ActiveDeploymentPointers>> getActivePointers() {
    return _guard(_local.loadActivePointers);
  }

  @override
  Future<Result<DeployedModelResolution>> resolveActiveModel(
    ModelTaskType taskType, {
    String? fallbackAssetPath,
  }) {
    return _guard(() async {
      final snap = DeploymentSnapshot(
        packages: await _local.loadPackages(),
        active: await _local.loadActivePointers(),
        generatedAt: DateTime.now().toUtc(),
      );
      return _engine.resolve(
        taskType: taskType,
        snapshot: snap,
        fallbackAssetPath: fallbackAssetPath,
      );
    });
  }

  @override
  Future<Result<DeploymentPackage>> createDemoPackage() {
    return _guard(() async {
      // Ensure bundled models exist, then stage + activate detection.
      await _models.seedBundledModels();
      final staged = await stageFromModel('bundled-yolov8n');
      final package = staged.fold(
        onOk: (p) => p,
        onErr: (f) => throw CacheException(message: f.message),
      );
      final withDemo = package.copyWith(
        isDemo: true,
        notes: 'Demo edge package from bundled YOLOv8n',
      );
      final packages = await _local.loadPackages();
      final idx = packages.indexWhere((p) => p.id == package.id);
      if (idx >= 0) {
        final next = [...packages]..[idx] = withDemo;
        await _local.savePackages(next);
      }
      final activated = await activateDeployment(package.id);
      return activated.fold(
        onOk: (p) => p.copyWith(isDemo: true),
        onErr: (f) => throw CacheException(message: f.message),
      );
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
