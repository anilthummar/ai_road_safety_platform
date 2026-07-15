import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/features/camera/data/datasources/camera_local_data_source.dart';
import 'package:ai_road_safety_platform/features/history/data/datasources/history_local_data_source.dart';
import 'package:ai_road_safety_platform/features/history/data/models/history_record_hive.dart';
import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Hive box name for history records.
const String historyBoxName = 'history_records';

/// Initializes Hive and opens the history box. Call once at app start.
Future<Box<HistoryRecordHive>> openHistoryHiveBox() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(historyRecordHiveTypeId)) {
    Hive.registerAdapter(HistoryRecordHiveAdapter());
  }
  return Hive.openBox<HistoryRecordHive>(historyBoxName);
}

/// Hive + documents-directory implementation of [HistoryLocalDataSource].
class HiveHistoryLocalDataSource implements HistoryLocalDataSource {
  /// Creates [HiveHistoryLocalDataSource].
  HiveHistoryLocalDataSource({
    required Box<HistoryRecordHive> box,
    required CameraLocalDataSource cameraDataSource,
    Uuid uuid = const Uuid(),
  })  : _box = box,
        _camera = cameraDataSource,
        _uuid = uuid;

  final Box<HistoryRecordHive> _box;
  final CameraLocalDataSource _camera;
  final Uuid _uuid;

  @override
  Stream<List<HistoryRecord>> watchRecords() async* {
    yield _sortedDomain();
    yield* _box.watch().map((_) => _sortedDomain());
  }

  @override
  Future<List<HistoryRecord>> getRecords() async => _sortedDomain();

  @override
  Future<HistoryRecord> saveRecord(HistoryRecordDraft draft) async {
    try {
      final id = _uuid.v4();
      var imagePath = draft.imagePath;

      if (draft.captureImage && (imagePath == null || imagePath.isEmpty)) {
        imagePath = await _tryCaptureImage(id);
      }

      final record = HistoryRecord(
        id: id,
        timestamp: draft.timestamp,
        floodPercent: draft.floodPercent,
        riskLevel: draft.riskLevel,
        riskScore: draft.riskScore,
        latitude: draft.latitude,
        longitude: draft.longitude,
        speedKmh: draft.speedKmh,
        accuracyMeters: draft.accuracyMeters,
        imagePath: imagePath,
        notes: draft.notes,
      );

      await _box.put(id, HistoryRecordHive.fromDomain(record));
      return record;
    } catch (error, stackTrace) {
      throw CacheException(
        message: 'Failed to save history record: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteRecord(String id) async {
    try {
      final existing = _box.get(id);
      await _box.delete(id);
      await _deleteImageFile(existing?.imagePath);
    } catch (error, stackTrace) {
      throw CacheException(
        message: 'Failed to delete history record: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteRecords(List<String> ids) async {
    for (final id in ids) {
      await deleteRecord(id);
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final paths = _box.values
          .map((e) => e.imagePath)
          .whereType<String>()
          .toList();
      await _box.clear();
      for (final path in paths) {
        await _deleteImageFile(path);
      }
    } catch (error, stackTrace) {
      throw CacheException(
        message: 'Failed to clear history: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<HistoryExportResult> exportJson(List<HistoryRecord> records) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${exportDir.path}/history_export_$stamp.json');
      final payload = {
        'exportedAt': DateTime.now().toIso8601String(),
        'count': records.length,
        'records': records.map((r) => r.toJson()).toList(),
      };
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
      );
      return HistoryExportResult(
        filePath: file.path,
        recordCount: records.length,
      );
    } catch (error, stackTrace) {
      throw CacheException(
        message: 'Failed to export history JSON: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  List<HistoryRecord> _sortedDomain() {
    final list = _box.values.map((e) => e.toDomain()).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<String?> _tryCaptureImage(String id) async {
    final controller = _camera.activeController;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }
    try {
      // takePicture is unreliable while an image stream is active.
      await _camera.stopFrameStreaming();
      final shot = await controller.takePicture();
      final docs = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${docs.path}/history_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final dest = File('${imagesDir.path}/$id.jpg');
      await File(shot.path).copy(dest.path);
      try {
        await File(shot.path).delete();
      } catch (_) {}
      await _camera.startFrameStreaming();
      return dest.path;
    } catch (_) {
      try {
        await _camera.startFrameStreaming();
      } catch (_) {}
      return null;
    }
  }

  Future<void> _deleteImageFile(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
