import 'package:equatable/equatable.dart';

/// Why a frame was prioritized for annotation (Phase 13.5).
enum SamplePriorityReason {
  unlabeled,
  aiDraftOnly,
  lowConfidence,
  needsReview,
  rareLabel,
  rejected,
  mixedDraft,
}

extension SamplePriorityReasonX on SamplePriorityReason {
  String get label => switch (this) {
        SamplePriorityReason.unlabeled => 'Unlabeled',
        SamplePriorityReason.aiDraftOnly => 'AI draft only',
        SamplePriorityReason.lowConfidence => 'Low AI confidence',
        SamplePriorityReason.needsReview => 'Needs review',
        SamplePriorityReason.rareLabel => 'Rare label',
        SamplePriorityReason.rejected => 'Rejected',
        SamplePriorityReason.mixedDraft => 'Draft / incomplete',
      };
}

/// Tunable weights for smart sample selection.
class ActiveLearningStrategyConfig extends Equatable {
  final double unlabeledWeight;
  final double aiDraftWeight;
  final double lowConfidenceWeight;
  final double needsReviewWeight;
  final double rareLabelWeight;
  final double rejectedWeight;
  final double draftWeight;
  final double confidenceThreshold;
  final double rareLabelMaxRatio;
  final int topK;

  const ActiveLearningStrategyConfig({
    this.unlabeledWeight = 40,
    this.aiDraftWeight = 22,
    this.lowConfidenceWeight = 28,
    this.needsReviewWeight = 26,
    this.rareLabelWeight = 18,
    this.rejectedWeight = 20,
    this.draftWeight = 12,
    this.confidenceThreshold = 0.55,
    this.rareLabelMaxRatio = 0.08,
    this.topK = 25,
  });

  static const ActiveLearningStrategyConfig defaults =
      ActiveLearningStrategyConfig();

  Map<String, dynamic> toJson() => {
        'unlabeledWeight': unlabeledWeight,
        'aiDraftWeight': aiDraftWeight,
        'lowConfidenceWeight': lowConfidenceWeight,
        'needsReviewWeight': needsReviewWeight,
        'rareLabelWeight': rareLabelWeight,
        'rejectedWeight': rejectedWeight,
        'draftWeight': draftWeight,
        'confidenceThreshold': confidenceThreshold,
        'rareLabelMaxRatio': rareLabelMaxRatio,
        'topK': topK,
      };

  factory ActiveLearningStrategyConfig.fromJson(Map<String, dynamic> json) {
    return ActiveLearningStrategyConfig(
      unlabeledWeight: (json['unlabeledWeight'] as num?)?.toDouble() ?? 40,
      aiDraftWeight: (json['aiDraftWeight'] as num?)?.toDouble() ?? 22,
      lowConfidenceWeight:
          (json['lowConfidenceWeight'] as num?)?.toDouble() ?? 28,
      needsReviewWeight: (json['needsReviewWeight'] as num?)?.toDouble() ?? 26,
      rareLabelWeight: (json['rareLabelWeight'] as num?)?.toDouble() ?? 18,
      rejectedWeight: (json['rejectedWeight'] as num?)?.toDouble() ?? 20,
      draftWeight: (json['draftWeight'] as num?)?.toDouble() ?? 12,
      confidenceThreshold:
          (json['confidenceThreshold'] as num?)?.toDouble() ?? 0.55,
      rareLabelMaxRatio: (json['rareLabelMaxRatio'] as num?)?.toDouble() ?? 0.08,
      topK: (json['topK'] as num?)?.toInt() ?? 25,
    );
  }

  @override
  List<Object?> get props => [
        unlabeledWeight,
        aiDraftWeight,
        lowConfidenceWeight,
        needsReviewWeight,
        rareLabelWeight,
        rejectedWeight,
        draftWeight,
        confidenceThreshold,
        rareLabelMaxRatio,
        topK,
      ];
}

/// Ranked frame suggested for labeling / review.
class SampleCandidate extends Equatable {
  final String sessionId;
  final int frameNumber;
  final String? imagePath;
  final double score;
  final List<SamplePriorityReason> reasons;
  final int annotationCount;
  final int aiAnnotationCount;
  final int humanAnnotationCount;
  final double? minAiConfidence;
  final String frameStatus;
  final List<String> rareLabelIds;

  const SampleCandidate({
    required this.sessionId,
    required this.frameNumber,
    required this.score,
    required this.reasons,
    required this.frameStatus,
    this.imagePath,
    this.annotationCount = 0,
    this.aiAnnotationCount = 0,
    this.humanAnnotationCount = 0,
    this.minAiConfidence,
    this.rareLabelIds = const [],
  });

  String get key => '$sessionId#$frameNumber';

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'frameNumber': frameNumber,
        'imagePath': imagePath,
        'score': score,
        'reasons': [for (final r in reasons) r.name],
        'annotationCount': annotationCount,
        'aiAnnotationCount': aiAnnotationCount,
        'humanAnnotationCount': humanAnnotationCount,
        'minAiConfidence': minAiConfidence,
        'frameStatus': frameStatus,
        'rareLabelIds': rareLabelIds,
      };

  factory SampleCandidate.fromJson(Map<String, dynamic> json) {
    return SampleCandidate(
      sessionId: json['sessionId'] as String? ?? '',
      frameNumber: (json['frameNumber'] as num?)?.toInt() ?? 0,
      imagePath: json['imagePath'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      reasons: [
        for (final r in (json['reasons'] as List? ?? const []))
          SamplePriorityReason.values.firstWhere(
            (e) => e.name == r.toString(),
            orElse: () => SamplePriorityReason.unlabeled,
          ),
      ],
      annotationCount: (json['annotationCount'] as num?)?.toInt() ?? 0,
      aiAnnotationCount: (json['aiAnnotationCount'] as num?)?.toInt() ?? 0,
      humanAnnotationCount:
          (json['humanAnnotationCount'] as num?)?.toInt() ?? 0,
      minAiConfidence: (json['minAiConfidence'] as num?)?.toDouble(),
      frameStatus: json['frameStatus'] as String? ?? 'unannotated',
      rareLabelIds: [
        for (final id in (json['rareLabelIds'] as List? ?? const []))
          id.toString(),
      ],
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        frameNumber,
        imagePath,
        score,
        reasons,
        annotationCount,
        aiAnnotationCount,
        humanAnnotationCount,
        minAiConfidence,
        frameStatus,
        rareLabelIds,
      ];
}

/// One smart-selection run with ranked candidates.
class ActiveLearningSelection extends Equatable {
  final String id;
  final List<String> sessionIds;
  final ActiveLearningStrategyConfig config;
  final List<SampleCandidate> candidates;
  final int framesConsidered;
  final Map<String, double> labelFrequencies;
  final String notes;
  final bool isDemo;
  final DateTime createdAt;

  const ActiveLearningSelection({
    required this.id,
    required this.config,
    required this.candidates,
    required this.createdAt,
    this.sessionIds = const [],
    this.framesConsidered = 0,
    this.labelFrequencies = const {},
    this.notes = '',
    this.isDemo = false,
  });

  int get selectedCount => candidates.length;

  double get topScore =>
      candidates.isEmpty ? 0 : candidates.first.score;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionIds': sessionIds,
        'config': config.toJson(),
        'candidates': [for (final c in candidates) c.toJson()],
        'framesConsidered': framesConsidered,
        'labelFrequencies': labelFrequencies,
        'notes': notes,
        'isDemo': isDemo,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory ActiveLearningSelection.fromJson(Map<String, dynamic> json) {
    final freqs = json['labelFrequencies'];
    return ActiveLearningSelection(
      id: json['id'] as String? ?? '',
      sessionIds: [
        for (final id in (json['sessionIds'] as List? ?? const []))
          id.toString(),
      ],
      config: json['config'] is Map
          ? ActiveLearningStrategyConfig.fromJson(
              Map<String, dynamic>.from(json['config'] as Map),
            )
          : ActiveLearningStrategyConfig.defaults,
      candidates: [
        for (final c in (json['candidates'] as List? ?? const []))
          SampleCandidate.fromJson(Map<String, dynamic>.from(c as Map)),
      ],
      framesConsidered: (json['framesConsidered'] as num?)?.toInt() ?? 0,
      labelFrequencies: freqs is Map
          ? {
              for (final e in freqs.entries)
                e.key.toString(): (e.value as num?)?.toDouble() ?? 0,
            }
          : const {},
      notes: json['notes'] as String? ?? '',
      isDemo: json['isDemo'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionIds,
        config,
        candidates,
        framesConsidered,
        labelFrequencies,
        notes,
        isDemo,
        createdAt,
      ];
}

/// Dashboard aggregate for active learning selections.
class ActiveLearningSnapshot extends Equatable {
  final List<ActiveLearningSelection> selections;
  final DateTime generatedAt;

  const ActiveLearningSnapshot({
    required this.selections,
    required this.generatedAt,
  });

  int get totalSelections => selections.length;

  int get totalCandidates =>
      selections.fold(0, (a, s) => a + s.candidates.length);

  ActiveLearningSelection? get latest {
    if (selections.isEmpty) return null;
    final sorted = [...selections]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  @override
  List<Object?> get props => [selections, generatedAt];
}

/// Per-frame scoring input for the engine.
class ActiveLearningFrameInput extends Equatable {
  final String sessionId;
  final int frameNumber;
  final String? imagePath;
  final String frameStatus;
  final int annotationCount;
  final int aiAnnotationCount;
  final int humanAnnotationCount;
  final double? minAiConfidence;
  final List<String> labelIds;

  const ActiveLearningFrameInput({
    required this.sessionId,
    required this.frameNumber,
    required this.frameStatus,
    this.imagePath,
    this.annotationCount = 0,
    this.aiAnnotationCount = 0,
    this.humanAnnotationCount = 0,
    this.minAiConfidence,
    this.labelIds = const [],
  });

  @override
  List<Object?> get props => [
        sessionId,
        frameNumber,
        imagePath,
        frameStatus,
        annotationCount,
        aiAnnotationCount,
        humanAnnotationCount,
        minAiConfidence,
        labelIds,
      ];
}
