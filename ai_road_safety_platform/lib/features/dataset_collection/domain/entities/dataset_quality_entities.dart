import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:equatable/equatable.dart';

/// Training-gate decision for a dataset / session (Phase 13.1).
enum QualityGateDecision {
  /// Safe to train.
  pass,

  /// Train with caution / remediation recommended.
  conditional,

  /// Block training until issues are fixed.
  fail,
}

extension QualityGateDecisionX on QualityGateDecision {
  String get label => switch (this) {
        QualityGateDecision.pass => 'Pass',
        QualityGateDecision.conditional => 'Conditional',
        QualityGateDecision.fail => 'Fail',
      };

  bool get allowsTraining => this != QualityGateDecision.fail;
}

/// Severity of a quality finding.
enum QualityIssueSeverity {
  info,
  warning,
  critical,
}

extension QualityIssueSeverityX on QualityIssueSeverity {
  String get label => switch (this) {
        QualityIssueSeverity.info => 'Info',
        QualityIssueSeverity.warning => 'Warning',
        QualityIssueSeverity.critical => 'Critical',
      };
}

/// Quality dimensions scored 0–100.
enum QualityDimension {
  captureCompleteness,
  annotationCoverage,
  labelBalance,
  integrity,
  approvalReadiness,
}

extension QualityDimensionX on QualityDimension {
  String get label => switch (this) {
        QualityDimension.captureCompleteness => 'Capture completeness',
        QualityDimension.annotationCoverage => 'Annotation coverage',
        QualityDimension.labelBalance => 'Label balance',
        QualityDimension.integrity => 'Data integrity',
        QualityDimension.approvalReadiness => 'Approval readiness',
      };
}

/// Configurable thresholds that gate training.
class QualityGateThresholds extends Equatable {
  /// Minimum overall score to Pass.
  final double passScore;

  /// Minimum overall score for Conditional (below = Fail).
  final double conditionalScore;

  /// Minimum annotated frame ratio (0–1).
  final double minAnnotationCoverage;

  /// Minimum approved annotation ratio among annotated (0–1).
  final double minApprovalRate;

  /// Max allowed image/metadata mismatch ratio (0–1).
  final double maxIntegrityMismatch;

  /// Minimum frames required in corpus.
  final int minFrames;

  /// Creates [QualityGateThresholds].
  const QualityGateThresholds({
    this.passScore = 75,
    this.conditionalScore = 55,
    this.minAnnotationCoverage = 0.4,
    this.minApprovalRate = 0.25,
    this.maxIntegrityMismatch = 0.15,
    this.minFrames = 10,
  });

  static const QualityGateThresholds defaults = QualityGateThresholds();

  QualityGateThresholds copyWith({
    double? passScore,
    double? conditionalScore,
    double? minAnnotationCoverage,
    double? minApprovalRate,
    double? maxIntegrityMismatch,
    int? minFrames,
  }) {
    return QualityGateThresholds(
      passScore: passScore ?? this.passScore,
      conditionalScore: conditionalScore ?? this.conditionalScore,
      minAnnotationCoverage:
          minAnnotationCoverage ?? this.minAnnotationCoverage,
      minApprovalRate: minApprovalRate ?? this.minApprovalRate,
      maxIntegrityMismatch: maxIntegrityMismatch ?? this.maxIntegrityMismatch,
      minFrames: minFrames ?? this.minFrames,
    );
  }

  Map<String, dynamic> toJson() => {
        'passScore': passScore,
        'conditionalScore': conditionalScore,
        'minAnnotationCoverage': minAnnotationCoverage,
        'minApprovalRate': minApprovalRate,
        'maxIntegrityMismatch': maxIntegrityMismatch,
        'minFrames': minFrames,
      };

  factory QualityGateThresholds.fromJson(Map<String, dynamic> json) {
    return QualityGateThresholds(
      passScore: (json['passScore'] as num?)?.toDouble() ?? 75,
      conditionalScore: (json['conditionalScore'] as num?)?.toDouble() ?? 55,
      minAnnotationCoverage:
          (json['minAnnotationCoverage'] as num?)?.toDouble() ?? 0.4,
      minApprovalRate: (json['minApprovalRate'] as num?)?.toDouble() ?? 0.25,
      maxIntegrityMismatch:
          (json['maxIntegrityMismatch'] as num?)?.toDouble() ?? 0.15,
      minFrames: (json['minFrames'] as num?)?.toInt() ?? 10,
    );
  }

  @override
  List<Object?> get props => [
        passScore,
        conditionalScore,
        minAnnotationCoverage,
        minApprovalRate,
        maxIntegrityMismatch,
        minFrames,
      ];
}

/// Single quality finding.
class QualityIssue extends Equatable {
  final String code;
  final String message;
  final QualityIssueSeverity severity;
  final QualityDimension? dimension;
  final String? sessionId;

  const QualityIssue({
    required this.code,
    required this.message,
    required this.severity,
    this.dimension,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'severity': severity.name,
        'dimension': dimension?.name,
        'sessionId': sessionId,
      };

  factory QualityIssue.fromJson(Map<String, dynamic> json) {
    return QualityIssue(
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: QualityIssueSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => QualityIssueSeverity.warning,
      ),
      dimension: json['dimension'] == null
          ? null
          : QualityDimension.values.firstWhere(
              (d) => d.name == json['dimension'],
              orElse: () => QualityDimension.integrity,
            ),
      sessionId: json['sessionId'] as String?,
    );
  }

  @override
  List<Object?> get props => [code, message, severity, dimension, sessionId];
}

/// Score for one dimension (0–100).
class DimensionScore extends Equatable {
  final QualityDimension dimension;
  final double score;
  final String summary;

  const DimensionScore({
    required this.dimension,
    required this.score,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'dimension': dimension.name,
        'score': score,
        'summary': summary,
      };

  factory DimensionScore.fromJson(Map<String, dynamic> json) {
    return DimensionScore(
      dimension: QualityDimension.values.firstWhere(
        (d) => d.name == json['dimension'],
        orElse: () => QualityDimension.integrity,
      ),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      summary: json['summary'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [dimension, score, summary];
}

/// Per-session quality row.
class SessionQualityAssessment extends Equatable {
  final String sessionId;
  final String sessionName;
  final int frameCount;
  final int annotatedFrames;
  final int approvedFrames;
  final int imageCount;
  final int metadataCount;
  final double overallScore;
  final QualityGateDecision decision;
  final List<DimensionScore> dimensions;
  final List<QualityIssue> issues;

  const SessionQualityAssessment({
    required this.sessionId,
    required this.sessionName,
    required this.frameCount,
    required this.annotatedFrames,
    required this.approvedFrames,
    required this.imageCount,
    required this.metadataCount,
    required this.overallScore,
    required this.decision,
    required this.dimensions,
    required this.issues,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'sessionName': sessionName,
        'frameCount': frameCount,
        'annotatedFrames': annotatedFrames,
        'approvedFrames': approvedFrames,
        'imageCount': imageCount,
        'metadataCount': metadataCount,
        'overallScore': overallScore,
        'decision': decision.name,
        'dimensions': [for (final d in dimensions) d.toJson()],
        'issues': [for (final i in issues) i.toJson()],
      };

  factory SessionQualityAssessment.fromJson(Map<String, dynamic> json) {
    return SessionQualityAssessment(
      sessionId: json['sessionId'] as String? ?? '',
      sessionName: json['sessionName'] as String? ?? '',
      frameCount: (json['frameCount'] as num?)?.toInt() ?? 0,
      annotatedFrames: (json['annotatedFrames'] as num?)?.toInt() ?? 0,
      approvedFrames: (json['approvedFrames'] as num?)?.toInt() ?? 0,
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
      metadataCount: (json['metadataCount'] as num?)?.toInt() ?? 0,
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0,
      decision: QualityGateDecision.values.firstWhere(
        (d) => d.name == json['decision'],
        orElse: () => QualityGateDecision.fail,
      ),
      dimensions: [
        for (final d in (json['dimensions'] as List? ?? const []))
          DimensionScore.fromJson(Map<String, dynamic>.from(d as Map)),
      ],
      issues: [
        for (final i in (json['issues'] as List? ?? const []))
          QualityIssue.fromJson(Map<String, dynamic>.from(i as Map)),
      ],
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        sessionName,
        frameCount,
        annotatedFrames,
        approvedFrames,
        imageCount,
        metadataCount,
        overallScore,
        decision,
        dimensions,
        issues,
      ];
}

/// Label histogram entry for balance analysis.
class LabelCoverageStat extends Equatable {
  final String labelId;
  final String labelName;
  final int count;
  final double ratio;

  const LabelCoverageStat({
    required this.labelId,
    required this.labelName,
    required this.count,
    required this.ratio,
  });

  Map<String, dynamic> toJson() => {
        'labelId': labelId,
        'labelName': labelName,
        'count': count,
        'ratio': ratio,
      };

  factory LabelCoverageStat.fromJson(Map<String, dynamic> json) {
    return LabelCoverageStat(
      labelId: json['labelId'] as String? ?? '',
      labelName: json['labelName'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [labelId, labelName, count, ratio];
}

/// Full corpus quality assessment report (training gate).
class DatasetQualityAssessmentReport extends Equatable {
  final DateTime generatedAt;
  final QualityGateThresholds thresholds;
  final QualityGateDecision decision;
  final double overallScore;
  final bool trainingAllowed;
  final String gateSummary;
  final List<DimensionScore> dimensions;
  final List<QualityIssue> issues;
  final List<SessionQualityAssessment> sessions;
  final List<LabelCoverageStat> labelCoverage;
  final DatasetQualityMetrics captureMetrics;
  final AnnotationQualityMetrics annotationMetrics;
  final int totalSessions;
  final int totalFrames;
  final int passSessions;
  final int conditionalSessions;
  final int failSessions;

  const DatasetQualityAssessmentReport({
    required this.generatedAt,
    required this.thresholds,
    required this.decision,
    required this.overallScore,
    required this.trainingAllowed,
    required this.gateSummary,
    required this.dimensions,
    required this.issues,
    required this.sessions,
    required this.labelCoverage,
    required this.captureMetrics,
    required this.annotationMetrics,
    required this.totalSessions,
    required this.totalFrames,
    required this.passSessions,
    required this.conditionalSessions,
    required this.failSessions,
  });

  factory DatasetQualityAssessmentReport.empty({
    QualityGateThresholds thresholds = QualityGateThresholds.defaults,
  }) {
    return DatasetQualityAssessmentReport(
      generatedAt: DateTime.now().toUtc(),
      thresholds: thresholds,
      decision: QualityGateDecision.fail,
      overallScore: 0,
      trainingAllowed: false,
      gateSummary: 'No sessions available for quality assessment',
      dimensions: const [],
      issues: const [
        QualityIssue(
          code: 'empty_corpus',
          message: 'Dataset is empty — cannot gate for training',
          severity: QualityIssueSeverity.critical,
          dimension: QualityDimension.captureCompleteness,
        ),
      ],
      sessions: const [],
      labelCoverage: const [],
      captureMetrics: const DatasetQualityMetrics.empty(),
      annotationMetrics: const AnnotationQualityMetrics.empty(),
      totalSessions: 0,
      totalFrames: 0,
      passSessions: 0,
      conditionalSessions: 0,
      failSessions: 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'thresholds': thresholds.toJson(),
        'decision': decision.name,
        'overallScore': overallScore,
        'trainingAllowed': trainingAllowed,
        'gateSummary': gateSummary,
        'dimensions': [for (final d in dimensions) d.toJson()],
        'issues': [for (final i in issues) i.toJson()],
        'sessions': [for (final s in sessions) s.toJson()],
        'labelCoverage': [for (final l in labelCoverage) l.toJson()],
        'totalSessions': totalSessions,
        'totalFrames': totalFrames,
        'passSessions': passSessions,
        'conditionalSessions': conditionalSessions,
        'failSessions': failSessions,
      };

  @override
  List<Object?> get props => [
        generatedAt,
        thresholds,
        decision,
        overallScore,
        trainingAllowed,
        gateSummary,
        dimensions,
        issues,
        sessions,
        labelCoverage,
        captureMetrics,
        annotationMetrics,
        totalSessions,
        totalFrames,
        passSessions,
        conditionalSessions,
        failSessions,
      ];
}

/// Input sample used by the pure assessment engine.
class QualitySessionInput extends Equatable {
  final String sessionId;
  final String sessionName;
  final int frameCount;
  final int imageCount;
  final int metadataCount;
  final int annotatedFrames;
  final int approvedFrames;
  final int missingLabelCount;
  final Map<String, int> labelCounts;

  const QualitySessionInput({
    required this.sessionId,
    required this.sessionName,
    required this.frameCount,
    required this.imageCount,
    required this.metadataCount,
    required this.annotatedFrames,
    required this.approvedFrames,
    this.missingLabelCount = 0,
    this.labelCounts = const {},
  });

  @override
  List<Object?> get props => [
        sessionId,
        sessionName,
        frameCount,
        imageCount,
        metadataCount,
        annotatedFrames,
        approvedFrames,
        missingLabelCount,
        labelCounts,
      ];
}
