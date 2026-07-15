import 'dart:async';

import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_capture_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/frame_metadata_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/frame_capture_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/metadata_repository.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/usecases/metadata_usecases.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/metadata_event.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/presentation/bloc/metadata_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'metadata_event.dart';
export 'metadata_state.dart';

/// Orchestrates per-frame metadata synchronization (Phase 12.4).
class MetadataBloc extends Bloc<MetadataEvent, MetadataState> {
  final GenerateFrameMetadataUseCase _generate;
  final ClearMetadataUseCase _clear;
  final MetadataRepository _repository;
  final FrameCaptureRepository _frames;
  final AppLogger _logger;

  StreamSubscription<CapturedFrame>? _frameSub;
  FrameMetadata? _latest;

  /// Creates [MetadataBloc].
  MetadataBloc({
    required GenerateFrameMetadataUseCase generateFrameMetadata,
    required ClearMetadataUseCase clearMetadata,
    required MetadataRepository repository,
    required FrameCaptureRepository frameCaptureRepository,
    required AppLogger logger,
  })  : _generate = generateFrameMetadata,
        _clear = clearMetadata,
        _repository = repository,
        _frames = frameCaptureRepository,
        _logger = logger,
        super(MetadataInitial(sensors: repository.sensorStatus)) {
    on<MetadataGenerateRequested>(_onGenerate);
    on<MetadataGeneratedEvent>(_onGenerated);
    on<MetadataClearRequested>(_onClear);
    on<MetadataRefreshSensorStatus>(_onRefreshSensors);

    _frameSub = _frames.watchCapturedFrames().listen((frame) {
      add(MetadataGenerateRequested(frame));
    });
  }

  Future<void> _onGenerate(
    MetadataGenerateRequested event,
    Emitter<MetadataState> emit,
  ) async {
    emit(
      MetadataGenerating(
        frameId: event.frame.frameId,
        latest: _latest,
        sensors: _repository.sensorStatus,
      ),
    );
    final result = await _generate(event.frame);
    await result.fold(
      onOk: (metadata) async {
        _latest = metadata;
        emit(
          MetadataGenerated(
            metadata: metadata,
            sensors: _repository.sensorStatus,
          ),
        );
      },
      onErr: (failure) async {
        _logger.warning(failure.message, tag: 'MetadataBloc');
        emit(
          MetadataError(failure, sensors: _repository.sensorStatus),
        );
      },
    );
  }

  void _onGenerated(
    MetadataGeneratedEvent event,
    Emitter<MetadataState> emit,
  ) {
    _latest = event.metadata;
    emit(
      MetadataGenerated(
        metadata: event.metadata,
        sensors: _repository.sensorStatus,
      ),
    );
  }

  Future<void> _onClear(
    MetadataClearRequested event,
    Emitter<MetadataState> emit,
  ) async {
    final result = await _clear(const NoParams());
    await result.fold(
      onOk: (_) async {
        _latest = null;
        emit(MetadataInitial(sensors: _repository.sensorStatus));
      },
      onErr: (failure) async {
        emit(MetadataError(failure, sensors: _repository.sensorStatus));
      },
    );
  }

  void _onRefreshSensors(
    MetadataRefreshSensorStatus event,
    Emitter<MetadataState> emit,
  ) {
    final sensors = _repository.sensorStatus;
    final current = state;
    if (current is MetadataGenerated) {
      emit(MetadataGenerated(metadata: current.metadata, sensors: sensors));
    } else if (current is MetadataGenerating) {
      emit(
        MetadataGenerating(
          frameId: current.frameId,
          latest: current.latest,
          sensors: sensors,
        ),
      );
    } else if (current is MetadataError) {
      emit(MetadataError(current.failure, sensors: sensors));
    } else {
      emit(MetadataInitial(sensors: sensors));
    }
  }

  @override
  Future<void> close() async {
    await _frameSub?.cancel();
    return super.close();
  }
}
