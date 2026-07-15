import 'package:equatable/equatable.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';

sealed class ActiveLearningEvent extends Equatable {
  const ActiveLearningEvent();
  @override
  List<Object?> get props => [];
}

class ActiveLearningLoad extends ActiveLearningEvent {
  const ActiveLearningLoad();
}

class ActiveLearningRefresh extends ActiveLearningEvent {
  const ActiveLearningRefresh();
}

class ActiveLearningRun extends ActiveLearningEvent {
  final List<String> sessionIds;
  final ActiveLearningStrategyConfig config;

  const ActiveLearningRun({
    this.sessionIds = const [],
    this.config = ActiveLearningStrategyConfig.defaults,
  });

  @override
  List<Object?> get props => [sessionIds, config];
}

class ActiveLearningDelete extends ActiveLearningEvent {
  final String selectionId;
  const ActiveLearningDelete(this.selectionId);
  @override
  List<Object?> get props => [selectionId];
}

class ActiveLearningCreateDemo extends ActiveLearningEvent {
  const ActiveLearningCreateDemo();
}
