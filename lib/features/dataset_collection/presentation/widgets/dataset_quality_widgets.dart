import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_quality_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QualityGateStatusCard extends StatelessWidget {
  final DatasetQualityAssessmentReport report;

  const QualityGateStatusCard({required this.report, super.key});

  @override
  Widget build(BuildContext context) {
    final color = switch (report.decision) {
      QualityGateDecision.pass => Colors.green.shade700,
      QualityGateDecision.conditional => Colors.orange.shade800,
      QualityGateDecision.fail => Theme.of(context).colorScheme.error,
    };
    return AppSectionCard(
      title: 'Training gate',
      subtitle: report.gateSummary,
      children: [
        Row(
          children: [
            Icon(
              report.trainingAllowed
                  ? Icons.verified_outlined
                  : Icons.gpp_bad_outlined,
              color: color,
              size: 36,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.decision.label.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Overall score ${report.overallScore.toStringAsFixed(0)} / 100',
                  ),
                  Text(
                    report.trainingAllowed
                        ? 'Training allowed'
                        : 'Training blocked until issues are resolved',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class QualityDimensionScoresCard extends StatelessWidget {
  final List<DimensionScore> dimensions;

  const QualityDimensionScoresCard({required this.dimensions, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Quality dimensions',
      children: [
        if (dimensions.isEmpty)
          const Text('No dimension scores')
        else
          for (final d in dimensions) ...[
            Text('${d.dimension.label} · ${d.score.toStringAsFixed(0)}'),
            LinearProgressIndicator(
              value: (d.score / 100).clamp(0, 1),
            ),
            Text(d.summary, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class QualityIssuesCard extends StatelessWidget {
  final List<QualityIssue> issues;

  const QualityIssuesCard({required this.issues, super.key});

  @override
  Widget build(BuildContext context) {
    final sorted = [...issues]..sort(
        (a, b) => b.severity.index.compareTo(a.severity.index),
      );
    return AppSectionCard(
      title: 'Findings',
      subtitle: '${issues.length} issues',
      children: [
        if (sorted.isEmpty)
          const Text('No issues — corpus looks healthy')
        else
          for (final i in sorted.take(20))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                switch (i.severity) {
                  QualityIssueSeverity.critical => Icons.error_outline,
                  QualityIssueSeverity.warning => Icons.warning_amber_outlined,
                  QualityIssueSeverity.info => Icons.info_outline,
                },
                color: switch (i.severity) {
                  QualityIssueSeverity.critical =>
                    Theme.of(context).colorScheme.error,
                  QualityIssueSeverity.warning => Colors.orange.shade800,
                  QualityIssueSeverity.info =>
                    Theme.of(context).colorScheme.primary,
                },
              ),
              title: Text(i.message),
              subtitle: Text(
                '${i.severity.label} · ${i.code}'
                '${i.sessionId != null ? ' · ${i.sessionId}' : ''}',
              ),
            ),
      ],
    );
  }
}

class QualitySessionTableCard extends StatelessWidget {
  final List<SessionQualityAssessment> sessions;

  const QualitySessionTableCard({required this.sessions, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Sessions',
      subtitle: '${sessions.length} assessed (worst first)',
      children: [
        if (sessions.isEmpty)
          const Text('No sessions')
        else
          for (final s in sessions.take(25))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(s.sessionName),
              subtitle: Text(
                '${s.decision.label} · score ${s.overallScore.toStringAsFixed(0)} · '
                '${s.annotatedFrames}/${s.frameCount} annotated · '
                'img ${s.imageCount} / meta ${s.metadataCount}',
              ),
              trailing: Text(s.decision.label),
            ),
      ],
    );
  }
}

class QualityLabelCoverageCard extends StatelessWidget {
  final List<LabelCoverageStat> coverage;

  const QualityLabelCoverageCard({required this.coverage, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Label coverage',
      children: [
        if (coverage.isEmpty)
          const Text('No annotations with labels yet')
        else
          for (final l in coverage.take(12)) ...[
            Text(
              '${l.labelName} · ${l.count} '
              '(${(l.ratio * 100).toStringAsFixed(0)}%)',
            ),
            LinearProgressIndicator(value: l.ratio.clamp(0, 1)),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class QualityThresholdsCard extends StatelessWidget {
  final QualityGateThresholds thresholds;
  final ValueChanged<QualityGateThresholds> onChanged;

  const QualityThresholdsCard({
    required this.thresholds,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Gate thresholds',
      subtitle: 'Tune before re-assessing',
      children: [
        _slider(
          context,
          label: 'Pass score ≥ ${thresholds.passScore.round()}',
          value: thresholds.passScore,
          onChanged: (v) => onChanged(thresholds.copyWith(passScore: v)),
        ),
        _slider(
          context,
          label: 'Conditional score ≥ ${thresholds.conditionalScore.round()}',
          value: thresholds.conditionalScore,
          min: 20,
          max: 90,
          onChanged: (v) =>
              onChanged(thresholds.copyWith(conditionalScore: v)),
        ),
        _slider(
          context,
          label:
              'Min annotation coverage ${(thresholds.minAnnotationCoverage * 100).round()}%',
          value: thresholds.minAnnotationCoverage * 100,
          onChanged: (v) => onChanged(
            thresholds.copyWith(minAnnotationCoverage: v / 100),
          ),
        ),
        FilledButton.tonal(
          onPressed: () => context
              .read<DatasetQualityBloc>()
              .add(const DatasetQualityEvaluateGate()),
          child: const Text('Re-evaluate gate'),
        ),
      ],
    );
  }

  Widget _slider(
    BuildContext context, {
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 40,
    double max = 95,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) / 5).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class QualityCorpusStatsCard extends StatelessWidget {
  final DatasetQualityAssessmentReport report;

  const QualityCorpusStatsCard({required this.report, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Corpus stats',
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _kv(context, 'Sessions', '${report.totalSessions}'),
            _kv(context, 'Frames', '${report.totalFrames}'),
            _kv(context, 'Pass', '${report.passSessions}'),
            _kv(context, 'Conditional', '${report.conditionalSessions}'),
            _kv(context, 'Fail', '${report.failSessions}'),
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
        Text(v, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
