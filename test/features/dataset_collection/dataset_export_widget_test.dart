import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_export_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExportFormatSelector selects JSON', (tester) async {
    ExportFormat? selected = ExportFormat.csv;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExportFormatSelector(
            selected: selected,
            onSelected: (f) => selected = f,
          ),
        ),
      ),
    );

    await tester.tap(find.text('JSON'));
    await tester.pump();
    expect(selected, ExportFormat.json);
  });

  testWidgets('ExportProgressCard shows percent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExportProgressCard(
            progress: ExportProgress(
              progress: 0.42,
              currentStep: 'Copying',
              elapsed: Duration(seconds: 5),
              logs: ['Export Started'],
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('42%'), findsOneWidget);
    expect(find.textContaining('Export Started'), findsOneWidget);
  });

  testWidgets('ExportSummaryCard shows format', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExportSummaryCard(
            settings: ExportSettings(format: ExportFormat.zip),
            availableSessions: 3,
          ),
        ),
      ),
    );
    expect(find.text('ZIP'), findsWidgets);
    expect(find.text('Format'), findsOneWidget);
  });
}
