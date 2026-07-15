import 'dart:convert';
import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:path/path.dart' as p;

abstract class ModelBenchmarkLocalDataSource {
  Future<List<BenchmarkReport>> loadReports();
  Future<void> saveReports(List<BenchmarkReport> reports);
}

class ModelBenchmarkLocalDataSourceImpl implements ModelBenchmarkLocalDataSource {
  final DatasetFileManager _files;
  final AppLogger _logger;

  ModelBenchmarkLocalDataSourceImpl({
    required DatasetFileManager fileManager,
    required AppLogger logger,
  })  : _files = fileManager,
        _logger = logger;

  Future<String> _path() async {
    await _files.ensureRootLayout();
    return p.join(_files.paths.benchmarks, 'reports.json');
  }

  @override
  Future<List<BenchmarkReport>> loadReports() async {
    final file = File(await _path());
    if (!await file.exists()) return const [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          BenchmarkReport.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (e) {
      _logger.warning('Benchmark load failed: $e', tag: 'Benchmark');
      throw CacheException(message: 'Corrupt benchmark reports: $e');
    }
  }

  @override
  Future<void> saveReports(List<BenchmarkReport> reports) async {
    final file = File(await _path());
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert([
        for (final r in reports) r.toJson(),
      ]),
    );
  }
}
