import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/core/utils/use_case.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/repositories/active_learning_repository.dart';
import 'package:equatable/equatable.dart';

class LoadActiveLearningSnapshotUseCase
    extends UseCase<Result<ActiveLearningSnapshot>, NoParams> {
  final ActiveLearningRepository _repository;
  LoadActiveLearningSnapshotUseCase(this._repository);

  @override
  Future<Result<ActiveLearningSnapshot>> call(NoParams params) =>
      _repository.loadSnapshot();
}

class RunActiveLearningParams extends Equatable {
  final List<String> sessionIds;
  final ActiveLearningStrategyConfig config;

  const RunActiveLearningParams({
    this.sessionIds = const [],
    this.config = ActiveLearningStrategyConfig.defaults,
  });

  @override
  List<Object?> get props => [sessionIds, config];
}

class RunActiveLearningSelectionUseCase
    extends UseCase<Result<ActiveLearningSelection>, RunActiveLearningParams> {
  final ActiveLearningRepository _repository;
  RunActiveLearningSelectionUseCase(this._repository);

  @override
  Future<Result<ActiveLearningSelection>> call(RunActiveLearningParams params) =>
      _repository.runSelection(
        sessionIds: params.sessionIds,
        config: params.config,
      );
}

class DeleteActiveLearningParams extends Equatable {
  final String selectionId;
  const DeleteActiveLearningParams(this.selectionId);
  @override
  List<Object?> get props => [selectionId];
}

class DeleteActiveLearningSelectionUseCase
    extends UseCase<Result<void>, DeleteActiveLearningParams> {
  final ActiveLearningRepository _repository;
  DeleteActiveLearningSelectionUseCase(this._repository);

  @override
  Future<Result<void>> call(DeleteActiveLearningParams params) =>
      _repository.deleteSelection(params.selectionId);
}

class CreateDemoActiveLearningUseCase
    extends UseCase<Result<ActiveLearningSelection>, NoParams> {
  final ActiveLearningRepository _repository;
  CreateDemoActiveLearningUseCase(this._repository);

  @override
  Future<Result<ActiveLearningSelection>> call(NoParams params) =>
      _repository.createDemoSelection();
}
