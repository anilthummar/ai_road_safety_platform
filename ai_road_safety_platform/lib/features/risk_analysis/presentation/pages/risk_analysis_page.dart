import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/presentation/bloc/risk_analysis_bloc.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/presentation/widgets/risk_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Risk analysis console — rule engine over flood / GPS / IMU inputs.
class RiskAnalysisPage extends StatelessWidget {
  /// Creates [RiskAnalysisPage].
  const RiskAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RiskAnalysisBloc>()..add(const RiskAnalysisStarted()),
      child: const _RiskAnalysisView(),
    );
  }
}

class _RiskAnalysisView extends StatelessWidget {
  const _RiskAnalysisView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk analysis'),
        actions: [
          BlocBuilder<RiskAnalysisBloc, RiskAnalysisState>(
            builder: (context, state) {
              final monitoring = state is RiskAnalysisActive &&
                  state.session.isMonitoring;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Center(
                  child: RiskMonitoringChip(isMonitoring: monitoring),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<RiskAnalysisBloc, RiskAnalysisState>(
        builder: (context, state) {
          return switch (state) {
            RiskAnalysisInitial() => const AppLoadingIndicator.page(
                message: 'Preparing risk engine…',
              ),
            RiskAnalysisLoading(:final message) => AppLoadingIndicator.page(
                message: message,
              ),
            RiskAnalysisError(:final failure) => AppErrorView.fromFailure(
                failure,
                onRetry: () => context
                    .read<RiskAnalysisBloc>()
                    .add(const RiskAnalysisStarted()),
              ),
            RiskAnalysisActive(:final session, :final assessment) =>
              AppPageContainer(
                child: _RiskActiveBody(
                  session: session,
                  assessment: assessment,
                ),
              ),
          };
        },
      ),
    );
  }
}

class _RiskActiveBody extends StatelessWidget {
  const _RiskActiveBody({
    required this.session,
    required this.assessment,
  });

  final RiskSession session;
  final RiskAssessment? assessment;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RiskAnalysisBloc>();
    final monitoring = session.isMonitoring;

    return ListView(
      children: [
        AppPrimaryButton(
          label: monitoring ? 'Stop live fusion' : 'Start live fusion',
          icon: monitoring
              ? Icons.stop_circle_outlined
              : Icons.play_arrow_rounded,
          onPressed: () => bloc.add(
                monitoring
                    ? const RiskMonitoringStopped()
                    : const RiskMonitoringStarted(),
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Live fusion reads flood %, GPS speed/accuracy, and IMU tilt/vibration. '
          'Or run a scenario below to exercise the rule engine.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Scenarios', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ActionChip(
              label: const Text('Clear / Low'),
              onPressed: () => bloc.add(
                    RiskEvaluateRequested(_scenarioLow()),
                  ),
            ),
            ActionChip(
              label: const Text('Flood caution'),
              onPressed: () => bloc.add(
                    RiskEvaluateRequested(_scenarioMedium()),
                  ),
            ),
            ActionChip(
              label: const Text('Rough + speed'),
              onPressed: () => bloc.add(
                    RiskEvaluateRequested(_scenarioHigh()),
                  ),
            ),
            ActionChip(
              label: const Text('Flood at speed'),
              onPressed: () => bloc.add(
                    RiskEvaluateRequested(_scenarioExtreme()),
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (assessment == null)
          const AppEmptyState(
            icon: Icons.shield_outlined,
            title: 'No assessment yet',
            message:
                'Start live fusion or pick a scenario to run the rule engine.',
          )
        else ...[
          RiskLevelBadge(
            level: assessment!.level,
            score: assessment!.score,
          ),
          const SizedBox(height: AppSpacing.md),
          RiskInputsSummaryCard(inputs: assessment!.inputs),
          const SizedBox(height: AppSpacing.md),
          RiskRecommendationsCard(
            recommendations: assessment!.recommendations,
          ),
          const SizedBox(height: AppSpacing.md),
          RiskFactorsList(factors: assessment!.triggeredRules),
        ],
      ],
    );
  }

  RiskInputSnapshot _scenarioLow() {
    return RiskInputSnapshot(
      floodCoveragePercent: 1,
      speedKmh: 30,
      gpsAccuracyMeters: 5,
      latitude: 25.2,
      longitude: 55.27,
      tiltDegrees: 3,
      vibrationIntensity: VibrationIntensity.calm,
      vibrationRms: 0.1,
      hasGpsFix: true,
      hasImuSample: true,
      hasFloodSample: true,
      timestamp: DateTime.now(),
    );
  }

  RiskInputSnapshot _scenarioMedium() {
    return RiskInputSnapshot(
      floodCoveragePercent: 10,
      speedKmh: 45,
      gpsAccuracyMeters: 12,
      latitude: 25.2,
      longitude: 55.27,
      tiltDegrees: 8,
      vibrationIntensity: VibrationIntensity.moderate,
      vibrationRms: 0.5,
      hasGpsFix: true,
      hasImuSample: true,
      hasFloodSample: true,
      timestamp: DateTime.now(),
    );
  }

  RiskInputSnapshot _scenarioHigh() {
    return RiskInputSnapshot(
      floodCoveragePercent: 6,
      speedKmh: 70,
      gpsAccuracyMeters: 30,
      latitude: 25.2,
      longitude: 55.27,
      tiltDegrees: 18,
      vibrationIntensity: VibrationIntensity.rough,
      vibrationRms: 1.2,
      hasGpsFix: true,
      hasImuSample: true,
      hasFloodSample: true,
      timestamp: DateTime.now(),
    );
  }

  RiskInputSnapshot _scenarioExtreme() {
    return RiskInputSnapshot(
      floodCoveragePercent: 22,
      speedKmh: 50,
      gpsAccuracyMeters: 8,
      latitude: 25.2,
      longitude: 55.27,
      tiltDegrees: 10,
      vibrationIntensity: VibrationIntensity.moderate,
      vibrationRms: 0.6,
      hasGpsFix: true,
      hasImuSample: true,
      hasFloodSample: true,
      timestamp: DateTime.now(),
    );
  }
}
