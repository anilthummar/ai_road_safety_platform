import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_benchmark_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BenchmarkSummaryCard extends StatelessWidget {
  final BenchmarkSnapshot snapshot;

  const BenchmarkSummaryCard({required this.snapshot, super.key});

  @override
  Widget build(BuildContext context) {
    final latest = snapshot.latest;
    return AppSectionCard(
      title: 'Benchmarks',
      subtitle:
          '${snapshot.totalCount} reports · avg mAP≈${snapshot.averageMapProxy.toStringAsFixed(2)}',
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _kv(context, 'Reports', '${snapshot.totalCount}'),
            _kv(
              context,
              'Latest mAP≈',
              latest == null
                  ? '—'
                  : latest.metrics.mapProxy.toStringAsFixed(2),
            ),
            _kv(
              context,
              'Latest P/R',
              latest == null
                  ? '—'
                  : '${latest.metrics.precision.toStringAsFixed(2)} / '
                      '${latest.metrics.recall.toStringAsFixed(2)}',
            ),
            _kv(
              context,
              'Model',
              latest?.modelId ?? '—',
            ),
          ],
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: Theme.of(context).textTheme.labelSmall),
        Text(v, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class BenchmarkReportListCard extends StatelessWidget {
  final List<BenchmarkReport> reports;

  const BenchmarkReportListCard({required this.reports, super.key});

  @override
  Widget build(BuildContext context) {
    final sorted = [...reports]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return AppSectionCard(
      title: 'Reports',
      subtitle: 'IoU matching · precision / recall / F1 / mAP≈',
      children: [
        if (sorted.isEmpty)
          const Text('No benchmark reports yet')
        else
          for (final r in sorted) _ReportTile(report: r),
      ],
    );
  }
}

class _ReportTile extends StatelessWidget {
  final BenchmarkReport report;

  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final m = report.metrics;
    final classPreview = report.perClass
        .take(3)
        .map((c) => '${c.labelId}:F1=${c.f1.toStringAsFixed(2)}')
        .join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.speed_outlined,
        color: m.mapProxy >= 0.5 ? Colors.green.shade700 : null,
      ),
      title: Text('${report.modelId} · IoU≥${report.iouThreshold}'),
      subtitle: Text(
        '${report.mode.label} · ${report.framesScored} frames · '
        'GT ${report.groundTruthBoxes} / pred ${report.predictionBoxes}\n'
        'P=${m.precision.toStringAsFixed(2)} R=${m.recall.toStringAsFixed(2)} '
        'F1=${m.f1.toStringAsFixed(2)} mAP≈${m.mapProxy.toStringAsFixed(2)}'
        '${classPreview.isEmpty ? '' : '\n$classPreview'}',
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'delete') {
            context
                .read<ModelBenchmarkBloc>()
                .add(ModelBenchmarkDelete(report.id));
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

class BenchmarkControls extends StatelessWidget {
  const BenchmarkControls({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Actions',
      subtitle: 'Offline scoring of AI boxes vs human ground truth',
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context
                  .read<ModelBenchmarkBloc>()
                  .add(const ModelBenchmarkRefresh()),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            FilledButton.icon(
              onPressed: () => context.read<ModelBenchmarkBloc>().add(
                    const ModelBenchmarkRun(modelId: 'bundled-yolov8n'),
                  ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run vs GT'),
            ),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<ModelBenchmarkBloc>()
                  .add(const ModelBenchmarkCreateDemo()),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Demo report'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Uses approved annotation boxes: human GT vs fromAi predictions. '
          'If AI boxes are missing, synthetic preds are generated from GT. '
          'Full TFLite inference wiring lands with Phase 13.6.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
