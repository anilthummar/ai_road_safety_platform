import 'dart:convert';
import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/experiment_tracking_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:path/path.dart' as p;

/// JSON persistence for local experiment runs.
abstract class ExperimentTrackingLocalDataSource {
  Future<List<ExperimentRun>> loadRuns();
  Future<void> saveRuns(List<ExperimentRun> runs);
}

class ExperimentTrackingLocalDataSourceImpl
    implements ExperimentTrackingLocalDataSource {
  final DatasetFileManager _files;
  final AppLogger _logger;

  ExperimentTrackingLocalDataSourceImpl({
    required DatasetFileManager fileManager,
    required AppLogger logger,
  })  : _files = fileManager,
        _logger = logger;

  Future<String> _runsPath() async {
    await _files.ensureRootLayout();
    return p.join(_files.paths.experiments, 'runs.json');
  }

  @override
  Future<List<ExperimentRun>> loadRuns() async {
    final file = File(await _runsPath());
    if (!await file.exists()) return const [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          ExperimentRun.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (e) {
      _logger.warning('Experiment runs load failed: $e', tag: 'Experiments');
      throw CacheException(message: 'Corrupt experiment runs: $e');
    }
  }

  @override
  Future<void> saveRuns(List<ExperimentRun> runs) async {
    final file = File(await _runsPath());
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert([
        for (final r in runs) r.toJson(),
      ]),
    );
  }
}
