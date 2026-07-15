import 'dart:io';

import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_explorer_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_collection_widgets.dart';
import 'package:flutter/material.dart';

/// Dashboard title + active recording strip.
class DashboardHeader extends StatelessWidget {
  /// Dashboard payload.
  final DatasetDashboardData data;

  /// Continue / open recording.
  final VoidCallback? onContinueRecording;

  /// Open session explorer.
  final VoidCallback? onBrowseSessions;

  /// Creates [DashboardHeader].
  const DashboardHeader({
    required this.data,
    this.onContinueRecording,
    this.onBrowseSessions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = data.activeSession;
    return AppSectionCard(
      title: 'Dataset research workspace',
      subtitle: 'Browse sessions · inspect storage · prepare for annotation',
      children: [
        if (active != null) ...[
          Material(
            color: scheme.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              leading: Icon(
                active.isRecording
                    ? Icons.fiber_manual_record
                    : Icons.pause_circle_outline,
                color: scheme.error,
              ),
              title: Text(active.sessionName),
              subtitle: Text(
                'Current status · ${active.status.label}',
              ),
              trailing: FilledButton(
                onPressed: onContinueRecording,
                child: const Text('Continue'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.tonalIcon(
              onPressed: onBrowseSessions,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Session explorer'),
            ),
            OutlinedButton.icon(
              onPressed: onContinueRecording,
              icon: const Icon(Icons.videocam_outlined),
              label: Text(
                active == null ? 'Start recording' : 'Recording dashboard',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Large statistic cards for the dashboard.
class StatisticsCards extends StatelessWidget {
  /// Dashboard data.
  final DatasetDashboardData data;

  /// Creates [StatisticsCards].
  const StatisticsCards({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final s = data.statistics;
    final items = <(String, String, IconData)>[
      ('Sessions', '${s.totalSessions}', Icons.collections_bookmark_outlined),
      ('Frames', '${s.totalFrames}', Icons.photo_library_outlined),
      ('Flood events', '${s.totalFloodEvents}', Icons.water_drop_outlined),
      (
        'Avg confidence',
        s.averageConfidence.toStringAsFixed(2),
        Icons.psychology_outlined,
      ),
      (
        'Dataset size',
        _formatBytes(s.totalStorage),
        Icons.sd_storage_outlined,
      ),
      (
        'Recording time',
        _formatDuration(data.totalRecordingTime),
        Icons.timer_outlined,
      ),
      (
        'Avg speed',
        '${s.averageSpeed.toStringAsFixed(1)} km/h',
        Icons.speed_outlined,
      ),
      (
        'Frames / min',
        data.framesPerMinute.toStringAsFixed(1),
        Icons.speed,
      ),
      (
        'Avg flood cover',
        '${data.averageFloodCoverage.toStringAsFixed(1)}%',
        Icons.water,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 3
            : width >= 700
                ? 2
                : 1;
        final cardWidth =
            (width - (AppSpacing.md * (columns - 1))) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: _StatTile(
                  label: item.$1,
                  value: item.$2,
                  icon: item.$3,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            child: Icon(icon, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Storage overview for the research dashboard.
class ExplorerStorageCard extends StatelessWidget {
  /// Soft-budget disk usage.
  final StorageUsage diskUsage;

  /// Hive folder snapshot.
  final DatasetStorage collectionStorage;

  /// Creates [ExplorerStorageCard].
  const ExplorerStorageCard({
    required this.diskUsage,
    required this.collectionStorage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remainingSoft =
        (diskUsage.softLimitBytes - diskUsage.usedBytes).clamp(0, 1 << 62);
    return AppSectionCard(
      title: 'Storage overview',
      subtitle: diskUsage.datasetRoot,
      children: [
        Text(
          'Used ${_formatBytes(diskUsage.usedBytes)} · '
          'Remaining soft budget ${_formatBytes(remainingSoft)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: diskUsage.softFillRatio,
            minHeight: 10,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          collectionStorage.remainingDiskSpace > 0
              ? 'Device free ≈ '
                  '${_formatBytes(collectionStorage.remainingDiskSpace)}'
              : 'Device free/total not reported on this platform',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (diskUsage.isLowStorage) ...[
          const SizedBox(height: AppSpacing.md),
          Material(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: scheme.onErrorContainer),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      diskUsage.warningMessage ??
                          'Storage budget is running low.',
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Rich session card for the explorer.
class ExplorerSessionCard extends StatelessWidget {
  /// Session.
  final DatasetSession session;

  /// Open details.
  final VoidCallback? onOpen;

  /// Quick actions callback.
  final void Function(String action)? onAction;

  /// Creates [ExplorerSessionCard].
  const ExplorerSessionCard({
    required this.session,
    this.onOpen,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.sessionName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              RecordingStatusBadge(status: session.status),
              QuickActionMenu(
                session: session,
                onAction: onAction,
              ),
            ],
          ),
          if (session.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              session.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _chip(context, Icons.schedule, _formatDuration(session.duration)),
              _chip(
                context,
                Icons.calendar_today_outlined,
                _shortDate(session.createdAt),
              ),
              _chip(context, Icons.photo, '${session.frameCount} frames'),
              _chip(
                context,
                Icons.sd_storage_outlined,
                _formatBytes(session.totalStorage),
              ),
              _chip(
                context,
                Icons.water_drop_outlined,
                '${session.floodEventCount} floods',
              ),
              _chip(
                context,
                Icons.speed,
                '${session.averageSpeed.toStringAsFixed(1)} km/h',
              ),
              _chip(
                context,
                Icons.psychology_outlined,
                'conf ${session.averageConfidence.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// Grid of session cards (tablet / desktop).
class SessionGrid extends StatelessWidget {
  /// Sessions.
  final List<DatasetSession> sessions;

  /// Open.
  final void Function(DatasetSession session) onOpen;

  /// Action.
  final void Function(DatasetSession session, String action) onAction;

  /// Creates [SessionGrid].
  const SessionGrid({
    required this.sessions,
    required this.onOpen,
    required this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 2
            : 1;
        if (columns == 1) {
          return SessionList(
            sessions: sessions,
            onOpen: onOpen,
            onAction: onAction,
          );
        }
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final s in sessions)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: ExplorerSessionCard(
                  session: s,
                  onOpen: () => onOpen(s),
                  onAction: (a) => onAction(s, a),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Vertical list of session cards.
class SessionList extends StatelessWidget {
  /// Sessions.
  final List<DatasetSession> sessions;

  /// Open.
  final void Function(DatasetSession session) onOpen;

  /// Action.
  final void Function(DatasetSession session, String action) onAction;

  /// Creates [SessionList].
  const SessionList({
    required this.sessions,
    required this.onOpen,
    required this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final s in sessions) ...[
          ExplorerSessionCard(
            session: s,
            onOpen: () => onOpen(s),
            onAction: (a) => onAction(s, a),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// Search field for explorer.
class ExplorerSearchBar extends StatefulWidget {
  /// Initial text.
  final String initialQuery;

  /// Debounced submit.
  final ValueChanged<String> onSearch;

  /// Creates [ExplorerSearchBar].
  const ExplorerSearchBar({
    required this.onSearch,
    this.initialQuery = '',
    super.key,
  });

  @override
  State<ExplorerSearchBar> createState() => _ExplorerSearchBarState();
}

class _ExplorerSearchBarState extends State<ExplorerSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      hintText: 'Search name, description, date, status…',
      leading: const Icon(Icons.search),
      trailing: [
        if (_controller.text.isNotEmpty)
          IconButton(
            onPressed: () {
              _controller.clear();
              widget.onSearch('');
              setState(() {});
            },
            icon: const Icon(Icons.clear),
          ),
        IconButton(
          onPressed: () => widget.onSearch(_controller.text.trim()),
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
      onChanged: (_) => setState(() {}),
      onSubmitted: (v) => widget.onSearch(v.trim()),
    );
  }
}

/// Filter bottom sheet.
Future<void> showFilterBottomSheet({
  required BuildContext context,
  required SessionQuery current,
  required void Function({
    required SessionDateFilter dateFilter,
    DatasetSessionStatus? status,
    int? minStorageBytes,
    int? minFloodEvents,
  }) onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      var date = current.dateFilter;
      DatasetSessionStatus? status = current.status;
      var minStorage = current.minStorageBytes;
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
                  'Filter sessions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Date', style: Theme.of(context).textTheme.labelLarge),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final f in SessionDateFilter.values)
                      ChoiceChip(
                        label: Text(_dateFilterLabel(f)),
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
                Text(
                  'Min storage (MB)',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Slider(
                  value: ((minStorage ?? 0) / (1024 * 1024)).clamp(0, 500),
                  max: 500,
                  divisions: 50,
                  label: minStorage == null || minStorage == 0
                      ? 'Any'
                      : '${(minStorage! / (1024 * 1024)).round()} MB',
                  onChanged: (v) => setModal(() {
                    minStorage = v <= 0 ? null : (v * 1024 * 1024).round();
                  }),
                ),
                Text(
                  'Min flood events',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
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
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onApply(
                      dateFilter: date,
                      status: status,
                      minStorageBytes: minStorage,
                      minFloodEvents: minFlood,
                    );
                  },
                  child: const Text('Apply filters'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Sort bottom sheet.
Future<void> showSortBottomSheet({
  required BuildContext context,
  required SessionSortOption current,
  required ValueChanged<SessionSortOption> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Sort sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final opt in SessionSortOption.values)
              ListTile(
                title: Text(_sortLabel(opt)),
                trailing: current == opt
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onApply(opt);
                },
              ),
          ],
        ),
      );
    },
  );
}

/// Quick actions popup.
class QuickActionMenu extends StatelessWidget {
  /// Session.
  final DatasetSession session;

  /// Action key callback.
  final void Function(String action)? onAction;

  /// Creates [QuickActionMenu].
  const QuickActionMenu({
    required this.session,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final canDelete = !session.status.isUnfinished;
    return PopupMenuButton<String>(
      onSelected: onAction,
      itemBuilder: (context) => [
        if (session.status.isUnfinished)
          const PopupMenuItem(
            value: 'continue',
            child: Text('Continue session'),
          ),
        const PopupMenuItem(value: 'details', child: Text('View details')),
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        if (canDelete)
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        const PopupMenuItem(
          value: 'export',
          enabled: false,
          child: Text('Export (soon)'),
        ),
        const PopupMenuItem(
          value: 'annotate',
          enabled: false,
          child: Text('Annotation (soon)'),
        ),
      ],
    );
  }
}

/// Thumbnail grid with lazy FileImage decode.
class ThumbnailGrid extends StatelessWidget {
  /// Previews.
  final List<SessionPreviewImage> previews;

  /// Creates [ThumbnailGrid].
  const ThumbnailGrid({required this.previews, super.key});

  @override
  Widget build(BuildContext context) {
    if (previews.isEmpty) {
      return const AppEmptyState(
        icon: Icons.image_not_supported_outlined,
        title: 'No preview images',
        message:
            'Frames appear here after images are saved locally. '
            'Metadata-only sessions show an empty grid.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${previews.length} preview(s)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: previews.length,
          gridDelegate: const CloverGridDelegate(),
          itemBuilder: (context, index) {
            final p = previews[index];
            return _ThumbnailTile(preview: p);
          },
        ),
      ],
    );
  }
}

/// Square grid delegate (3–4 columns responsive via parent width).
class CloverGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  /// Creates [CloverGridDelegate].
  const CloverGridDelegate()
      : super(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1,
        );
}

class _ThumbnailTile extends StatelessWidget {
  final SessionPreviewImage preview;

  const _ThumbnailTile({required this.preview});

  @override
  Widget build(BuildContext context) {
    final path = _resolvePath(preview);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: path == null
                ? const Icon(Icons.broken_image_outlined)
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                    cacheHeight: 240,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '#${preview.frameNumber}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _resolvePath(SessionPreviewImage p) {
    for (final candidate in [p.thumbnailPath, p.originalPath]) {
      if (candidate != null && File(candidate).existsSync()) {
        return candidate;
      }
    }
    return null;
  }
}

/// Metadata summary card.
class ExplorerMetadataCard extends StatelessWidget {
  /// Details.
  final SessionDetails details;

  /// Creates [ExplorerMetadataCard].
  const ExplorerMetadataCard({required this.details, super.key});

  @override
  Widget build(BuildContext context) {
    final s = details.session;
    return AppSectionCard(
      title: 'Metadata summary',
      subtitle: details.metadataSummary ?? 'No frame metadata on disk yet',
      children: [
        _kv(context, 'Capture rate',
            '${details.captureRateFpm.toStringAsFixed(1)} frames/min'),
        _kv(context, 'Avg confidence',
            s.averageConfidence.toStringAsFixed(2)),
        _kv(context, 'Avg speed',
            '${s.averageSpeed.toStringAsFixed(1)} km/h'),
        _kv(context, 'Avg flood coverage',
            '${s.averageFloodCoverage.toStringAsFixed(1)}%'),
        _kv(context, 'Device', s.deviceName),
        _kv(context, 'Model', s.modelVersion),
        if (details.isIncompleteOnDisk)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Disk scan reported incomplete media/metadata.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
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
}

/// Loading placeholder.
class ExplorerLoadingState extends StatelessWidget {
  /// Message.
  final String message;

  /// Creates [ExplorerLoadingState].
  const ExplorerLoadingState({this.message = 'Loading…', super.key});

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

/// Empty explorer state.
class ExplorerEmptyState extends StatelessWidget {
  /// Primary action.
  final VoidCallback? onStartRecording;

  /// Creates [ExplorerEmptyState].
  const ExplorerEmptyState({this.onStartRecording, super.key});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Empty dataset',
      message:
          'No sessions match your filters, or none have been collected yet. '
          'Start a recording to grow the research corpus.',
      actionLabel: onStartRecording == null ? null : 'Open recording',
      onAction: onStartRecording,
    );
  }
}

String _dateFilterLabel(SessionDateFilter f) => switch (f) {
      SessionDateFilter.all => 'All',
      SessionDateFilter.today => 'Today',
      SessionDateFilter.yesterday => 'Yesterday',
      SessionDateFilter.last7Days => 'Last 7 days',
      SessionDateFilter.lastMonth => 'Last month',
    };

String _sortLabel(SessionSortOption o) => switch (o) {
      SessionSortOption.newest => 'Newest',
      SessionSortOption.oldest => 'Oldest',
      SessionSortOption.largestDataset => 'Largest dataset',
      SessionSortOption.mostFrames => 'Most frames',
      SessionSortOption.longestDuration => 'Longest duration',
      SessionSortOption.highestFloodEvents => 'Highest flood events',
    };

String _shortDate(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')}';
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '$h:$m:$s';
  return '$m:$s';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
