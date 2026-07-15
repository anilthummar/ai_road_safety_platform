import 'dart:typed_data';

import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:equatable/equatable.dart';

/// Dataset storage presentation states (Phase 12.5).
sealed class DatasetStorageState extends Equatable {
  const DatasetStorageState();

  @override
  List<Object?> get props => [];
}

/// Idle.
final class DatasetStorageInitial extends DatasetStorageState {
  const DatasetStorageInitial();
}

/// Busy saving.
final class DatasetStorageSaving extends DatasetStorageState {
  /// Status text.
  final String message;

  /// Creates [DatasetStorageSaving].
  const DatasetStorageSaving({this.message = 'Saving…'});

  @override
  List<Object?> get props => [message];
}

/// Save completed.
final class DatasetStorageSaved extends DatasetStorageState {
  /// Optional image paths.
  final SavedImagePaths? imagePaths;

  /// Optional metadata path.
  final String? metadataPath;

  /// Message.
  final String message;

  /// Creates [DatasetStorageSaved].
  const DatasetStorageSaved({
    this.imagePaths,
    this.metadataPath,
    this.message = 'Saved',
  });

  @override
  List<Object?> get props => [imagePaths, metadataPath, message];
}

/// Busy loading.
final class DatasetStorageLoading extends DatasetStorageState {
  /// Status.
  final String message;

  /// Creates [DatasetStorageLoading].
  const DatasetStorageLoading({this.message = 'Loading…'});

  @override
  List<Object?> get props => [message];
}

/// Loaded image bytes.
final class DatasetStorageImageLoaded extends DatasetStorageState {
  /// Bytes.
  final Uint8List bytes;

  /// Creates [DatasetStorageImageLoaded].
  const DatasetStorageImageLoaded(this.bytes);

  @override
  List<Object?> get props => [bytes];
}

/// Loaded metadata.
final class DatasetStorageMetadataLoaded extends DatasetStorageState {
  /// Metadata.
  final FrameMetadata metadata;

  /// Creates [DatasetStorageMetadataLoaded].
  const DatasetStorageMetadataLoaded(this.metadata);

  @override
  List<Object?> get props => [metadata];
}

/// Busy deleting.
final class DatasetStorageDeleting extends DatasetStorageState {
  const DatasetStorageDeleting();
}

/// Recovery finished.
final class DatasetStorageRecovered extends DatasetStorageState {
  /// Recovery rows.
  final List<SessionRecoveryInfo> sessions;

  /// Creates [DatasetStorageRecovered].
  const DatasetStorageRecovered(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

/// Usage calculated (dashboard-ready).
final class DatasetStorageCalculated extends DatasetStorageState {
  /// Usage.
  final StorageUsage usage;

  /// Folder cards.
  final List<FolderInfo> folders;

  /// Recent files.
  final List<RecentStorageFile> recentFiles;

  /// Creates [DatasetStorageCalculated].
  const DatasetStorageCalculated({
    required this.usage,
    required this.folders,
    required this.recentFiles,
  });

  @override
  List<Object?> get props => [usage, folders, recentFiles];
}

/// Failure.
final class DatasetStorageError extends DatasetStorageState {
  /// Failure.
  final Failure failure;

  /// Creates [DatasetStorageError].
  const DatasetStorageError(this.failure);

  @override
  List<Object?> get props => [failure];
}
