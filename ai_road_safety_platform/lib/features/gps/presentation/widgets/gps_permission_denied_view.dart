import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/gps/presentation/bloc/gps_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Permission-denied surface for GPS.
class GpsPermissionDeniedView extends StatelessWidget {
  /// Whether the user must open system settings.
  final bool isPermanentlyDenied;

  /// Message under the title.
  final String message;

  /// Creates [GpsPermissionDeniedView].
  const GpsPermissionDeniedView({
    required this.isPermanentlyDenied,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.location_off_outlined,
      title: 'Location permission required',
      message: message,
      actionLabel: isPermanentlyDenied ? 'Open settings' : 'Grant permission',
      onAction: () {
        final bloc = context.read<GpsBloc>();
        if (isPermanentlyDenied) {
          bloc.add(const GpsOpenSettingsRequested());
        } else {
          bloc.add(const GpsPermissionRequested());
        }
      },
    );
  }
}
