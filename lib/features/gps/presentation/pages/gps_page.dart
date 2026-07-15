import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/gps/presentation/bloc/gps_bloc.dart';
import 'package:ai_road_safety_platform/features/gps/presentation/widgets/gps_location_card.dart';
import 'package:ai_road_safety_platform/features/gps/presentation/widgets/gps_metric_tile.dart';
import 'package:ai_road_safety_platform/features/gps/presentation/widgets/gps_permission_denied_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// GPS feature screen — permissions, current fix, continuous tracking metrics.
class GpsPage extends StatelessWidget {
  /// Creates [GpsPage].
  const GpsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GpsBloc>()..add(const GpsStarted()),
      child: const _GpsView(),
    );
  }
}

class _GpsView extends StatelessWidget {
  const _GpsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS'),
        actions: [
          BlocBuilder<GpsBloc, GpsState>(
            builder: (context, state) {
              final streaming =
                  state is GpsActive && state.session.isStreaming;
              return IconButton(
                tooltip: streaming ? 'Stop tracking' : 'Start tracking',
                icon: Icon(
                  streaming ? Icons.pause_circle_outline : Icons.play_circle_outline,
                ),
                onPressed: () {
                  final bloc = context.read<GpsBloc>();
                  if (streaming) {
                    bloc.add(const GpsTrackingStopped());
                  } else {
                    bloc.add(const GpsTrackingStarted());
                  }
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh location',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GpsBloc>().add(const GpsCurrentLocationRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<GpsBloc, GpsState>(
        builder: (context, state) {
          return switch (state) {
            GpsInitial() => const AppLoadingIndicator.page(
                message: 'Starting GPS…',
              ),
            GpsLoading(:final message) => AppLoadingIndicator.page(
                message: message,
              ),
            GpsPermissionDenied(
              :final isPermanentlyDenied,
              :final message,
            ) =>
              GpsPermissionDeniedView(
                isPermanentlyDenied: isPermanentlyDenied,
                message: message,
              ),
            GpsServiceDisabled(:final message) => AppEmptyState(
                icon: Icons.location_disabled_outlined,
                title: 'Location services off',
                message: message,
                actionLabel: 'Enable GPS',
                onAction: () => context.read<GpsBloc>().add(
                      const GpsOpenSettingsRequested(locationServices: true),
                    ),
              ),
            GpsError(:final failure) => AppErrorView.fromFailure(
                failure,
                onRetry: () =>
                    context.read<GpsBloc>().add(const GpsStarted()),
              ),
            GpsActive(:final session) => AppPageContainer(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<GpsBloc>()
                        .add(const GpsCurrentLocationRequested());
                    await Future<void>.delayed(
                      const Duration(milliseconds: 400),
                    );
                  },
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          GpsStatusChip(
                            isStreaming: session.isStreaming,
                            isServiceEnabled: session.isServiceEnabled,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${session.fixCount} fixes',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (session.latestFix == null)
                        const AppEmptyState(
                          icon: Icons.satellite_alt_outlined,
                          title: 'Waiting for GPS fix',
                          message:
                              'Move outdoors or wait for the receiver to lock.',
                        )
                      else ...[
                        GpsLocationCard(fix: session.latestFix!),
                        const SizedBox(height: AppSpacing.lg),
                        GpsMetricsGrid(fix: session.latestFix!),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      AppPrimaryButton(
                        label: session.isStreaming
                            ? 'Stop continuous updates'
                            : 'Start continuous updates',
                        icon: session.isStreaming
                            ? Icons.stop_circle_outlined
                            : Icons.play_arrow_rounded,
                        onPressed: () {
                          final bloc = context.read<GpsBloc>();
                          if (session.isStreaming) {
                            bloc.add(const GpsTrackingStopped());
                          } else {
                            bloc.add(const GpsTrackingStarted());
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppSecondaryButton(
                        label: 'Get current location',
                        icon: Icons.my_location,
                        onPressed: () {
                          context
                              .read<GpsBloc>()
                              .add(const GpsCurrentLocationRequested());
                        },
                      ),
                    ],
                  ),
                ),
              ),
          };
        },
      ),
    );
  }
}
