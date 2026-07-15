import 'package:ai_road_safety_platform/features/flood_detection/domain/entities/detection_entities.dart';
import 'package:equatable/equatable.dart';

/// Inference Bloc events.
sealed class InferenceEvent extends Equatable {
  const InferenceEvent();

  @override
  List<Object?> get props => [];
}

/// Loads TFLite model + delegates.
class InferenceStarted extends InferenceEvent {
  const InferenceStarted();
}

/// Begins real-time frame inference.
class InferenceStreamStarted extends InferenceEvent {
  const InferenceStreamStarted();
}

/// Stops real-time frame inference.
class InferenceStreamStopped extends InferenceEvent {
  const InferenceStreamStopped();
}

/// Tears down the engine (leaving camera screen).
class InferenceDisposed extends InferenceEvent {
  const InferenceDisposed();
}

/// Internal session fan-in.
class InferenceSessionUpdated extends InferenceEvent {
  /// Latest session snapshot.
  final InferenceSession session;

  /// Creates [InferenceSessionUpdated].
  const InferenceSessionUpdated(this.session);

  @override
  List<Object?> get props => [session];
}

/// Internal result fan-in.
class InferenceResultUpdated extends InferenceEvent {
  /// Latest detections for overlay.
  final InferenceResult result;

  /// Creates [InferenceResultUpdated].
  const InferenceResultUpdated(this.result);

  @override
  List<Object?> get props => [result];
}
