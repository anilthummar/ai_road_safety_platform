import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/active_learning_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = ActiveLearningEngine();

  test('unlabeled frames score highest among simple set', () {
    final ranked = engine.rank(
      frames: const [
        ActiveLearningFrameInput(
          sessionId: 's',
          frameNumber: 1,
          frameStatus: 'unannotated',
          annotationCount: 0,
        ),
        ActiveLearningFrameInput(
          sessionId: 's',
          frameNumber: 2,
          frameStatus: 'approved',
          annotationCount: 2,
          humanAnnotationCount: 2,
          labelIds: ['pothole', 'pothole'],
        ),
      ],
      config: const ActiveLearningStrategyConfig(topK: 5),
    );
    expect(ranked, isNotEmpty);
    expect(ranked.first.frameNumber, 1);
    expect(
      ranked.first.reasons,
      contains(SamplePriorityReason.unlabeled),
    );
  });

  test('low confidence AI drafts are prioritized', () {
    final ranked = engine.rank(
      frames: const [
        ActiveLearningFrameInput(
          sessionId: 's',
          frameNumber: 3,
          frameStatus: 'draft',
          annotationCount: 1,
          aiAnnotationCount: 1,
          humanAnnotationCount: 0,
          minAiConfidence: 0.2,
          labelIds: ['obstacle'],
        ),
      ],
    );
    expect(ranked.first.reasons, contains(SamplePriorityReason.aiDraftOnly));
    expect(
      ranked.first.reasons,
      contains(SamplePriorityReason.lowConfidence),
    );
    expect(ranked.first.score, greaterThan(30));
  });

  test('rare labels bump score', () {
    final frames = <ActiveLearningFrameInput>[
      for (var i = 0; i < 20; i++)
        ActiveLearningFrameInput(
          sessionId: 's',
          frameNumber: i,
          frameStatus: 'approved',
          annotationCount: 1,
          humanAnnotationCount: 1,
          labelIds: const ['pothole'],
        ),
      const ActiveLearningFrameInput(
        sessionId: 's',
        frameNumber: 99,
        frameStatus: 'approved',
        annotationCount: 1,
        humanAnnotationCount: 1,
        labelIds: ['edge_damage'],
      ),
    ];
    final ranked = engine.rank(
      frames: frames,
      config: const ActiveLearningStrategyConfig(
        topK: 5,
        rareLabelMaxRatio: 0.1,
      ),
    );
    expect(ranked.any((c) => c.frameNumber == 99), isTrue);
    final rare = ranked.firstWhere((c) => c.frameNumber == 99);
    expect(rare.reasons, contains(SamplePriorityReason.rareLabel));
  });

  test('ActiveLearningSelection json round-trip', () {
    final sel = ActiveLearningSelection(
      id: 'al1',
      createdAt: DateTime.utc(2026, 7, 14),
      config: const ActiveLearningStrategyConfig(topK: 3),
      candidates: const [
        SampleCandidate(
          sessionId: 's',
          frameNumber: 1,
          score: 40,
          reasons: [SamplePriorityReason.unlabeled],
          frameStatus: 'unannotated',
        ),
      ],
      framesConsidered: 10,
    );
    expect(ActiveLearningSelection.fromJson(sel.toJson()), sel);
  });
}
