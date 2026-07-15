import 'package:equatable/equatable.dart';

/// Supported annotation geometries (Phase 12.9).
enum AnnotationType {
  boundingBox,
  polygon,
  polyline,
  point,
  classification,
  segmentationMask,
  keypoints,
}

/// Display helpers.
extension AnnotationTypeX on AnnotationType {
  String get label => switch (this) {
        AnnotationType.boundingBox => 'Bounding box',
        AnnotationType.polygon => 'Polygon',
        AnnotationType.polyline => 'Polyline',
        AnnotationType.point => 'Point',
        AnnotationType.classification => 'Classification',
        AnnotationType.segmentationMask => 'Segmentation (placeholder)',
        AnnotationType.keypoints => 'Keypoints (placeholder)',
      };

  bool get isPlaceholder =>
      this == AnnotationType.segmentationMask ||
      this == AnnotationType.keypoints;
}

/// Review / lifecycle status for a frame or annotation.
enum AnnotationStatus {
  unannotated,
  draft,
  reviewed,
  approved,
  rejected,
  needsReview,
}

extension AnnotationStatusX on AnnotationStatus {
  String get label => switch (this) {
        AnnotationStatus.unannotated => 'Unannotated',
        AnnotationStatus.draft => 'Draft',
        AnnotationStatus.reviewed => 'Reviewed',
        AnnotationStatus.approved => 'Approved',
        AnnotationStatus.rejected => 'Rejected',
        AnnotationStatus.needsReview => 'Needs review',
      };
}

/// Active canvas tool.
enum AnnotationTool {
  select,
  boundingBox,
  polygon,
  polyline,
  point,
  classification,
  delete,
  pan,
}

extension AnnotationToolX on AnnotationTool {
  String get label => switch (this) {
        AnnotationTool.select => 'Select',
        AnnotationTool.boundingBox => 'Box',
        AnnotationTool.polygon => 'Polygon',
        AnnotationTool.polyline => 'Polyline',
        AnnotationTool.point => 'Point',
        AnnotationTool.classification => 'Class',
        AnnotationTool.delete => 'Delete',
        AnnotationTool.pan => 'Pan',
      };
}

/// History action kinds.
enum AnnotationHistoryAction {
  created,
  modified,
  deleted,
  approved,
  rejected,
  undid,
  redid,
}

/// Normalized image point \[0–1\] relative to image width/height.
class AnnotationPoint extends Equatable {
  final double x;
  final double y;

  const AnnotationPoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory AnnotationPoint.fromJson(Map<String, dynamic> json) =>
      AnnotationPoint(
        (json['x'] as num?)?.toDouble() ?? 0,
        (json['y'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [x, y];
}

/// Axis-aligned box in normalized coords (top-left + size).
class BoundingBox extends Equatable {
  final double x;
  final double y;
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double get right => x + width;
  double get bottom => y + height;
  double get area => width * height;

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  factory BoundingBox.fromJson(Map<String, dynamic> json) => BoundingBox(
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        width: (json['width'] as num?)?.toDouble() ?? 0,
        height: (json['height'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [x, y, width, height];
}

/// Closed / open polygon or polyline vertices.
class PolygonGeometry extends Equatable {
  final List<AnnotationPoint> points;
  final bool closed;

  const PolygonGeometry({
    required this.points,
    this.closed = true,
  });

  Map<String, dynamic> toJson() => {
        'closed': closed,
        'points': [for (final p in points) p.toJson()],
      };

  factory PolygonGeometry.fromJson(Map<String, dynamic> json) =>
      PolygonGeometry(
        closed: json['closed'] as bool? ?? true,
        points: [
          for (final p in (json['points'] as List? ?? const []))
            AnnotationPoint.fromJson(Map<String, dynamic>.from(p as Map)),
        ],
      );

  @override
  List<Object?> get props => [points, closed];
}

/// Configurable hazard / road label.
class AnnotationLabel extends Equatable {
  final String id;
  final String name;
  final int colorArgb;
  final int priority;
  final bool enabled;

  const AnnotationLabel({
    required this.id,
    required this.name,
    required this.colorArgb,
    this.priority = 0,
    this.enabled = true,
  });

  AnnotationLabel copyWith({
    String? id,
    String? name,
    int? colorArgb,
    int? priority,
    bool? enabled,
  }) {
    return AnnotationLabel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorArgb: colorArgb ?? this.colorArgb,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorArgb': colorArgb,
        'priority': priority,
        'enabled': enabled,
      };

  factory AnnotationLabel.fromJson(Map<String, dynamic> json) =>
      AnnotationLabel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        colorArgb: (json['colorArgb'] as num?)?.toInt() ?? 0xFF2196F3,
        priority: (json['priority'] as num?)?.toInt() ?? 0,
        enabled: json['enabled'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, name, colorArgb, priority, enabled];
}

/// Default road-hazard label catalogue.
class DefaultHazardLabels {
  DefaultHazardLabels._();

  static const List<AnnotationLabel> all = [
    AnnotationLabel(id: 'flooded_road', name: 'Flooded Road', colorArgb: 0xFF1565C0, priority: 100),
    AnnotationLabel(id: 'water_pool', name: 'Water Pool', colorArgb: 0xFF0288D1, priority: 90),
    AnnotationLabel(id: 'hidden_hazard', name: 'Possible Hidden Hazard', colorArgb: 0xFF6A1B9A, priority: 95),
    AnnotationLabel(id: 'pothole', name: 'Visible Pothole', colorArgb: 0xFFE65100, priority: 80),
    AnnotationLabel(id: 'crack', name: 'Road Crack', colorArgb: 0xFFF9A825, priority: 70),
    AnnotationLabel(id: 'broken_road', name: 'Broken Road', colorArgb: 0xFFBF360C, priority: 85),
    AnnotationLabel(id: 'speed_breaker', name: 'Speed Breaker', colorArgb: 0xFF455A64, priority: 60),
    AnnotationLabel(id: 'edge_damage', name: 'Road Edge Damage', colorArgb: 0xFF5D4037, priority: 65),
    AnnotationLabel(id: 'construction', name: 'Construction Zone', colorArgb: 0xFFFF6F00, priority: 75),
    AnnotationLabel(id: 'obstacle', name: 'Obstacle', colorArgb: 0xFFC62828, priority: 88),
    AnnotationLabel(id: 'unknown', name: 'Unknown', colorArgb: 0xFF757575, priority: 10),
  ];
}

/// One immutable annotation instance on a frame.
class Annotation extends Equatable {
  final String id;
  final String sessionId;
  final int frameNumber;
  final AnnotationType type;
  final String labelId;
  final AnnotationStatus status;
  final BoundingBox? box;
  final PolygonGeometry? polygon;
  final AnnotationPoint? point;
  final String? classificationNote;
  final bool fromAi;
  final double? aiConfidence;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final String? reviewComment;

  const Annotation({
    required this.id,
    required this.sessionId,
    required this.frameNumber,
    required this.type,
    required this.labelId,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.box,
    this.polygon,
    this.point,
    this.classificationNote,
    this.fromAi = false,
    this.aiConfidence,
    this.version = 1,
    this.reviewComment,
  });

  Annotation copyWith({
    String? id,
    String? sessionId,
    int? frameNumber,
    AnnotationType? type,
    String? labelId,
    AnnotationStatus? status,
    BoundingBox? box,
    PolygonGeometry? polygon,
    AnnotationPoint? point,
    String? classificationNote,
    bool? fromAi,
    double? aiConfidence,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? reviewComment,
    bool clearBox = false,
    bool clearPolygon = false,
    bool clearPoint = false,
    bool clearComment = false,
  }) {
    return Annotation(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      frameNumber: frameNumber ?? this.frameNumber,
      type: type ?? this.type,
      labelId: labelId ?? this.labelId,
      status: status ?? this.status,
      box: clearBox ? null : (box ?? this.box),
      polygon: clearPolygon ? null : (polygon ?? this.polygon),
      point: clearPoint ? null : (point ?? this.point),
      classificationNote: classificationNote ?? this.classificationNote,
      fromAi: fromAi ?? this.fromAi,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      reviewComment: clearComment ? null : (reviewComment ?? this.reviewComment),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'frameNumber': frameNumber,
        'type': type.name,
        'labelId': labelId,
        'status': status.name,
        'box': box?.toJson(),
        'polygon': polygon?.toJson(),
        'point': point?.toJson(),
        'classificationNote': classificationNote,
        'fromAi': fromAi,
        'aiConfidence': aiConfidence,
        'createdBy': createdBy,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'version': version,
        'reviewComment': reviewComment,
      };

  factory Annotation.fromJson(Map<String, dynamic> json) {
    return Annotation(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      frameNumber: (json['frameNumber'] as num?)?.toInt() ?? 0,
      type: AnnotationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AnnotationType.boundingBox,
      ),
      labelId: json['labelId'] as String? ?? 'unknown',
      status: AnnotationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => AnnotationStatus.draft,
      ),
      box: json['box'] is Map
          ? BoundingBox.fromJson(Map<String, dynamic>.from(json['box'] as Map))
          : null,
      polygon: json['polygon'] is Map
          ? PolygonGeometry.fromJson(
              Map<String, dynamic>.from(json['polygon'] as Map),
            )
          : null,
      point: json['point'] is Map
          ? AnnotationPoint.fromJson(
              Map<String, dynamic>.from(json['point'] as Map),
            )
          : null,
      classificationNote: json['classificationNote'] as String?,
      fromAi: json['fromAi'] as bool? ?? false,
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble(),
      createdBy: json['createdBy'] as String? ?? 'researcher',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      version: (json['version'] as num?)?.toInt() ?? 1,
      reviewComment: json['reviewComment'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        frameNumber,
        type,
        labelId,
        status,
        box,
        polygon,
        point,
        classificationNote,
        fromAi,
        aiConfidence,
        createdBy,
        createdAt,
        updatedAt,
        version,
        reviewComment,
      ];
}

/// Audit trail row.
class AnnotationHistoryEntry extends Equatable {
  final String id;
  final String annotationId;
  final AnnotationHistoryAction action;
  final String reviewer;
  final DateTime timestamp;
  final int version;
  final String? reason;
  final Map<String, dynamic>? snapshot;

  const AnnotationHistoryEntry({
    required this.id,
    required this.annotationId,
    required this.action,
    required this.reviewer,
    required this.timestamp,
    required this.version,
    this.reason,
    this.snapshot,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'annotationId': annotationId,
        'action': action.name,
        'reviewer': reviewer,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'version': version,
        'reason': reason,
        'snapshot': snapshot,
      };

  factory AnnotationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AnnotationHistoryEntry(
      id: json['id'] as String? ?? '',
      annotationId: json['annotationId'] as String? ?? '',
      action: AnnotationHistoryAction.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => AnnotationHistoryAction.modified,
      ),
      reviewer: json['reviewer'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      version: (json['version'] as num?)?.toInt() ?? 1,
      reason: json['reason'] as String?,
      snapshot: json['snapshot'] is Map
          ? Map<String, dynamic>.from(json['snapshot'] as Map)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, annotationId, action, reviewer, timestamp, version, reason, snapshot];
}

/// Frame-level ground truth package.
class GroundTruth extends Equatable {
  final String sessionId;
  final int frameNumber;
  final String? imagePath;
  final double imageWidth;
  final double imageHeight;
  final List<Annotation> annotations;
  final List<AnnotationHistoryEntry> history;
  final AnnotationStatus frameStatus;
  final List<String> reviewers;
  final String? reviewComment;
  final DateTime updatedAt;

  const GroundTruth({
    required this.sessionId,
    required this.frameNumber,
    required this.annotations,
    required this.history,
    required this.frameStatus,
    required this.updatedAt,
    this.imagePath,
    this.imageWidth = 1,
    this.imageHeight = 1,
    this.reviewers = const [],
    this.reviewComment,
  });

  GroundTruth copyWith({
    String? sessionId,
    int? frameNumber,
    String? imagePath,
    double? imageWidth,
    double? imageHeight,
    List<Annotation>? annotations,
    List<AnnotationHistoryEntry>? history,
    AnnotationStatus? frameStatus,
    List<String>? reviewers,
    String? reviewComment,
    DateTime? updatedAt,
  }) {
    return GroundTruth(
      sessionId: sessionId ?? this.sessionId,
      frameNumber: frameNumber ?? this.frameNumber,
      imagePath: imagePath ?? this.imagePath,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      annotations: annotations ?? this.annotations,
      history: history ?? this.history,
      frameStatus: frameStatus ?? this.frameStatus,
      reviewers: reviewers ?? this.reviewers,
      reviewComment: reviewComment ?? this.reviewComment,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'frameNumber': frameNumber,
        'imagePath': imagePath,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'annotations': [for (final a in annotations) a.toJson()],
        'history': [for (final h in history) h.toJson()],
        'frameStatus': frameStatus.name,
        'reviewers': reviewers,
        'reviewComment': reviewComment,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory GroundTruth.fromJson(Map<String, dynamic> json) {
    return GroundTruth(
      sessionId: json['sessionId'] as String? ?? '',
      frameNumber: (json['frameNumber'] as num?)?.toInt() ?? 0,
      imagePath: json['imagePath'] as String?,
      imageWidth: (json['imageWidth'] as num?)?.toDouble() ?? 1,
      imageHeight: (json['imageHeight'] as num?)?.toDouble() ?? 1,
      annotations: [
        for (final a in (json['annotations'] as List? ?? const []))
          Annotation.fromJson(Map<String, dynamic>.from(a as Map)),
      ],
      history: [
        for (final h in (json['history'] as List? ?? const []))
          AnnotationHistoryEntry.fromJson(Map<String, dynamic>.from(h as Map)),
      ],
      frameStatus: AnnotationStatus.values.firstWhere(
        (s) => s.name == json['frameStatus'],
        orElse: () => AnnotationStatus.unannotated,
      ),
      reviewers: [
        for (final r in (json['reviewers'] as List? ?? const []))
          r.toString(),
      ],
      reviewComment: json['reviewComment'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        frameNumber,
        imagePath,
        imageWidth,
        imageHeight,
        annotations,
        history,
        frameStatus,
        reviewers,
        reviewComment,
        updatedAt,
      ];
}

/// Validation issue.
class AnnotationValidationIssue extends Equatable {
  final String code;
  final String message;
  final String? annotationId;

  const AnnotationValidationIssue({
    required this.code,
    required this.message,
    this.annotationId,
  });

  @override
  List<Object?> get props => [code, message, annotationId];
}

/// QC scoreboard for a session / frame set.
class AnnotationQualityMetrics extends Equatable {
  final int totalFrames;
  final int annotatedFrames;
  final int approvedFrames;
  final int missingLabelCount;
  final double completeness;
  final double approvalPercentage;
  final double qualityScore;

  const AnnotationQualityMetrics({
    required this.totalFrames,
    required this.annotatedFrames,
    required this.approvedFrames,
    required this.missingLabelCount,
    required this.completeness,
    required this.approvalPercentage,
    required this.qualityScore,
  });

  const AnnotationQualityMetrics.empty()
      : totalFrames = 0,
        annotatedFrames = 0,
        approvedFrames = 0,
        missingLabelCount = 0,
        completeness = 0,
        approvalPercentage = 0,
        qualityScore = 0;

  @override
  List<Object?> get props => [
        totalFrames,
        annotatedFrames,
        approvedFrames,
        missingLabelCount,
        completeness,
        approvalPercentage,
        qualityScore,
      ];
}

/// Frame descriptor for the annotation browser.
class AnnotatableFrame extends Equatable {
  final String sessionId;
  final int frameNumber;
  final String? imagePath;
  final AnnotationStatus status;
  final int annotationCount;

  const AnnotatableFrame({
    required this.sessionId,
    required this.frameNumber,
    required this.status,
    required this.annotationCount,
    this.imagePath,
  });

  @override
  List<Object?> get props =>
      [sessionId, frameNumber, imagePath, status, annotationCount];
}
