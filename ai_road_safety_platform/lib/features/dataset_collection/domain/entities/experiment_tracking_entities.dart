import 'package:equatable/equatable.dart';

/// Lifecycle of a local experiment run (Phase 13.3).
enum ExperimentRunStatus {
  draft,
  running,
  completed,
  failed,
  cancelled,
}

extension ExperimentRunStatusX on ExperimentRunStatus {
  String get label => switch (this) {
        ExperimentRunStatus.draft => 'Draft',
        ExperimentRunStatus.running => 'Running',
        ExperimentRunStatus.completed => 'Completed',
        ExperimentRunStatus.failed => 'Failed',
        ExperimentRunStatus.cancelled => 'Cancelled',
      };
}

/// How the run was created.
enum ExperimentRunSource {
  manual,
  pipeline,
  demo,
}

extension ExperimentRunSourceX on ExperimentRunSource {
  String get label => switch (this) {
        ExperimentRunSource.manual => 'Manual',
        ExperimentRunSource.pipeline => 'Pipeline',
        ExperimentRunSource.demo => 'Demo',
      };
}

/// Timed metric sample (supports step curves for later charts / benchmarks).
class ExperimentMetricPoint extends Equatable {
  final String key;
  final double value;
  final int step;
  final DateTime recordedAt;

  const ExperimentMetricPoint({
    required this.key,
    required this.value,
    required this.recordedAt,
    this.step = 0,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'step': step,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      };

  factory ExperimentMetricPoint.fromJson(Map<String, dynamic> json) {
    return ExperimentMetricPoint(
      key: json['key'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      step: (json['step'] as num?)?.toInt() ?? 0,
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props => [key, value, step, recordedAt];
}

/// One experiment run: hyperparameters + metrics + links to model / dataset.
class ExperimentRun extends Equatable {
  final String id;
  final String name;
  final String experimentName;
  final ExperimentRunStatus status;
  final ExperimentRunSource source;
  final String? modelId;
  final String? modelVersion;
  final List<String> datasetSessionIds;
  final Map<String, String> params;
  final Map<String, double> metrics;
  final List<ExperimentMetricPoint> metricHistory;
  final Map<String, String> tags;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const ExperimentRun({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.experimentName = 'default',
    this.status = ExperimentRunStatus.draft,
    this.source = ExperimentRunSource.manual,
    this.modelId,
    this.modelVersion,
    this.datasetSessionIds = const [],
    this.params = const {},
    this.metrics = const {},
    this.metricHistory = const [],
    this.tags = const {},
    this.notes = '',
    this.startedAt,
    this.endedAt,
  });

  String get displayName => name.trim().isEmpty ? id : name;

  Duration? get duration {
    final start = startedAt;
    if (start == null) return null;
    final end = endedAt ?? DateTime.now().toUtc();
    return end.difference(start);
  }

  ExperimentRun copyWith({
    String? id,
    String? name,
    String? experimentName,
    ExperimentRunStatus? status,
    ExperimentRunSource? source,
    String? modelId,
    String? modelVersion,
    List<String>? datasetSessionIds,
    Map<String, String>? params,
    Map<String, double>? metrics,
    List<ExperimentMetricPoint>? metricHistory,
    Map<String, String>? tags,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearModelId = false,
    bool clearModelVersion = false,
    bool clearStartedAt = false,
    bool clearEndedAt = false,
  }) {
    return ExperimentRun(
      id: id ?? this.id,
      name: name ?? this.name,
      experimentName: experimentName ?? this.experimentName,
      status: status ?? this.status,
      source: source ?? this.source,
      modelId: clearModelId ? null : (modelId ?? this.modelId),
      modelVersion:
          clearModelVersion ? null : (modelVersion ?? this.modelVersion),
      datasetSessionIds: datasetSessionIds ?? this.datasetSessionIds,
      params: params ?? this.params,
      metrics: metrics ?? this.metrics,
      metricHistory: metricHistory ?? this.metricHistory,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'experimentName': experimentName,
        'status': status.name,
        'source': source.name,
        'modelId': modelId,
        'modelVersion': modelVersion,
        'datasetSessionIds': datasetSessionIds,
        'params': params,
        'metrics': metrics,
        'metricHistory': [for (final p in metricHistory) p.toJson()],
        'tags': tags,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'startedAt': startedAt?.toUtc().toIso8601String(),
        'endedAt': endedAt?.toUtc().toIso8601String(),
      };

  factory ExperimentRun.fromJson(Map<String, dynamic> json) {
    final paramsRaw = json['params'];
    final metricsRaw = json['metrics'];
    final tagsRaw = json['tags'];
    final historyRaw = json['metricHistory'];
    return ExperimentRun(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      experimentName: json['experimentName'] as String? ?? 'default',
      status: ExperimentRunStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ExperimentRunStatus.draft,
      ),
      source: ExperimentRunSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => ExperimentRunSource.manual,
      ),
      modelId: json['modelId'] as String?,
      modelVersion: json['modelVersion'] as String?,
      datasetSessionIds: [
        for (final id in (json['datasetSessionIds'] as List? ?? const []))
          id.toString(),
      ],
      params: paramsRaw is Map
          ? {
              for (final e in paramsRaw.entries)
                e.key.toString(): e.value.toString(),
            }
          : const {},
      metrics: metricsRaw is Map
          ? {
              for (final e in metricsRaw.entries)
                e.key.toString(): (e.value as num?)?.toDouble() ?? 0,
            }
          : const {},
      metricHistory: [
        for (final item in (historyRaw as List? ?? const []))
          ExperimentMetricPoint.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
      ],
      tags: tagsRaw is Map
          ? {
              for (final e in tagsRaw.entries)
                e.key.toString(): e.value.toString(),
            }
          : const {},
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '')?.toUtc(),
      endedAt: DateTime.tryParse(json['endedAt'] as String? ?? '')?.toUtc(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        experimentName,
        status,
        source,
        modelId,
        modelVersion,
        datasetSessionIds,
        params,
        metrics,
        metricHistory,
        tags,
        notes,
        createdAt,
        updatedAt,
        startedAt,
        endedAt,
      ];
}

/// Dashboard aggregate for experiment tracking UI.
class ExperimentTrackerSnapshot extends Equatable {
  final List<ExperimentRun> runs;
  final DateTime generatedAt;

  const ExperimentTrackerSnapshot({
    required this.runs,
    required this.generatedAt,
  });

  int get totalCount => runs.length;

  int get runningCount =>
      runs.where((r) => r.status == ExperimentRunStatus.running).length;

  int get completedCount =>
      runs.where((r) => r.status == ExperimentRunStatus.completed).length;

  int get failedCount =>
      runs.where((r) => r.status == ExperimentRunStatus.failed).length;

  Set<String> get experimentNames => {
        for (final r in runs) r.experimentName,
      };

  ExperimentRun? get latestRun {
    if (runs.isEmpty) return null;
    final sorted = [...runs]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.first;
  }

  @override
  List<Object?> get props => [runs, generatedAt];
}
