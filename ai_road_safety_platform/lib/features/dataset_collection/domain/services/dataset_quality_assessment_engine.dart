import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';

/// Pure dataset quality assessment & training gate (Phase 13.1).
///
/// Composes capture metrics (12.7) + annotation metrics (12.9) into a
/// go/no-go decision without I/O.
class DatasetQualityAssessmentEngine {
  const DatasetQualityAssessmentEngine();

  /// Builds a full assessment report from pre-collected session inputs.
  DatasetQualityAssessmentReport assess({
    required List<QualitySessionInput> sessions,
    required List<AnnotationLabel> labels,
    DatasetQualityMetrics captureMetrics = const DatasetQualityMetrics.empty(),
    QualityGateThresholds thresholds = QualityGateThresholds.defaults,
  }) {
    if (sessions.isEmpty) {
      return DatasetQualityAssessmentReport.empty(thresholds: thresholds);
    }

    final sessionRows = [
      for (final s in sessions) _assessSession(s, thresholds),
    ];

    final totalFrames =
        sessions.fold<int>(0, (n, s) => n + s.frameCount);
    final annotated =
        sessions.fold<int>(0, (n, s) => n + s.annotatedFrames);
    final approved =
        sessions.fold<int>(0, (n, s) => n + s.approvedFrames);
    final missingLabels =
        sessions.fold<int>(0, (n, s) => n + s.missingLabelCount);

    final completeness = totalFrames == 0 ? 0.0 : annotated / totalFrames;
    final approvalRatio = totalFrames == 0 ? 0.0 : approved / totalFrames;
    final annotationMetrics = AnnotationQualityMetrics(
      totalFrames: totalFrames,
      annotatedFrames: annotated,
      approvedFrames: approved,
      missingLabelCount: missingLabels,
      completeness: completeness,
      approvalPercentage: approvalRatio * 100,
      qualityScore: _clamp(
        ((completeness * 0.6) + (approvalRatio * 0.4)) * 100 -
            missingLabels * 2,
      ),
    );

    final labelCoverage = _labelCoverage(sessions, labels);
    final dimensions = _corpusDimensions(
      sessions: sessions,
      captureMetrics: captureMetrics,
      annotationMetrics: annotationMetrics,
      labelCoverage: labelCoverage,
      thresholds: thresholds,
    );

    final overall = dimensions.isEmpty
        ? 0.0
        : dimensions.fold<double>(0, (n, d) => n + d.score) /
            dimensions.length;

    final issues = <QualityIssue>[
      for (final row in sessionRows) ...row.issues,
      ..._corpusIssues(
        sessions: sessions,
        annotationMetrics: annotationMetrics,
        captureMetrics: captureMetrics,
        labelCoverage: labelCoverage,
        thresholds: thresholds,
        overall: overall,
      ),
    ];

    // Deduplicate by code+sessionId.
    final seen = <String>{};
    final uniqueIssues = <QualityIssue>[];
    for (final i in issues) {
      final key = '${i.code}|${i.sessionId ?? ''}';
      if (seen.add(key)) uniqueIssues.add(i);
    }

    final decision = _decide(overall, uniqueIssues, thresholds, totalFrames);
    final passSessions =
        sessionRows.where((s) => s.decision == QualityGateDecision.pass).length;
    final conditionalSessions = sessionRows
        .where((s) => s.decision == QualityGateDecision.conditional)
        .length;
    final failSessions =
        sessionRows.where((s) => s.decision == QualityGateDecision.fail).length;

    return DatasetQualityAssessmentReport(
      generatedAt: DateTime.now().toUtc(),
      thresholds: thresholds,
      decision: decision,
      overallScore: _clamp(overall),
      trainingAllowed: decision.allowsTraining,
      gateSummary: _summary(decision, overall, uniqueIssues),
      dimensions: dimensions,
      issues: uniqueIssues,
      sessions: (List<SessionQualityAssessment>.from(sessionRows)
        ..sort((a, b) => a.overallScore.compareTo(b.overallScore))),
      labelCoverage: labelCoverage,
      captureMetrics: captureMetrics,
      annotationMetrics: annotationMetrics,
      totalSessions: sessions.length,
      totalFrames: totalFrames,
      passSessions: passSessions,
      conditionalSessions: conditionalSessions,
      failSessions: failSessions,
    );
  }

  /// Evaluates whether [report] may proceed to training under [thresholds].
  QualityGateDecision evaluateGate(
    DatasetQualityAssessmentReport report, {
    QualityGateThresholds? thresholds,
  }) {
    final t = thresholds ?? report.thresholds;
    return _decide(
      report.overallScore,
      report.issues,
      t,
      report.totalFrames,
    );
  }

  SessionQualityAssessment _assessSession(
    QualitySessionInput s,
    QualityGateThresholds thresholds,
  ) {
    final issues = <QualityIssue>[];
    final coverage =
        s.frameCount == 0 ? 0.0 : s.annotatedFrames / s.frameCount;
    final approval = s.annotatedFrames == 0
        ? 0.0
        : s.approvedFrames / s.annotatedFrames;
    final mismatchDenom =
        s.imageCount > s.metadataCount ? s.imageCount : s.metadataCount;
    final mismatch = mismatchDenom == 0
        ? (s.frameCount > 0 ? 1.0 : 0.0)
        : (s.imageCount - s.metadataCount).abs() / mismatchDenom;

    final captureScore = s.frameCount == 0
        ? 0.0
        : _clamp(100 *
            (s.imageCount.clamp(0, s.frameCount) /
                (s.frameCount == 0 ? 1 : s.frameCount)));
    final annotationScore = _clamp(coverage * 100);
    final approvalScore = _clamp(approval * 100);
    final integrityScore = _clamp((1 - mismatch) * 100);
    // Session-level label balance approximates coverage presence.
    final balanceScore = s.annotatedFrames == 0
        ? 0.0
        : _clamp(40 + coverage * 60);

    final dimensions = [
      DimensionScore(
        dimension: QualityDimension.captureCompleteness,
        score: captureScore,
        summary: '${s.imageCount} images / ${s.frameCount} frames',
      ),
      DimensionScore(
        dimension: QualityDimension.annotationCoverage,
        score: annotationScore,
        summary:
            '${(coverage * 100).toStringAsFixed(0)}% frames annotated',
      ),
      DimensionScore(
        dimension: QualityDimension.approvalReadiness,
        score: approvalScore,
        summary:
            '${(approval * 100).toStringAsFixed(0)}% annotations approved',
      ),
      DimensionScore(
        dimension: QualityDimension.integrity,
        score: integrityScore,
        summary:
            'images ${s.imageCount} · metadata ${s.metadataCount}',
      ),
      DimensionScore(
        dimension: QualityDimension.labelBalance,
        score: balanceScore,
        summary: '${s.labelCounts.length} labels used',
      ),
    ];

    final overall =
        dimensions.fold<double>(0, (n, d) => n + d.score) / dimensions.length;

    if (s.frameCount == 0) {
      issues.add(
        QualityIssue(
          code: 'empty_session',
          message: 'Session "${s.sessionName}" has no frames',
          severity: QualityIssueSeverity.critical,
          dimension: QualityDimension.captureCompleteness,
          sessionId: s.sessionId,
        ),
      );
    }
    if (coverage < thresholds.minAnnotationCoverage) {
      issues.add(
        QualityIssue(
          code: 'low_annotation_coverage',
          message:
              'Annotation coverage ${(coverage * 100).toStringAsFixed(0)}% '
              'below gate ${(thresholds.minAnnotationCoverage * 100).toStringAsFixed(0)}%',
          severity: QualityIssueSeverity.warning,
          dimension: QualityDimension.annotationCoverage,
          sessionId: s.sessionId,
        ),
      );
    }
    if (s.annotatedFrames > 0 && approval < thresholds.minApprovalRate) {
      issues.add(
        QualityIssue(
          code: 'low_approval_rate',
          message:
              'Approval rate ${(approval * 100).toStringAsFixed(0)}% below gate',
          severity: QualityIssueSeverity.warning,
          dimension: QualityDimension.approvalReadiness,
          sessionId: s.sessionId,
        ),
      );
    }
    if (mismatch > thresholds.maxIntegrityMismatch) {
      issues.add(
        QualityIssue(
          code: 'integrity_mismatch',
          message:
              'Image/metadata mismatch ${(mismatch * 100).toStringAsFixed(0)}%',
          severity: QualityIssueSeverity.critical,
          dimension: QualityDimension.integrity,
          sessionId: s.sessionId,
        ),
      );
    }
    if (s.missingLabelCount > 0) {
      issues.add(
        QualityIssue(
          code: 'missing_labels',
          message: '${s.missingLabelCount} annotations missing labels',
          severity: QualityIssueSeverity.warning,
          dimension: QualityDimension.annotationCoverage,
          sessionId: s.sessionId,
        ),
      );
    }

    return SessionQualityAssessment(
      sessionId: s.sessionId,
      sessionName: s.sessionName,
      frameCount: s.frameCount,
      annotatedFrames: s.annotatedFrames,
      approvedFrames: s.approvedFrames,
      imageCount: s.imageCount,
      metadataCount: s.metadataCount,
      overallScore: _clamp(overall),
      decision: _decide(overall, issues, thresholds, s.frameCount),
      dimensions: dimensions,
      issues: issues,
    );
  }

  List<DimensionScore> _corpusDimensions({
    required List<QualitySessionInput> sessions,
    required DatasetQualityMetrics captureMetrics,
    required AnnotationQualityMetrics annotationMetrics,
    required List<LabelCoverageStat> labelCoverage,
    required QualityGateThresholds thresholds,
  }) {
    final captureScore = captureMetrics.completenessScore > 0
        ? captureMetrics.completenessScore
        : _avg(
            sessions.map((s) {
              if (s.frameCount == 0) return 0.0;
              return 100.0 *
                  s.imageCount.clamp(0, s.frameCount) /
                  s.frameCount;
            }),
          );

    final annotationScore = annotationMetrics.completeness * 100;
    final approvalScore = annotationMetrics.approvalPercentage;
    final integrityScore = _avg(
      sessions.map((s) {
        final denom =
            s.imageCount > s.metadataCount ? s.imageCount : s.metadataCount;
        if (denom == 0) return s.frameCount > 0 ? 0.0 : 100.0;
        final mismatch =
            (s.imageCount - s.metadataCount).abs() / denom;
        return (1 - mismatch) * 100;
      }),
    );
    final balanceScore = _balanceScore(labelCoverage);

    return [
      DimensionScore(
        dimension: QualityDimension.captureCompleteness,
        score: _clamp(captureScore),
        summary:
            'Capture success ${(captureMetrics.captureSuccessRate * 100).toStringAsFixed(0)}%',
      ),
      DimensionScore(
        dimension: QualityDimension.annotationCoverage,
        score: _clamp(annotationScore),
        summary:
            '${annotationMetrics.annotatedFrames}/${annotationMetrics.totalFrames} annotated',
      ),
      DimensionScore(
        dimension: QualityDimension.approvalReadiness,
        score: _clamp(approvalScore),
        summary:
            '${annotationMetrics.approvedFrames} approved frames',
      ),
      DimensionScore(
        dimension: QualityDimension.integrity,
        score: _clamp(integrityScore),
        summary:
            'Missing metadata ~${captureMetrics.missingMetadataCount}',
      ),
      DimensionScore(
        dimension: QualityDimension.labelBalance,
        score: _clamp(balanceScore),
        summary: '${labelCoverage.length} labels represented',
      ),
    ];
  }

  List<QualityIssue> _corpusIssues({
    required List<QualitySessionInput> sessions,
    required AnnotationQualityMetrics annotationMetrics,
    required DatasetQualityMetrics captureMetrics,
    required List<LabelCoverageStat> labelCoverage,
    required QualityGateThresholds thresholds,
    required double overall,
  }) {
    final issues = <QualityIssue>[];
    final totalFrames = annotationMetrics.totalFrames;

    if (totalFrames < thresholds.minFrames) {
      issues.add(
        QualityIssue(
          code: 'insufficient_frames',
          message:
              'Corpus has $totalFrames frames; gate requires ≥ ${thresholds.minFrames}',
          severity: QualityIssueSeverity.critical,
          dimension: QualityDimension.captureCompleteness,
        ),
      );
    }
    if (annotationMetrics.completeness < thresholds.minAnnotationCoverage) {
      issues.add(
        QualityIssue(
          code: 'corpus_low_annotation',
          message:
              'Corpus annotation coverage ${(annotationMetrics.completeness * 100).toStringAsFixed(0)}% below gate',
          severity: QualityIssueSeverity.critical,
          dimension: QualityDimension.annotationCoverage,
        ),
      );
    }
    if (captureMetrics.emptySessionCount > 0) {
      issues.add(
        QualityIssue(
          code: 'empty_sessions',
          message:
              '${captureMetrics.emptySessionCount} empty sessions in corpus',
          severity: QualityIssueSeverity.warning,
          dimension: QualityDimension.captureCompleteness,
        ),
      );
    }
    if (captureMetrics.corruptedFrameCount > 0) {
      issues.add(
        QualityIssue(
          code: 'corrupted_frames',
          message:
              '${captureMetrics.corruptedFrameCount} corrupted / incomplete frames detected',
          severity: QualityIssueSeverity.critical,
          dimension: QualityDimension.integrity,
        ),
      );
    }
    final dominant = labelCoverage.where((l) => l.ratio > 0.7).toList();
    if (dominant.isNotEmpty && labelCoverage.length > 1) {
      issues.add(
        QualityIssue(
          code: 'label_imbalance',
          message:
              'Label "${dominant.first.labelName}" dominates '
              '${(dominant.first.ratio * 100).toStringAsFixed(0)}% of annotations',
          severity: QualityIssueSeverity.warning,
          dimension: QualityDimension.labelBalance,
        ),
      );
    }
    if (overall < thresholds.conditionalScore) {
      issues.add(
        QualityIssue(
          code: 'score_below_gate',
          message:
              'Overall score ${overall.toStringAsFixed(0)} below Fail threshold ${thresholds.conditionalScore}',
          severity: QualityIssueSeverity.critical,
        ),
      );
    } else if (overall < thresholds.passScore) {
      issues.add(
        QualityIssue(
          code: 'score_conditional',
          message:
              'Overall score ${overall.toStringAsFixed(0)} below Pass threshold ${thresholds.passScore}',
          severity: QualityIssueSeverity.warning,
        ),
      );
    }
    return issues;
  }

  List<LabelCoverageStat> _labelCoverage(
    List<QualitySessionInput> sessions,
    List<AnnotationLabel> labels,
  ) {
    final counts = <String, int>{};
    for (final s in sessions) {
      s.labelCounts.forEach((id, n) {
        counts[id] = (counts[id] ?? 0) + n;
      });
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final byId = {for (final l in labels) l.id: l};
    final stats = <LabelCoverageStat>[
      for (final e in counts.entries)
        LabelCoverageStat(
          labelId: e.key,
          labelName: byId[e.key]?.name ?? e.key,
          count: e.value,
          ratio: total == 0 ? 0 : e.value / total,
        ),
    ]..sort((a, b) => b.count.compareTo(a.count));
    return stats;
  }

  double _balanceScore(List<LabelCoverageStat> coverage) {
    if (coverage.isEmpty) return 0;
    if (coverage.length == 1) return 35;
    // Inverse of max dominance: uniform distribution → high score.
    final maxRatio = coverage.map((c) => c.ratio).reduce(
          (a, b) => a > b ? a : b,
        );
    final ideal = 1 / coverage.length;
    final spread = (maxRatio - ideal).abs();
    return _clamp(100 * (1 - spread.clamp(0, 1)));
  }

  QualityGateDecision _decide(
    double overall,
    List<QualityIssue> issues,
    QualityGateThresholds thresholds,
    int totalFrames,
  ) {
    final hasCritical = issues.any(
      (i) => i.severity == QualityIssueSeverity.critical,
    );
    if (totalFrames < thresholds.minFrames || hasCritical) {
      // Critical still Fail even if score looks ok — except score_conditional.
      final blocking = issues.any(
        (i) =>
            i.severity == QualityIssueSeverity.critical &&
            i.code != 'score_conditional',
      );
      if (blocking || overall < thresholds.conditionalScore) {
        return QualityGateDecision.fail;
      }
    }
    if (overall >= thresholds.passScore &&
        !issues.any((i) => i.severity == QualityIssueSeverity.critical)) {
      return QualityGateDecision.pass;
    }
    if (overall >= thresholds.conditionalScore) {
      return QualityGateDecision.conditional;
    }
    return QualityGateDecision.fail;
  }

  String _summary(
    QualityGateDecision decision,
    double overall,
    List<QualityIssue> issues,
  ) {
    final critical =
        issues.where((i) => i.severity == QualityIssueSeverity.critical).length;
    final warnings =
        issues.where((i) => i.severity == QualityIssueSeverity.warning).length;
    return switch (decision) {
      QualityGateDecision.pass =>
        'Training gate PASSED · score ${overall.toStringAsFixed(0)}',
      QualityGateDecision.conditional =>
        'Training gate CONDITIONAL · score ${overall.toStringAsFixed(0)} · '
            '$warnings warnings',
      QualityGateDecision.fail =>
        'Training gate FAILED · score ${overall.toStringAsFixed(0)} · '
            '$critical critical issues',
    };
  }

  double _avg(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (a, b) => a + b) / list.length;
  }

  double _clamp(double v) => v.clamp(0, 100).toDouble();
}
