import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:ai_road_safety_platform/features/imu/presentation/bloc/imu_bloc.dart';
import 'package:ai_road_safety_platform/features/imu/presentation/widgets/imu_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Live IMU console: accel / gyro / mag, tilt, vibration, calibration.
class ImuPage extends StatelessWidget {
  /// Creates [ImuPage].
  const ImuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ImuBloc>()..add(const ImuStarted()),
      child: const _ImuView(),
    );
  }
}

class _ImuView extends StatelessWidget {
  const _ImuView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMU sensors'),
        actions: [
          BlocBuilder<ImuBloc, ImuState>(
            builder: (context, state) {
              final streaming =
                  state is ImuActive && state.session.isStreaming;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Center(child: ImuStatusChip(isStreaming: streaming)),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ImuBloc, ImuState>(
        builder: (context, state) {
          return switch (state) {
            ImuInitial() => const AppLoadingIndicator.page(
                message: 'Preparing IMU…',
              ),
            ImuLoading(:final message) => AppLoadingIndicator.page(
                message: message,
              ),
            ImuError(:final failure) => AppErrorView.fromFailure(
                failure,
                onRetry: () =>
                    context.read<ImuBloc>().add(const ImuStarted()),
              ),
            ImuActive(:final session, :final sample) => AppPageContainer(
                child: _ImuActiveBody(
                  session: session,
                  sample: sample,
                ),
              ),
          };
        },
      ),
    );
  }
}

class _ImuActiveBody extends StatelessWidget {
  const _ImuActiveBody({
    required this.session,
    required this.sample,
  });

  final ImuSession session;
  final ImuSample? sample;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ImuBloc>();
    final streaming = session.isStreaming;
    final calibrating = session.isCalibrating;

    return ListView(
      children: [
        ImuCalibrationBanner(
          calibration: session.calibration,
          isCalibrating: calibrating,
          progress: session.calibrationProgress,
        ),
        const SizedBox(height: AppSpacing.md),
        AppPrimaryButton(
          label: streaming ? 'Stop sensors' : 'Start sensors',
          icon:
              streaming ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
          onPressed: calibrating
              ? null
              : () => bloc.add(
                    streaming
                        ? const ImuStreamingStopped()
                        : const ImuStreamingStarted(),
                  ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: calibrating ? 'Calibrating…' : 'Calibrate (hold still)',
          icon: Icons.tune,
          onPressed: (!streaming || calibrating)
              ? null
              : () => bloc.add(const ImuCalibrationRequested()),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (sample == null)
          const AppEmptyState(
            icon: Icons.sensors_outlined,
            title: 'Waiting for samples',
            message: 'Sensor streams are starting…',
          )
        else ...[
          ImuVibrationCard(vibration: sample!.vibration),
          const SizedBox(height: AppSpacing.md),
          ImuOrientationCard(
            orientation: sample!.orientation,
            tiltDegrees: sample!.tiltDegrees,
          ),
          const SizedBox(height: AppSpacing.md),
          ImuAxisCard(
            title: 'Accelerometer',
            vector: sample!.accelerometer,
            unit: 'm/s²',
            icon: Icons.speed,
          ),
          const SizedBox(height: AppSpacing.md),
          ImuAxisCard(
            title: 'Gyroscope',
            vector: sample!.gyroscope,
            unit: 'rad/s',
            icon: Icons.rotate_90_degrees_ccw,
          ),
          const SizedBox(height: AppSpacing.md),
          ImuAxisCard(
            title: 'Magnetometer',
            vector: sample!.magnetometer,
            unit: 'µT',
            icon: Icons.explore,
          ),
        ],
      ],
    );
  }
}
