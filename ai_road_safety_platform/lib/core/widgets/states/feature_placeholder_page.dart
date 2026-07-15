import 'package:ai_road_safety_platform/core/constants/app_constants.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:flutter/material.dart';

/// Generic Phase-1 placeholder screen for features not yet implemented.
///
/// Keeps navigation live while business modules land in later phases.
class FeaturePlaceholderPage extends StatelessWidget {
  /// App bar / hero title.
  final String title;

  /// Short feature description.
  final String description;

  /// Leading icon for empty state.
  final IconData icon;

  /// Creates a [FeaturePlaceholderPage].
  const FeaturePlaceholderPage({
    required this.title,
    required this.description,
    this.icon = Icons.construction_outlined,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppPageContainer(
        child: AppEmptyState(
          icon: icon,
          title: title,
          message: '$description\n\n${AppConstants.phasePlaceholderMessage}',
        ),
      ),
    );
  }
}

/// Compact in-page banner for stub modules inside richer shells.
class FeatureComingSoonCard extends StatelessWidget {
  /// Card title.
  final String title;

  /// Card body.
  final String message;

  /// Creates a [FeatureComingSoonCard].
  const FeatureComingSoonCard({
    required this.title,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
