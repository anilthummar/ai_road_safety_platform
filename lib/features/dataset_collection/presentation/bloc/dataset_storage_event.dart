import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:equatable/equatable.dart';

/// Dataset storage Bloc events (Phase 12.5).
sealed class DatasetStorageEvent extends Equatable {
  const DatasetStorageEvent();

  @override
  List<Object?> get props => [];
}

/// Persist image bytes.
final class DatasetStorageSaveImage extends DatasetStorageEvent {
  /// Params.
  final SaveImageParams params;

  /// Creates [DatasetStorageSaveImage].
  const DatasetStorageSaveImage(this.params);

  @override
  List<Object?> get props => [params];
}

/// Persist metadata JSON.
final class DatasetStorageSaveMetadata extends DatasetStorageEvent {
  /// Metadata.
  final FrameMetadata metadata;

  /// Creates [DatasetStorageSaveMetadata].
  const DatasetStorageSaveMetadata(this.metadata);

  @override
  List<Object?> get props => [metadata];
}

/// Load image.
final class DatasetStorageLoadImage extends DatasetStorageEvent {
  /// Session.
  final String sessionId;

  /// Frame number.
  final int frameNumber;

  /// Creates [DatasetStorageLoadImage].
  const DatasetStorageLoadImage({
    required this.sessionId,
    required this.frameNumber,
  });

  @override
  List<Object?> get props => [sessionId, frameNumber];
}

/// Load metadata.
final class DatasetStorageLoadMetadata extends DatasetStorageEvent {
  /// Session.
  final String sessionId;

  /// Frame number.
  final int frameNumber;

  /// Creates [DatasetStorageLoadMetadata].
  const DatasetStorageLoadMetadata({
    required this.sessionId,
    required this.frameNumber,
  });

  @override
  List<Object?> get props => [sessionId, frameNumber];
}

/// Delete session folder.
final class DatasetStorageDeleteSession extends DatasetStorageEvent {
  /// Session id.
  final String sessionId;

  /// Creates [DatasetStorageDeleteSession].
  const DatasetStorageDeleteSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Recalculate usage + folders.
final class DatasetStorageCalculateStorage extends DatasetStorageEvent {
  const DatasetStorageCalculateStorage();
}

/// Clear cache + temps.
final class DatasetStorageCleanupStorage extends DatasetStorageEvent {
  const DatasetStorageCleanupStorage();
}

/// Recover sessions (optional id).
final class DatasetStorageRecoverSession extends DatasetStorageEvent {
  /// Optional single session.
  final String? sessionId;

  /// Creates [DatasetStorageRecoverSession].
  const DatasetStorageRecoverSession({this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}
