import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:equatable/equatable.dart';

/// Metadata presentation states (Phase 12.4).
sealed class MetadataState extends Equatable {
  const MetadataState();

  @override
  List<Object?> get props => [];
}

/// Cold start.
final class MetadataInitial extends MetadataState {
  /// Sensor status.
  final SensorStatusSnapshot sensors;

  /// Creates [MetadataInitial].
  const MetadataInitial({
    this.sensors = const SensorStatusSnapshot.cold(),
  });

  @override
  List<Object?> get props => [sensors];
}

/// Sync in progress.
final class MetadataGenerating extends MetadataState {
  /// Frame id being processed.
  final String frameId;

  /// Last known metadata (optional).
  final FrameMetadata? latest;

  /// Sensor status.
  final SensorStatusSnapshot sensors;

  /// Creates [MetadataGenerating].
  const MetadataGenerating({
    required this.frameId,
    required this.sensors,
    this.latest,
  });

  @override
  List<Object?> get props => [frameId, latest, sensors];
}

/// Latest synchronized metadata ready.
final class MetadataGenerated extends MetadataState {
  /// Metadata payload.
  final FrameMetadata metadata;

  /// Sensor status.
  final SensorStatusSnapshot sensors;

  /// Creates [MetadataGenerated].
  const MetadataGenerated({
    required this.metadata,
    required this.sensors,
  });

  @override
  List<Object?> get props => [metadata, sensors];
}

/// Failure.
final class MetadataError extends MetadataState {
  /// Failure.
  final Failure failure;

  /// Sensor status.
  final SensorStatusSnapshot sensors;

  /// Creates [MetadataError].
  const MetadataError(this.failure, {required this.sensors});

  @override
  List<Object?> get props => [failure, sensors];
}
