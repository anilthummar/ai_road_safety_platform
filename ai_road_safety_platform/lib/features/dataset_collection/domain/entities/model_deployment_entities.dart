import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';
import 'package:equatable/equatable.dart';

/// Lifecycle of an edge deployment package (Phase 13.6).
enum DeploymentStatus {
  staged,
  active,
  rolledBack,
  failed,
  archived,
}

extension DeploymentStatusX on DeploymentStatus {
  String get label => switch (this) {
        DeploymentStatus.staged => 'Staged',
        DeploymentStatus.active => 'Active',
        DeploymentStatus.rolledBack => 'Rolled back',
        DeploymentStatus.failed => 'Failed',
        DeploymentStatus.archived => 'Archived',
      };
}

/// Packaged artifact entry inside a deployment directory.
class DeploymentArtifact extends Equatable {
  final String fileName;
  final String? absolutePath;
  final String? sourceAssetPath;
  final int byteSize;
  final String role;

  const DeploymentArtifact({
    required this.fileName,
    this.absolutePath,
    this.sourceAssetPath,
    this.byteSize = 0,
    this.role = 'model',
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'absolutePath': absolutePath,
        'sourceAssetPath': sourceAssetPath,
        'byteSize': byteSize,
        'role': role,
      };

  factory DeploymentArtifact.fromJson(Map<String, dynamic> json) {
    return DeploymentArtifact(
      fileName: json['fileName'] as String? ?? '',
      absolutePath: json['absolutePath'] as String?,
      sourceAssetPath: json['sourceAssetPath'] as String?,
      byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? 'model',
    );
  }

  @override
  List<Object?> get props =>
      [fileName, absolutePath, sourceAssetPath, byteSize, role];
}

/// Versioned edge package ready to activate / roll back.
class DeploymentPackage extends Equatable {
  final String id;
  final String modelId;
  final String modelVersion;
  final String displayName;
  final ModelTaskType taskType;
  final DeploymentStatus status;
  final List<DeploymentArtifact> artifacts;
  final String packageDir;
  final String? previousDeploymentId;
  final String? notes;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? rolledBackAt;

  const DeploymentPackage({
    required this.id,
    required this.modelId,
    required this.modelVersion,
    required this.displayName,
    required this.taskType,
    required this.status,
    required this.createdAt,
    this.artifacts = const [],
    this.packageDir = '',
    this.previousDeploymentId,
    this.notes,
    this.isDemo = false,
    this.activatedAt,
    this.rolledBackAt,
  });

  DeploymentArtifact? get primaryModelArtifact {
    for (final a in artifacts) {
      if (a.role == 'model' || a.fileName.endsWith('.tflite')) return a;
    }
    return artifacts.isEmpty ? null : artifacts.first;
  }

  /// Prefer filesystem package path; fall back to bundled asset for runtime.
  String? get resolvableModelPath =>
      primaryModelArtifact?.absolutePath ??
      primaryModelArtifact?.sourceAssetPath;

  DeploymentPackage copyWith({
    String? id,
    String? modelId,
    String? modelVersion,
    String? displayName,
    ModelTaskType? taskType,
    DeploymentStatus? status,
    List<DeploymentArtifact>? artifacts,
    String? packageDir,
    String? previousDeploymentId,
    String? notes,
    bool? isDemo,
    DateTime? createdAt,
    DateTime? activatedAt,
    DateTime? rolledBackAt,
    bool clearPrevious = false,
    bool clearActivatedAt = false,
    bool clearRolledBackAt = false,
  }) {
    return DeploymentPackage(
      id: id ?? this.id,
      modelId: modelId ?? this.modelId,
      modelVersion: modelVersion ?? this.modelVersion,
      displayName: displayName ?? this.displayName,
      taskType: taskType ?? this.taskType,
      status: status ?? this.status,
      artifacts: artifacts ?? this.artifacts,
      packageDir: packageDir ?? this.packageDir,
      previousDeploymentId: clearPrevious
          ? null
          : (previousDeploymentId ?? this.previousDeploymentId),
      notes: notes ?? this.notes,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt ?? this.createdAt,
      activatedAt:
          clearActivatedAt ? null : (activatedAt ?? this.activatedAt),
      rolledBackAt:
          clearRolledBackAt ? null : (rolledBackAt ?? this.rolledBackAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'modelId': modelId,
        'modelVersion': modelVersion,
        'displayName': displayName,
        'taskType': taskType.name,
        'status': status.name,
        'artifacts': [for (final a in artifacts) a.toJson()],
        'packageDir': packageDir,
        'previousDeploymentId': previousDeploymentId,
        'notes': notes,
        'isDemo': isDemo,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'activatedAt': activatedAt?.toUtc().toIso8601String(),
        'rolledBackAt': rolledBackAt?.toUtc().toIso8601String(),
      };

  factory DeploymentPackage.fromJson(Map<String, dynamic> json) {
    return DeploymentPackage(
      id: json['id'] as String? ?? '',
      modelId: json['modelId'] as String? ?? '',
      modelVersion: json['modelVersion'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      taskType: ModelTaskType.values.firstWhere(
        (t) => t.name == json['taskType'],
        orElse: () => ModelTaskType.unknown,
      ),
      status: DeploymentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DeploymentStatus.staged,
      ),
      artifacts: [
        for (final a in (json['artifacts'] as List? ?? const []))
          DeploymentArtifact.fromJson(Map<String, dynamic>.from(a as Map)),
      ],
      packageDir: json['packageDir'] as String? ?? '',
      previousDeploymentId: json['previousDeploymentId'] as String?,
      notes: json['notes'] as String?,
      isDemo: json['isDemo'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      activatedAt:
          DateTime.tryParse(json['activatedAt'] as String? ?? '')?.toUtc(),
      rolledBackAt:
          DateTime.tryParse(json['rolledBackAt'] as String? ?? '')?.toUtc(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        modelId,
        modelVersion,
        displayName,
        taskType,
        status,
        artifacts,
        packageDir,
        previousDeploymentId,
        notes,
        isDemo,
        createdAt,
        activatedAt,
        rolledBackAt,
      ];
}

/// Active edge package pointers per task family.
class ActiveDeploymentPointers extends Equatable {
  final String? detectionDeploymentId;
  final String? segmentationDeploymentId;
  final String? classificationDeploymentId;
  final DateTime updatedAt;

  const ActiveDeploymentPointers({
    required this.updatedAt,
    this.detectionDeploymentId,
    this.segmentationDeploymentId,
    this.classificationDeploymentId,
  });

  ActiveDeploymentPointers copyWith({
    String? detectionDeploymentId,
    String? segmentationDeploymentId,
    String? classificationDeploymentId,
    DateTime? updatedAt,
    bool clearDetection = false,
    bool clearSegmentation = false,
    bool clearClassification = false,
  }) {
    return ActiveDeploymentPointers(
      detectionDeploymentId: clearDetection
          ? null
          : (detectionDeploymentId ?? this.detectionDeploymentId),
      segmentationDeploymentId: clearSegmentation
          ? null
          : (segmentationDeploymentId ?? this.segmentationDeploymentId),
      classificationDeploymentId: clearClassification
          ? null
          : (classificationDeploymentId ?? this.classificationDeploymentId),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String? idForTask(ModelTaskType task) => switch (task) {
        ModelTaskType.objectDetection => detectionDeploymentId,
        ModelTaskType.semanticSegmentation => segmentationDeploymentId,
        ModelTaskType.classification => classificationDeploymentId,
        ModelTaskType.unknown => null,
      };

  Map<String, dynamic> toJson() => {
        'detectionDeploymentId': detectionDeploymentId,
        'segmentationDeploymentId': segmentationDeploymentId,
        'classificationDeploymentId': classificationDeploymentId,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ActiveDeploymentPointers.fromJson(Map<String, dynamic> json) {
    return ActiveDeploymentPointers(
      detectionDeploymentId: json['detectionDeploymentId'] as String?,
      segmentationDeploymentId: json['segmentationDeploymentId'] as String?,
      classificationDeploymentId: json['classificationDeploymentId'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  @override
  List<Object?> get props => [
        detectionDeploymentId,
        segmentationDeploymentId,
        classificationDeploymentId,
        updatedAt,
      ];
}

/// Resolved runtime location for a deployed / fallback model.
class DeployedModelResolution extends Equatable {
  final ModelTaskType taskType;
  final String? deploymentId;
  final String? modelId;
  final String? filesystemPath;
  final String? assetPath;
  final bool usesBundledAsset;

  const DeployedModelResolution({
    required this.taskType,
    required this.usesBundledAsset,
    this.deploymentId,
    this.modelId,
    this.filesystemPath,
    this.assetPath,
  });

  String? get preferredPath => filesystemPath ?? assetPath;

  @override
  List<Object?> get props => [
        taskType,
        deploymentId,
        modelId,
        filesystemPath,
        assetPath,
        usesBundledAsset,
      ];
}

/// Dashboard aggregate for deployment manager.
class DeploymentSnapshot extends Equatable {
  final List<DeploymentPackage> packages;
  final ActiveDeploymentPointers active;
  final DateTime generatedAt;

  const DeploymentSnapshot({
    required this.packages,
    required this.active,
    required this.generatedAt,
  });

  int get totalCount => packages.length;

  int get activeCount =>
      packages.where((p) => p.status == DeploymentStatus.active).length;

  int get stagedCount =>
      packages.where((p) => p.status == DeploymentStatus.staged).length;

  DeploymentPackage? packageById(String id) {
    for (final p in packages) {
      if (p.id == id) return p;
    }
    return null;
  }

  DeploymentPackage? get latest {
    if (packages.isEmpty) return null;
    final sorted = [...packages]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  @override
  List<Object?> get props => [packages, active, generatedAt];
}
