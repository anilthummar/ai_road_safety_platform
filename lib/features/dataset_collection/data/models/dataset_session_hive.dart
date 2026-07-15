import 'package:ai_road_safety_platform/features/dataset_collection/data/models/dataset_collection_models.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:hive/hive.dart';

/// Hive type id for [DatasetSessionHive] (History uses 1).
const int datasetSessionHiveTypeId = 2;

/// Hive box name for dataset sessions.
const String datasetSessionsBoxName = 'dataset_sessions';

/// Hive DTO for [DatasetSession] metadata.
class DatasetSessionHive extends HiveObject {
  /// Session id.
  String id;

  /// Display name.
  String sessionName;

  /// Description.
  String description;

  /// Created ISO.
  String createdAtIso;

  /// Updated ISO.
  String updatedAtIso;

  /// Started ISO.
  String? startedAtIso;

  /// Ended ISO.
  String? endedAtIso;

  /// Duration ms.
  int durationMs;

  /// Status name.
  String statusName;

  /// Frame count.
  int frameCount;

  /// Flood events.
  int floodEventCount;

  /// Storage bytes.
  int totalStorage;

  /// Avg speed.
  double averageSpeed;

  /// Avg confidence.
  double averageConfidence;

  /// Avg flood %.
  double averageFloodCoverage;

  /// Device.
  String deviceName;

  /// App version.
  String appVersion;

  /// Model version.
  String modelVersion;

  /// Creates [DatasetSessionHive].
  DatasetSessionHive({
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

  /// From domain via model.
  factory DatasetSessionHive.fromDomain(DatasetSession session) {
    final model = DatasetSessionModel.fromDomain(session);
    return DatasetSessionHive.fromModel(model);
  }

  /// From transferable model.
  factory DatasetSessionHive.fromModel(DatasetSessionModel model) {
    return DatasetSessionHive(
      id: model.id,
      sessionName: model.sessionName,
      description: model.description,
      createdAtIso: model.createdAtIso,
      updatedAtIso: model.updatedAtIso,
      startedAtIso: model.startedAtIso,
      endedAtIso: model.endedAtIso,
      durationMs: model.durationMs,
      statusName: model.statusName,
      frameCount: model.frameCount,
      floodEventCount: model.floodEventCount,
      totalStorage: model.totalStorage,
      averageSpeed: model.averageSpeed,
      averageConfidence: model.averageConfidence,
      averageFloodCoverage: model.averageFloodCoverage,
      deviceName: model.deviceName,
      appVersion: model.appVersion,
      modelVersion: model.modelVersion,
    );
  }

  /// To transferable model.
  DatasetSessionModel toModel() {
    return DatasetSessionModel(
      id: id,
      sessionName: sessionName,
      description: description,
      createdAtIso: createdAtIso,
      updatedAtIso: updatedAtIso,
      startedAtIso: startedAtIso,
      endedAtIso: endedAtIso,
      durationMs: durationMs,
      statusName: statusName,
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

  /// To domain.
  DatasetSession toDomain() => toModel().toDomain();
}

/// Manual Hive [TypeAdapter] (no build_runner).
class DatasetSessionHiveAdapter extends TypeAdapter<DatasetSessionHive> {
  @override
  final int typeId = datasetSessionHiveTypeId;

  @override
  DatasetSessionHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DatasetSessionHive(
      id: fields[0] as String,
      sessionName: fields[1] as String,
      description: fields[2] as String,
      createdAtIso: fields[3] as String,
      updatedAtIso: fields[4] as String,
      startedAtIso: fields[5] as String?,
      endedAtIso: fields[6] as String?,
      durationMs: (fields[7] as num).toInt(),
      statusName: fields[8] as String,
      frameCount: (fields[9] as num).toInt(),
      floodEventCount: (fields[10] as num).toInt(),
      totalStorage: (fields[11] as num).toInt(),
      averageSpeed: (fields[12] as num).toDouble(),
      averageConfidence: (fields[13] as num).toDouble(),
      averageFloodCoverage: (fields[14] as num).toDouble(),
      deviceName: fields[15] as String,
      appVersion: fields[16] as String,
      modelVersion: fields[17] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DatasetSessionHive obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAtIso)
      ..writeByte(4)
      ..write(obj.updatedAtIso)
      ..writeByte(5)
      ..write(obj.startedAtIso)
      ..writeByte(6)
      ..write(obj.endedAtIso)
      ..writeByte(7)
      ..write(obj.durationMs)
      ..writeByte(8)
      ..write(obj.statusName)
      ..writeByte(9)
      ..write(obj.frameCount)
      ..writeByte(10)
      ..write(obj.floodEventCount)
      ..writeByte(11)
      ..write(obj.totalStorage)
      ..writeByte(12)
      ..write(obj.averageSpeed)
      ..writeByte(13)
      ..write(obj.averageConfidence)
      ..writeByte(14)
      ..write(obj.averageFloodCoverage)
      ..writeByte(15)
      ..write(obj.deviceName)
      ..writeByte(16)
      ..write(obj.appVersion)
      ..writeByte(17)
      ..write(obj.modelVersion);
  }
}
