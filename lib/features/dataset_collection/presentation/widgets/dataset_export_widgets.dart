import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Format chips selector.
class ExportFormatSelector extends StatelessWidget {
  final ExportFormat selected;
  final ValueChanged<ExportFormat> onSelected;

  /// Creates [ExportFormatSelector].
  const ExportFormatSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Export format',
      subtitle: 'Pluggable strategies · placeholders for annotation formats',
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final f in ExportFormat.values)
              ChoiceChip(
                label: Text(f.label),
                selected: selected == f,
                onSelected: (_) => onSelected(f),
              ),
          ],
        ),
      ],
    );
  }
}

/// Summary of pending export options.
class ExportSummaryCard extends StatelessWidget {
  final ExportSettings settings;
  final int availableSessions;

  /// Creates [ExportSummaryCard].
  const ExportSummaryCard({
    required this.settings,
    required this.availableSessions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final selected = settings.sessionIds.isEmpty
        ? 'All ($availableSessions)'
        : '${settings.sessionIds.length} selected';
    return AppSectionCard(
      title: 'Export summary',
      subtitle: settings.datasetName,
      children: [
        _row(context, 'Format', settings.format.label),
        _row(context, 'Sessions', selected),
        _row(context, 'Images', settings.includeImages ? 'Yes' : 'No'),
        _row(context, 'Metadata', settings.includeMetadata ? 'Yes' : 'No'),
        _row(context, 'Statistics', settings.includeStatistics ? 'Yes' : 'No'),
        _row(context, 'Manifest', settings.generateManifest ? 'Yes' : 'No'),
        _row(context, 'README', settings.generateReadme ? 'Yes' : 'No'),
        _row(context, 'ZIP', settings.compressOutput ||
                settings.format == ExportFormat.zip
            ? 'Yes'
            : 'No'),
      ],
    );
  }
}

/// Progress panel with logs.
class ExportProgressCard extends StatelessWidget {
  final ExportProgress progress;

  /// Creates [ExportProgressCard].
  const ExportProgressCard({required this.progress, super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Export progress',
      subtitle: progress.currentStep,
      children: [
        LinearProgressIndicator(
          value: progress.progress.clamp(0.0, 1.0),
          minHeight: 10,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${(progress.progress * 100).toStringAsFixed(0)}% · '
          'elapsed ${_fmt(progress.elapsed)}'
          '${progress.remainingEstimate == null ? '' : ' · ETA ${_fmt(progress.remainingEstimate!)}'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        ExportLogsViewer(logs: progress.logs),
      ],
    );
  }
}

/// Scrollable log lines.
class ExportLogsViewer extends StatelessWidget {
  final List<String> logs;

  /// Creates [ExportLogsViewer].
  const ExportLogsViewer({required this.logs, super.key});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Text(
        'No logs yet',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 160),
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, i) => Text(
          '• ${logs[i]}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
        ),
      ),
    );
  }
}

/// Prior exports list.
class ExportHistoryCard extends StatelessWidget {
  final List<ExportHistoryEntry> history;
  final void Function(ExportHistoryEntry entry)? onValidate;
  final void Function(ExportHistoryEntry entry)? onCompress;

  /// Creates [ExportHistoryCard].
  const ExportHistoryCard({
    required this.history,
    this.onValidate,
    this.onCompress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Export history',
      subtitle: history.isEmpty ? 'None yet' : '${history.length} package(s)',
      children: [
        if (history.isEmpty)
          const Text('Completed exports appear here.')
        else
          for (final e in history)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.datasetName),
              subtitle: Text(
                '${e.format.label} · ${e.sessionCount} sessions · '
                '${e.completedAt.toLocal()}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'validate') onValidate?.call(e);
                  if (v == 'compress') onCompress?.call(e);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'validate', child: Text('Validate')),
                  PopupMenuItem(value: 'compress', child: Text('Compress')),
                ],
              ),
            ),
      ],
    );
  }
}

/// Settings toggles dialog.
Future<ExportSettings?> showExportSettingsDialog({
  required BuildContext context,
  required ExportSettings current,
  required List<DatasetSession> sessions,
}) {
  return showDialog<ExportSettings>(
    context: context,
    builder: (ctx) {
      var draft = current;
      final selected = {...current.sessionIds};
      final nameController = TextEditingController(text: current.datasetName);
      return StatefulBuilder(
        builder: (context, setModal) {
          return AlertDialog(
            title: const Text('Export settings'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Dataset name',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sessions (empty = all)',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    ...sessions.take(30).map(
                          (s) => CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: selected.isEmpty
                                ? true
                                : selected.contains(s.id),
                            title: Text(s.sessionName),
                            subtitle: Text('${s.frameCount} frames'),
                            onChanged: (v) {
                              setModal(() {
                                if (selected.isEmpty) {
                                  selected
                                    ..clear()
                                    ..addAll(sessions.map((e) => e.id));
                                }
                                if (v == true) {
                                  selected.add(s.id);
                                } else {
                                  selected.remove(s.id);
                                }
                              });
                            },
                          ),
                        ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include images'),
                      value: draft.includeImages,
                      onChanged: (v) =>
                          setModal(() => draft = draft.copyWith(includeImages: v)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include metadata'),
                      value: draft.includeMetadata,
                      onChanged: (v) => setModal(
                        () => draft = draft.copyWith(includeMetadata: v),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include statistics'),
                      value: draft.includeStatistics,
                      onChanged: (v) => setModal(
                        () => draft = draft.copyWith(includeStatistics: v),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Generate manifest'),
                      value: draft.generateManifest,
                      onChanged: (v) => setModal(
                        () => draft = draft.copyWith(generateManifest: v),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Generate README'),
                      value: draft.generateReadme,
                      onChanged: (v) => setModal(
                        () => draft = draft.copyWith(generateReadme: v),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Compress to ZIP'),
                      value: draft.compressOutput,
                      onChanged: (v) => setModal(
                        () => draft = draft.copyWith(compressOutput: v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final ids = selected.length == sessions.length
                      ? <String>[]
                      : selected.toList();
                  Navigator.pop(
                    ctx,
                    draft.copyWith(
                      datasetName: nameController.text.trim().isEmpty
                          ? draft.datasetName
                          : nameController.text.trim(),
                      sessionIds: ids,
                    ),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Completion dialog with path copy.
Future<void> showCompletedExportDialog({
  required BuildContext context,
  required ExportResult result,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Export completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.manifest.datasetName),
            const SizedBox(height: AppSpacing.sm),
            Text(
              result.exportFolderPath,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (result.zipPath != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'ZIP: ${result.zipPath}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (result.isPlaceholderFormat) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Placeholder format — scaffold only. Annotation layouts arrive later.',
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: result.exportFolderPath),
              );
            },
            child: const Text('Copy path'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      );
    },
  );
}

Widget _row(BuildContext context, String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(child: Text(k)),
        Text(v, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}
