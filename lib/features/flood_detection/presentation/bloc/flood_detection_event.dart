import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/flood_entities.dart';
import 'package:equatable/equatable.dart';

/// Flood detection Bloc events.
sealed class FloodDetectionEvent extends Equatable {
  const FloodDetectionEvent();

  @override
  List<Object?> get props => [];
}

/// Loads model + starts readiness.
class FloodDetectionStarted extends FloodDetectionEvent {
  const FloodDetectionStarted();
}

/// Starts live segmentation.
class FloodDetectionStreamStarted extends FloodDetectionEvent {
  const FloodDetectionStreamStarted();
}

/// Stops live segmentation.
class FloodDetectionStreamStopped extends FloodDetectionEvent {
  const FloodDetectionStreamStopped();
}

/// Disposes the engine.
class FloodDetectionDisposed extends FloodDetectionEvent {
  const FloodDetectionDisposed();
}

/// Internal session fan-in.
class FloodDetectionSessionUpdated extends FloodDetectionEvent {
  /// Latest session.
  final FloodDetectionSession session;

  /// Creates [FloodDetectionSessionUpdated].
  const FloodDetectionSessionUpdated(this.session);

  @override
  List<Object?> get props => [session];
}

/// Internal result fan-in.
class FloodDetectionResultUpdated extends FloodDetectionEvent {
  /// Latest segmentation result.
  final FloodSegmentationResult result;

  /// Creates [FloodDetectionResultUpdated].
  const FloodDetectionResultUpdated(this.result);

  @override
  List<Object?> get props => [result];
}
