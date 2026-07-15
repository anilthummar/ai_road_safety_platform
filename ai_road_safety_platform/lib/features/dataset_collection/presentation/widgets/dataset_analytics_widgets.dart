import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Reusable chart shell with title.
class ChartSection extends StatelessWidget {
  /// Title.
  final String title;

  /// Optional subtitle.
  final String? subtitle;

  /// Chart body.
  final Widget child;

  /// Creates [ChartSection].
  const ChartSection({
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: title,
      subtitle: subtitle,
      children: [
        SizedBox(height: 220, child: child),
      ],
    );
  }
}

/// Line chart over [AnalyticsChartPoint]s.
class AnalyticsLineChart extends StatelessWidget {
  /// Points.
  final List<AnalyticsChartPoint> points;

  /// Creates [AnalyticsLineChart].
  const AnalyticsLineChart({required this.points, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (points.isEmpty) return _empty(context);
    final maxY = points.fold<double>(1, (m, p) => p.value > m ? p.value : m);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, points),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].value),
            ],
            isCurved: true,
            color: scheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Area chart (line + fill).
class AnalyticsAreaChart extends StatelessWidget {
  /// Points.
  final List<AnalyticsChartPoint> points;

  /// Creates [AnalyticsAreaChart].
  const AnalyticsAreaChart({required this.points, super.key});

  @override
  Widget build(BuildContext context) {
    return AnalyticsLineChart(points: points);
  }
}

/// Bar chart.
class AnalyticsBarChart extends StatelessWidget {
  /// Points.
  final List<AnalyticsChartPoint> points;

  /// Creates [AnalyticsBarChart].
  const AnalyticsBarChart({required this.points, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (points.isEmpty) return _empty(context);
    final maxY = points.fold<double>(1, (m, p) => p.value > m ? p.value : m);
    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, points),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].value,
                  color: scheme.secondary,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Pie / doughnut chart.
class AnalyticsPieChart extends StatelessWidget {
  /// Points.
  final List<AnalyticsChartPoint> points;

  /// Creates [AnalyticsPieChart].
  const AnalyticsPieChart({required this.points, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (points.isEmpty) return _empty(context);
    final total = points.fold<double>(0, (a, p) => a + p.value);
    if (total <= 0) return _empty(context);
    final colors = [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
      scheme.primaryContainer,
      scheme.secondaryContainer,
    ];
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < points.length; i++)
                  PieChartSectionData(
                    value: points[i].value,
                    color: colors[i % colors.length],
                    title: points[i].value >= total * 0.08
                        ? points[i].value.toStringAsFixed(0)
                        : '',
                    radius: 48,
                    titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < points.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          points[i].label,
                          style: Theme.of(context).textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Timeline chart alias (sessions over days).
class AnalyticsTimelineChart extends StatelessWidget {
  /// Points.
  final List<AnalyticsChartPoint> points;

  /// Creates [AnalyticsTimelineChart].
  const AnalyticsTimelineChart({required this.points, super.key});

  @override
  Widget build(BuildContext context) => AnalyticsBarChart(points: points);
}

FlTitlesData _titles(BuildContext context, List<AnalyticsChartPoint> points) {
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 32,
        getTitlesWidget: (value, meta) => Text(
          value.toInt().toString(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (i < 0 || i >= points.length) return const SizedBox.shrink();
          // Sparse labels when many points.
          if (points.length > 8 && i % ((points.length / 6).ceil()) != 0) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              points[i].label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          );
        },
      ),
    ),
  );
}

Widget _empty(BuildContext context) {
  return Center(
    child: Text(
      'No chart data',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    ),
  );
}

/// KPI grid for overview.
class StatisticsGrid extends StatelessWidget {
  /// Overview.
  final DatasetAnalyticsOverview overview;

  /// Creates [StatisticsGrid].
  const StatisticsGrid({required this.overview, super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData)>[
      ('Sessions', '${overview.totalSessions}', Icons.collections_bookmark_outlined),
      ('Frames', '${overview.totalFrames}', Icons.photo_library_outlined),
      (
        'Recording time',
        _fmtDuration(overview.totalRecordingTime),
        Icons.timer_outlined,
      ),
      (
        'Flood events',
        '${overview.totalFloodEvents}',
        Icons.water_drop_outlined,
      ),
      (
        'Avg duration',
        _fmtDuration(overview.averageRecordingDuration),
        Icons.schedule,
      ),
      (
        'Avg speed',
        '${overview.averageSpeed.toStringAsFixed(1)} km/h',
        Icons.speed,
      ),
      (
        'Avg confidence',
        overview.averageFloodConfidence.toStringAsFixed(2),
        Icons.psychology_outlined,
      ),
      (
        'Avg water cover',
        '${overview.averageWaterCoverage.toStringAsFixed(1)}%',
        Icons.water,
      ),
      (
        'Storage used',
        _fmtBytes(overview.storageUsedBytes),
        Icons.sd_storage_outlined,
      ),
      (
        'Storage left',
        _fmtBytes(overview.storageRemainingSoftBytes),
        Icons.storage_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 700
                ? 2
                : 1;
        final w =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final item in items)
              SizedBox(
                width: w,
                child: AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        child: Icon(
                          item.$3,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              item.$1,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Quality metrics card.
class DatasetQualityCard extends StatelessWidget {
  /// Metrics.
  final DatasetQualityMetrics quality;

  /// Creates [DatasetQualityCard].
  const DatasetQualityCard({required this.quality, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Dataset quality',
      subtitle:
          'Completeness ${quality.completenessScore.toStringAsFixed(0)} / 100',
      children: [
        LinearProgressIndicator(
          value: (quality.completenessScore / 100).clamp(0, 1),
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: AppSpacing.md),
        _kv(context, 'Frames / session',
            quality.framesPerSession.toStringAsFixed(1)),
        _kv(context, 'Frames / minute',
            quality.framesPerMinute.toStringAsFixed(1)),
        _kv(context, 'Capture frequency',
            '${quality.captureFrequencyHz.toStringAsFixed(2)} Hz'),
        _kv(context, 'Capture success',
            '${(quality.captureSuccessRate * 100).toStringAsFixed(0)}%'),
        _kv(context, 'Avg interval',
            '${quality.averageCaptureIntervalSeconds.toStringAsFixed(1)} s'),
        _kv(context, 'Missing metadata', '${quality.missingMetadataCount}'),
        _kv(context, 'Corrupted frames', '${quality.corruptedFrameCount}'),
        _kv(context, 'Empty sessions', '${quality.emptySessionCount}'),
      ],
    );
  }
}

/// Research insight list.
class ResearchInsightCard extends StatelessWidget {
  /// Insights.
  final ResearchInsights insights;

  /// Optional tap on session-backed insight.
  final void Function(String sessionId)? onOpenSession;

  /// Creates [ResearchInsightCard].
  const ResearchInsightCard({
    required this.insights,
    this.onOpenSession,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Research insights',
      subtitle: 'Highlights from the filtered corpus',
      children: [
        for (final i in insights.insights)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(i.title),
            subtitle: Text(i.subtitle),
            trailing: Text(
              i.value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            onTap: i.sessionId == null
                ? null
                : () => onOpenSession?.call(i.sessionId!),
          ),
      ],
    );
  }
}

/// Location analytics card.
class LocationAnalyticsCard extends StatelessWidget {
  /// Data.
  final LocationAnalytics location;

  /// Creates [LocationAnalyticsCard].
  const LocationAnalyticsCard({required this.location, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Location analytics',
      children: [
        _kv(context, 'GPS points', '${location.totalGpsPoints}'),
        _kv(context, 'Avg speed',
            '${location.averageSpeed.toStringAsFixed(1)} km/h'),
        _kv(context, 'Distance covered',
            '${location.distanceCoveredKm.toStringAsFixed(1)} km'),
        _kv(context, 'Sessions with GPS', '${location.sessionsWithGps}'),
        _kv(context, 'Sessions without GPS', '${location.sessionsWithoutGps}'),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 180,
          child: AnalyticsPieChart(points: location.accuracyDistribution),
        ),
      ],
    );
  }
}

/// Inference analytics card.
class InferenceAnalyticsCard extends StatelessWidget {
  /// Data.
  final InferenceAnalytics inference;

  /// Creates [InferenceAnalyticsCard].
  const InferenceAnalyticsCard({required this.inference, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'AI analytics',
      children: [
        _kv(context, 'Avg inference',
            '${inference.averageInferenceTimeMs.toStringAsFixed(1)} ms'),
        _kv(context, 'Avg flood confidence',
            inference.averageFloodConfidence.toStringAsFixed(2)),
        _kv(context, 'Flood detections', '${inference.floodDetectionCount}'),
        const SizedBox(height: AppSpacing.md),
        Text('Risk levels', style: Theme.of(context).textTheme.labelLarge),
        SizedBox(
          height: 180,
          child: AnalyticsPieChart(points: inference.riskLevelDistribution),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Water coverage', style: Theme.of(context).textTheme.labelLarge),
        SizedBox(
          height: 180,
          child: AnalyticsBarChart(points: inference.waterCoverageDistribution),
        ),
      ],
    );
  }
}

/// Storage analytics card.
class StorageAnalyticsCard extends StatelessWidget {
  /// Data.
  final StorageAnalytics storage;

  /// Creates [StorageAnalyticsCard].
  const StorageAnalyticsCard({required this.storage, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Storage analytics',
      children: [
        _kv(context, 'Total', _fmtBytes(storage.totalStorageBytes)),
        _kv(context, 'Images', _fmtBytes(storage.imagesStorageBytes)),
        _kv(context, 'Metadata', _fmtBytes(storage.metadataStorageBytes)),
        _kv(context, 'Cache', _fmtBytes(storage.cacheSizeBytes)),
        _kv(context, 'Temporary', _fmtBytes(storage.temporaryFilesBytes)),
        _kv(
          context,
          'Avg session size',
          _fmtBytes(storage.averageSessionSizeBytes.round()),
        ),
        _kv(
          context,
          'Soft budget left',
          _fmtBytes(storage.remainingSoftBudgetBytes),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 180,
          child: AnalyticsPieChart(points: storage.breakdown),
        ),
      ],
    );
  }
}

/// Session analytics distributions.
class SessionAnalyticsCard extends StatelessWidget {
  /// Data.
  final SessionAnalytics sessions;

  /// Creates [SessionAnalyticsCard].
  const SessionAnalyticsCard({required this.sessions, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChartSection(
          title: 'Session duration distribution',
          child: AnalyticsBarChart(points: sessions.durationDistribution),
        ),
        const SizedBox(height: AppSpacing.md),
        ChartSection(
          title: 'Frame count distribution',
          child: AnalyticsBarChart(points: sessions.frameCountDistribution),
        ),
        const SizedBox(height: AppSpacing.md),
        ChartSection(
          title: 'Storage distribution',
          child: AnalyticsBarChart(points: sessions.storageDistribution),
        ),
        const SizedBox(height: AppSpacing.md),
        ChartSection(
          title: 'Recording frequency',
          child: AnalyticsAreaChart(points: sessions.recordingFrequency),
        ),
        const SizedBox(height: AppSpacing.md),
        ChartSection(
          title: 'Session timeline',
          child: AnalyticsTimelineChart(points: sessions.sessionTimeline),
        ),
        const SizedBox(height: AppSpacing.md),
        ChartSection(
          title: 'Status mix',
          child: AnalyticsPieChart(points: sessions.statusDistribution),
        ),
      ],
    );
  }
}

/// Analytics dashboard composite (sections).
class AnalyticsDashboard extends StatelessWidget {
  /// Report.
  final DatasetAnalyticsReport report;

  /// Open session from insight.
  final void Function(String sessionId)? onOpenSession;

  /// Creates [AnalyticsDashboard].
  const AnalyticsDashboard({
    required this.report,
    this.onOpenSession,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatisticsGrid(overview: report.overview),
        const SizedBox(height: AppSpacing.lg),
        ChartSection(
          title: 'Dataset growth',
          subtitle: 'Cumulative frames over time',
          child: AnalyticsLineChart(points: report.overview.datasetGrowth),
        ),
        const SizedBox(height: AppSpacing.lg),
        DatasetQualityCard(quality: report.quality),
        const SizedBox(height: AppSpacing.lg),
        ResearchInsightCard(
          insights: report.insights,
          onOpenSession: onOpenSession,
        ),
        const SizedBox(height: AppSpacing.lg),
        LocationAnalyticsCard(location: report.location),
        const SizedBox(height: AppSpacing.lg),
        InferenceAnalyticsCard(inference: report.inference),
        const SizedBox(height: AppSpacing.lg),
        StorageAnalyticsCard(storage: report.storage),
        const SizedBox(height: AppSpacing.lg),
        SessionAnalyticsCard(sessions: report.sessions),
      ],
    );
  }
}

/// Filter + search bar.
class AnalyticsFilterBar extends StatefulWidget {
  /// Current filter.
  final AnalyticsFilter filter;

  /// Applied callback.
  final ValueChanged<AnalyticsFilter> onChanged;

  /// Creates [AnalyticsFilterBar].
  const AnalyticsFilterBar({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  @override
  State<AnalyticsFilterBar> createState() => _AnalyticsFilterBarState();
}

class _AnalyticsFilterBarState extends State<AnalyticsFilterBar> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.filter.searchQuery);
  }

  @override
  void didUpdateWidget(covariant AnalyticsFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.searchQuery != widget.filter.searchQuery &&
        _search.text != widget.filter.searchQuery) {
      _search.text = widget.filter.searchQuery;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchBar(
          controller: _search,
          hintText: 'Search session, date, status…',
          leading: const Icon(Icons.search),
          trailing: [
            IconButton(
              onPressed: () => widget.onChanged(
                widget.filter.copyWith(searchQuery: _search.text.trim()),
              ),
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
          onSubmitted: (v) => widget.onChanged(
            widget.filter.copyWith(searchQuery: v.trim()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => showAnalyticsFilterSheet(
                  context: context,
                  current: widget.filter,
                  onApply: widget.onChanged,
                ),
                icon: const Icon(Icons.filter_list),
                label: const Text('Filters'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    initialDateRange: widget.filter.customStart != null &&
                            widget.filter.customEnd != null
                        ? DateTimeRange(
                            start: widget.filter.customStart!,
                            end: widget.filter.customEnd!,
                          )
                        : null,
                  );
                  if (range == null) return;
                  widget.onChanged(
                    widget.filter.copyWith(
                      dateFilter: AnalyticsDateFilter.custom,
                      customStart: range.start,
                      customEnd: range.end,
                    ),
                  );
                },
                icon: const Icon(Icons.date_range),
                label: const Text('Date range'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Filter bottom sheet.
Future<void> showAnalyticsFilterSheet({
  required BuildContext context,
  required AnalyticsFilter current,
  required ValueChanged<AnalyticsFilter> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      var date = current.dateFilter;
      var status = current.status;
      var minFlood = current.minFloodEvents;
      return StatefulBuilder(
        builder: (context, setModal) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Analytics filters',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final f in AnalyticsDateFilter.values)
                      if (f != AnalyticsDateFilter.custom)
                        ChoiceChip(
                          label: Text(_dateLabel(f)),
                          selected: date == f,
                          onSelected: (_) => setModal(() => date = f),
                        ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Status', style: Theme.of(context).textTheme.labelLarge),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('Any'),
                      selected: status == null,
                      onSelected: (_) => setModal(() => status = null),
                    ),
                    for (final s in DatasetSessionStatus.values)
                      ChoiceChip(
                        label: Text(s.label),
                        selected: status == s,
                        onSelected: (_) => setModal(() => status = s),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Min flood events',
                    style: Theme.of(context).textTheme.labelLarge),
                Slider(
                  value: (minFlood ?? 0).toDouble().clamp(0, 100),
                  max: 100,
                  divisions: 20,
                  label: minFlood == null || minFlood == 0
                      ? 'Any'
                      : '$minFlood',
                  onChanged: (v) => setModal(() {
                    minFlood = v <= 0 ? null : v.round();
                  }),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onApply(
                      current.copyWith(
                        dateFilter: date,
                        status: status,
                        minFloodEvents: minFlood,
                        clearStatus: status == null,
                        clearMinFlood: minFlood == null,
                      ),
                    );
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Empty analytics state.
class AnalyticsEmptyState extends StatelessWidget {
  /// Action.
  final VoidCallback? onOpenDashboard;

  /// Creates [AnalyticsEmptyState].
  const AnalyticsEmptyState({this.onOpenDashboard, super.key});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.analytics_outlined,
      title: 'No analytics data',
      message:
          'No sessions match this filter, or the dataset is empty. '
          'Record sessions to unlock research insights.',
      actionLabel: onOpenDashboard == null ? null : 'Open dataset dashboard',
      onAction: onOpenDashboard,
    );
  }
}

/// Loading state.
class AnalyticsLoadingState extends StatelessWidget {
  /// Message.
  final String message;

  /// Creates [AnalyticsLoadingState].
  const AnalyticsLoadingState({
    this.message = 'Computing analytics…',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(message),
          ],
        ),
      ),
    );
  }
}

Widget _kv(BuildContext context, String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(child: Text(k)),
        Text(v, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}

String _dateLabel(AnalyticsDateFilter f) => switch (f) {
      AnalyticsDateFilter.all => 'All',
      AnalyticsDateFilter.today => 'Today',
      AnalyticsDateFilter.yesterday => 'Yesterday',
      AnalyticsDateFilter.last7Days => 'Last 7 days',
      AnalyticsDateFilter.last30Days => 'Last 30 days',
      AnalyticsDateFilter.custom => 'Custom',
    };

String _fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '$h:$m:$s';
  return '$m:$s';
}

String _fmtBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
