import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_registry_entities.dart';

/// Validation issues for model metadata / artifacts.
class ModelValidationIssue {
  final String code;
  final String message;

  const ModelValidationIssue({required this.code, required this.message});
}

/// Validates registry entries before persist / activate.
class ModelRegistryValidator {
  const ModelRegistryValidator();

  List<ModelValidationIssue> validate(RegisteredModel model) {
    final issues = <ModelValidationIssue>[];
    if (model.id.trim().isEmpty) {
      issues.add(
        const ModelValidationIssue(
          code: 'missing_id',
          message: 'Model id is required',
        ),
      );
    }
    if (model.name.trim().isEmpty) {
      issues.add(
        const ModelValidationIssue(
          code: 'missing_name',
          message: 'Model name is required',
        ),
      );
    }
    if (model.version.trim().isEmpty) {
      issues.add(
        const ModelValidationIssue(
          code: 'missing_version',
          message: 'Semantic version is required',
        ),
      );
    }
    if (model.artifacts.isEmpty) {
      issues.add(
        const ModelValidationIssue(
          code: 'missing_artifact',
          message: 'At least one artifact is required',
        ),
      );
    }
    for (final a in model.artifacts) {
      if (a.assetPath == null &&
          (a.absolutePath == null || a.absolutePath!.isEmpty)) {
        issues.add(
          ModelValidationIssue(
            code: 'artifact_path',
            message: 'Artifact ${a.fileName} has no path',
          ),
        );
      }
    }
    return issues;
  }
}
