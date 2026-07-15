import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/dataset_collection_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/annotation_bloc.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/widgets/annotation_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 12.9 annotation & ground-truth workspace.
class AnnotationDashboardPage extends StatelessWidget {
  /// Optional session to open immediately.
  final String? sessionId;

  /// Creates [AnnotationDashboardPage].
  const AnnotationDashboardPage({this.sessionId, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<AnnotationBloc>();
        final id = sessionId;
        if (id != null && id.isNotEmpty) {
          bloc.add(AnnotationLoadSession(id));
        }
        return bloc;
      },
      child: const _AnnotationDashboardView(),
    );
  }
}

class _AnnotationDashboardView extends StatefulWidget {
  const _AnnotationDashboardView();

  @override
  State<_AnnotationDashboardView> createState() =>
      _AnnotationDashboardViewState();
}

class _AnnotationDashboardViewState extends State<_AnnotationDashboardView> {
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
    return AnnotationShortcuts(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Annotation workspace'),
          actions: [
            IconButton(
              tooltip: 'Open session',
              onPressed: () => _pickSession(context),
              icon: const Icon(Icons.folder_open_outlined),
            ),
          ],
        ),
        body: BlocConsumer<AnnotationBloc, AnnotationState>(
          listenWhen: (p, n) =>
              n is AnnotationError ||
              (n is AnnotationEditing && n.statusMessage != null),
          listener: (context, state) {
            if (state is AnnotationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.failure.message)),
              );
            } else if (state is AnnotationEditing &&
                state.statusMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.statusMessage!)),
              );
            }
          },
          builder: (context, state) {
            return switch (state) {
              AnnotationInitial() => _EmptySessionPicker(
                  sessions: _sessions,
                  onPick: (id) => context
                      .read<AnnotationBloc>()
                      .add(AnnotationLoadSession(id)),
                ),
              AnnotationLoading(:final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(message),
                    ],
                  ),
                ),
              AnnotationSaving(:final snapshot) =>
                _Workspace(editing: snapshot, saving: true),
              AnnotationError(:final snapshot) => snapshot != null
                  ? _Workspace(editing: snapshot, saving: false)
                  : Center(child: Text(state.failure.message)),
              AnnotationEditing() =>
                _Workspace(editing: state, saving: false),
            };
          },
        ),
      ),
    );
  }

  Future<void> _pickSession(BuildContext context) async {
    if (_sessions.isEmpty) await _loadSessions();
    if (!context.mounted) return;
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Select session to annotate')),
            if (_sessions.isEmpty)
              const ListTile(title: Text('No sessions yet'))
            else
              for (final s in _sessions)
                ListTile(
                  title: Text(s.sessionName),
                  subtitle: Text('${s.frameCount} frames · ${s.status.name}'),
                  onTap: () => Navigator.pop(ctx, s.id),
                ),
          ],
        ),
      ),
    );
    if (id == null || !context.mounted) return;
    context.read<AnnotationBloc>().add(AnnotationLoadSession(id));
  }
}

class _EmptySessionPicker extends StatelessWidget {
  final List<DatasetSession> sessions;
  final ValueChanged<String> onPick;

  const _EmptySessionPicker({
    required this.sessions,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return AppPageContainer(
      child: ListView(
        children: [
          AppSectionCard(
            title: 'Annotation & ground truth',
            subtitle: 'Phase 12.9 · pluggable geometries · local JSON',
            children: [
              Text(
                'Open a recording session to review frames, draw boxes / '
                'polygons, validate AI suggestions, and approve ground truth.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (sessions.isEmpty)
                const Text('No sessions available. Record or import data first.')
              else
                for (final s in sessions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_note_outlined),
                    title: Text(s.sessionName),
                    subtitle: Text('${s.frameCount} frames'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onPick(s.id),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Workspace extends StatelessWidget {
  final AnnotationEditing editing;
  final bool saving;

  const _Workspace({required this.editing, required this.saving});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final selected = editing.selectedAnnotationId == null
        ? null
        : editing.groundTruth.annotations
            .where((a) => a.id == editing.selectedAnnotationId)
            .firstOrNull;
    final frame = editing.frames
        .where((f) => f.frameNumber == editing.groundTruth.frameNumber)
        .firstOrNull;

    final canvasBody = Stack(
      children: [
        Positioned.fill(
          child: AnnotationCanvas(
            state: editing,
            onCreate: (a) =>
                context.read<AnnotationBloc>().add(AnnotationCreate(a)),
            onSelect: (id) {
              final bloc = context.read<AnnotationBloc>();
              if (editing.tool == AnnotationTool.delete) {
                bloc.add(AnnotationDelete(id));
              } else {
                bloc.add(AnnotationSelectAnnotation(id));
              }
            },
          ),
        ),
        if (saving)
          const Positioned(
            top: 12,
            right: 12,
            child: Chip(label: Text('Saving…')),
          ),
      ],
    );

    final sidePanels = [
      GroundTruthPanel(
        groundTruth: editing.groundTruth,
        quality: editing.quality,
      ),
      const SizedBox(height: AppSpacing.md),
      ReviewPanel(
        selected: selected,
        onApprove: selected == null
            ? null
            : () => context
                .read<AnnotationBloc>()
                .add(AnnotationApprove(selected.id)),
        onReject: selected == null
            ? null
            : () => context
                .read<AnnotationBloc>()
                .add(AnnotationReject(selected.id)),
      ),
      const SizedBox(height: AppSpacing.md),
      AnnotationListPanel(
        annotations: editing.groundTruth.annotations,
        labels: editing.labels,
        selectedId: editing.selectedAnnotationId,
        onSelect: (id) => context
            .read<AnnotationBloc>()
            .add(AnnotationSelectAnnotation(id)),
        onDelete: (id) =>
            context.read<AnnotationBloc>().add(AnnotationDelete(id)),
        onApprove: (id) =>
            context.read<AnnotationBloc>().add(AnnotationApprove(id)),
        onReject: (id) =>
            context.read<AnnotationBloc>().add(AnnotationReject(id)),
      ),
      const SizedBox(height: AppSpacing.md),
      HistoryPanel(history: editing.groundTruth.history),
      const SizedBox(height: AppSpacing.md),
      MetadataPanel(groundTruth: editing.groundTruth, frame: frame),
    ];

    return Column(
      children: [
        Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: AnnotationToolbar(
                          tool: editing.tool,
                          onTool: (t) => context
                              .read<AnnotationBloc>()
                              .add(AnnotationSelectTool(t)),
                        ),
                      ),
                    ),
                    UndoRedoBar(
                      canUndo: editing.undoAvailable,
                      canRedo: editing.redoAvailable,
                      onUndo: () => context
                          .read<AnnotationBloc>()
                          .add(const AnnotationUndo()),
                      onRedo: () => context
                          .read<AnnotationBloc>()
                          .add(const AnnotationRedo()),
                    ),
                    ZoomControls(
                      zoom: editing.zoom,
                      onZoomIn: () => context
                          .read<AnnotationBloc>()
                          .add(AnnotationSetZoom(editing.zoom * 1.25)),
                      onZoomOut: () => context
                          .read<AnnotationBloc>()
                          .add(AnnotationSetZoom(editing.zoom / 1.25)),
                      onFit: () => context
                          .read<AnnotationBloc>()
                          .add(const AnnotationFitToScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: LabelSelector(
                        labels: editing.labels,
                        selectedId: editing.selectedLabelId,
                        onSelected: (id) => context
                            .read<AnnotationBloc>()
                            .add(AnnotationSelectLabel(id)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _FrameStrip(editing: editing),
                    if (selected != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      PopupMenuButton<String>(
                        tooltip: 'AI / edit actions',
                        onSelected: (v) {
                          final bloc = context.read<AnnotationBloc>();
                          switch (v) {
                            case 'dup':
                              bloc.add(AnnotationDuplicate(selected.id));
                            case 'split':
                              bloc.add(AnnotationSplit(selected.id));
                            case 'merge':
                              final other = editing.groundTruth.annotations
                                  .where(
                                    (a) =>
                                        a.id != selected.id && a.box != null,
                                  )
                                  .firstOrNull;
                              if (other != null) {
                                bloc.add(
                                  AnnotationMerge(
                                    primaryId: selected.id,
                                    secondaryId: other.id,
                                  ),
                                );
                              }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'dup',
                            child: Text('Duplicate'),
                          ),
                          PopupMenuItem(
                            value: 'split',
                            child: Text('Split box'),
                          ),
                          PopupMenuItem(
                            value: 'merge',
                            child: Text('Merge with next box'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: canvasBody),
                    SizedBox(
                      width: 340,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: sidePanels,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(flex: 3, child: canvasBody),
                    Expanded(
                      flex: 2,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: sidePanels,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _FrameStrip extends StatelessWidget {
  final AnnotationEditing editing;

  const _FrameStrip({required this.editing});

  @override
  Widget build(BuildContext context) {
    if (editing.frames.isEmpty) {
      return const Text('No frames');
    }
    final current = editing.groundTruth.frameNumber;
    final idx = editing.frames.indexWhere((f) => f.frameNumber == current);
    final safeIdx = idx < 0 ? 0 : idx;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous frame',
          onPressed: safeIdx <= 0
              ? null
              : () {
                  final f = editing.frames[safeIdx - 1];
                  context.read<AnnotationBloc>().add(
                        AnnotationLoadImage(
                          sessionId: f.sessionId,
                          frameNumber: f.frameNumber,
                        ),
                      );
                },
          icon: const Icon(Icons.chevron_left),
        ),
        Text('#$current / ${editing.frames.length}'),
        IconButton(
          tooltip: 'Next frame',
          onPressed: safeIdx >= editing.frames.length - 1
              ? null
              : () {
                  final f = editing.frames[safeIdx + 1];
                  context.read<AnnotationBloc>().add(
                        AnnotationLoadImage(
                          sessionId: f.sessionId,
                          frameNumber: f.frameNumber,
                        ),
                      );
                },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
