import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/metadata_repository.dart';

/// Generates synchronized [FrameMetadata] for a captured frame.
class GenerateFrameMetadataUseCase
    extends UseCase<Result<FrameMetadata>, CapturedFrame> {
  final MetadataRepository _repository;

  /// Creates [GenerateFrameMetadataUseCase].
  GenerateFrameMetadataUseCase(this._repository);

  @override
  Future<Result<FrameMetadata>> call(CapturedFrame params) {
    return _repository.generateMetadata(params);
  }
}

/// Explicit synchronize alias (same pipeline).
class SynchronizeMetadataUseCase
    extends UseCase<Result<FrameMetadata>, CapturedFrame> {
  final MetadataRepository _repository;

  /// Creates [SynchronizeMetadataUseCase].
  SynchronizeMetadataUseCase(this._repository);

  @override
  Future<Result<FrameMetadata>> call(CapturedFrame params) {
    return _repository.synchronizeMetadata(params);
  }
}

/// Returns the latest in-memory metadata.
class GetCurrentMetadataUseCase
    extends UseCase<Result<FrameMetadata?>, NoParams> {
  final MetadataRepository _repository;

  /// Creates [GetCurrentMetadataUseCase].
  GetCurrentMetadataUseCase(this._repository);

  @override
  Future<Result<FrameMetadata?>> call(NoParams params) {
    return _repository.getLatestMetadata();
  }
}

/// Clears in-memory metadata.
class ClearMetadataUseCase extends UseCase<Result<void>, NoParams> {
  final MetadataRepository _repository;

  /// Creates [ClearMetadataUseCase].
  ClearMetadataUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.clearMetadata();
  }
}
