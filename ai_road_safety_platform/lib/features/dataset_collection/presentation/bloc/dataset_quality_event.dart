import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:equatable/equatable.dart';

sealed class DatasetQualityEvent extends Equatable {
  const DatasetQualityEvent();
  @override
  List<Object?> get props => [];
}

final class DatasetQualityLoad extends DatasetQualityEvent {
  const DatasetQualityLoad();
}

final class DatasetQualityAssess extends DatasetQualityEvent {
  final String? sessionId;
  const DatasetQualityAssess({this.sessionId});
  @override
  List<Object?> get props => [sessionId];
}

final class DatasetQualityRefresh extends DatasetQualityEvent {
  const DatasetQualityRefresh();
}

final class DatasetQualityUpdateThresholds extends DatasetQualityEvent {
  final QualityGateThresholds thresholds;
  const DatasetQualityUpdateThresholds(this.thresholds);
  @override
  List<Object?> get props => [thresholds];
}

final class DatasetQualityEvaluateGate extends DatasetQualityEvent {
  const DatasetQualityEvaluateGate();
}
