import 'package:ai_road_safety_platform/core/constants/app_colors.dart';
import 'package:ai_road_safety_platform/core/constants/app_config.dart';
import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/constants/route_names.dart';
import 'package:ai_road_safety_platform/core/theme/theme_bloc.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// One research tool entry with its accent and destination route.
class _ToolItem {
  const _ToolItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String route;
}

const List<_ToolItem> _datasetTools = [
  _ToolItem(
    icon: Icons.folder_special_outlined,
    color: AppColors.brandPrimary,
    title: 'Dataset dashboard',
    subtitle: 'Browse sessions · storage · workspace',
    route: RouteNames.datasetCollection,
  ),
  _ToolItem(
    icon: Icons.analytics_outlined,
    color: AppColors.info,
    title: 'Research analytics',
    subtitle: 'Quality metrics · insights · charts',
    route: RouteNames.datasetCollectionAnalytics,
  ),
  _ToolItem(
    icon: Icons.ios_share_outlined,
    color: AppColors.brandSecondary,
    title: 'Dataset export',
    subtitle: 'JSON · CSV · ZIP · annotations',
    route: RouteNames.datasetCollectionExport,
  ),
  _ToolItem(
    icon: Icons.edit_note_outlined,
    color: AppColors.brandCaution,
    title: 'Annotation workspace',
    subtitle: 'Ground truth · tools · review · QC',
    route: RouteNames.datasetCollectionAnnotate,
  ),
  _ToolItem(
    icon: Icons.account_tree_outlined,
    color: AppColors.success,
    title: 'Pipeline engine',
    subtitle: 'Queues · stages · retries · workers',
    route: RouteNames.datasetCollectionPipeline,
  ),
  _ToolItem(
    icon: Icons.fact_check_outlined,
    color: AppColors.riskHigh,
    title: 'Dataset quality gate',
    subtitle: 'Training readiness · findings',
    route: RouteNames.datasetCollectionQuality,
  ),
];

const List<_ToolItem> _aiTools = [
  _ToolItem(
    icon: Icons.memory_outlined,
    color: AppColors.brandPrimary,
    title: 'Model management',
    subtitle: 'Versions · artifacts · metadata',
    route: RouteNames.datasetCollectionModels,
  ),
  _ToolItem(
    icon: Icons.science_outlined,
    color: AppColors.info,
    title: 'Experiment tracking',
    subtitle: 'Runs · params · metrics',
    route: RouteNames.datasetCollectionExperiments,
  ),
  _ToolItem(
    icon: Icons.speed_outlined,
    color: AppColors.brandSecondary,
    title: 'Model benchmark',
    subtitle: 'Offline scoring vs ground truth',
    route: RouteNames.datasetCollectionBenchmark,
  ),
  _ToolItem(
    icon: Icons.psychology_outlined,
    color: AppColors.brandCaution,
    title: 'Active learning',
    subtitle: 'Smart sample selection',
    route: RouteNames.datasetCollectionActiveLearning,
  ),
  _ToolItem(
    icon: Icons.rocket_launch_outlined,
    color: AppColors.riskHigh,
    title: 'Deployment manager',
    subtitle: 'Edge packages · rollback',
    route: RouteNames.datasetCollectionDeploy,
  ),
  _ToolItem(
    icon: Icons.merge_type,
    color: AppColors.success,
    title: 'Sensor fusion',
    subtitle: 'Camera + GPS + IMU streams',
    route: RouteNames.datasetCollectionSensorFusion,
  ),
];

/// App settings — theme + research tools + about.
class SettingsPage extends StatelessWidget {
  /// Creates [SettingsPage].
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AppPageContainer(
        child: ListView(
          children: [
            AppSectionCard(
              title: 'Appearance',
              subtitle: 'Theme preference is persisted locally.',
              children: [
                BlocSelector<ThemeBloc, ThemeState, ThemeMode>(
                  selector: (state) => state.themeMode,
                  builder: (context, themeMode) {
                    return SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {themeMode},
                      showSelectedIcon: false,
                      expandedInsets: EdgeInsets.zero,
                      onSelectionChanged: (selection) {
                        context
                            .read<ThemeBloc>()
                            .add(ThemeModeChanged(selection.first));
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSectionCard(
              title: 'Research workspace',
              subtitle: 'Dataset collection · annotation · export',
              children: [
                for (final tool in _datasetTools) _ToolTile(tool: tool),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSectionCard(
              title: 'AI lifecycle',
              subtitle: 'Models · experiments · deployment · fusion',
              children: [
                for (final tool in _aiTools) _ToolTile(tool: tool),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _AboutCard(),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool});

  final _ToolItem tool;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: () => context.push(tool.route),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tool.icon, color: tool.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      tool.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  static const List<String> _modules = [
    'Camera',
    'Flood AI',
    'GPS',
    'IMU',
    'Risk engine',
    'Driver HUD',
    'History',
    'Analytics',
    'Dataset platform',
    'AI lifecycle',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSectionCard(
      title: 'About',
      subtitle: AppConfig.appName,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                ),
              ),
              child: const Icon(
                Icons.add_road_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConfig.appShortName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Clean Architecture · flutter_bloc · GetIt',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final module in _modules)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  module,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
