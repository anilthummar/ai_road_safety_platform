import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:equatable/equatable.dart';

/// Metadata Bloc events (Phase 12.4).
sealed class MetadataEvent extends Equatable {
  const MetadataEvent();

  @override
  List<Object?> get props => [];
}

/// Request sync for a captured frame.
final class MetadataGenerateRequested extends MetadataEvent {
  /// Source frame.
  final CapturedFrame frame;

  /// Creates [MetadataGenerateRequested].
  const MetadataGenerateRequested(this.frame);

  @override
  List<Object?> get props => [frame];
}

/// Internal: metadata produced (also used for stream fan-out).
final class MetadataGeneratedEvent extends MetadataEvent {
  /// Built metadata.
  final FrameMetadata metadata;

  /// Creates [MetadataGeneratedEvent].
  const MetadataGeneratedEvent(this.metadata);

  @override
  List<Object?> get props => [metadata];
}

/// Clear in-memory buffer.
final class MetadataClearRequested extends MetadataEvent {
  const MetadataClearRequested();
}

/// Refresh sensor status card.
final class MetadataRefreshSensorStatus extends MetadataEvent {
  const MetadataRefreshSensorStatus();
}
