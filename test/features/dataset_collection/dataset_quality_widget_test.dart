import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_quality_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final report = DatasetQualityAssessmentReport(
    generatedAt: DateTime.utc(2026, 7, 14),
    thresholds: QualityGateThresholds.defaults,
    decision: QualityGateDecision.pass,
    overallScore: 82,
    trainingAllowed: true,
    gateSummary: 'Training gate PASSED · score 82',
    dimensions: const [
      DimensionScore(
        dimension: QualityDimension.captureCompleteness,
        score: 90,
        summary: 'good',
      ),
    ],
    issues: const [
      QualityIssue(
        code: 'info_ok',
        message: 'Looks healthy',
        severity: QualityIssueSeverity.info,
      ),
    ],
    sessions: const [],
    labelCoverage: const [
      LabelCoverageStat(
        labelId: 'pothole',
        labelName: 'Visible Pothole',
        count: 12,
        ratio: 0.4,
      ),
    ],
    captureMetrics: const DatasetQualityMetrics.empty(),
    annotationMetrics: const AnnotationQualityMetrics.empty(),
    totalSessions: 3,
    totalFrames: 120,
    passSessions: 3,
    conditionalSessions: 0,
    failSessions: 0,
  );

  testWidgets('QualityGateStatusCard shows PASS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QualityGateStatusCard(report: report)),
      ),
    );
    expect(find.text('PASS'), findsOneWidget);
    expect(find.textContaining('Training allowed'), findsOneWidget);
  });

  testWidgets('QualityLabelCoverageCard shows label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QualityLabelCoverageCard(coverage: report.labelCoverage),
        ),
      ),
    );
    expect(find.textContaining('Visible Pothole'), findsOneWidget);
  });
}
