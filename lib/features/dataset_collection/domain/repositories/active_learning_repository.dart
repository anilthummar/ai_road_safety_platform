import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';

/// Smart sample selection for active learning (Phase 13.5).
abstract class ActiveLearningRepository {
  Future<Result<ActiveLearningSnapshot>> loadSnapshot();

  Future<Result<ActiveLearningSelection>> getSelection(String selectionId);

  /// Rank frames across [sessionIds] (all sessions if empty).
  Future<Result<ActiveLearningSelection>> runSelection({
    List<String> sessionIds = const [],
    ActiveLearningStrategyConfig config = ActiveLearningStrategyConfig.defaults,
  });

  Future<Result<void>> deleteSelection(String selectionId);

  Future<Result<ActiveLearningSelection>> createDemoSelection();
}
