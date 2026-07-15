import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:flutter/material.dart';

/// Empty state when no dataset sessions exist yet.
class DatasetEmptyState extends StatelessWidget {
  /// Create-session / start callback.
  final VoidCallback? onCreateSession;

  /// Creates [DatasetEmptyState].
  const DatasetEmptyState({this.onCreateSession, super.key});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.folder_off_outlined,
      title: 'No recording sessions',
      message:
          'Start a recording session to track drive dataset collection. '
          'Frame capture arrives in a later phase — this phase manages '
          'sessions only.',
      actionLabel: onCreateSession == null ? null : 'Start recording',
      onAction: onCreateSession,
    );
  }
}

/// Phase note: session manager only (no frames yet).
class DatasetSessionManagerBanner extends StatelessWidget {
  /// Creates [DatasetSessionManagerBanner].
  const DatasetSessionManagerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fiber_manual_record, color: scheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recording session manager',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Phase 12.2 manages session lifecycle and timing only. '
                  'Camera frames, GPS metadata, and AI labels come later.',
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

/// Colored status badge for a session.
class RecordingStatusBadge extends StatelessWidget {
  /// Status to display.
  final DatasetSessionStatus status;

  /// Creates [RecordingStatusBadge].
  const RecordingStatusBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      DatasetSessionStatus.recording => (
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      DatasetSessionStatus.paused => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      DatasetSessionStatus.stopped ||
      DatasetSessionStatus.completed => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
      DatasetSessionStatus.cancelled ||
      DatasetSessionStatus.failed => (
          scheme.errorContainer.withValues(alpha: 0.5),
          scheme.onErrorContainer,
        ),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Displays elapsed recording time (driven by Bloc, not a UI Timer).
class RecordingTimerWidget extends StatelessWidget {
  /// Elapsed duration from [SessionTimerService] via Bloc.
  final Duration elapsed;

  /// Whether recording is actively ticking.
  final bool isLive;

  /// Creates [RecordingTimerWidget].
  const RecordingTimerWidget({
    required this.elapsed,
    this.isLive = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isLive ? Icons.timer : Icons.timer_outlined,
          color: isLive ? scheme.error : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _formatDuration(elapsed),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w600,
                color: isLive ? scheme.error : null,
              ),
        ),
      ],
    );
  }
}

/// Session detail card for the active recording.
class SessionInformationCard extends StatelessWidget {
  /// Active or selected session.
  final DatasetSession session;

  /// Live elapsed (may differ from persisted [DatasetSession.duration]).
  final Duration elapsed;

  /// Creates [SessionInformationCard].
  const SessionInformationCard({
    required this.session,
    required this.elapsed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Session',
      subtitle: session.sessionName,
      trailing: RecordingStatusBadge(status: session.status),
      children: [
        if (session.description.isNotEmpty) ...[
          Text(
            session.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _MetricRow(label: 'Frames', value: '${session.frameCount}'),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(label: 'Flood events', value: '${session.floodEvents}'),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(
          label: 'Storage used',
          value: _formatBytes(session.storageUsed),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(
          label: 'Started',
          value: session.startedAt?.toLocal().toString() ?? '—',
        ),
        const SizedBox(height: AppSpacing.md),
        RecordingTimerWidget(
          elapsed: elapsed,
          isLive: session.isRecording,
        ),
      ],
    );
  }
}

/// Compact session row card.
class SessionCard extends StatelessWidget {
  /// Session.
  final DatasetSession session;

  /// Rename.
  final VoidCallback? onRename;

  /// Delete.
  final VoidCallback? onDelete;

  /// Creates [SessionCard].
  const SessionCard({
    required this.session,
    this.onRename,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canDelete = !session.status.isUnfinished;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(
          session.isRecording
              ? Icons.fiber_manual_record
              : Icons.folder_outlined,
          color: scheme.onPrimaryContainer,
        ),
      ),
      title: Text(session.sessionName),
      subtitle: Text(
        '${session.status.label} · ${_formatDuration(session.duration)} · '
        '${session.frameCount} frames',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'rename') onRename?.call();
          if (value == 'delete') onDelete?.call();
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'rename', child: Text('Rename')),
          if (canDelete)
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

/// Start / Pause / Resume / Stop / Cancel / Rename controls.
class RecordingControlsWidget extends StatelessWidget {
  /// Whether a recording or paused session is active.
  final bool hasActiveSession;

  /// Whether currently recording (vs paused).
  final bool isRecording;

  /// Whether currently paused.
  final bool isPaused;

  /// Callbacks.
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onCancel;
  final VoidCallback? onRename;

  /// Creates [RecordingControlsWidget].
  const RecordingControlsWidget({
    required this.hasActiveSession,
    required this.isRecording,
    required this.isPaused,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onCancel,
    this.onRename,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Controls',
      subtitle: 'Session lifecycle (no frame capture yet)',
      children: [
        if (!hasActiveSession)
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.fiber_manual_record),
            label: const Text('Start Recording'),
          )
        else ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (isRecording)
                FilledButton.tonalIcon(
                  onPressed: onPause,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
              if (isPaused)
                FilledButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                ),
              OutlinedButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel'),
              ),
              TextButton.icon(
                onPressed: onRename,
                icon: const Icon(Icons.drive_file_rename_outline),
                label: const Text('Rename'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Storage card for the dataset root folder.
class DatasetStorageCard extends StatelessWidget {
  /// Storage snapshot.
  final DatasetStorage storage;

  /// Optional refresh.
  final VoidCallback? onRefresh;

  /// Creates [DatasetStorageCard].
  const DatasetStorageCard({
    required this.storage,
    this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Storage',
      subtitle: 'Local dataset folder',
      trailing: onRefresh == null
          ? null
          : IconButton(
              tooltip: 'Refresh storage',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
      children: [
        _MetricRow(
          label: 'Dataset folder',
          value: storage.datasetFolder,
          isPath: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(
          label: 'Used by datasets',
          value: _formatBytes(storage.usedDiskSpace),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(
          label: 'Device free / total',
          value: storage.totalDiskSpace <= 0
              ? 'Not reported on this platform'
              : '${_formatBytes(storage.remainingDiskSpace)} / '
                  '${_formatBytes(storage.totalDiskSpace)}',
        ),
      ],
    );
  }
}

/// Aggregate statistics card.
class DatasetStatisticsCard extends StatelessWidget {
  /// Stats.
  final DatasetStatistics statistics;

  /// Creates [DatasetStatisticsCard].
  const DatasetStatisticsCard({required this.statistics, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Statistics',
      subtitle: 'Across all local sessions',
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _StatChip(
              label: 'Sessions',
              value: '${statistics.totalSessions}',
            ),
            _StatChip(
              label: 'Frames',
              value: '${statistics.totalFrames}',
            ),
            _StatChip(
              label: 'Flood events',
              value: '${statistics.totalFloodEvents}',
            ),
            _StatChip(
              label: 'Storage',
              value: _formatBytes(statistics.totalStorage),
            ),
          ],
        ),
      ],
    );
  }
}

/// Recent sessions list.
class DatasetRecentSessionsList extends StatelessWidget {
  /// Sessions.
  final List<DatasetSession> sessions;

  /// Rename requested.
  final ValueChanged<DatasetSession>? onRename;

  /// Delete requested.
  final ValueChanged<DatasetSession>? onDelete;

  /// Creates [DatasetRecentSessionsList].
  const DatasetRecentSessionsList({
    required this.sessions,
    this.onRename,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }
    return AppSectionCard(
      title: 'Recent sessions',
      subtitle: '${sessions.length} saved',
      children: [
        for (var i = 0; i < sessions.length; i++) ...[
          if (i > 0) const Divider(height: AppSpacing.lg),
          SessionCard(
            session: sessions[i],
            onRename: onRename == null ? null : () => onRename!(sessions[i]),
            onDelete: onDelete == null ? null : () => onDelete!(sessions[i]),
          ),
        ],
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPath;

  const _MetricRow({
    required this.label,
    required this.value,
    this.isPath = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: isPath ? 3 : 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:$m:$s';
  }
  return '$m:$s';
}
