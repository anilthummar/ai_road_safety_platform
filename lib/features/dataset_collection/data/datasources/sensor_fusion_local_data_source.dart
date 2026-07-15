import 'dart:convert';
import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:path/path.dart' as p;

abstract class SensorFusionLocalDataSource {
  Future<List<FusedSample>> loadSamples();
  Future<void> saveSamples(List<FusedSample> samples);
  Future<SensorFusionSession?> loadSession();
  Future<void> saveSession(SensorFusionSession? session);
}

class SensorFusionLocalDataSourceImpl implements SensorFusionLocalDataSource {
  final DatasetFileManager _files;
  final AppLogger _logger;

  SensorFusionLocalDataSourceImpl({
    required DatasetFileManager fileManager,
    required AppLogger logger,
  })  : _files = fileManager,
        _logger = logger;

  Future<String> _samplesPath() async {
    await _files.ensureRootLayout();
    return p.join(_files.paths.sensorFusion, 'samples.json');
  }

  Future<String> _sessionPath() async {
    await _files.ensureRootLayout();
    return p.join(_files.paths.sensorFusion, 'session.json');
  }

  @override
  Future<List<FusedSample>> loadSamples() async {
    final file = File(await _samplesPath());
    if (!await file.exists()) return const [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          FusedSample.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (e) {
      _logger.warning('Fusion samples load failed: $e', tag: 'SensorFusion');
      throw CacheException(message: 'Corrupt fusion samples: $e');
    }
  }

  @override
  Future<void> saveSamples(List<FusedSample> samples) async {
    final file = File(await _samplesPath());
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert([
        for (final s in samples) s.toJson(),
      ]),
    );
  }

  @override
  Future<SensorFusionSession?> loadSession() async {
    final file = File(await _sessionPath());
    if (!await file.exists()) return null;
    try {
      return SensorFusionSession.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(await file.readAsString()) as Map,
        ),
      );
    } catch (e) {
      _logger.warning('Fusion session load failed: $e', tag: 'SensorFusion');
      return null;
    }
  }

  @override
  Future<void> saveSession(SensorFusionSession? session) async {
    final file = File(await _sessionPath());
    await file.parent.create(recursive: true);
    if (session == null) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(session.toJson()),
    );
  }
}
