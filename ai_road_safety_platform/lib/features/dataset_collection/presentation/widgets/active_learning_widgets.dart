import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/active_learning_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActiveLearningSummaryCard extends StatelessWidget {
  final ActiveLearningSnapshot snapshot;

  const ActiveLearningSummaryCard({required this.snapshot, super.key});

  @override
  Widget build(BuildContext context) {
    final latest = snapshot.latest;
    return AppSectionCard(
      title: 'Active learning',
      subtitle:
          '${snapshot.totalSelections} selections · ${snapshot.totalCandidates} candidates',
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _kv(context, 'Runs', '${snapshot.totalSelections}'),
            _kv(
              context,
              'Latest picks',
              latest == null ? '—' : '${latest.selectedCount}',
            ),
            _kv(
              context,
              'Top score',
              latest == null ? '—' : latest.topScore.toStringAsFixed(0),
            ),
            _kv(
              context,
              'Frames scored',
              latest == null ? '—' : '${latest.framesConsidered}',
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

class ActiveLearningSelectionListCard extends StatelessWidget {
  final List<ActiveLearningSelection> selections;

  const ActiveLearningSelectionListCard({
    required this.selections,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...selections]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return AppSectionCard(
      title: 'Selections',
      subtitle: 'Uncertainty · coverage · review priority',
      children: [
        if (sorted.isEmpty)
          const Text('No selections yet')
        else
          for (final s in sorted) _SelectionTile(selection: s),
      ],
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final ActiveLearningSelection selection;

  const _SelectionTile({required this.selection});

  @override
  Widget build(BuildContext context) {
    final top = selection.candidates.take(3).map((c) {
      final reasons = c.reasons.map((r) => r.label).take(2).join(', ');
      return '#${c.frameNumber} (${c.score.toStringAsFixed(0)})'
          '${reasons.isEmpty ? '' : ' · $reasons'}';
    }).join('\n');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selection.isDemo ? Icons.science_outlined : Icons.psychology_outlined,
        color: selection.topScore >= 50 ? Colors.orange.shade800 : null,
      ),
      title: Text(
        '${selection.isDemo ? 'Demo · ' : ''}'
        '${selection.selectedCount} of ${selection.framesConsidered} frames',
      ),
      subtitle: Text(
        '${selection.sessionIds.length} session(s) · topK=${selection.config.topK}\n'
        '${top.isEmpty ? selection.notes : top}',
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'delete') {
            context
                .read<ActiveLearningBloc>()
                .add(ActiveLearningDelete(selection.id));
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

class ActiveLearningControls extends StatelessWidget {
  const ActiveLearningControls({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Actions',
      subtitle: 'Prioritize frames that need human labeling',
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context
                  .read<ActiveLearningBloc>()
                  .add(const ActiveLearningRefresh()),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            FilledButton.icon(
              onPressed: () => context
                  .read<ActiveLearningBloc>()
                  .add(const ActiveLearningRun()),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Rank samples'),
            ),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<ActiveLearningBloc>()
                  .add(const ActiveLearningCreateDemo()),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Demo selection'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Scores unlabeled frames, AI-only drafts, low confidence, '
          'needs-review, and rare labels. Open Annotate to label the queue.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
