import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/metadata_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Compact metadata summary for developers (Phase 12.4).
class MetadataCard extends StatelessWidget {
  /// Creates [MetadataCard].
  const MetadataCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetadataBloc, MetadataState>(
      builder: (context, state) {
        final metadata = switch (state) {
          MetadataGenerated(:final metadata) => metadata,
          MetadataGenerating(:final latest) => latest,
          _ => null,
        };
        return AppSectionCard(
          title: 'Frame metadata',
          subtitle: 'Synchronized in memory — not saved to disk',
          trailing: TextButton(
            onPressed: () => context
                .read<MetadataBloc>()
                .add(const MetadataClearRequested()),
            child: const Text('Clear'),
          ),
          children: [
            if (state is MetadataGenerating)
              const LinearProgressIndicator()
            else if (metadata == null)
              Text(
                'Waiting for the next captured frame…',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              FrameMetadataPreview(metadata: metadata),
          ],
        );
      },
    );
  }
}

/// GPS / IMU / AI / risk liveness.
class SensorStatusCard extends StatelessWidget {
  /// Creates [SensorStatusCard].
  const SensorStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetadataBloc, MetadataState>(
      builder: (context, state) {
        final sensors = switch (state) {
          MetadataInitial(:final sensors) => sensors,
          MetadataGenerating(:final sensors) => sensors,
          MetadataGenerated(:final sensors) => sensors,
          MetadataError(:final sensors) => sensors,
        };
        return AppSectionCard(
          title: 'Sensor status',
          subtitle: 'Caches used at capture time',
          trailing: IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<MetadataBloc>()
                .add(const MetadataRefreshSensorStatus()),
            icon: const Icon(Icons.refresh),
          ),
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatusChip(label: 'GPS', live: sensors.gpsLive),
                _StatusChip(label: 'IMU', live: sensors.imuLive),
                _StatusChip(label: 'AI', live: sensors.aiLive),
                _StatusChip(label: 'Risk', live: sensors.riskLive),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Scrollable live metadata viewer.
class LiveMetadataViewer extends StatelessWidget {
  /// Creates [LiveMetadataViewer].
  const LiveMetadataViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetadataBloc, MetadataState>(
      builder: (context, state) {
        if (state is! MetadataGenerated) {
          return AppCard(
            child: Text(
              'No synchronized metadata yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        final m = state.metadata;
        return AppSectionCard(
          title: 'Live metadata viewer',
          subtitle: 'Frame #${m.session.frameNumber}',
          children: [
            _kv(context, 'Session', m.session.sessionId),
            _kv(context, 'Frame id', m.session.frameId),
            _kv(context, 'Capture', m.session.captureType.name),
            _kv(context, 'Reason', m.session.captureReason),
            _kv(
              context,
              'GPS',
              m.location.isAvailable
                  ? '${m.location.latitude.toStringAsFixed(5)}, '
                      '${m.location.longitude.toStringAsFixed(5)} '
                      '@ ${m.location.speed.toStringAsFixed(1)} m/s'
                  : 'missing',
            ),
            _kv(
              context,
              'IMU',
              m.motion.isAvailable
                  ? 'acc(${m.motion.accelerometerX.toStringAsFixed(2)}, '
                      '${m.motion.accelerometerY.toStringAsFixed(2)}, '
                      '${m.motion.accelerometerZ.toStringAsFixed(2)})'
                  : 'missing',
            ),
            _kv(
              context,
              'AI',
              m.inference.isAvailable
                  ? '${m.inference.prediction} '
                      'conf=${m.inference.confidence.toStringAsFixed(2)} '
                      'water=${m.inference.waterCoverage.toStringAsFixed(1)}% '
                      'risk=${m.inference.riskLevel}'
                  : 'missing',
            ),
            _kv(
              context,
              'Device',
              '${m.device.deviceModel} · bat=${m.device.batteryLevel} · '
              'v${m.device.appVersion}',
            ),
            if (m.validation.warnings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Warnings: ${m.validation.warnings.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(k, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: Text(
              v,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nested preview used inside [MetadataCard].
class FrameMetadataPreview extends StatelessWidget {
  /// Metadata.
  final FrameMetadata metadata;

  /// Creates [FrameMetadataPreview].
  const FrameMetadataPreview({required this.metadata, super.key});

  @override
  Widget build(BuildContext context) {
    final s = metadata.session;
    final i = metadata.inference;
    final l = metadata.location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frame #${s.frameNumber} · ${s.captureType.name}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'GPS: ${l.isAvailable ? '${l.latitude.toStringAsFixed(4)}, ${l.longitude.toStringAsFixed(4)}' : '—'}'
          ' · AI: ${i.isAvailable ? '${i.prediction} (${(i.confidence * 100).toStringAsFixed(0)}%)' : '—'}'
          ' · risk ${i.riskLevel}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool live;

  const _StatusChip({required this.label, required this.live});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = live ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = live ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
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
        '$label · ${live ? 'live' : 'cold'}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
