import 'dart:convert';
import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:path/path.dart' as p;

/// JSON file access for annotations / labels / ground truth.
abstract class AnnotationLocalDataSource {
  Future<List<AnnotationLabel>> loadLabels();
  Future<void> saveLabels(List<AnnotationLabel> labels);

  Future<GroundTruth?> loadGroundTruth({
    required String sessionId,
    required int frameNumber,
  });

  Future<void> saveGroundTruth(GroundTruth groundTruth);

  Future<List<AnnotatableFrame>> listFrames(String sessionId);

  Future<List<GroundTruth>> loadAllGroundTruth(String sessionId);
}

class AnnotationLocalDataSourceImpl implements AnnotationLocalDataSource {
  final DatasetFileManager _files;
  final AppLogger _logger;

  AnnotationLocalDataSourceImpl({
    required DatasetFileManager fileManager,
    required AppLogger logger,
  })  : _files = fileManager,
        _logger = logger;

  Future<String> _annotationsRoot() async {
    await _files.ensureRootLayout();
    final root = p.join(_files.paths.root, 'annotations');
    await Directory(root).create(recursive: true);
    return root;
  }

  Future<String> _labelsPath() async =>
      p.join(await _annotationsRoot(), 'labels.json');

  Future<String> _gtPath(String sessionId, int frameNumber) async {
    final dir = p.join(await _annotationsRoot(), sessionId);
    await Directory(dir).create(recursive: true);
    return p.join(
      dir,
      '${DatasetPaths.frameStem(frameNumber)}_gt.json',
    );
  }

  @override
  Future<List<AnnotationLabel>> loadLabels() async {
    final path = await _labelsPath();
    final file = File(path);
    if (!await file.exists()) {
      await saveLabels(DefaultHazardLabels.all);
      return DefaultHazardLabels.all;
    }
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return DefaultHazardLabels.all;
      return [
        for (final item in raw)
          AnnotationLabel.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (e) {
      _logger.warning('Labels load failed: $e', tag: 'Annotation');
      return DefaultHazardLabels.all;
    }
  }

  @override
  Future<void> saveLabels(List<AnnotationLabel> labels) async {
    final file = File(await _labelsPath());
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert([
        for (final l in labels) l.toJson(),
      ]),
    );
  }

  @override
  Future<GroundTruth?> loadGroundTruth({
    required String sessionId,
    required int frameNumber,
  }) async {
    final path = await _gtPath(sessionId, frameNumber);
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      return GroundTruth.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(await file.readAsString()) as Map,
        ),
      );
    } catch (e) {
      throw CacheException(message: 'Corrupt ground truth: $e');
    }
  }

  @override
  Future<void> saveGroundTruth(GroundTruth groundTruth) async {
    final path = await _gtPath(groundTruth.sessionId, groundTruth.frameNumber);
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(groundTruth.toJson()),
    );
  }

  @override
  Future<List<AnnotatableFrame>> listFrames(String sessionId) async {
    await _files.ensureRootLayout();
    final originals = Directory(_files.paths.imagesOriginal(sessionId));
    final frames = <int>{};
    if (await originals.exists()) {
      await for (final e in originals.list(followLinks: false)) {
        if (e is! File) continue;
        final name = p.basename(e.path);
        final m = RegExp(r'frame_(\d+)\.jpg').firstMatch(name);
        if (m != null) frames.add(int.parse(m.group(1)!));
      }
    }
    // Frames that only have GT JSON.
    final gtDir = Directory(p.join(await _annotationsRoot(), sessionId));
    if (await gtDir.exists()) {
      await for (final e in gtDir.list(followLinks: false)) {
        if (e is! File) continue;
        final m = RegExp(r'frame_(\d+)_gt\.json').firstMatch(p.basename(e.path));
        if (m != null) frames.add(int.parse(m.group(1)!));
      }
    }
    // Frames present as metadata only (images not yet persisted).
    final metaDir = Directory(_files.paths.frameMetadataDir(sessionId));
    if (await metaDir.exists()) {
      await for (final e in metaDir.list(followLinks: false)) {
        if (e is! File) continue;
        final m = RegExp(r'frame_(\d+)\.json').firstMatch(p.basename(e.path));
        if (m != null) frames.add(int.parse(m.group(1)!));
      }
    }

    final sorted = frames.toList()..sort();
    final result = <AnnotatableFrame>[];
    for (final n in sorted) {
      final imagePath = p.join(
        _files.paths.imagesOriginal(sessionId),
        DatasetPaths.originalFileName(n),
      );
      final exists = await File(imagePath).exists();
      final gt = await loadGroundTruth(sessionId: sessionId, frameNumber: n);
      result.add(
        AnnotatableFrame(
          sessionId: sessionId,
          frameNumber: n,
          imagePath: exists ? imagePath : null,
          status: gt?.frameStatus ?? AnnotationStatus.unannotated,
          annotationCount: gt?.annotations.length ?? 0,
        ),
      );
    }
    return result;
  }

  @override
  Future<List<GroundTruth>> loadAllGroundTruth(String sessionId) async {
    final dir = Directory(p.join(await _annotationsRoot(), sessionId));
    if (!await dir.exists()) return const [];
    final list = <GroundTruth>[];
    await for (final e in dir.list(followLinks: false)) {
      if (e is! File || !e.path.endsWith('_gt.json')) continue;
      try {
        list.add(
          GroundTruth.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(await e.readAsString()) as Map,
            ),
          ),
        );
      } catch (_) {}
    }
    return list;
  }
}
