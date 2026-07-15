import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/model_deployment_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeploymentSummaryCard shows counts', (tester) async {
    final now = DateTime.utc(2026, 7, 14);
    final snap = DeploymentSnapshot(
      packages: [
        DeploymentPackage(
          id: 'deploy-abc12345',
          modelId: 'bundled-yolov8n',
          modelVersion: '1.0.0',
          displayName: 'YOLO',
          taskType: ModelTaskType.objectDetection,
          status: DeploymentStatus.active,
          createdAt: now,
        ),
      ],
      active: ActiveDeploymentPointers(
        detectionDeploymentId: 'deploy-abc12345',
        updatedAt: now,
      ),
      generatedAt: now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DeploymentSummaryCard(snapshot: snap)),
      ),
    );
    expect(find.textContaining('packages'), findsOneWidget);
    expect(find.textContaining('deploy-a'), findsOneWidget);
  });
}
