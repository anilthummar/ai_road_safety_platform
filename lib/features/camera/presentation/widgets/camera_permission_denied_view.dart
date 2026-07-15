import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/camera/presentation/bloc/camera_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Permission-denied surface with retry / open-settings actions.
class CameraPermissionDeniedView extends StatelessWidget {
  /// Whether the user must grant access from system settings.
  final bool isPermanentlyDenied;

  /// Message shown under the title.
  final String message;

  /// Creates [CameraPermissionDeniedView].
  const CameraPermissionDeniedView({
    required this.isPermanentlyDenied,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.no_photography_outlined,
      title: 'Camera permission required',
      message: message,
      actionLabel: isPermanentlyDenied ? 'Open settings' : 'Grant permission',
      onAction: () {
        final bloc = context.read<CameraBloc>();
        if (isPermanentlyDenied) {
          bloc.add(const CameraOpenSettingsRequested());
        } else {
          bloc.add(const CameraPermissionRequested());
        }
      },
    );
  }
}
