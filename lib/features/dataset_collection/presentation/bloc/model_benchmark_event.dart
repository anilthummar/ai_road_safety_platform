import 'package:equatable/equatable.dart';

sealed class ModelBenchmarkEvent extends Equatable {
  const ModelBenchmarkEvent();
  @override
  List<Object?> get props => [];
}

class ModelBenchmarkLoad extends ModelBenchmarkEvent {
  const ModelBenchmarkLoad();
}

class ModelBenchmarkRefresh extends ModelBenchmarkEvent {
  const ModelBenchmarkRefresh();
}

class ModelBenchmarkRun extends ModelBenchmarkEvent {
  final String modelId;
  final List<String> sessionIds;
  final String? experimentRunId;
  final double iouThreshold;

  const ModelBenchmarkRun({
    required this.modelId,
    this.sessionIds = const [],
    this.experimentRunId,
    this.iouThreshold = 0.5,
  });

  @override
  List<Object?> get props =>
      [modelId, sessionIds, experimentRunId, iouThreshold];
}

class ModelBenchmarkDelete extends ModelBenchmarkEvent {
  final String reportId;
  const ModelBenchmarkDelete(this.reportId);
  @override
  List<Object?> get props => [reportId];
}

class ModelBenchmarkCreateDemo extends ModelBenchmarkEvent {
  const ModelBenchmarkCreateDemo();
}
