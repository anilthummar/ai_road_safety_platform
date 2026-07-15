import 'package:ai_road_safety_platform/core/constants/app_dimensions.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/buttons/app_primary_button.dart';
import 'package:flutter/material.dart';

/// Reusable empty-collection placeholder.
class AppEmptyState extends StatelessWidget {
  /// Headline.
  final String title;

  /// Supporting copy.
  final String message;

  /// Decorative icon.
  final IconData icon;

  /// Optional CTA label.
  final String? actionLabel;

  /// Optional CTA callback.
  final VoidCallback? onAction;

  /// Creates an [AppEmptyState].
  const AppEmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

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
                icon,
                size: AppDimensions.iconSizeLarge,
                color: scheme.onSurfaceVariant,
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
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  isExpanded: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
