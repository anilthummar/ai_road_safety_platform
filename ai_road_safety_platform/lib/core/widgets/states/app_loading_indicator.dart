import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:flutter/material.dart';

/// Centered loading indicator with optional message.
class AppLoadingIndicator extends StatelessWidget {
  /// Optional status text under the spinner.
  final String? message;

  /// Spinner size.
  final double size;

  /// Creates an [AppLoadingIndicator].
  const AppLoadingIndicator({
    this.message,
    this.size = 36,
    super.key,
  });

  /// Full-screen centered loader.
  const AppLoadingIndicator.page({
    this.message,
    super.key,
  }) : size = 40;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
