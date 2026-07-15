import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:equatable/equatable.dart';

sealed class AnnotationState extends Equatable {
  const AnnotationState();
  @override
  List<Object?> get props => [];
}

final class AnnotationInitial extends AnnotationState {
  const AnnotationInitial();
}

final class AnnotationLoading extends AnnotationState {
  final String message;
  const AnnotationLoading({this.message = 'Loading…'});
  @override
  List<Object?> get props => [message];
}

/// Primary editing workspace state.
final class AnnotationEditing extends AnnotationState {
  final String sessionId;
  final List<AnnotatableFrame> frames;
  final GroundTruth groundTruth;
  final List<AnnotationLabel> labels;
  final AnnotationTool tool;
  final String selectedLabelId;
  final String? selectedAnnotationId;
  final double zoom;
  final double panX;
  final double panY;
  final bool undoAvailable;
  final bool redoAvailable;
  final AnnotationQualityMetrics quality;
  final String? statusMessage;

  const AnnotationEditing({
    required this.sessionId,
    required this.frames,
    required this.groundTruth,
    required this.labels,
    required this.tool,
    required this.selectedLabelId,
    required this.zoom,
    required this.panX,
    required this.panY,
    required this.undoAvailable,
    required this.redoAvailable,
    required this.quality,
    this.selectedAnnotationId,
    this.statusMessage,
  });

  AnnotationEditing copyWith({
    String? sessionId,
    List<AnnotatableFrame>? frames,
    GroundTruth? groundTruth,
    List<AnnotationLabel>? labels,
    AnnotationTool? tool,
    String? selectedLabelId,
    String? selectedAnnotationId,
    double? zoom,
    double? panX,
    double? panY,
    bool? undoAvailable,
    bool? redoAvailable,
    AnnotationQualityMetrics? quality,
    String? statusMessage,
    bool clearSelection = false,
    bool clearStatus = false,
  }) {
    return AnnotationEditing(
      sessionId: sessionId ?? this.sessionId,
      frames: frames ?? this.frames,
      groundTruth: groundTruth ?? this.groundTruth,
      labels: labels ?? this.labels,
      tool: tool ?? this.tool,
      selectedLabelId: selectedLabelId ?? this.selectedLabelId,
      selectedAnnotationId: clearSelection
          ? null
          : (selectedAnnotationId ?? this.selectedAnnotationId),
      zoom: zoom ?? this.zoom,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      undoAvailable: undoAvailable ?? this.undoAvailable,
      redoAvailable: redoAvailable ?? this.redoAvailable,
      quality: quality ?? this.quality,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        frames,
        groundTruth,
        labels,
        tool,
        selectedLabelId,
        selectedAnnotationId,
        zoom,
        panX,
        panY,
        undoAvailable,
        redoAvailable,
        quality,
        statusMessage,
      ];
}

final class AnnotationSaving extends AnnotationState {
  final AnnotationEditing snapshot;
  const AnnotationSaving(this.snapshot);
  @override
  List<Object?> get props => [snapshot];
}

final class AnnotationError extends AnnotationState {
  final Failure failure;
  final AnnotationEditing? snapshot;
  const AnnotationError(this.failure, {this.snapshot});
  @override
  List<Object?> get props => [failure, snapshot];
}
