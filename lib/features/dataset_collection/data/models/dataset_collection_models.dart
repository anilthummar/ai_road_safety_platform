import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:equatable/equatable.dart';

/// JSON / transfer DTO for [DatasetSession].
class DatasetSessionModel extends Equatable {
  /// Session id.
  final String id;

  /// Display name.
  final String sessionName;

  /// Description.
  final String description;

  /// Created ISO.
  final String createdAtIso;

  /// Updated ISO.
  final String updatedAtIso;

  /// Started ISO or null.
  final String? startedAtIso;

  /// Ended ISO or null.
  final String? endedAtIso;

  /// Duration in milliseconds.
  final int durationMs;

  /// Status wire name.
  final String statusName;

  /// Frame count.
  final int frameCount;

  /// Flood event count.
  final int floodEventCount;

  /// Storage bytes.
  final int totalStorage;

  /// Average speed.
  final double averageSpeed;

  /// Average confidence.
  final double averageConfidence;

  /// Average flood coverage.
  final double averageFloodCoverage;

  /// Device name.
  final String deviceName;

  /// App version.
  final String appVersion;

  /// Model version.
  final String modelVersion;

  /// Creates [DatasetSessionModel].
  const DatasetSessionModel({
    required this.id,
    required this.sessionName,
    required this.description,
    required this.createdAtIso,
    required this.updatedAtIso,
    required this.durationMs,
    required this.statusName,
    required this.frameCount,
    required this.floodEventCount,
    required this.totalStorage,
    required this.averageSpeed,
    required this.averageConfidence,
    required this.averageFloodCoverage,
    required this.deviceName,
    required this.appVersion,
    required this.modelVersion,
    this.startedAtIso,
    this.endedAtIso,
  });

  /// From domain.
  factory DatasetSessionModel.fromDomain(DatasetSession session) {
    return DatasetSessionModel(
      id: session.id,
      sessionName: session.sessionName,
      description: session.description,
      createdAtIso: session.createdAt.toIso8601String(),
      updatedAtIso: session.updatedAt.toIso8601String(),
      startedAtIso: session.startedAt?.toIso8601String(),
      endedAtIso: session.endedAt?.toIso8601String(),
      durationMs: session.duration.inMilliseconds,
      statusName: session.status.name,
      frameCount: session.frameCount,
      floodEventCount: session.floodEventCount,
      totalStorage: session.totalStorage,
      averageSpeed: session.averageSpeed,
      averageConfidence: session.averageConfidence,
      averageFloodCoverage: session.averageFloodCoverage,
      deviceName: session.deviceName,
      appVersion: session.appVersion,
      modelVersion: session.modelVersion,
    );
  }

  /// From JSON map.
  factory DatasetSessionModel.fromJson(Map<String, dynamic> json) {
    return DatasetSessionModel(
      id: json['id'] as String,
      sessionName: json['sessionName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAtIso: json['createdAt'] as String? ??
          DateTime.now().toIso8601String(),
      updatedAtIso: json['updatedAt'] as String? ??
          DateTime.now().toIso8601String(),
      startedAtIso: json['startedAt'] as String?,
      endedAtIso: json['endedAt'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      statusName: json['status'] as String? ?? DatasetSessionStatus.idle.name,
      frameCount: (json['frameCount'] as num?)?.toInt() ?? 0,
      floodEventCount: (json['floodEventCount'] as num?)?.toInt() ?? 0,
      totalStorage: (json['totalStorage'] as num?)?.toInt() ?? 0,
      averageSpeed: (json['averageSpeed'] as num?)?.toDouble() ?? 0,
      averageConfidence: (json['averageConfidence'] as num?)?.toDouble() ?? 0,
      averageFloodCoverage:
          (json['averageFloodCoverage'] as num?)?.toDouble() ?? 0,
      deviceName: json['deviceName'] as String? ?? 'unknown',
      appVersion: json['appVersion'] as String? ?? '',
      modelVersion: json['modelVersion'] as String? ?? 'pending',
    );
  }

  /// To JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionName': sessionName,
        'description': description,
        'createdAt': createdAtIso,
        'updatedAt': updatedAtIso,
        'startedAt': startedAtIso,
        'endedAt': endedAtIso,
        'durationMs': durationMs,
        'status': statusName,
        'frameCount': frameCount,
        'floodEventCount': floodEventCount,
        'totalStorage': totalStorage,
        'averageSpeed': averageSpeed,
        'averageConfidence': averageConfidence,
        'averageFloodCoverage': averageFloodCoverage,
        'deviceName': deviceName,
        'appVersion': appVersion,
        'modelVersion': modelVersion,
      };

  /// To domain.
  DatasetSession toDomain() {
    return DatasetSession(
      id: id,
      sessionName: sessionName,
      description: description,
      createdAt: DateTime.tryParse(createdAtIso) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAtIso) ?? DateTime.now(),
      startedAt:
          startedAtIso == null ? null : DateTime.tryParse(startedAtIso!),
      endedAt: endedAtIso == null ? null : DateTime.tryParse(endedAtIso!),
      duration: Duration(milliseconds: durationMs),
      status: DatasetSessionStatusX.parse(statusName),
      frameCount: frameCount,
      floodEventCount: floodEventCount,
      totalStorage: totalStorage,
      averageSpeed: averageSpeed,
      averageConfidence: averageConfidence,
      averageFloodCoverage: averageFloodCoverage,
      deviceName: deviceName,
      appVersion: appVersion,
      modelVersion: modelVersion,
    );
  }

  /// Copy helper.
  DatasetSessionModel copyWith({
    String? id,
    String? sessionName,
    String? description,
    String? createdAtIso,
    String? updatedAtIso,
    String? startedAtIso,
    String? endedAtIso,
    int? durationMs,
    String? statusName,
    int? frameCount,
    int? floodEventCount,
    int? totalStorage,
    double? averageSpeed,
    double? averageConfidence,
    double? averageFloodCoverage,
    String? deviceName,
    String? appVersion,
    String? modelVersion,
  }) {
    return DatasetSessionModel(
      id: id ?? this.id,
      sessionName: sessionName ?? this.sessionName,
      description: description ?? this.description,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      startedAtIso: startedAtIso ?? this.startedAtIso,
      endedAtIso: endedAtIso ?? this.endedAtIso,
      durationMs: durationMs ?? this.durationMs,
      statusName: statusName ?? this.statusName,
      frameCount: frameCount ?? this.frameCount,
      floodEventCount: floodEventCount ?? this.floodEventCount,
      totalStorage: totalStorage ?? this.totalStorage,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      averageConfidence: averageConfidence ?? this.averageConfidence,
      averageFloodCoverage:
          averageFloodCoverage ?? this.averageFloodCoverage,
      deviceName: deviceName ?? this.deviceName,
      appVersion: appVersion ?? this.appVersion,
      modelVersion: modelVersion ?? this.modelVersion,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionName,
        description,
        createdAtIso,
        updatedAtIso,
        startedAtIso,
        endedAtIso,
        durationMs,
        statusName,
        frameCount,
        floodEventCount,
        totalStorage,
        averageSpeed,
        averageConfidence,
        averageFloodCoverage,
        deviceName,
        appVersion,
        modelVersion,
      ];
}

/// JSON DTO for [DatasetStatistics].
class DatasetStatisticsModel extends Equatable {
  /// Totals.
  final int totalSessions;
  final int totalFrames;
  final int totalFloodEvents;
  final int totalStorage;
  final double averageSpeed;
  final double averageConfidence;

  /// Creates [DatasetStatisticsModel].
  const DatasetStatisticsModel({
    required this.totalSessions,
    required this.totalFrames,
    required this.totalFloodEvents,
    required this.totalStorage,
    required this.averageSpeed,
    required this.averageConfidence,
  });

  factory DatasetStatisticsModel.fromDomain(DatasetStatistics stats) {
    return DatasetStatisticsModel(
      totalSessions: stats.totalSessions,
      totalFrames: stats.totalFrames,
      totalFloodEvents: stats.totalFloodEvents,
      totalStorage: stats.totalStorage,
      averageSpeed: stats.averageSpeed,
      averageConfidence: stats.averageConfidence,
    );
  }

  factory DatasetStatisticsModel.fromJson(Map<String, dynamic> json) {
    return DatasetStatisticsModel(
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalFrames: (json['totalFrames'] as num?)?.toInt() ?? 0,
      totalFloodEvents: (json['totalFloodEvents'] as num?)?.toInt() ?? 0,
      totalStorage: (json['totalStorage'] as num?)?.toInt() ?? 0,
      averageSpeed: (json['averageSpeed'] as num?)?.toDouble() ?? 0,
      averageConfidence: (json['averageConfidence'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalSessions': totalSessions,
        'totalFrames': totalFrames,
        'totalFloodEvents': totalFloodEvents,
        'totalStorage': totalStorage,
        'averageSpeed': averageSpeed,
        'averageConfidence': averageConfidence,
      };

  DatasetStatistics toDomain() => DatasetStatistics(
        totalSessions: totalSessions,
        totalFrames: totalFrames,
        totalFloodEvents: totalFloodEvents,
        totalStorage: totalStorage,
        averageSpeed: averageSpeed,
        averageConfidence: averageConfidence,
      );

  DatasetStatisticsModel copyWith({
    int? totalSessions,
    int? totalFrames,
    int? totalFloodEvents,
    int? totalStorage,
    double? averageSpeed,
    double? averageConfidence,
  }) {
    return DatasetStatisticsModel(
      totalSessions: totalSessions ?? this.totalSessions,
      totalFrames: totalFrames ?? this.totalFrames,
      totalFloodEvents: totalFloodEvents ?? this.totalFloodEvents,
      totalStorage: totalStorage ?? this.totalStorage,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      averageConfidence: averageConfidence ?? this.averageConfidence,
    );
  }

  @override
  List<Object?> get props => [
        totalSessions,
        totalFrames,
        totalFloodEvents,
        totalStorage,
        averageSpeed,
        averageConfidence,
      ];
}

/// JSON DTO for [DatasetStorage].
class DatasetStorageModel extends Equatable {
  final int totalDiskSpace;
  final int usedDiskSpace;
  final int remainingDiskSpace;
  final String datasetFolder;

  /// Creates [DatasetStorageModel].
  const DatasetStorageModel({
    required this.totalDiskSpace,
    required this.usedDiskSpace,
    required this.remainingDiskSpace,
    required this.datasetFolder,
  });

  factory DatasetStorageModel.fromDomain(DatasetStorage storage) {
    return DatasetStorageModel(
      totalDiskSpace: storage.totalDiskSpace,
      usedDiskSpace: storage.usedDiskSpace,
      remainingDiskSpace: storage.remainingDiskSpace,
      datasetFolder: storage.datasetFolder,
    );
  }

  factory DatasetStorageModel.fromJson(Map<String, dynamic> json) {
    return DatasetStorageModel(
      totalDiskSpace: (json['totalDiskSpace'] as num?)?.toInt() ?? 0,
      usedDiskSpace: (json['usedDiskSpace'] as num?)?.toInt() ?? 0,
      remainingDiskSpace: (json['remainingDiskSpace'] as num?)?.toInt() ?? 0,
      datasetFolder: json['datasetFolder'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'totalDiskSpace': totalDiskSpace,
        'usedDiskSpace': usedDiskSpace,
        'remainingDiskSpace': remainingDiskSpace,
        'datasetFolder': datasetFolder,
      };

  DatasetStorage toDomain() => DatasetStorage(
        totalDiskSpace: totalDiskSpace,
        usedDiskSpace: usedDiskSpace,
        remainingDiskSpace: remainingDiskSpace,
        datasetFolder: datasetFolder,
      );

  DatasetStorageModel copyWith({
    int? totalDiskSpace,
    int? usedDiskSpace,
    int? remainingDiskSpace,
    String? datasetFolder,
  }) {
    return DatasetStorageModel(
      totalDiskSpace: totalDiskSpace ?? this.totalDiskSpace,
      usedDiskSpace: usedDiskSpace ?? this.usedDiskSpace,
      remainingDiskSpace: remainingDiskSpace ?? this.remainingDiskSpace,
      datasetFolder: datasetFolder ?? this.datasetFolder,
    );
  }

  @override
  List<Object?> get props => [
        totalDiskSpace,
        usedDiskSpace,
        remainingDiskSpace,
        datasetFolder,
      ];
}
