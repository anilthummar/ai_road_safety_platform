import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:equatable/equatable.dart';

/// IMU presentation events.
sealed class ImuEvent extends Equatable {
  const ImuEvent();

  @override
  List<Object?> get props => [];
}

/// Bootstraps session streams and starts sensing.
final class ImuStarted extends ImuEvent {
  const ImuStarted();
}

/// Starts sensor streams.
final class ImuStreamingStarted extends ImuEvent {
  const ImuStreamingStarted();
}

/// Stops sensor streams.
final class ImuStreamingStopped extends ImuEvent {
  const ImuStreamingStopped();
}

/// Holds device still and collects bias samples.
final class ImuCalibrationRequested extends ImuEvent {
  const ImuCalibrationRequested();
}

/// Releases subscriptions / sensors.
final class ImuDisposed extends ImuEvent {
  const ImuDisposed();
}

/// Internal: session metadata from repository.
final class ImuSessionUpdated extends ImuEvent {
  /// Latest session snapshot.
  final ImuSession session;

  /// Creates [ImuSessionUpdated].
  const ImuSessionUpdated(this.session);

  @override
  List<Object?> get props => [session];
}

/// Internal: throttled fused sample.
final class ImuSampleUpdated extends ImuEvent {
  /// Latest sample.
  final ImuSample sample;

  /// Creates [ImuSampleUpdated].
  const ImuSampleUpdated(this.sample);

  @override
  List<Object?> get props => [sample];
}
