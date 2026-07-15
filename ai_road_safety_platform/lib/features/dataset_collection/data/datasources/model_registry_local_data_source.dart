import 'dart:convert';
import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:path/path.dart' as p;

/// JSON + file access for the local model registry.
abstract class ModelRegistryLocalDataSource {
  Future<List<RegisteredModel>> loadModels();
  Future<void> saveModels(List<RegisteredModel> models);
  Future<ActiveModelPointers> loadActivePointers();
  Future<void> saveActivePointers(ActiveModelPointers pointers);
  Future<ModelArtifact> copyArtifactIntoRegistry({
    required String modelId,
    required String sourcePath,
    required String fileName,
  });
  Future<void> deleteModelDirectory(String modelId);
}

class ModelRegistryLocalDataSourceImpl implements ModelRegistryLocalDataSource {
  final DatasetFileManager _files;
  final AppLogger _logger;

  ModelRegistryLocalDataSourceImpl({
    required DatasetFileManager fileManager,
    required AppLogger logger,
  })  : _files = fileManager,
        _logger = logger;

  Future<String> _registryPath() async {
    await _files.ensureRootLayout();
    return p.join(_files.paths.models, 'registry.json');
  }

  Future<String> _activePath() async {
    await _files.ensureRootLayout();
    return p.join(_files.paths.models, 'active.json');
  }

  @override
  Future<List<RegisteredModel>> loadModels() async {
    final file = File(await _registryPath());
    if (!await file.exists()) return const [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          RegisteredModel.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (e) {
      _logger.warning('Registry load failed: $e', tag: 'ModelRegistry');
      throw CacheException(message: 'Corrupt model registry: $e');
    }
  }

  @override
  Future<void> saveModels(List<RegisteredModel> models) async {
    final file = File(await _registryPath());
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert([
        for (final m in models) m.toJson(),
      ]),
    );
  }

  @override
  Future<ActiveModelPointers> loadActivePointers() async {
    final file = File(await _activePath());
    if (!await file.exists()) {
      return ActiveModelPointers(updatedAt: DateTime.now().toUtc());
    }
    try {
      return ActiveModelPointers.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(await file.readAsString()) as Map,
        ),
      );
    } catch (e) {
      _logger.warning('Active pointers load failed: $e', tag: 'ModelRegistry');
      return ActiveModelPointers(updatedAt: DateTime.now().toUtc());
    }
  }

  @override
  Future<void> saveActivePointers(ActiveModelPointers pointers) async {
    final file = File(await _activePath());
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(pointers.toJson()),
    );
  }

  @override
  Future<ModelArtifact> copyArtifactIntoRegistry({
    required String modelId,
    required String sourcePath,
    required String fileName,
  }) async {
    await _files.ensureRootLayout();
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw CacheException(message: 'Artifact not found: $sourcePath');
    }
    final dir = Directory(_files.paths.modelVersionDir(modelId));
    await dir.create(recursive: true);
    final destPath = p.join(dir.path, fileName);
    await source.copy(destPath);
    final size = await File(destPath).length();
    _logger.info('Artifact copied $destPath ($size bytes)', tag: 'ModelRegistry');
    return ModelArtifact(
      id: 'art-$modelId-${fileName.hashCode.abs()}',
      fileName: fileName,
      absolutePath: destPath,
      byteSize: size,
      source: ModelArtifactSource.imported,
      mimeHint: fileName.endsWith('.tflite')
          ? 'application/tflite'
          : 'text/plain',
    );
  }

  @override
  Future<void> deleteModelDirectory(String modelId) async {
    final dir = Directory(_files.paths.modelVersionDir(modelId));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
