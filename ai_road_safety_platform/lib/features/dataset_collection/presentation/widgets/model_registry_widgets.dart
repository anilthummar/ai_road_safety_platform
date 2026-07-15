import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/model_registry_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModelRegistrySummaryCard extends StatelessWidget {
  final ModelRegistrySnapshot snapshot;

  const ModelRegistrySummaryCard({required this.snapshot, super.key});

  @override
  Widget build(BuildContext context) {
    final mb = snapshot.totalBytes / (1024 * 1024);
    return AppSectionCard(
      title: 'Model registry',
      subtitle: '${snapshot.models.length} versions · ${snapshot.activeCount} active',
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _kv(context, 'Bundled', '${snapshot.bundledCount}'),
            _kv(context, 'Active', '${snapshot.activeCount}'),
            _kv(
              context,
              'Artifacts',
              mb > 0.01 ? '${mb.toStringAsFixed(2)} MB' : '—',
            ),
            _kv(
              context,
              'Detection',
              snapshot.active.detectionModelId ?? '—',
            ),
            _kv(
              context,
              'Segmentation',
              snapshot.active.segmentationModelId ?? '—',
            ),
          ],
        ),
      ],
    );
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

class ModelListCard extends StatelessWidget {
  final List<RegisteredModel> models;
  final ActiveModelPointers active;

  const ModelListCard({
    required this.models,
    required this.active,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...models]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return AppSectionCard(
      title: 'Versions',
      subtitle: 'Activate one per task family',
      children: [
        if (sorted.isEmpty)
          const Text('No models registered')
        else
          for (final m in sorted)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                m.status == ModelStatus.active
                    ? Icons.check_circle
                    : Icons.memory_outlined,
                color: m.status == ModelStatus.active
                    ? Colors.green.shade700
                    : null,
              ),
              title: Text(m.displayName),
              subtitle: Text(
                '${m.taskType.label} · ${m.status.label} · '
                '${m.framework} · ${m.artifacts.length} artifact(s)'
                '${m.isBundled ? ' · bundled' : ''}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  final bloc = context.read<ModelRegistryBloc>();
                  switch (v) {
                    case 'activate':
                      bloc.add(ModelRegistryActivate(m.id));
                    case 'archive':
                      bloc.add(ModelRegistryArchive(m.id));
                    case 'delete':
                      bloc.add(ModelRegistryDelete(m.id));
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'activate',
                    child: Text('Activate'),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Archive'),
                  ),
                  if (!m.isBundled)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class ModelDetailCard extends StatelessWidget {
  final RegisteredModel model;

  const ModelDetailCard({required this.model, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: model.displayName,
      subtitle: model.taskType.label,
      children: [
        Text(model.description.isEmpty ? 'No description' : model.description),
        const SizedBox(height: AppSpacing.sm),
        Text('Input: ${model.inputSpec.isEmpty ? '—' : model.inputSpec}'),
        Text('Output: ${model.outputSpec.isEmpty ? '—' : model.outputSpec}'),
        if (model.labelsAssetPath != null)
          Text('Labels asset: ${model.labelsAssetPath}'),
        if (model.labels.isNotEmpty)
          Text('Labels: ${model.labels.take(8).join(', ')}'),
        const SizedBox(height: AppSpacing.sm),
        Text('Artifacts', style: Theme.of(context).textTheme.titleSmall),
        for (final a in model.artifacts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(a.fileName),
            subtitle: Text(
              '${a.source.label} · ${a.byteSize} bytes'
              '${a.assetPath != null ? ' · ${a.assetPath}' : ''}'
              '${a.absolutePath != null ? ' · ${a.absolutePath}' : ''}',
            ),
          ),
        if (model.tags.isNotEmpty)
          Text('Tags: ${model.tags.entries.map((e) => '${e.key}=${e.value}').join(', ')}'),
        if (model.notes != null) Text('Notes: ${model.notes}'),
      ],
    );
  }
}

class ModelRegistryControls extends StatelessWidget {
  const ModelRegistryControls({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Actions',
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: () => context
                  .read<ModelRegistryBloc>()
                  .add(const ModelRegistryRefresh()),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => context
                  .read<ModelRegistryBloc>()
                  .add(const ModelRegistrySeedBundled()),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Seed bundled'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.read<ModelRegistryBloc>().add(
                    const ModelRegistryRegisterDemo(),
                  ),
              icon: const Icon(Icons.add),
              label: const Text('Register draft'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Import of external .tflite files is available via repository API; '
          'runtime still defaults to bundled assets until Phase 13.6 deployment.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
