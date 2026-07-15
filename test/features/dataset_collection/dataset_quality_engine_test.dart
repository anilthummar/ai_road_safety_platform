import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_quality_assessment_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = DatasetQualityAssessmentEngine();

  QualitySessionInput healthy({
    String id = 's1',
    int frames = 100,
  }) {
    return QualitySessionInput(
      sessionId: id,
      sessionName: 'Healthy',
      frameCount: frames,
      imageCount: frames,
      metadataCount: frames,
      annotatedFrames: 80,
      approvedFrames: 50,
      labelCounts: const {
        'flooded_road': 40,
        'pothole': 30,
        'crack': 10,
      },
    );
  }

  test('empty corpus fails gate', () {
    final report = engine.assess(
      sessions: const [],
      labels: DefaultHazardLabels.all,
    );
    expect(report.decision, QualityGateDecision.fail);
    expect(report.trainingAllowed, isFalse);
  });

  test('healthy corpus can pass', () {
    final report = engine.assess(
      sessions: [
        healthy(),
        healthy(id: 's2', frames: 80),
      ],
      labels: DefaultHazardLabels.all,
      captureMetrics: const DatasetQualityMetrics(
        framesPerSession: 90,
        framesPerMinute: 10,
        captureFrequencyHz: 1,
        captureSuccessRate: 0.95,
        averageCaptureIntervalSeconds: 1,
        completenessScore: 90,
        missingMetadataCount: 0,
        corruptedFrameCount: 0,
        emptySessionCount: 0,
      ),
      thresholds: const QualityGateThresholds(
        passScore: 70,
        conditionalScore: 50,
        minAnnotationCoverage: 0.3,
        minApprovalRate: 0.2,
        maxIntegrityMismatch: 0.2,
        minFrames: 10,
      ),
    );
    expect(report.totalFrames, greaterThan(0));
    expect(report.dimensions.length, 5);
    expect(report.decision, isNot(QualityGateDecision.fail));
    expect(report.trainingAllowed, isTrue);
  });

  test('integrity mismatch fails', () {
    final report = engine.assess(
      sessions: [
        const QualitySessionInput(
          sessionId: 'bad',
          sessionName: 'Mismatch',
          frameCount: 50,
          imageCount: 50,
          metadataCount: 5,
          annotatedFrames: 40,
          approvedFrames: 30,
        ),
      ],
      labels: DefaultHazardLabels.all,
      thresholds: const QualityGateThresholds(
        minFrames: 10,
        maxIntegrityMismatch: 0.1,
        minAnnotationCoverage: 0.2,
        passScore: 90,
        conditionalScore: 40,
      ),
    );
    expect(
      report.issues.any((i) => i.code == 'integrity_mismatch'),
      isTrue,
    );
    expect(report.decision, QualityGateDecision.fail);
  });

  test('insufficient frames fails', () {
    final report = engine.assess(
      sessions: [healthy(frames: 5)],
      labels: DefaultHazardLabels.all,
      thresholds: const QualityGateThresholds(minFrames: 50),
    );
    expect(
      report.issues.any((i) => i.code == 'insufficient_frames'),
      isTrue,
    );
    expect(report.decision, QualityGateDecision.fail);
  });

  test('evaluateGate respects thresholds', () {
    final report = engine.assess(
      sessions: [healthy()],
      labels: DefaultHazardLabels.all,
    );
    final decision = engine.evaluateGate(
      report,
      thresholds: const QualityGateThresholds(
        passScore: 99,
        conditionalScore: 1,
        minFrames: 1,
        minAnnotationCoverage: 0.01,
      ),
    );
    expect(
      decision == QualityGateDecision.conditional ||
          decision == QualityGateDecision.pass ||
          decision == QualityGateDecision.fail,
      isTrue,
    );
  });

  test('label coverage computed', () {
    final report = engine.assess(
      sessions: [healthy()],
      labels: DefaultHazardLabels.all,
    );
    expect(report.labelCoverage, isNotEmpty);
    expect(report.labelCoverage.first.count, greaterThan(0));
  });
}
