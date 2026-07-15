import 'dart:convert';
import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:path/path.dart' as p;

abstract class ActiveLearningLocalDataSource {
  Future<List<ActiveLearningSelection>> loadSelections();
  Future<void> saveSelections(List<ActiveLearningSelection> selections);
}

class ActiveLearningLocalDataSourceImpl implements ActiveLearningLocalDataSource {
  final DatasetFileManager _files;
  final AppLogger _logger;

  ActiveLearningLocalDataSourceImpl({
    required DatasetFileManager fileManager,
    required AppLogger logger,
  })  : _files = fileManager,
        _logger = logger;

  Future<String> _path() async {
    await _files.ensureRootLayout();
    return p.join(_files.paths.activeLearning, 'selections.json');
  }

  @override
  Future<List<ActiveLearningSelection>> loadSelections() async {
    final file = File(await _path());
    if (!await file.exists()) return const [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          ActiveLearningSelection.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
      ];
    } catch (e) {
      _logger.warning('Active learning load failed: $e', tag: 'ActiveLearning');
      throw CacheException(message: 'Corrupt active learning selections: $e');
    }
  }

  @override
  Future<void> saveSelections(List<ActiveLearningSelection> selections) async {
    final file = File(await _path());
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert([
        for (final s in selections) s.toJson(),
      ]),
    );
  }
}
