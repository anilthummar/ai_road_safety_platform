import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_deployment_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_deployment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeploymentSummaryCard extends StatelessWidget {
  final DeploymentSnapshot snapshot;

  const DeploymentSummaryCard({required this.snapshot, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Edge deployments',
      subtitle:
          '${snapshot.totalCount} packages · ${snapshot.activeCount} active',
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _kv(context, 'Staged', '${snapshot.stagedCount}'),
            _kv(context, 'Active', '${snapshot.activeCount}'),
            _kv(
              context,
              'Detection',
              _short(snapshot.active.detectionDeploymentId),
            ),
            _kv(
              context,
              'Segmentation',
              _short(snapshot.active.segmentationDeploymentId),
            ),
          ],
        ),
      ],
    );
  }

  String _short(String? id) {
    if (id == null || id.isEmpty) return '—';
    return id.length <= 8 ? id : id.substring(0, 8);
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: Theme.of(context).textTheme.labelSmall),
        Text(v, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class DeploymentPackageListCard extends StatelessWidget {
  final List<DeploymentPackage> packages;
  final ActiveDeploymentPointers active;

  const DeploymentPackageListCard({
    required this.packages,
    required this.active,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...packages]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return AppSectionCard(
      title: 'Packages',
      subtitle: 'Stage · activate · rollback',
      children: [
        if (sorted.isEmpty)
          const Text('No deployment packages yet')
        else
          for (final p in sorted)
            _PackageTile(
              package: p,
              isPointerActive: active.idForTask(p.taskType) == p.id,
            ),
      ],
    );
  }
}

class _PackageTile extends StatelessWidget {
  final DeploymentPackage package;
  final bool isPointerActive;

  const _PackageTile({
    required this.package,
    required this.isPointerActive,
  });

  @override
  Widget build(BuildContext context) {
    final art = package.primaryModelArtifact;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        package.status == DeploymentStatus.active
            ? Icons.rocket_launch_outlined
            : Icons.inventory_2_outlined,
        color: package.status == DeploymentStatus.active
            ? Colors.green.shade700
            : null,
      ),
      title: Text(package.displayName),
      subtitle: Text(
        '${package.taskType.label} · ${package.status.label}'
        '${isPointerActive ? ' · pointer' : ''}\n'
        '${package.modelId} · ${art?.fileName ?? 'no artifact'}'
        '${package.previousDeploymentId == null ? '' : ' · can rollback'}',
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          final bloc = context.read<ModelDeploymentBloc>();
          switch (v) {
            case 'activate':
              bloc.add(ModelDeploymentActivate(package.id));
            case 'rollback':
              bloc.add(ModelDeploymentRollback(package.id));
            case 'delete':
              bloc.add(ModelDeploymentDelete(package.id));
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'activate', child: Text('Activate')),
          if (package.previousDeploymentId != null)
            const PopupMenuItem(value: 'rollback', child: Text('Rollback')),
          if (package.status != DeploymentStatus.active)
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

class DeploymentControls extends StatelessWidget {
  const DeploymentControls({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Actions',
      subtitle: 'Package registry models for edge rollout',
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context
                  .read<ModelDeploymentBloc>()
                  .add(const ModelDeploymentRefresh()),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            FilledButton.icon(
              onPressed: () => context
                  .read<ModelDeploymentBloc>()
                  .add(const ModelDeploymentStageActiveDetection()),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Stage YOLOv8n'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.read<ModelDeploymentBloc>().add(
                    const ModelDeploymentStage('bundled-flood-seg'),
                  ),
              icon: const Icon(Icons.water_drop_outlined),
              label: const Text('Stage flood seg'),
            ),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<ModelDeploymentBloc>()
                  .add(const ModelDeploymentCreateDemo()),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Demo deploy'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Packages copy on-disk artifacts when available; bundled models '
          'record asset paths. TFLite loaders still default to assets until '
          'wired to DeployedModelResolution.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
