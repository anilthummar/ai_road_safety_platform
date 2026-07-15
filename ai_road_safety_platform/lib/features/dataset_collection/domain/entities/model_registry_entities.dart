import 'package:equatable/equatable.dart';

/// Model family / task type in the local registry (Phase 13.2).
enum ModelTaskType {
  objectDetection,
  semanticSegmentation,
  classification,
  unknown,
}

extension ModelTaskTypeX on ModelTaskType {
  String get label => switch (this) {
        ModelTaskType.objectDetection => 'Object detection',
        ModelTaskType.semanticSegmentation => 'Semantic segmentation',
        ModelTaskType.classification => 'Classification',
        ModelTaskType.unknown => 'Unknown',
      };
}

/// Lifecycle status of a registered model version.
enum ModelStatus {
  draft,
  registered,
  active,
  archived,
  failed,
}

extension ModelStatusX on ModelStatus {
  String get label => switch (this) {
        ModelStatus.draft => 'Draft',
        ModelStatus.registered => 'Registered',
        ModelStatus.active => 'Active',
        ModelStatus.archived => 'Archived',
        ModelStatus.failed => 'Failed',
      };
}

/// Where the artifact originates.
enum ModelArtifactSource {
  bundledAsset,
  localFile,
  imported,
}

extension ModelArtifactSourceX on ModelArtifactSource {
  String get label => switch (this) {
        ModelArtifactSource.bundledAsset => 'Bundled asset',
        ModelArtifactSource.localFile => 'Local file',
        ModelArtifactSource.imported => 'Imported',
      };
}

/// Binary / sidecar artifact descriptor.
class ModelArtifact extends Equatable {
  final String id;
  final String fileName;
  final String? absolutePath;
  final String? assetPath;
  final int byteSize;
  final String? checksumSha256;
  final ModelArtifactSource source;
  final String mimeHint;

  const ModelArtifact({
    required this.id,
    required this.fileName,
    required this.source,
    this.absolutePath,
    this.assetPath,
    this.byteSize = 0,
    this.checksumSha256,
    this.mimeHint = 'application/octet-stream',
  });

  ModelArtifact copyWith({
    String? id,
    String? fileName,
    String? absolutePath,
    String? assetPath,
    int? byteSize,
    String? checksumSha256,
    ModelArtifactSource? source,
    String? mimeHint,
  }) {
    return ModelArtifact(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      absolutePath: absolutePath ?? this.absolutePath,
      assetPath: assetPath ?? this.assetPath,
      byteSize: byteSize ?? this.byteSize,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
      source: source ?? this.source,
      mimeHint: mimeHint ?? this.mimeHint,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'absolutePath': absolutePath,
        'assetPath': assetPath,
        'byteSize': byteSize,
        'checksumSha256': checksumSha256,
        'source': source.name,
        'mimeHint': mimeHint,
      };

  factory ModelArtifact.fromJson(Map<String, dynamic> json) {
    return ModelArtifact(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      absolutePath: json['absolutePath'] as String?,
      assetPath: json['assetPath'] as String?,
      byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
      checksumSha256: json['checksumSha256'] as String?,
      source: ModelArtifactSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => ModelArtifactSource.localFile,
      ),
      mimeHint: json['mimeHint'] as String? ?? 'application/octet-stream',
    );
  }

  @override
  List<Object?> get props => [
        id,
        fileName,
        absolutePath,
        assetPath,
        byteSize,
        checksumSha256,
        source,
        mimeHint,
      ];
}

/// Versioned model entry with metadata + artifacts.
class RegisteredModel extends Equatable {
  final String id;
  final String name;
  final String version;
  final ModelTaskType taskType;
  final ModelStatus status;
  final String description;
  final String framework;
  final String inputSpec;
  final String outputSpec;
  final List<String> labels;
  final String? labelsAssetPath;
  final List<ModelArtifact> artifacts;
  final Map<String, Object?> metrics;
  final Map<String, String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? parentVersionId;
  final String? notes;
  final bool isBundled;

  const RegisteredModel({
    required this.id,
    required this.name,
    required this.version,
    required this.taskType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.framework = 'tflite',
    this.inputSpec = '',
    this.outputSpec = '',
    this.labels = const [],
    this.labelsAssetPath,
    this.artifacts = const [],
    this.metrics = const {},
    this.tags = const {},
    this.createdBy = 'researcher',
    this.parentVersionId,
    this.notes,
    this.isBundled = false,
  });

  String get displayName => '$name · v$version';

  ModelArtifact? get primaryArtifact {
    for (final a in artifacts) {
      if (a.fileName.endsWith('.tflite') || a.mimeHint.contains('tflite')) {
        return a;
      }
    }
    return artifacts.isEmpty ? null : artifacts.first;
  }

  RegisteredModel copyWith({
    String? id,
    String? name,
    String? version,
    ModelTaskType? taskType,
    ModelStatus? status,
    String? description,
    String? framework,
    String? inputSpec,
    String? outputSpec,
    List<String>? labels,
    String? labelsAssetPath,
    List<ModelArtifact>? artifacts,
    Map<String, Object?>? metrics,
    Map<String, String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? parentVersionId,
    String? notes,
    bool? isBundled,
  }) {
    return RegisteredModel(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      taskType: taskType ?? this.taskType,
      status: status ?? this.status,
      description: description ?? this.description,
      framework: framework ?? this.framework,
      inputSpec: inputSpec ?? this.inputSpec,
      outputSpec: outputSpec ?? this.outputSpec,
      labels: labels ?? this.labels,
      labelsAssetPath: labelsAssetPath ?? this.labelsAssetPath,
      artifacts: artifacts ?? this.artifacts,
      metrics: metrics ?? this.metrics,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      parentVersionId: parentVersionId ?? this.parentVersionId,
      notes: notes ?? this.notes,
      isBundled: isBundled ?? this.isBundled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'taskType': taskType.name,
        'status': status.name,
        'description': description,
        'framework': framework,
        'inputSpec': inputSpec,
        'outputSpec': outputSpec,
        'labels': labels,
        'labelsAssetPath': labelsAssetPath,
        'artifacts': [for (final a in artifacts) a.toJson()],
        'metrics': metrics,
        'tags': tags,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'createdBy': createdBy,
        'parentVersionId': parentVersionId,
        'notes': notes,
        'isBundled': isBundled,
      };

  factory RegisteredModel.fromJson(Map<String, dynamic> json) {
    return RegisteredModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '0.0.0',
      taskType: ModelTaskType.values.firstWhere(
        (t) => t.name == json['taskType'],
        orElse: () => ModelTaskType.unknown,
      ),
      status: ModelStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ModelStatus.registered,
      ),
      description: json['description'] as String? ?? '',
      framework: json['framework'] as String? ?? 'tflite',
      inputSpec: json['inputSpec'] as String? ?? '',
      outputSpec: json['outputSpec'] as String? ?? '',
      labels: [
        for (final l in (json['labels'] as List? ?? const [])) l.toString(),
      ],
      labelsAssetPath: json['labelsAssetPath'] as String?,
      artifacts: [
        for (final a in (json['artifacts'] as List? ?? const []))
          ModelArtifact.fromJson(Map<String, dynamic>.from(a as Map)),
      ],
      metrics: Map<String, Object?>.from(json['metrics'] as Map? ?? const {}),
      tags: {
        for (final e in (json['tags'] as Map? ?? const {}).entries)
          e.key.toString(): e.value.toString(),
      },
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdBy: json['createdBy'] as String? ?? 'researcher',
      parentVersionId: json['parentVersionId'] as String?,
      notes: json['notes'] as String?,
      isBundled: json['isBundled'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        taskType,
        status,
        description,
        framework,
        inputSpec,
        outputSpec,
        labels,
        labelsAssetPath,
        artifacts,
        metrics,
        tags,
        createdAt,
        updatedAt,
        createdBy,
        parentVersionId,
        notes,
        isBundled,
      ];
}

/// Active deployment pointers per task family.
class ActiveModelPointers extends Equatable {
  final String? detectionModelId;
  final String? segmentationModelId;
  final String? classificationModelId;
  final DateTime updatedAt;

  const ActiveModelPointers({
    required this.updatedAt,
    this.detectionModelId,
    this.segmentationModelId,
    this.classificationModelId,
  });

  ActiveModelPointers copyWith({
    String? detectionModelId,
    String? segmentationModelId,
    String? classificationModelId,
    DateTime? updatedAt,
    bool clearDetection = false,
    bool clearSegmentation = false,
    bool clearClassification = false,
  }) {
    return ActiveModelPointers(
      detectionModelId: clearDetection
          ? null
          : (detectionModelId ?? this.detectionModelId),
      segmentationModelId: clearSegmentation
          ? null
          : (segmentationModelId ?? this.segmentationModelId),
      classificationModelId: clearClassification
          ? null
          : (classificationModelId ?? this.classificationModelId),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'detectionModelId': detectionModelId,
        'segmentationModelId': segmentationModelId,
        'classificationModelId': classificationModelId,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ActiveModelPointers.fromJson(Map<String, dynamic> json) {
    return ActiveModelPointers(
      detectionModelId: json['detectionModelId'] as String?,
      segmentationModelId: json['segmentationModelId'] as String?,
      classificationModelId: json['classificationModelId'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  List<Object?> get props => [
        detectionModelId,
        segmentationModelId,
        classificationModelId,
        updatedAt,
      ];
}

/// Full registry snapshot for UI.
class ModelRegistrySnapshot extends Equatable {
  final List<RegisteredModel> models;
  final ActiveModelPointers active;
  final DateTime generatedAt;

  const ModelRegistrySnapshot({
    required this.models,
    required this.active,
    required this.generatedAt,
  });

  int get activeCount =>
      models.where((m) => m.status == ModelStatus.active).length;

  int get bundledCount => models.where((m) => m.isBundled).length;

  int get totalBytes => models.fold<int>(
        0,
        (n, m) =>
            n + m.artifacts.fold<int>(0, (a, art) => a + art.byteSize),
      );

  @override
  List<Object?> get props => [models, active, generatedAt];
}

/// Seeds shipping bundled models into the registry.
class BundledModelCatalog {
  BundledModelCatalog._();

  static List<RegisteredModel> defaults({DateTime? now}) {
    final t = now ?? DateTime.now().toUtc();
    return [
      RegisteredModel(
        id: 'bundled-yolov8n',
        name: 'YOLOv8n Detection',
        version: '1.0.0',
        taskType: ModelTaskType.objectDetection,
        status: ModelStatus.registered,
        description: 'Bundled YOLO nano detector for road objects',
        framework: 'tflite',
        inputSpec: 'RGB · letterbox · float32',
        outputSpec: 'boxes · scores · classes',
        labelsAssetPath: 'assets/labels/coco_labels.txt',
        artifacts: const [
          ModelArtifact(
            id: 'art-yolo',
            fileName: 'yolov8n.tflite',
            assetPath: 'assets/models/yolov8n.tflite',
            source: ModelArtifactSource.bundledAsset,
            mimeHint: 'application/tflite',
          ),
        ],
        tags: const {'role': 'detection', 'size': 'nano'},
        createdAt: t,
        updatedAt: t,
        createdBy: 'system',
        isBundled: true,
      ),
      RegisteredModel(
        id: 'bundled-flood-seg',
        name: 'Flood Segmentation',
        version: '1.0.0',
        taskType: ModelTaskType.semanticSegmentation,
        status: ModelStatus.registered,
        description: 'Bundled flood water / hazard segmentation',
        framework: 'tflite',
        inputSpec: 'RGB · HxW · float32',
        outputSpec: 'per-pixel class map',
        labelsAssetPath: 'assets/labels/flood_seg_labels.txt',
        labels: const ['background', 'road', 'water', 'vehicle', 'obstacle'],
        artifacts: const [
          ModelArtifact(
            id: 'art-flood',
            fileName: 'flood_seg.tflite',
            assetPath: 'assets/models/flood_seg.tflite',
            source: ModelArtifactSource.bundledAsset,
            mimeHint: 'application/tflite',
          ),
        ],
        tags: const {'role': 'segmentation'},
        createdAt: t,
        updatedAt: t,
        createdBy: 'system',
        isBundled: true,
      ),
    ];
  }
}
