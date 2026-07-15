import 'dart:io';

import 'package:ai_road_safety_platform/core/constants/app_config.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/datasources/dataset_collection_local_data_source.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/data/models/dataset_session_hive.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Prefs key for unfinished recording session id.
const String datasetCurrentSessionIdKey = 'dataset.current_session_id';

/// Opens the dataset sessions Hive box (idempotent init).
Future<Box<DatasetSessionHive>> openDatasetSessionsHiveBox() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(datasetSessionHiveTypeId)) {
    Hive.registerAdapter(DatasetSessionHiveAdapter());
  }
  return Hive.openBox<DatasetSessionHive>(datasetSessionsBoxName);
}

/// Hive-backed [DatasetCollectionLocalDataSource] (session manager — Phase 12.2).
class HiveDatasetCollectionLocalDataSource
    implements DatasetCollectionLocalDataSource {
  final Box<DatasetSessionHive> _box;
  final SharedPreferences _prefs;
  final Uuid _uuid;

  /// Creates [HiveDatasetCollectionLocalDataSource].
  HiveDatasetCollectionLocalDataSource({
    required Box<DatasetSessionHive> box,
    required SharedPreferences preferences,
    Uuid? uuid,
  })  : _box = box,
        _prefs = preferences,
        _uuid = uuid ?? const Uuid();

  @override
  Future<DatasetSession> createSession(CreateDatasetSessionParams params) {
    return saveSession(buildNewSession(params));
  }

  @override
  Future<DatasetSession> startRecordingSession(
    CreateDatasetSessionParams params,
  ) {
    final now = DateTime.now();
    return saveSession(
      buildNewSession(params).copyWith(
        status: DatasetSessionStatus.recording,
        startedAt: now,
        updatedAt: now,
        clearEndedAt: true,
      ),
    );
  }

  @override
  Future<DatasetSession> saveSession(DatasetSession session) async {
    try {
      await _box.put(session.id, DatasetSessionHive.fromDomain(session));
      return session;
    } catch (error, stackTrace) {
      throw CacheException(
        message: 'Failed to save dataset session: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<DatasetSession> updateSession(DatasetSession session) async {
    if (!_box.containsKey(session.id)) {
      throw const CacheException(message: 'Dataset session not found.');
    }
    return saveSession(session);
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      if (!_box.containsKey(id)) {
        throw const CacheException(message: 'Dataset session not found.');
      }
      await _box.delete(id);
      final current = _prefs.getString(datasetCurrentSessionIdKey);
      if (current == id) {
        await setCurrentSessionId(null);
      }
    } catch (error, stackTrace) {
      if (error is CacheException) rethrow;
      throw CacheException(
        message: 'Failed to delete dataset session: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<DatasetSession>> getSessions() async {
    try {
      return _sortedDomain();
    } catch (error, stackTrace) {
      throw CacheException(
        message: 'Failed to read dataset sessions: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<DatasetSession> getSession(String id) async {
    try {
      final hive = _box.get(id);
      if (hive == null) {
        throw const CacheException(message: 'Dataset session not found.');
      }
      return hive.toDomain();
    } catch (error, stackTrace) {
      if (error is CacheException) rethrow;
      throw CacheException(
        message: 'Failed to read dataset session: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<DatasetSession?> getActiveSession() async {
    try {
      final unfinished = _sortedDomain()
          .where((s) => s.status.isUnfinished)
          .toList();
      if (unfinished.isEmpty) {
        await setCurrentSessionId(null);
        return null;
      }
      // Prefer the remembered id when still unfinished.
      final remembered = _prefs.getString(datasetCurrentSessionIdKey);
      if (remembered != null) {
        for (final s in unfinished) {
          if (s.id == remembered) return s;
        }
      }
      final session = unfinished.first;
      await setCurrentSessionId(session.id);
      return session;
    } catch (error, stackTrace) {
      throw CacheException(
        message: 'Failed to load active dataset session: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setCurrentSessionId(String? id) async {
    if (id == null || id.isEmpty) {
      await _prefs.remove(datasetCurrentSessionIdKey);
    } else {
      await _prefs.setString(datasetCurrentSessionIdKey, id);
    }
  }

  @override
  Future<String?> getCurrentSessionId() async {
    return _prefs.getString(datasetCurrentSessionIdKey);
  }

  @override
  Future<DatasetStatistics> getStatistics() async {
    final sessions = await getSessions();
    if (sessions.isEmpty) {
      return const DatasetStatistics.empty();
    }
    final totalFrames =
        sessions.fold<int>(0, (sum, s) => sum + s.frameCount);
    final totalFlood =
        sessions.fold<int>(0, (sum, s) => sum + s.floodEventCount);
    final totalStorage =
        sessions.fold<int>(0, (sum, s) => sum + s.totalStorage);
    final avgSpeed =
        sessions.fold<double>(0, (sum, s) => sum + s.averageSpeed) /
            sessions.length;
    final avgConf =
        sessions.fold<double>(0, (sum, s) => sum + s.averageConfidence) /
            sessions.length;
    return DatasetStatistics(
      totalSessions: sessions.length,
      totalFrames: totalFrames,
      totalFloodEvents: totalFlood,
      totalStorage: totalStorage,
      averageSpeed: avgSpeed,
      averageConfidence: avgConf,
    );
  }

  @override
  Future<DatasetStorage> getStorageInformation() async {
    try {
      final folder = await ensureDatasetRoot();
      final used = await _directoryByteSize(folder);
      return DatasetStorage(
        totalDiskSpace: 0,
        usedDiskSpace: used,
        remainingDiskSpace: 0,
        datasetFolder: folder.path,
      );
    } catch (error, stackTrace) {
      throw CacheException(
        message: 'Failed to read dataset storage: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Ensures `…/dataset_collection` exists and returns it.
  Future<Directory> ensureDatasetRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/dataset_collection');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Builds a new idle session from create params (no persistence).
  DatasetSession buildNewSession(CreateDatasetSessionParams params) {
    final now = DateTime.now();
    final name = params.sessionName.trim();
    return DatasetSession(
      id: _uuid.v4(),
      sessionName: name.isEmpty ? 'Session ${now.toIso8601String()}' : name,
      description: params.description.trim(),
      createdAt: now,
      updatedAt: now,
      duration: Duration.zero,
      status: DatasetSessionStatus.idle,
      frameCount: 0,
      floodEventCount: 0,
      totalStorage: 0,
      averageSpeed: 0,
      averageConfidence: 0,
      averageFloodCoverage: 0,
      deviceName: _deviceLabel(),
      appVersion: AppConfig.appVersion,
      modelVersion: 'pending',
    );
  }

  List<DatasetSession> _sortedDomain() {
    final list = _box.values.map((e) => e.toDomain()).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<int> _directoryByteSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  String _deviceLabel() {
    if (kIsWeb) return 'web';
    return '${defaultTargetPlatform.name} device';
  }
}
