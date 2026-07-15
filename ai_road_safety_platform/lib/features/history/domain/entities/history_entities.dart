import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:equatable/equatable.dart';

/// Persisted detection / hazard event for local history.
class HistoryRecord extends Equatable {
  /// Unique id (UUID).
  final String id;

  /// Event timestamp.
  final DateTime timestamp;

  /// Flood / water coverage percent \[0–100\].
  final double floodPercent;

  /// Fused risk level.
  final RiskLevel riskLevel;

  /// Risk score \[0–100\].
  final double riskScore;

  /// GPS latitude when available.
  final double? latitude;

  /// GPS longitude when available.
  final double? longitude;

  /// Vehicle speed km/h.
  final double speedKmh;

  /// Horizontal GPS accuracy meters.
  final double? accuracyMeters;

  /// On-disk JPEG/PNG path for snapshot image (optional).
  final String? imagePath;

  /// Optional free-text note.
  final String? notes;

  /// Creates [HistoryRecord].
  const HistoryRecord({
    required this.id,
    required this.timestamp,
    required this.floodPercent,
    required this.riskLevel,
    required this.riskScore,
    required this.speedKmh,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.imagePath,
    this.notes,
  });

  /// Whether GPS coordinates were stored.
  bool get hasGps => latitude != null && longitude != null;

  /// Whether an image file path exists.
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// Searchable blob for text query.
  String get searchBlob {
    final coords = hasGps
        ? '${latitude!.toStringAsFixed(4)},${longitude!.toStringAsFixed(4)}'
        : '';
    return [
      riskLevel.label,
      floodPercent.toStringAsFixed(1),
      speedKmh.toStringAsFixed(0),
      coords,
      notes ?? '',
      id,
    ].join(' ').toLowerCase();
  }

  /// JSON-serializable map (export / diagnostics).
  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'floodPercent': floodPercent,
        'riskLevel': riskLevel.name,
        'riskScore': riskScore,
        'latitude': latitude,
        'longitude': longitude,
        'speedKmh': speedKmh,
        'accuracyMeters': accuracyMeters,
        'imagePath': imagePath,
        'notes': notes,
      };

  /// Copy helper.
  HistoryRecord copyWith({
    String? id,
    DateTime? timestamp,
    double? floodPercent,
    RiskLevel? riskLevel,
    double? riskScore,
    double? latitude,
    double? longitude,
    double? speedKmh,
    double? accuracyMeters,
    String? imagePath,
    String? notes,
    bool clearImage = false,
  }) {
    return HistoryRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      floodPercent: floodPercent ?? this.floodPercent,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedKmh: speedKmh ?? this.speedKmh,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        floodPercent,
        riskLevel,
        riskScore,
        latitude,
        longitude,
        speedKmh,
        accuracyMeters,
        imagePath,
        notes,
      ];
}

/// Query / filter for history listing.
class HistoryFilter extends Equatable {
  /// Free-text search (risk, coords, notes, id).
  final String searchQuery;

  /// Restrict to these risk levels (empty = all).
  final Set<RiskLevel> riskLevels;

  /// Inclusive start (UTC local ok).
  final DateTime? from;

  /// Inclusive end.
  final DateTime? to;

  /// Minimum flood coverage percent (null = any).
  final double? minFloodPercent;

  /// Only records that have an image.
  final bool? hasImageOnly;

  /// Creates [HistoryFilter].
  const HistoryFilter({
    this.searchQuery = '',
    this.riskLevels = const {},
    this.from,
    this.to,
    this.minFloodPercent,
    this.hasImageOnly,
  });

  /// Empty / default filter.
  const HistoryFilter.empty()
      : searchQuery = '',
        riskLevels = const {},
        from = null,
        to = null,
        minFloodPercent = null,
        hasImageOnly = null;

  /// Whether any non-default constraint is active.
  bool get isActive =>
      searchQuery.trim().isNotEmpty ||
      riskLevels.isNotEmpty ||
      from != null ||
      to != null ||
      minFloodPercent != null ||
      hasImageOnly == true;

  /// Copy helper.
  HistoryFilter copyWith({
    String? searchQuery,
    Set<RiskLevel>? riskLevels,
    DateTime? from,
    DateTime? to,
    double? minFloodPercent,
    bool? hasImageOnly,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearMinFlood = false,
    bool clearHasImage = false,
  }) {
    return HistoryFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      riskLevels: riskLevels ?? this.riskLevels,
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      minFloodPercent:
          clearMinFlood ? null : (minFloodPercent ?? this.minFloodPercent),
      hasImageOnly:
          clearHasImage ? null : (hasImageOnly ?? this.hasImageOnly),
    );
  }

  /// Applies filter to [records] (newest first assumed after sort).
  List<HistoryRecord> apply(List<HistoryRecord> records) {
    final q = searchQuery.trim().toLowerCase();
    return records.where((r) {
      if (q.isNotEmpty && !r.searchBlob.contains(q)) return false;
      if (riskLevels.isNotEmpty && !riskLevels.contains(r.riskLevel)) {
        return false;
      }
      if (from != null && r.timestamp.isBefore(from!)) return false;
      if (to != null && r.timestamp.isAfter(to!)) return false;
      if (minFloodPercent != null && r.floodPercent < minFloodPercent!) {
        return false;
      }
      if (hasImageOnly == true && !r.hasImage) return false;
      return true;
    }).toList();
  }

  @override
  List<Object?> get props => [
        searchQuery,
        riskLevels,
        from,
        to,
        minFloodPercent,
        hasImageOnly,
      ];
}

/// Draft used when creating a new history entry (id assigned in data layer).
class HistoryRecordDraft extends Equatable {
  /// Event timestamp.
  final DateTime timestamp;

  /// Flood percent.
  final double floodPercent;

  /// Risk level.
  final RiskLevel riskLevel;

  /// Risk score.
  final double riskScore;

  /// Latitude.
  final double? latitude;

  /// Longitude.
  final double? longitude;

  /// Speed km/h.
  final double speedKmh;

  /// Accuracy meters.
  final double? accuracyMeters;

  /// When true, attempt to capture a camera JPEG into documents.
  final bool captureImage;

  /// Optional notes.
  final String? notes;

  /// Optional existing image path (skip capture).
  final String? imagePath;

  /// Creates [HistoryRecordDraft].
  const HistoryRecordDraft({
    required this.timestamp,
    required this.floodPercent,
    required this.riskLevel,
    required this.riskScore,
    required this.speedKmh,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.captureImage = true,
    this.notes,
    this.imagePath,
  });

  @override
  List<Object?> get props => [
        timestamp,
        floodPercent,
        riskLevel,
        riskScore,
        latitude,
        longitude,
        speedKmh,
        accuracyMeters,
        captureImage,
        notes,
        imagePath,
      ];
}

/// Result of exporting history as JSON.
class HistoryExportResult extends Equatable {
  /// Absolute file path written.
  final String filePath;

  /// Number of records exported.
  final int recordCount;

  /// Creates [HistoryExportResult].
  const HistoryExportResult({
    required this.filePath,
    required this.recordCount,
  });

  @override
  List<Object?> get props => [filePath, recordCount];
}
