import 'package:equatable/equatable.dart';

sealed class SensorFusionEvent extends Equatable {
  const SensorFusionEvent();
  @override
  List<Object?> get props => [];
}

class SensorFusionLoad extends SensorFusionEvent {
  const SensorFusionLoad();
}

class SensorFusionRefresh extends SensorFusionEvent {
  const SensorFusionRefresh();
}

class SensorFusionStart extends SensorFusionEvent {
  const SensorFusionStart();
}

class SensorFusionStop extends SensorFusionEvent {
  const SensorFusionStop();
}

class SensorFusionTick extends SensorFusionEvent {
  const SensorFusionTick();
}

class SensorFusionCreateDemo extends SensorFusionEvent {
  const SensorFusionCreateDemo();
}

class SensorFusionClear extends SensorFusionEvent {
  const SensorFusionClear();
}
