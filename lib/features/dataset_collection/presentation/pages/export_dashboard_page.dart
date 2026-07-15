import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_collection_usecases.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/dataset_export_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/dataset_export_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 12.8 research dataset export workspace.
class ExportDashboardPage extends StatelessWidget {
  /// Creates [ExportDashboardPage].
  const ExportDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DatasetExportBloc>()
        ..add(const DatasetExportLoadHistory()),
      child: const _ExportDashboardView(),
    );
  }
}

class _ExportDashboardView extends StatefulWidget {
  const _ExportDashboardView();

  @override
  State<_ExportDashboardView> createState() => _ExportDashboardViewState();
}

class _ExportDashboardViewState extends State<_ExportDashboardView> {
  List<DatasetSession> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final result = await sl<GetDatasetSessionsUseCase>()(const NoParams());
    if (!mounted) return;
    result.fold(
      onOk: (list) => setState(() => _sessions = list),
      onErr: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dataset export'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () async {
              final bloc = context.read<DatasetExportBloc>();
              final current = _currentSettings(bloc.state);
              final next = await showExportSettingsDialog(
                context: context,
                current: current,
                sessions: _sessions,
              );
              if (next == null || !mounted) return;
              bloc.add(DatasetExportUpdateSettings(next));
            },
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: BlocConsumer<DatasetExportBloc, DatasetExportState>(
        listenWhen: (p, n) =>
            n is DatasetExportCompleted || n is DatasetExportFailed,
        listener: (context, state) async {
          if (state is DatasetExportCompleted) {
            await showCompletedExportDialog(
              context: context,
              result: state.result,
            );
          } else if (state is DatasetExportFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          }
        },
        builder: (context, state) {
          final settings = _currentSettings(state);
          final busy = state is DatasetExportPreparing ||
              state is DatasetExportExporting ||
              state is DatasetExportCompressing;
          final progress = switch (state) {
            DatasetExportPreparing(:final progress) => progress,
            DatasetExportExporting(:final progress) => progress,
            DatasetExportCompressing(:final progress) => progress,
            DatasetExportFailed(:final progress) => progress,
            _ => null,
          };
          final history = switch (state) {
            DatasetExportInitial(:final history) => history,
            DatasetExportCompleted(:final history) => history,
            _ => const <ExportHistoryEntry>[],
          };

          return AppPageContainer(
            child: ListView(
              children: [
                AppSectionCard(
                  title: 'Research export engine',
                  subtitle:
                      'Industry-standard local packages · strategy + factory',
                  children: [
                    Text(
                      'Exports land under the app documents dataset/exports '
                      'folder. Annotation formats are scaffolds until later phases.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ExportFormatSelector(
                  selected: settings.format,
                  onSelected: busy
                      ? (_) {}
                      : (f) => context.read<DatasetExportBloc>().add(
                            DatasetExportUpdateSettings(
                              settings.copyWith(format: f),
                            ),
                          ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ExportSummaryCard(
                  settings: settings,
                  availableSessions: _sessions.length,
                ),
                if (progress != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ExportProgressCard(progress: progress),
                ],
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => context.read<DatasetExportBloc>().add(
                                DatasetExportRequested(settings),
                              ),
                      icon: const Icon(Icons.ios_share_outlined),
                      label: const Text('Export dataset'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy || _sessions.isEmpty
                          ? null
                          : () => context.read<DatasetExportBloc>().add(
                                DatasetExportSessionRequested(
                                  sessionId: _sessions.first.id,
                                  settings: settings.copyWith(
                                    sessionIds: [_sessions.first.id],
                                  ),
                                ),
                              ),
                      icon: const Icon(Icons.folder_outlined),
                      label: const Text('Export first session'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ExportHistoryCard(
                  history: history,
                  onValidate: (e) => context
                      .read<DatasetExportBloc>()
                      .add(DatasetExportValidate(e.folderPath)),
                  onCompress: (e) => context
                      .read<DatasetExportBloc>()
                      .add(DatasetExportCompress(e.folderPath)),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  ExportSettings _currentSettings(DatasetExportState state) {
    return switch (state) {
      DatasetExportInitial(:final settings) => settings,
      DatasetExportPreparing(:final settings) => settings,
      DatasetExportExporting(:final settings) => settings,
      DatasetExportCompressing(:final settings) => settings,
      DatasetExportFailed(:final settings) => settings,
      DatasetExportCompleted(:final result) => result.settings,
    };
  }
}
