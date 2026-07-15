import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:equatable/equatable.dart';

/// Flood detection Bloc states.
sealed class FloodDetectionState extends Equatable {
  const FloodDetectionState();

  @override
  List<Object?> get props => [];
}

/// Not started.
class FloodDetectionInitial extends FloodDetectionState {
  const FloodDetectionInitial();
}

/// Loading model / labels.
class FloodDetectionLoading extends FloodDetectionState {
  /// Status message.
  final String message;

  /// Creates [FloodDetectionLoading].
  const FloodDetectionLoading({
    this.message = 'Loading flood segmentation model…',
  });

  @override
  List<Object?> get props => [message];
}

/// Engine active with optional latest result.
class FloodDetectionActive extends FloodDetectionState {
  /// Session metrics.
  final FloodDetectionSession session;

  /// Latest mask + coverage stats.
  final FloodSegmentationResult? latestResult;

  /// Creates [FloodDetectionActive].
  const FloodDetectionActive({
    required this.session,
    this.latestResult,
  });

  /// Copy helper.
  FloodDetectionActive copyWith({
    FloodDetectionSession? session,
    FloodSegmentationResult? latestResult,
    bool clearResult = false,
  }) {
    return FloodDetectionActive(
      session: session ?? this.session,
      latestResult: clearResult ? null : (latestResult ?? this.latestResult),
    );
  }

  @override
  List<Object?> get props => [session, latestResult];
}

/// Fatal failure (e.g. missing model).
class FloodDetectionError extends FloodDetectionState {
  /// Domain failure.
  final Failure failure;

  /// Creates [FloodDetectionError].
  const FloodDetectionError(this.failure);

  @override
  List<Object?> get props => [failure];
}
