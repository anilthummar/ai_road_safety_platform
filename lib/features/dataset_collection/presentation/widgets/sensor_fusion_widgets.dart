import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/sensor_fusion_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/sensor_fusion_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SensorFusionSummaryCard extends StatelessWidget {
  final SensorFusionSnapshot snapshot;

  const SensorFusionSummaryCard({required this.snapshot, super.key});

  @override
  Widget build(BuildContext context) {
    final session = snapshot.session;
    final latest = snapshot.latestSample;
    return AppSectionCard(
      title: 'Sensor fusion',
      subtitle: snapshot.isRunning
          ? 'Running · ${(session?.sampleCount ?? 0)} samples'
          : 'Idle · ${snapshot.recentSamples.length} buffered',
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _kv(context, 'Status', snapshot.isRunning ? 'Live' : 'Stopped'),
            _kv(
              context,
              'Avg Q',
              snapshot.recentSamples.isEmpty
                  ? '—'
                  : snapshot.averageQuality.toStringAsFixed(0),
            ),
            _kv(
              context,
              'Latest Q',
              latest == null
                  ? '—'
                  : latest.qualityScore.toStringAsFixed(0),
            ),
            _kv(
              context,
              'Sources',
              latest == null
                  ? '—'
                  : '${latest.sourcesPresent.length}',
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

class FusionChannelHealthCard extends StatelessWidget {
  final List<FusionChannelStatus> channels;

  const FusionChannelHealthCard({required this.channels, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Channels',
      subtitle: 'Camera · GPS · IMU · Sonar (later)',
      children: [
        for (final c in channels)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              switch (c.channel) {
                FusionSensorChannel.camera => Icons.videocam_outlined,
                FusionSensorChannel.gps => Icons.gps_fixed,
                FusionSensorChannel.imu => Icons.screen_rotation_alt,
                FusionSensorChannel.sonar => Icons.surround_sound_outlined,
              },
              color: switch (c.health) {
                FusionChannelHealth.live => Colors.green.shade700,
                FusionChannelHealth.stale => Colors.orange.shade800,
                FusionChannelHealth.missing => Colors.red.shade700,
                FusionChannelHealth.disabled => null,
              },
            ),
            title: Text(c.channel.label),
            subtitle: Text(
              '${c.health.label}'
              '${c.detail.isEmpty ? '' : ' · ${c.detail}'}'
              '${c.lastSampleAt == null ? '' : ' · ${c.ageMs} ms'}',
            ),
          ),
      ],
    );
  }
}

class FusedSampleListCard extends StatelessWidget {
  final List<FusedSample> samples;

  const FusedSampleListCard({required this.samples, super.key});

  @override
  Widget build(BuildContext context) {
    final sorted = samples.take(12).toList();
    return AppSectionCard(
      title: 'Recent fused samples',
      subtitle: 'Time-aligned GPS + IMU on camera / tick clocks',
      children: [
        if (sorted.isEmpty)
          const Text('No fused samples yet')
        else
          for (final s in sorted)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.merge_type,
                color: s.qualityScore >= 70 ? Colors.green.shade700 : null,
              ),
              title: Text(
                'Q=${s.qualityScore.toStringAsFixed(0)} · ${s.qualityBand.label}',
              ),
              subtitle: Text(
                [
                  if (s.gps != null)
                    'GPS ±${s.gps!.accuracyMeters.toStringAsFixed(1)}m '
                        '(${s.gps!.ageMs}ms)',
                  if (s.imu != null)
                    'IMU tilt ${s.imu!.tiltDegrees.toStringAsFixed(1)}° '
                        '(${s.imu!.ageMs}ms)',
                  if (s.camera != null) 'Cam #${s.camera!.sequence ?? '-'}',
                  'Sonar ${s.sonar.available ? 'on' : 'off'}',
                ].join(' · '),
              ),
            ),
      ],
    );
  }
}

class SensorFusionControls extends StatelessWidget {
  const SensorFusionControls({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Actions',
      subtitle: 'Start live fusion or inject a demo sample',
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context
                  .read<SensorFusionBloc>()
                  .add(const SensorFusionRefresh()),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            FilledButton.icon(
              onPressed: () => context
                  .read<SensorFusionBloc>()
                  .add(const SensorFusionStart()),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            ),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<SensorFusionBloc>()
                  .add(const SensorFusionStop()),
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<SensorFusionBloc>()
                  .add(const SensorFusionTick()),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Fuse tick'),
            ),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<SensorFusionBloc>()
                  .add(const SensorFusionCreateDemo()),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Demo sample'),
            ),
            TextButton(
              onPressed: () => context
                  .read<SensorFusionBloc>()
                  .add(const SensorFusionClear()),
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Aligns latest GPS + IMU onto camera frame times (or a 2 Hz tick). '
          'Sonar is a reserved channel for a future hardware module.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
