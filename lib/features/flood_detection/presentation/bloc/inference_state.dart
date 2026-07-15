import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:equatable/equatable.dart';

/// Inference Bloc states.
sealed class InferenceState extends Equatable {
  const InferenceState();

  @override
  List<Object?> get props => [];
}

/// Engine not started.
class InferenceInitial extends InferenceState {
  const InferenceInitial();
}

/// Model / delegate loading.
class InferenceLoading extends InferenceState {
  /// Status text for the loading indicator.
  final String message;

  /// Creates [InferenceLoading].
  const InferenceLoading({this.message = 'Loading YOLOv8 model…'});

  @override
  List<Object?> get props => [message];
}

/// Engine ready / running with optional latest detections.
class InferenceActive extends InferenceState {
  /// Engine session metrics.
  final InferenceSession session;

  /// Latest detections for overlay painting.
  final InferenceResult? latestResult;

  /// Creates [InferenceActive].
  const InferenceActive({
    required this.session,
    this.latestResult,
  });

  /// Copy helper.
  InferenceActive copyWith({
    InferenceSession? session,
    InferenceResult? latestResult,
    bool clearResult = false,
  }) {
    return InferenceActive(
      session: session ?? this.session,
      latestResult: clearResult ? null : (latestResult ?? this.latestResult),
    );
  }

  @override
  List<Object?> get props => [session, latestResult];
}

/// Fatal inference failure.
class InferenceError extends InferenceState {
  /// Domain failure.
  final Failure failure;

  /// Creates [InferenceError].
  const InferenceError(this.failure);

  @override
  List<Object?> get props => [failure];
}
