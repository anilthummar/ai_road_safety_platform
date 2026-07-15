import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/active_learning_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ActiveLearningSummaryCard shows counts', (tester) async {
    final snap = ActiveLearningSnapshot(
      selections: [
        ActiveLearningSelection(
          id: 'al1',
          createdAt: DateTime.utc(2026, 7, 14),
          config: const ActiveLearningStrategyConfig(topK: 5),
          candidates: const [
            SampleCandidate(
              sessionId: 's',
              frameNumber: 7,
              score: 55,
              reasons: [SamplePriorityReason.needsReview],
              frameStatus: 'needsReview',
            ),
          ],
          framesConsidered: 12,
        ),
      ],
      generatedAt: DateTime.utc(2026, 7, 14),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ActiveLearningSummaryCard(snapshot: snap)),
      ),
    );
    expect(find.textContaining('selections'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });
}
