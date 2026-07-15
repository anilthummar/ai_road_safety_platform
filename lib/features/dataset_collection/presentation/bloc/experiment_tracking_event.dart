import 'package:equatable/equatable.dart';

sealed class ExperimentTrackingEvent extends Equatable {
  const ExperimentTrackingEvent();
  @override
  List<Object?> get props => [];
}

class ExperimentTrackingLoad extends ExperimentTrackingEvent {
  const ExperimentTrackingLoad();
}

class ExperimentTrackingRefresh extends ExperimentTrackingEvent {
  const ExperimentTrackingRefresh();
}

class ExperimentTrackingCreateDraft extends ExperimentTrackingEvent {
  final String name;
  final String experimentName;
  final String? modelId;
  final Map<String, String> params;

  const ExperimentTrackingCreateDraft({
    required this.name,
    this.experimentName = 'default',
    this.modelId,
    this.params = const {},
  });

  @override
  List<Object?> get props => [name, experimentName, modelId, params];
}

class ExperimentTrackingStart extends ExperimentTrackingEvent {
  final String runId;
  const ExperimentTrackingStart(this.runId);
  @override
  List<Object?> get props => [runId];
}

class ExperimentTrackingLogMetric extends ExperimentTrackingEvent {
  final String runId;
  final String key;
  final double value;
  final int step;

  const ExperimentTrackingLogMetric({
    required this.runId,
    required this.key,
    required this.value,
    this.step = 0,
  });

  @override
  List<Object?> get props => [runId, key, value, step];
}

class ExperimentTrackingComplete extends ExperimentTrackingEvent {
  final String runId;
  const ExperimentTrackingComplete(this.runId);
  @override
  List<Object?> get props => [runId];
}

class ExperimentTrackingFail extends ExperimentTrackingEvent {
  final String runId;
  const ExperimentTrackingFail(this.runId);
  @override
  List<Object?> get props => [runId];
}

class ExperimentTrackingCancel extends ExperimentTrackingEvent {
  final String runId;
  const ExperimentTrackingCancel(this.runId);
  @override
  List<Object?> get props => [runId];
}

class ExperimentTrackingDelete extends ExperimentTrackingEvent {
  final String runId;
  const ExperimentTrackingDelete(this.runId);
  @override
  List<Object?> get props => [runId];
}

class ExperimentTrackingCreateDemo extends ExperimentTrackingEvent {
  const ExperimentTrackingCreateDemo();
}
