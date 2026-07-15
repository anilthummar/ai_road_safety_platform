import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('thresholds json round-trip', () {
    const t = QualityGateThresholds(
      passScore: 80,
      conditionalScore: 60,
      minAnnotationCoverage: 0.5,
      minApprovalRate: 0.3,
      maxIntegrityMismatch: 0.1,
      minFrames: 25,
    );
    expect(QualityGateThresholds.fromJson(t.toJson()), t);
  });

  test('QualityIssue and SessionQualityAssessment round-trip', () {
    const issue = QualityIssue(
      code: 'x',
      message: 'msg',
      severity: QualityIssueSeverity.warning,
      dimension: QualityDimension.integrity,
      sessionId: 's1',
    );
    expect(QualityIssue.fromJson(issue.toJson()), issue);

    final session = const SessionQualityAssessment(
      sessionId: 's1',
      sessionName: 'A',
      frameCount: 10,
      annotatedFrames: 5,
      approvedFrames: 2,
      imageCount: 10,
      metadataCount: 9,
      overallScore: 70,
      decision: QualityGateDecision.conditional,
      dimensions: [
        DimensionScore(
          dimension: QualityDimension.integrity,
          score: 80,
          summary: 'ok',
        ),
      ],
      issues: [issue],
    );
    expect(SessionQualityAssessment.fromJson(session.toJson()), session);
  });

  test('gate decision allowsTraining', () {
    expect(QualityGateDecision.pass.allowsTraining, isTrue);
    expect(QualityGateDecision.conditional.allowsTraining, isTrue);
    expect(QualityGateDecision.fail.allowsTraining, isFalse);
  });
}
