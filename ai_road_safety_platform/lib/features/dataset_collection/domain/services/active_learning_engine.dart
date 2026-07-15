import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/active_learning_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';

/// Ranks frames for annotation priority (Phase 13.5).
class ActiveLearningEngine {
  const ActiveLearningEngine();

  /// Corpus label frequencies (count / total annotations).
  Map<String, double> labelFrequencies(
    Iterable<ActiveLearningFrameInput> frames,
  ) {
    final counts = <String, int>{};
    var total = 0;
    for (final f in frames) {
      for (final id in f.labelIds) {
        if (id.isEmpty) continue;
        counts[id] = (counts[id] ?? 0) + 1;
        total++;
      }
    }
    if (total == 0) return const {};
    return {
      for (final e in counts.entries) e.key: e.value / total,
    };
  }

  Set<String> rareLabels(
    Map<String, double> frequencies, {
    required double maxRatio,
  }) {
    return {
      for (final e in frequencies.entries)
        if (e.value <= maxRatio) e.key,
    };
  }

  ActiveLearningFrameInput fromGroundTruth(GroundTruth gt) {
    final ai = gt.annotations.where((a) => a.fromAi).toList();
    final human = gt.annotations.where((a) => !a.fromAi).toList();
    double? minConf;
    for (final a in ai) {
      final c = a.aiConfidence;
      if (c == null) continue;
      minConf = minConf == null ? c : (c < minConf ? c : minConf);
    }
    return ActiveLearningFrameInput(
      sessionId: gt.sessionId,
      frameNumber: gt.frameNumber,
      imagePath: gt.imagePath,
      frameStatus: gt.frameStatus.name,
      annotationCount: gt.annotations.length,
      aiAnnotationCount: ai.length,
      humanAnnotationCount: human.length,
      minAiConfidence: minConf,
      labelIds: [for (final a in gt.annotations) a.labelId],
    );
  }

  ActiveLearningFrameInput fromAnnotatableFrame(AnnotatableFrame frame) {
    return ActiveLearningFrameInput(
      sessionId: frame.sessionId,
      frameNumber: frame.frameNumber,
      imagePath: frame.imagePath,
      frameStatus: frame.status.name,
      annotationCount: frame.annotationCount,
      humanAnnotationCount: frame.annotationCount,
    );
  }

  SampleCandidate scoreFrame({
    required ActiveLearningFrameInput frame,
    required ActiveLearningStrategyConfig config,
    required Set<String> rareLabelIds,
  }) {
    var score = 0.0;
    final reasons = <SamplePriorityReason>[];

    final unlabeled = frame.annotationCount == 0 ||
        frame.frameStatus == AnnotationStatus.unannotated.name;
    if (unlabeled) {
      score += config.unlabeledWeight;
      reasons.add(SamplePriorityReason.unlabeled);
    }

    if (frame.frameStatus == AnnotationStatus.needsReview.name) {
      score += config.needsReviewWeight;
      reasons.add(SamplePriorityReason.needsReview);
    }

    if (frame.frameStatus == AnnotationStatus.rejected.name) {
      score += config.rejectedWeight;
      reasons.add(SamplePriorityReason.rejected);
    }

    if (!unlabeled &&
        frame.aiAnnotationCount > 0 &&
        frame.humanAnnotationCount == 0) {
      score += config.aiDraftWeight;
      reasons.add(SamplePriorityReason.aiDraftOnly);
    }

    final minConf = frame.minAiConfidence;
    if (minConf != null && minConf < config.confidenceThreshold) {
      final factor =
          ((config.confidenceThreshold - minConf) / config.confidenceThreshold)
              .clamp(0.0, 1.0);
      score += config.lowConfidenceWeight * factor;
      reasons.add(SamplePriorityReason.lowConfidence);
    }

    if (frame.frameStatus == AnnotationStatus.draft.name && !unlabeled) {
      score += config.draftWeight;
      if (!reasons.contains(SamplePriorityReason.mixedDraft)) {
        reasons.add(SamplePriorityReason.mixedDraft);
      }
    }

    final rareHit = [
      for (final id in frame.labelIds)
        if (rareLabelIds.contains(id)) id,
    ];
    if (rareHit.isNotEmpty) {
      score += config.rareLabelWeight;
      reasons.add(SamplePriorityReason.rareLabel);
    }

    if (score > 100) score = 100;
    if (score < 0) score = 0;

    return SampleCandidate(
      sessionId: frame.sessionId,
      frameNumber: frame.frameNumber,
      imagePath: frame.imagePath,
      score: score,
      reasons: reasons,
      annotationCount: frame.annotationCount,
      aiAnnotationCount: frame.aiAnnotationCount,
      humanAnnotationCount: frame.humanAnnotationCount,
      minAiConfidence: frame.minAiConfidence,
      frameStatus: frame.frameStatus,
      rareLabelIds: rareHit.toSet().toList(),
    );
  }

  /// Score all frames, keep those with score > 0, sort desc, take [topK].
  List<SampleCandidate> rank({
    required List<ActiveLearningFrameInput> frames,
    ActiveLearningStrategyConfig config = ActiveLearningStrategyConfig.defaults,
  }) {
    final freqs = labelFrequencies(frames);
    final rare = rareLabels(freqs, maxRatio: config.rareLabelMaxRatio);
    final ranked = [
      for (final f in frames)
        scoreFrame(frame: f, config: config, rareLabelIds: rare),
    ].where((c) => c.score > 0).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        final bySession = a.sessionId.compareTo(b.sessionId);
        if (bySession != 0) return bySession;
        return a.frameNumber.compareTo(b.frameNumber);
      });

    final k = config.topK <= 0 ? ranked.length : config.topK;
    return ranked.take(k).toList();
  }
}
