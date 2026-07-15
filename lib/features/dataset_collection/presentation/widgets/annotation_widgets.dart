import 'dart:io';

import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/widgets/app_widgets.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/annotation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

/// Toolbar of annotation tools.
class AnnotationToolbar extends StatelessWidget {
  final AnnotationTool tool;
  final ValueChanged<AnnotationTool> onTool;

  const AnnotationToolbar({
    required this.tool,
    required this.onTool,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final t in AnnotationTool.values)
          ChoiceChip(
            label: Text(t.label),
            selected: tool == t,
            onSelected: (_) => onTool(t),
          ),
      ],
    );
  }
}

class UndoRedoBar extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const UndoRedoBar({
    required this.canUndo,
    required this.canRedo,
    this.onUndo,
    this.onRedo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Undo',
          onPressed: canUndo ? onUndo : null,
          icon: const Icon(Icons.undo),
        ),
        IconButton(
          tooltip: 'Redo',
          onPressed: canRedo ? onRedo : null,
          icon: const Icon(Icons.redo),
        ),
      ],
    );
  }
}

class ZoomControls extends StatelessWidget {
  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;

  const ZoomControls({
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Zoom out',
          onPressed: onZoomOut,
          icon: const Icon(Icons.zoom_out),
        ),
        Text('${(zoom * 100).round()}%'),
        IconButton(
          tooltip: 'Zoom in',
          onPressed: onZoomIn,
          icon: const Icon(Icons.zoom_in),
        ),
        IconButton(
          tooltip: 'Fit',
          onPressed: onFit,
          icon: const Icon(Icons.fit_screen),
        ),
      ],
    );
  }
}

class LabelSelector extends StatelessWidget {
  final List<AnnotationLabel> labels;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const LabelSelector({
    required this.labels,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = labels.where((l) => l.enabled).toList();
    return DropdownButtonFormField<String>(
      initialValue: enabled.any((l) => l.id == selectedId)
          ? selectedId
          : enabled.firstOrNull?.id,
      decoration: const InputDecoration(labelText: 'Label'),
      items: [
        for (final l in enabled)
          DropdownMenuItem(
            value: l.id,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Color(l.colorArgb),
                ),
                const SizedBox(width: 8),
                Text(l.name),
              ],
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onSelected(v);
      },
    );
  }
}

class AnnotationListPanel extends StatelessWidget {
  final List<Annotation> annotations;
  final List<AnnotationLabel> labels;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  const AnnotationListPanel({
    required this.annotations,
    required this.labels,
    required this.onSelect,
    required this.onDelete,
    required this.onApprove,
    required this.onReject,
    this.selectedId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Annotations',
      subtitle: '${annotations.length} on frame',
      children: [
        if (annotations.isEmpty)
          const Text('No annotations yet')
        else
          for (final a in annotations)
            ListTile(
              selected: a.id == selectedId,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                a.fromAi ? Icons.smart_toy_outlined : Icons.edit_outlined,
                color: Color(
                  labels
                      .firstWhere(
                        (l) => l.id == a.labelId,
                        orElse: () => DefaultHazardLabels.all.last,
                      )
                      .colorArgb,
                ),
              ),
              title: Text(
                labels
                    .firstWhere(
                      (l) => l.id == a.labelId,
                      orElse: () => AnnotationLabel(
                        id: 'x',
                        name: a.labelId,
                        colorArgb: 0xFF888888,
                      ),
                    )
                    .name,
              ),
              subtitle: Text('${a.type.label} · ${a.status.label}'),
              onTap: () => onSelect(a.id),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'approve':
                      onApprove(a.id);
                    case 'reject':
                      onReject(a.id);
                    case 'delete':
                      onDelete(a.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'approve', child: Text('Approve')),
                  PopupMenuItem(value: 'reject', child: Text('Reject')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
      ],
    );
  }
}

class GroundTruthPanel extends StatelessWidget {
  final GroundTruth groundTruth;
  final AnnotationQualityMetrics quality;

  const GroundTruthPanel({
    required this.groundTruth,
    required this.quality,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Ground truth',
      subtitle: groundTruth.frameStatus.label,
      children: [
        Text('Frame #${groundTruth.frameNumber}'),
        Text('Reviewers: ${groundTruth.reviewers.isEmpty ? '—' : groundTruth.reviewers.join(', ')}'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Completeness ${(quality.completeness * 100).toStringAsFixed(0)}% · '
          'Approval ${quality.approvalPercentage.toStringAsFixed(0)}% · '
          'Quality ${quality.qualityScore.toStringAsFixed(0)}',
        ),
        if (quality.missingLabelCount > 0)
          Text(
            'Missing labels: ${quality.missingLabelCount}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

class HistoryPanel extends StatelessWidget {
  final List<AnnotationHistoryEntry> history;

  const HistoryPanel({required this.history, super.key});

  @override
  Widget build(BuildContext context) {
    final recent = history.reversed.take(12).toList();
    return AppSectionCard(
      title: 'History',
      children: [
        if (recent.isEmpty)
          const Text('No history yet')
        else
          for (final h in recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(h.action.name),
              subtitle: Text(
                '${h.reviewer} · v${h.version} · ${h.timestamp.toLocal()}',
              ),
            ),
      ],
    );
  }
}

class ReviewPanel extends StatelessWidget {
  final Annotation? selected;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ReviewPanel({
    this.selected,
    this.onApprove,
    this.onReject,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Review',
      children: [
        if (selected == null)
          const Text('Select an annotation to review')
        else ...[
          Text('${selected!.type.label} · ${selected!.status.label}'),
          if (selected!.fromAi)
            Text(
              'AI suggestion · conf ${(selected!.aiConfidence ?? 0).toStringAsFixed(2)}',
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilledButton.tonal(
                onPressed: onApprove,
                child: const Text('Approve'),
              ),
              OutlinedButton(
                onPressed: onReject,
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class MetadataPanel extends StatelessWidget {
  final AnnotatableFrame? frame;
  final GroundTruth groundTruth;

  const MetadataPanel({
    required this.groundTruth,
    this.frame,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Frame metadata',
      children: [
        Text('Session ${groundTruth.sessionId}'),
        Text('Frame ${groundTruth.frameNumber}'),
        Text('Image: ${groundTruth.imagePath ?? frame?.imagePath ?? 'missing'}'),
        Text('Updated ${groundTruth.updatedAt.toLocal()}'),
      ],
    );
  }
}

/// Interactive annotation canvas with zoom / pan / draw.
class AnnotationCanvas extends StatefulWidget {
  final AnnotationEditing state;
  final void Function(Annotation annotation) onCreate;
  final void Function(String id) onSelect;

  const AnnotationCanvas({
    required this.state,
    required this.onCreate,
    required this.onSelect,
    super.key,
  });

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  Offset? _dragStart;
  Offset? _dragCurrent;
  final List<Offset> _polyDraft = [];
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final gt = widget.state.groundTruth;
    final path = gt.imagePath;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleUpdate: widget.state.tool == AnnotationTool.pan
                ? (d) {
                    context.read<AnnotationBloc>().add(
                          AnnotationSetPan(
                            panX: widget.state.panX + d.focalPointDelta.dx,
                            panY: widget.state.panY + d.focalPointDelta.dy,
                          ),
                        );
                    context.read<AnnotationBloc>().add(
                          AnnotationSetZoom(widget.state.zoom * d.scale),
                        );
                  }
                : null,
            onTapDown: (d) => _onTap(d.localPosition, size),
            onPanStart: (d) => _onPanStart(d.localPosition, size),
            onPanUpdate: (d) => _onPanUpdate(d.localPosition),
            onPanEnd: (_) => _onPanEnd(size),
            child: Transform(
              transform: Matrix4.identity()
                ..translateByDouble(widget.state.panX, widget.state.panY, 0, 1)
                ..scaleByDouble(
                  widget.state.zoom,
                  widget.state.zoom,
                  1,
                  1,
                ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: path != null && File(path).existsSync()
                        ? Image.file(
                            File(path),
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const Center(child: Text('Image missing')),
                          )
                        : const Center(
                            child: Text('No image — annotate metadata-only frame'),
                          ),
                  ),
                  CustomPaint(
                    painter: _AnnotationPainter(
                      annotations: gt.annotations,
                      labels: widget.state.labels,
                      selectedId: widget.state.selectedAnnotationId,
                      draftStart: _dragStart,
                      draftCurrent: _dragCurrent,
                      polyDraft: _polyDraft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTap(Offset local, Size size) {
    final tool = widget.state.tool;
    final norm = _toNorm(local, size);
    if (tool == AnnotationTool.select) {
      final hit = _hitTest(norm);
      if (hit != null) widget.onSelect(hit);
      return;
    }
    if (tool == AnnotationTool.point) {
      _emitPoint(norm);
      return;
    }
    if (tool == AnnotationTool.classification) {
      _emitClassification();
      return;
    }
    if (tool == AnnotationTool.polygon || tool == AnnotationTool.polyline) {
      setState(() => _polyDraft.add(local));
      return;
    }
  }

  void _onPanStart(Offset local, Size size) {
    final tool = widget.state.tool;
    if (tool == AnnotationTool.boundingBox) {
      setState(() {
        _dragStart = local;
        _dragCurrent = local;
      });
    }
  }

  void _onPanUpdate(Offset local) {
    if (_dragStart != null) {
      setState(() => _dragCurrent = local);
    }
  }

  void _onPanEnd(Size size) {
    final tool = widget.state.tool;
    if (tool == AnnotationTool.boundingBox &&
        _dragStart != null &&
        _dragCurrent != null) {
      final a = _toNorm(_dragStart!, size);
      final b = _toNorm(_dragCurrent!, size);
      final x = a.dx < b.dx ? a.dx : b.dx;
      final y = a.dy < b.dy ? a.dy : b.dy;
      final w = (a.dx - b.dx).abs();
      final h = (a.dy - b.dy).abs();
      if (w > 0.01 && h > 0.01) {
        _emitBox(BoundingBox(x: x, y: y, width: w, height: h));
      }
    }
    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _finishPolygon() {
    final tool = widget.state.tool;
    if (_polyDraft.length < 2) return;
    final size = context.size;
    if (size == null) return;
    final points = [
      for (final o in _polyDraft) _toPoint(_toNorm(o, size)),
    ];
    final closed = tool == AnnotationTool.polygon;
    if (closed && points.length < 3) return;
    final now = DateTime.now().toUtc();
    final gt = widget.state.groundTruth;
    widget.onCreate(
      Annotation(
        id: _uuid.v4(),
        sessionId: gt.sessionId,
        frameNumber: gt.frameNumber,
        type: closed ? AnnotationType.polygon : AnnotationType.polyline,
        labelId: widget.state.selectedLabelId,
        status: AnnotationStatus.draft,
        polygon: PolygonGeometry(points: points, closed: closed),
        createdBy: 'researcher',
        createdAt: now,
        updatedAt: now,
      ),
    );
    setState(() => _polyDraft.clear());
  }

  void _emitBox(BoundingBox box) {
    final now = DateTime.now().toUtc();
    final gt = widget.state.groundTruth;
    widget.onCreate(
      Annotation(
        id: _uuid.v4(),
        sessionId: gt.sessionId,
        frameNumber: gt.frameNumber,
        type: AnnotationType.boundingBox,
        labelId: widget.state.selectedLabelId,
        status: AnnotationStatus.draft,
        box: box,
        createdBy: 'researcher',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  void _emitPoint(Offset norm) {
    final now = DateTime.now().toUtc();
    final gt = widget.state.groundTruth;
    widget.onCreate(
      Annotation(
        id: _uuid.v4(),
        sessionId: gt.sessionId,
        frameNumber: gt.frameNumber,
        type: AnnotationType.point,
        labelId: widget.state.selectedLabelId,
        status: AnnotationStatus.draft,
        point: AnnotationPoint(norm.dx, norm.dy),
        createdBy: 'researcher',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  void _emitClassification() {
    final now = DateTime.now().toUtc();
    final gt = widget.state.groundTruth;
    widget.onCreate(
      Annotation(
        id: _uuid.v4(),
        sessionId: gt.sessionId,
        frameNumber: gt.frameNumber,
        type: AnnotationType.classification,
        labelId: widget.state.selectedLabelId,
        status: AnnotationStatus.draft,
        classificationNote: 'Frame classification',
        createdBy: 'researcher',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Offset _toNorm(Offset local, Size size) {
    final w = size.width <= 0 ? 1.0 : size.width;
    final h = size.height <= 0 ? 1.0 : size.height;
    return Offset(
      (local.dx / w).clamp(0.0, 1.0),
      (local.dy / h).clamp(0.0, 1.0),
    );
  }

  AnnotationPoint _toPoint(Offset o) => AnnotationPoint(o.dx, o.dy);

  String? _hitTest(Offset norm) {
    for (final a in widget.state.groundTruth.annotations.reversed) {
      final box = a.box;
      if (box != null &&
          norm.dx >= box.x &&
          norm.dx <= box.right &&
          norm.dy >= box.y &&
          norm.dy <= box.bottom) {
        return a.id;
      }
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant AnnotationCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Finish polygon on tool change away from polygon tools.
    if (oldWidget.state.tool != widget.state.tool &&
        (oldWidget.state.tool == AnnotationTool.polygon ||
            oldWidget.state.tool == AnnotationTool.polyline) &&
        _polyDraft.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishPolygon());
    }
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<Annotation> annotations;
  final List<AnnotationLabel> labels;
  final String? selectedId;
  final Offset? draftStart;
  final Offset? draftCurrent;
  final List<Offset> polyDraft;

  _AnnotationPainter({
    required this.annotations,
    required this.labels,
    required this.selectedId,
    required this.draftStart,
    required this.draftCurrent,
    required this.polyDraft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final a in annotations) {
      final color = Color(
        labels
            .firstWhere(
              (l) => l.id == a.labelId,
              orElse: () => DefaultHazardLabels.all.last,
            )
            .colorArgb,
      );
      final selected = a.id == selectedId;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 3 : 2
        ..color = color;
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.18);

      if (a.box != null) {
        final r = Rect.fromLTWH(
          a.box!.x * size.width,
          a.box!.y * size.height,
          a.box!.width * size.width,
          a.box!.height * size.height,
        );
        canvas.drawRect(r, fill);
        canvas.drawRect(r, paint);
      } else if (a.polygon != null && a.polygon!.points.isNotEmpty) {
        final path = Path();
        final first = a.polygon!.points.first;
        path.moveTo(first.x * size.width, first.y * size.height);
        for (final p in a.polygon!.points.skip(1)) {
          path.lineTo(p.x * size.width, p.y * size.height);
        }
        if (a.polygon!.closed) path.close();
        if (a.polygon!.closed) canvas.drawPath(path, fill);
        canvas.drawPath(path, paint);
      } else if (a.point != null) {
        canvas.drawCircle(
          Offset(a.point!.x * size.width, a.point!.y * size.height),
          selected ? 7 : 5,
          paint..style = PaintingStyle.fill,
        );
      }
    }

    if (draftStart != null && draftCurrent != null) {
      final r = Rect.fromPoints(draftStart!, draftCurrent!);
      canvas.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white
          ..strokeWidth = 2,
      );
    }
    if (polyDraft.isNotEmpty) {
      final path = Path()..moveTo(polyDraft.first.dx, polyDraft.first.dy);
      for (final p in polyDraft.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white
          ..strokeWidth = 2,
      );
      for (final p in polyDraft) {
        canvas.drawCircle(p, 4, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}

/// Shortcuts helper for desktop.
class AnnotationShortcuts extends StatelessWidget {
  final Widget child;

  const AnnotationShortcuts({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () =>
            context.read<AnnotationBloc>().add(const AnnotationUndo()),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            context.read<AnnotationBloc>().add(const AnnotationUndo()),
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): () =>
            context.read<AnnotationBloc>().add(const AnnotationRedo()),
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () =>
            context.read<AnnotationBloc>().add(const AnnotationRedo()),
        const SingleActivator(LogicalKeyboardKey.keyB): () => context
            .read<AnnotationBloc>()
            .add(const AnnotationSelectTool(AnnotationTool.boundingBox)),
        const SingleActivator(LogicalKeyboardKey.keyV): () => context
            .read<AnnotationBloc>()
            .add(const AnnotationSelectTool(AnnotationTool.select)),
        const SingleActivator(LogicalKeyboardKey.delete): () {
          final s = context.read<AnnotationBloc>().state;
          if (s is AnnotationEditing && s.selectedAnnotationId != null) {
            context
                .read<AnnotationBloc>()
                .add(AnnotationDelete(s.selectedAnnotationId!));
          }
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
