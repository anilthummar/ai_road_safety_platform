import 'dart:typed_data';

import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:equatable/equatable.dart';

/// Absolute / relative path helpers for the dataset tree (Phase 12.5).
class DatasetPaths extends Equatable {
  /// Root `…/dataset` folder.
  final String root;

  /// Creates [DatasetPaths].
  const DatasetPaths({required this.root});

  String get sessions => '$root/sessions';
  String get exports => '$root/exports';
  String get cache => '$root/cache';
  String get backups => '$root/backups';

  /// Local AI model registry & artifacts (Phase 13.2).
  String get models => '$root/models';

  String get modelVersions => '$models/versions';

  String get modelImported => '$models/imported';

  String modelVersionDir(String modelId) => '$modelVersions/$modelId';

  /// Local experiment tracking runs / params / metrics (Phase 13.3).
  String get experiments => '$root/experiments';

  /// Offline benchmark reports vs ground truth (Phase 13.4).
  String get benchmarks => '$root/benchmarks';

  /// Active learning smart sample selections (Phase 13.5).
  String get activeLearning => '$root/active_learning';

  /// Edge deployment packages / rollback pointers (Phase 13.6).
  String get deployments => '$root/deployments';

  String get deploymentPackages => '$deployments/packages';

  String deploymentPackageDir(String deploymentId) =>
      '$deploymentPackages/$deploymentId';

  /// Sensor fusion sessions / sample buffer (Phase 13.7).
  String get sensorFusion => '$root/sensor_fusion';

  String session(String sessionId) => '$sessions/$sessionId';

  String imagesOriginal(String sessionId) =>
      '${session(sessionId)}/images/original';

  String imagesCompressed(String sessionId) =>
      '${session(sessionId)}/images/compressed';

  String imagesThumbnails(String sessionId) =>
      '${session(sessionId)}/images/thumbnails';

  String frameMetadataDir(String sessionId) =>
      '${session(sessionId)}/metadata/frame_metadata';

  String sessionMetadataDir(String sessionId) =>
      '${session(sessionId)}/metadata/session_metadata';

  String previews(String sessionId) => '${session(sessionId)}/previews';

  String temp(String sessionId) => '${session(sessionId)}/temp';

  String logs(String sessionId) => '${session(sessionId)}/logs';

  /// Zero-padded frame file stem, e.g. `frame_000001`.
  static String frameStem(int frameNumber) =>
      'frame_${frameNumber.toString().padLeft(6, '0')}';

  /// Original JPEG filename.
  static String originalFileName(int frameNumber) =>
      '${frameStem(frameNumber)}.jpg';

  /// Compressed JPEG filename.
  static String compressedFileName(int frameNumber) =>
      '${frameStem(frameNumber)}.jpg';

  /// Thumbnail JPEG filename.
  static String thumbnailFileName(int frameNumber) =>
      '${frameStem(frameNumber)}.jpg';

  /// Frame metadata JSON filename.
  static String frameMetadataFileName(int frameNumber) =>
      '${frameStem(frameNumber)}.json';

  @override
  List<Object?> get props => [root];
}

/// Result of persisting an image triad (original / compressed / thumbnail).
class SavedImagePaths extends Equatable {
  /// Session id.
  final String sessionId;

  /// Frame number used in filenames.
  final int frameNumber;

  /// Absolute original path.
  final String originalPath;

  /// Absolute compressed path.
  final String compressedPath;

  /// Absolute thumbnail path.
  final String thumbnailPath;

  /// Bytes written for original.
  final int originalBytes;

  /// Creates [SavedImagePaths].
  const SavedImagePaths({
    required this.sessionId,
    required this.frameNumber,
    required this.originalPath,
    required this.compressedPath,
    required this.thumbnailPath,
    required this.originalBytes,
  });

  @override
  List<Object?> get props => [
        sessionId,
        frameNumber,
        originalPath,
        compressedPath,
        thumbnailPath,
        originalBytes,
      ];
}

/// Input for [DatasetStorageRepository.saveImage].
class SaveImageParams extends Equatable {
  /// Target session.
  final String sessionId;

  /// Monotonic frame number (filename source — never timestamps).
  final int frameNumber;

  /// Encoded image bytes (JPEG/PNG/raw RGBA — re-encoded as JPEG).
  final Uint8List bytes;

  /// Source width hint (0 = decode from bytes).
  final int width;

  /// Source height hint.
  final int height;

  /// Creates [SaveImageParams].
  const SaveImageParams({
    required this.sessionId,
    required this.frameNumber,
    required this.bytes,
    this.width = 0,
    this.height = 0,
  });

  @override
  List<Object?> get props => [sessionId, frameNumber, bytes, width, height];
}

/// Input for saving frame metadata JSON.
class SaveMetadataParams extends Equatable {
  /// Metadata payload.
  final FrameMetadata metadata;

  /// Creates [SaveMetadataParams].
  const SaveMetadataParams(this.metadata);

  @override
  List<Object?> get props => [metadata];
}

/// Aggregated disk usage for the dataset root.
class StorageUsage extends Equatable {
  /// Dataset root absolute path.
  final String datasetRoot;

  /// Bytes under dataset root.
  final int usedBytes;

  /// Device free bytes when known; else `0`.
  final int freeBytes;

  /// Device total bytes when known; else `0`.
  final int totalBytes;

  /// Soft capacity budget for datasets (warn when [usedBytes] exceeds).
  final int softLimitBytes;

  /// True when free space or soft budget is critically low.
  final bool isLowStorage;

  /// Human warning when [isLowStorage].
  final String? warningMessage;

  /// Creates [StorageUsage].
  const StorageUsage({
    required this.datasetRoot,
    required this.usedBytes,
    required this.freeBytes,
    required this.totalBytes,
    required this.softLimitBytes,
    required this.isLowStorage,
    this.warningMessage,
  });

  /// Fill ratio against soft limit \[0–1\].
  double get softFillRatio {
    if (softLimitBytes <= 0) return 0;
    return (usedBytes / softLimitBytes).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        datasetRoot,
        usedBytes,
        freeBytes,
        totalBytes,
        softLimitBytes,
        isLowStorage,
        warningMessage,
      ];
}

/// Session recovery scan result.
class SessionRecoveryInfo extends Equatable {
  /// Session folder id.
  final String sessionId;

  /// Absolute session path.
  final String sessionPath;

  /// Count of original images found.
  final int imageCount;

  /// Count of frame metadata JSON files.
  final int metadataCount;

  /// True when images/metadata counts mismatch or temp leftover present.
  final bool isIncomplete;

  /// Human notes.
  final List<String> notes;

  /// Creates [SessionRecoveryInfo].
  const SessionRecoveryInfo({
    required this.sessionId,
    required this.sessionPath,
    required this.imageCount,
    required this.metadataCount,
    required this.isIncomplete,
    this.notes = const [],
  });

  @override
  List<Object?> get props => [
        sessionId,
        sessionPath,
        imageCount,
        metadataCount,
        isIncomplete,
        notes,
      ];
}

/// Folder listing card for developer UI.
class FolderInfo extends Equatable {
  /// Display label.
  final String label;

  /// Absolute path.
  final String path;

  /// Byte size.
  final int sizeBytes;

  /// File count (non-recursive if noted).
  final int fileCount;

  /// Creates [FolderInfo].
  const FolderInfo({
    required this.label,
    required this.path,
    required this.sizeBytes,
    required this.fileCount,
  });

  @override
  List<Object?> get props => [label, path, sizeBytes, fileCount];
}

/// Recent file row for UI.
class RecentStorageFile extends Equatable {
  /// Absolute path.
  final String path;

  /// File name.
  final String name;

  /// Size bytes.
  final int sizeBytes;

  /// Modified time.
  final DateTime modifiedAt;

  /// Creates [RecentStorageFile].
  const RecentStorageFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  @override
  List<Object?> get props => [path, name, sizeBytes, modifiedAt];
}
