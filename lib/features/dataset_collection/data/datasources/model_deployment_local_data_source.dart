import 'dart:convert';
import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:path/path.dart' as p;

abstract class ModelDeploymentLocalDataSource {
  Future<List<DeploymentPackage>> loadPackages();
  Future<void> savePackages(List<DeploymentPackage> packages);
  Future<ActiveDeploymentPointers> loadActivePointers();
  Future<void> saveActivePointers(ActiveDeploymentPointers pointers);
  Future<String> packageDir(String deploymentId);
  Future<DeploymentArtifact> materializeArtifact({
    required String deploymentId,
    required String fileName,
    String? absoluteSourcePath,
    String? assetPath,
    String role,
  });
  Future<void> deletePackageDirectory(String deploymentId);
}

class ModelDeploymentLocalDataSourceImpl
    implements ModelDeploymentLocalDataSource {
  final DatasetFileManager _files;
  final AppLogger _logger;

  ModelDeploymentLocalDataSourceImpl({
    required DatasetFileManager fileManager,
    required AppLogger logger,
  })  : _files = fileManager,
        _logger = logger;

  Future<String> _packagesPath() async {
    await _files.ensureRootLayout();
    return p.join(_files.paths.deployments, 'packages.json');
  }

  Future<String> _activePath() async {
    await _files.ensureRootLayout();
    return p.join(_files.paths.deployments, 'active.json');
  }

  @override
  Future<String> packageDir(String deploymentId) async {
    await _files.ensureRootLayout();
    final dir = Directory(
      p.join(_files.paths.deploymentPackages, deploymentId),
    );
    await dir.create(recursive: true);
    return dir.path;
  }

  @override
  Future<List<DeploymentPackage>> loadPackages() async {
    final file = File(await _packagesPath());
    if (!await file.exists()) return const [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          DeploymentPackage.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (e) {
      _logger.warning('Deployment packages load failed: $e', tag: 'Deploy');
      throw CacheException(message: 'Corrupt deployment packages: $e');
    }
  }

  @override
  Future<void> savePackages(List<DeploymentPackage> packages) async {
    final file = File(await _packagesPath());
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert([
        for (final p in packages) p.toJson(),
      ]),
    );
  }

  @override
  Future<ActiveDeploymentPointers> loadActivePointers() async {
    final file = File(await _activePath());
    if (!await file.exists()) {
      return ActiveDeploymentPointers(updatedAt: DateTime.now().toUtc());
    }
    try {
      return ActiveDeploymentPointers.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(await file.readAsString()) as Map,
        ),
      );
    } catch (e) {
      _logger.warning('Active deployment pointers load failed: $e', tag: 'Deploy');
      return ActiveDeploymentPointers(updatedAt: DateTime.now().toUtc());
    }
  }

  @override
  Future<void> saveActivePointers(ActiveDeploymentPointers pointers) async {
    final file = File(await _activePath());
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(pointers.toJson()),
    );
  }

  @override
  Future<DeploymentArtifact> materializeArtifact({
    required String deploymentId,
    required String fileName,
    String? absoluteSourcePath,
    String? assetPath,
    String role = 'model',
  }) async {
    final dir = await packageDir(deploymentId);
    final destPath = p.join(dir, fileName);

    if (absoluteSourcePath != null && absoluteSourcePath.isNotEmpty) {
      final source = File(absoluteSourcePath);
      if (await source.exists()) {
        await source.copy(destPath);
        final size = await File(destPath).length();
        _logger.info(
          'Packaged $destPath ($size bytes)',
          tag: 'Deploy',
        );
        return DeploymentArtifact(
          fileName: fileName,
          absolutePath: destPath,
          sourceAssetPath: assetPath,
          byteSize: size,
          role: role,
        );
      }
    }

    // Bundled asset — record path without binary copy (Flutter assets).
    return DeploymentArtifact(
      fileName: fileName,
      sourceAssetPath: assetPath,
      absolutePath: null,
      byteSize: 0,
      role: role,
    );
  }

  @override
  Future<void> deletePackageDirectory(String deploymentId) async {
    final dir = Directory(
      p.join(_files.paths.deploymentPackages, deploymentId),
    );
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
