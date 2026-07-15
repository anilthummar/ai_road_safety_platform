import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/model_registry_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ModelRegistrySummaryCard shows counts', (tester) async {
    final snap = ModelRegistrySnapshot(
      models: BundledModelCatalog.defaults(now: DateTime.utc(2026, 7, 14)),
      active: ActiveModelPointers(
        detectionModelId: 'bundled-yolov8n',
        segmentationModelId: 'bundled-flood-seg',
        updatedAt: DateTime.utc(2026, 7, 14),
      ),
      generatedAt: DateTime.utc(2026, 7, 14),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ModelRegistrySummaryCard(snapshot: snap)),
      ),
    );
    expect(find.textContaining('versions'), findsOneWidget);
    expect(find.textContaining('bundled-yolov8n'), findsOneWidget);
  });
}
