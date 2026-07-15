import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';

/// Builds `manifest.json` payloads.
class ExportManifestGenerator {
  /// Creates [ExportManifestGenerator].
  const ExportManifestGenerator();

  /// Builds a manifest from sessions + counts.
  ExportManifest build({
    required ExportSettings settings,
    required List<DatasetSession> sessions,
    required int imageCount,
    required int metadataCount,
    required int storageSizeBytes,
    required String applicationVersion,
    required String aiModelVersion,
    DateTime? exportDate,
  }) {
    final frames =
        sessions.fold<int>(0, (a, s) => a + s.frameCount);
    return ExportManifest(
      datasetName: settings.datasetName,
      exportDate: exportDate ?? DateTime.now().toUtc(),
      exportVersion: '12.8.0',
      sessionCount: sessions.length,
      frameCount: frames,
      imageCount: imageCount,
      metadataCount: metadataCount,
      storageSizeBytes: storageSizeBytes,
      applicationVersion: applicationVersion,
      aiModelVersion: aiModelVersion,
      format: settings.format.pathTag,
      sessionIds: [for (final s in sessions) s.id],
    );
  }
}

/// Builds README.md for an export package.
class ExportReadmeGenerator {
  /// Creates [ExportReadmeGenerator].
  const ExportReadmeGenerator();

  /// Markdown README body.
  String build({
    required ExportManifest manifest,
    required ExportSettings settings,
    required List<DatasetSession> sessions,
  }) {
    final structure = '''
```
Export/
  ${settings.datasetName}/
    images/
    metadata/
    statistics/
    sessions/
    config/
    README.md
    manifest.json
```
''';

    final sessionLines = sessions.isEmpty
        ? '- (none)'
        : sessions
            .take(20)
            .map(
              (s) =>
                  '- **${s.sessionName}** (`${s.id}`) · '
                  '${s.frameCount} frames · ${s.status.label}',
            )
            .join('\n');

    return '''
# ${manifest.datasetName}

Research dataset export from **AI Road Safety Platform**.

## Dataset description

Offline corpus of road-driving capture sessions including frames, synchronized
metadata, and aggregate statistics intended for flood / hazard perception
research.

## Folder structure

$structure

## Supported formats

- Active: JSON, CSV, ZIP
- Placeholders (structure only): YOLO, COCO, Pascal VOC, Label Studio, CVAT, Roboflow

**This package format:** `${manifest.format}`

## Session summary

- Sessions: ${manifest.sessionCount}
- Frames: ${manifest.frameCount}
- Images exported: ${manifest.imageCount}
- Metadata files: ${manifest.metadataCount}
- Storage size (bytes): ${manifest.storageSizeBytes}

### Sessions

$sessionLines

## Statistics

See `statistics/statistics.json` for computed aggregates.

## License

License placeholder — replace with your research / data-sharing agreement.

## Research notes

- Export version: ${manifest.exportVersion}
- Application: ${manifest.applicationVersion}
- Model tag: ${manifest.aiModelVersion}
- Generated (UTC): ${manifest.exportDate.toIso8601String()}
- Include images: ${settings.includeImages}
- Include metadata: ${settings.includeMetadata}
- Compressed: ${settings.compressOutput}

---
Generated automatically by Phase 12.8 Research Dataset Export Engine.
''';
  }
}
