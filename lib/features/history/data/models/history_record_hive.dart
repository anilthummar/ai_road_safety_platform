import 'package:ai_road_safety_platform/features/history/domain/entities/history_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:hive/hive.dart';

/// Hive type id for [HistoryRecordHive].
const int historyRecordHiveTypeId = 1;

/// Hive-serializable DTO for [HistoryRecord].
@HiveType(typeId: historyRecordHiveTypeId)
class HistoryRecordHive extends HiveObject {
  /// Record id.
  @HiveField(0)
  String id;

  /// ISO-8601 timestamp.
  @HiveField(1)
  String timestampIso;

  /// Flood %.
  @HiveField(2)
  double floodPercent;

  /// Risk level name.
  @HiveField(3)
  String riskLevelName;

  /// Risk score.
  @HiveField(4)
  double riskScore;

  /// Latitude.
  @HiveField(5)
  double? latitude;

  /// Longitude.
  @HiveField(6)
  double? longitude;

  /// Speed km/h.
  @HiveField(7)
  double speedKmh;

  /// Accuracy meters.
  @HiveField(8)
  double? accuracyMeters;

  /// Image file path.
  @HiveField(9)
  String? imagePath;

  /// Notes.
  @HiveField(10)
  String? notes;

  /// Creates [HistoryRecordHive].
  HistoryRecordHive({
    required this.id,
    required this.timestampIso,
    required this.floodPercent,
    required this.riskLevelName,
    required this.riskScore,
    required this.speedKmh,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.imagePath,
    this.notes,
  });

  /// From domain.
  factory HistoryRecordHive.fromDomain(HistoryRecord record) {
    return HistoryRecordHive(
      id: record.id,
      timestampIso: record.timestamp.toIso8601String(),
      floodPercent: record.floodPercent,
      riskLevelName: record.riskLevel.name,
      riskScore: record.riskScore,
      latitude: record.latitude,
      longitude: record.longitude,
      speedKmh: record.speedKmh,
      accuracyMeters: record.accuracyMeters,
      imagePath: record.imagePath,
      notes: record.notes,
    );
  }

  /// To domain.
  HistoryRecord toDomain() {
    return HistoryRecord(
      id: id,
      timestamp: DateTime.tryParse(timestampIso) ?? DateTime.now(),
      floodPercent: floodPercent,
      riskLevel: RiskLevel.values.firstWhere(
        (l) => l.name == riskLevelName,
        orElse: () => RiskLevel.low,
      ),
      riskScore: riskScore,
      latitude: latitude,
      longitude: longitude,
      speedKmh: speedKmh,
      accuracyMeters: accuracyMeters,
      imagePath: imagePath,
      notes: notes,
    );
  }
}

/// Manual TypeAdapter (avoids build_runner).
class HistoryRecordHiveAdapter extends TypeAdapter<HistoryRecordHive> {
  @override
  final int typeId = historyRecordHiveTypeId;

  @override
  HistoryRecordHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryRecordHive(
      id: fields[0] as String,
      timestampIso: fields[1] as String,
      floodPercent: (fields[2] as num).toDouble(),
      riskLevelName: fields[3] as String,
      riskScore: (fields[4] as num).toDouble(),
      latitude: (fields[5] as num?)?.toDouble(),
      longitude: (fields[6] as num?)?.toDouble(),
      speedKmh: (fields[7] as num).toDouble(),
      accuracyMeters: (fields[8] as num?)?.toDouble(),
      imagePath: fields[9] as String?,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryRecordHive obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestampIso)
      ..writeByte(2)
      ..write(obj.floodPercent)
      ..writeByte(3)
      ..write(obj.riskLevelName)
      ..writeByte(4)
      ..write(obj.riskScore)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude)
      ..writeByte(7)
      ..write(obj.speedKmh)
      ..writeByte(8)
      ..write(obj.accuracyMeters)
      ..writeByte(9)
      ..write(obj.imagePath)
      ..writeByte(10)
      ..write(obj.notes);
  }
}
