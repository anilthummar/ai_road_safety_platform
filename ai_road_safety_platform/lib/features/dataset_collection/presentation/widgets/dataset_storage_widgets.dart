import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_storage_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Storage dashboard section (developer — Phase 12.5).
class StorageDashboard extends StatelessWidget {
  /// Creates [StorageDashboard].
  const StorageDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatasetStorageBloc, DatasetStorageState>(
      buildWhen: (p, n) =>
          n is DatasetStorageInitial ||
          n is DatasetStorageLoading ||
          n is DatasetStorageCalculated ||
          n is DatasetStorageError ||
          n is DatasetStorageRecovered,
      builder: (context, state) {
        if (state is DatasetStorageLoading || state is DatasetStorageInitial) {
          return const AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: LinearProgressIndicator(),
            ),
          );
        }
        if (state is DatasetStorageError) {
          return AppCard(
            child: Text(state.failure.message),
          );
        }
        if (state is DatasetStorageCalculated) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StorageUsageCard(usage: state.usage),
              const SizedBox(height: AppSpacing.md),
              if (state.usage.isLowStorage)
                StorageWarningWidget(message: state.usage.warningMessage ?? ''),
              if (state.usage.isLowStorage)
                const SizedBox(height: AppSpacing.md),
              StorageProgressIndicator(usage: state.usage),
              const SizedBox(height: AppSpacing.md),
              FolderInformationWidget(folders: state.folders),
              const SizedBox(height: AppSpacing.md),
              RecentFilesWidget(files: state.recentFiles),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => context
                        .read<DatasetStorageBloc>()
                        .add(const DatasetStorageCalculateStorage()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<DatasetStorageBloc>()
                        .add(const DatasetStorageCleanupStorage()),
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Cleanup'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<DatasetStorageBloc>()
                        .add(const DatasetStorageRecoverSession()),
                    icon: const Icon(Icons.restore),
                    label: const Text('Recover'),
                  ),
                ],
              ),
            ],
          );
        }
        if (state is DatasetStorageRecovered) {
          return AppSectionCard(
            title: 'Recovery',
            subtitle: '${state.sessions.length} session(s) scanned',
            children: [
              for (final s in state.sessions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.sessionId),
                  subtitle: Text(
                    '${s.imageCount} images · ${s.metadataCount} meta'
                    '${s.isIncomplete ? ' · incomplete' : ''}',
                  ),
                ),
              TextButton(
                onPressed: () => context
                    .read<DatasetStorageBloc>()
                    .add(const DatasetStorageCalculateStorage()),
                child: const Text('Back to usage'),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Usage summary card.
class StorageUsageCard extends StatelessWidget {
  /// Usage.
  final StorageUsage usage;

  /// Creates [StorageUsageCard].
  const StorageUsageCard({required this.usage, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Dataset storage',
      subtitle: usage.datasetRoot,
      children: [
        Text(
          'Used: ${_formatBytes(usage.usedBytes)} / soft '
          '${_formatBytes(usage.softLimitBytes)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          usage.freeBytes > 0
              ? 'Device free: ${_formatBytes(usage.freeBytes)}'
              : 'Device free/total not reported on this platform',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Soft-limit progress bar.
class StorageProgressIndicator extends StatelessWidget {
  /// Usage.
  final StorageUsage usage;

  /// Creates [StorageProgressIndicator].
  const StorageProgressIndicator({required this.usage, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soft budget ${(usage.softFillRatio * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: usage.softFillRatio,
          color: usage.isLowStorage
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      ],
    );
  }
}

/// Folder tree summary.
class FolderInformationWidget extends StatelessWidget {
  /// Folders.
  final List<FolderInfo> folders;

  /// Creates [FolderInformationWidget].
  const FolderInformationWidget({required this.folders, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Folders',
      subtitle: 'Dataset hierarchy',
      children: [
        for (final f in folders) ...[
          Text(
            '${f.label}: ${_formatBytes(f.sizeBytes)} · ${f.fileCount} files',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            f.path,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Recent files list.
class RecentFilesWidget extends StatelessWidget {
  /// Files.
  final List<RecentStorageFile> files;

  /// Creates [RecentFilesWidget].
  const RecentFilesWidget({required this.files, super.key});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return AppCard(
        child: Text(
          'No files saved yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return AppSectionCard(
      title: 'Recent files',
      subtitle: '${files.length} newest',
      children: [
        for (final f in files.take(8))
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_formatBytes(f.sizeBytes)),
          ),
      ],
    );
  }
}

/// Low storage banner.
class StorageWarningWidget extends StatelessWidget {
  /// Warning message.
  final String message;

  /// Creates [StorageWarningWidget].
  const StorageWarningWidget({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}
