import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:equatable/equatable.dart';

sealed class DatasetQualityState extends Equatable {
  const DatasetQualityState();
  @override
  List<Object?> get props => [];
}

final class DatasetQualityInitial extends DatasetQualityState {
  const DatasetQualityInitial();
}

final class DatasetQualityLoading extends DatasetQualityState {
  final String message;
  const DatasetQualityLoading({this.message = 'Assessing dataset quality…'});
  @override
  List<Object?> get props => [message];
}

final class DatasetQualityLoaded extends DatasetQualityState {
  final DatasetQualityAssessmentReport report;
  final QualityGateThresholds thresholds;

  const DatasetQualityLoaded({
    required this.report,
    required this.thresholds,
  });

  @override
  List<Object?> get props => [report, thresholds];
}

final class DatasetQualityEmpty extends DatasetQualityState {
  final QualityGateThresholds thresholds;
  final String message;

  const DatasetQualityEmpty({
    required this.thresholds,
    this.message = 'No sessions to assess',
  });

  @override
  List<Object?> get props => [thresholds, message];
}

final class DatasetQualityError extends DatasetQualityState {
  final Failure failure;
  final DatasetQualityAssessmentReport? report;
  final QualityGateThresholds thresholds;

  const DatasetQualityError({
    required this.failure,
    required this.thresholds,
    this.report,
  });

  @override
  List<Object?> get props => [failure, report, thresholds];
}
