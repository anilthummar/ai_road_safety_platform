import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/widgets/buttons/app_primary_button.dart';
import 'package:ai_road_safety_platform/core/widgets/buttons/app_secondary_button.dart';
import 'package:flutter/material.dart';

/// Reusable error surface for Bloc error states and fatal page failures.
class AppErrorView extends StatelessWidget {
  /// Headline shown to the user.
  final String title;

  /// Detailed message (often [Failure.message]).
  final String message;

  /// Retry callback.
  final VoidCallback? onRetry;

  /// Secondary dismiss / back callback.
  final VoidCallback? onSecondary;

  /// Label for secondary action.
  final String secondaryLabel;

  /// Creates an [AppErrorView].
  const AppErrorView({
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.onSecondary,
    this.secondaryLabel = 'Go back',
    super.key,
  });

  /// Builds from a domain [Failure].
  factory AppErrorView.fromFailure(
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onSecondary,
    Key? key,
  }) {
    return AppErrorView(
      key: key,
      title: _titleFor(failure),
      message: failure.message,
      onRetry: onRetry,
      onSecondary: onSecondary,
    );
  }

  static String _titleFor(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'You are offline',
      ServerFailure() => 'Server error',
      PermissionFailure() => 'Permission required',
      CameraFailure() => 'Camera unavailable',
      InferenceFailure() => 'AI inference error',
      GpsFailure() => 'GPS unavailable',
      ImuFailure() => 'IMU unavailable',
      RiskFailure() => 'Risk analysis error',
      CacheFailure() => 'Storage error',
      ValidationFailure() => 'Invalid input',
      _ => 'Something went wrong',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppDimensions.maxFormWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: AppDimensions.iconSizeLarge,
                color: scheme.error,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (onRetry != null || onSecondary != null) ...[
                const SizedBox(height: AppSpacing.xl),
                if (onRetry != null)
                  AppPrimaryButton(
                    label: 'Try again',
                    onPressed: onRetry,
                    icon: Icons.refresh_rounded,
                  ),
                if (onRetry != null && onSecondary != null)
                  const SizedBox(height: AppSpacing.sm),
                if (onSecondary != null)
                  AppSecondaryButton(
                    label: secondaryLabel,
                    onPressed: onSecondary,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
