import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_export_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_export_factory.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/export_document_generators.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/export_strategies.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/export_strategy.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_collection_entities.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemWriter implements ExportFileWriter {
  @override
  final String exportRoot;
  final Map<String, String> texts = {};
  final Set<String> dirs = {};

  _MemWriter(this.exportRoot);

  @override
  Future<String> ensureDir(String relativePath) async {
    dirs.add(relativePath);
    return '$exportRoot/$relativePath';
  }

  @override
  Future<void> writeText(String relativePath, String contents) async {
    texts[relativePath] = contents;
  }

  @override
  Future<void> writeBytes(String relativePath, List<int> bytes) async {}

  @override
  Future<void> copyFile(String sourcePath, String relativeDest) async {}

  @override
  Future<int> copyDirectory(String sourceDir, String relativeDest) async => 0;

  @override
  Future<bool> existsAbsolute(String path) async => false;

  @override
  Future<List<String>> listFiles(String absoluteDir) async => const [];

  @override
  Future<String> readAbsoluteText(String path) async => '';

  @override
  Future<List<int>> readAbsoluteBytes(String path) async => const [];
}

DatasetSession _session() {
  final now = DateTime.utc(2026, 7, 14);
  return DatasetSession(
    id: 's1',
    sessionName: 'Drive',
    description: '',
    createdAt: now,
    updatedAt: now,
    duration: const Duration(minutes: 3),
    status: DatasetSessionStatus.completed,
    frameCount: 30,
    floodEventCount: 2,
    totalStorage: 1024,
    averageSpeed: 20,
    averageConfidence: 0.8,
    averageFloodCoverage: 5,
    deviceName: 't',
    appVersion: '1',
    modelVersion: 'm1',
  );
}

void main() {
  final paths = const DatasetPaths(root: '/tmp/dataset');

  test('DatasetExportFactory creates strategies for every format', () {
    final factory = DatasetExportFactory(paths: () => paths);
    for (final f in ExportFormat.values) {
      expect(factory.create(f).format, f);
    }
  });

  test('JsonExportStrategy writes sessions + config', () async {
    final writer = _MemWriter('/tmp/export');
    final strategy = JsonExportStrategy(paths: () => paths);
    final result = await strategy.export(
      ExportContext(
        exportRoot: writer.exportRoot,
        settings: const ExportSettings(includeImages: false),
        sessions: [_session()],
        applicationVersion: '1.0.0',
        defaultModelVersion: 'm1',
      ),
      writer,
    );
    expect(writer.texts.containsKey('sessions/sessions.json'), isTrue);
    expect(writer.texts.containsKey('config/export_config.json'), isTrue);
    expect(result.notes, contains('JSON'));
  });

  test('CsvExportStrategy writes CSV header', () async {
    final writer = _MemWriter('/tmp/export');
    final strategy = CsvExportStrategy(paths: () => paths);
    await strategy.export(
      ExportContext(
        exportRoot: writer.exportRoot,
        settings: const ExportSettings(
          format: ExportFormat.csv,
          includeImages: false,
        ),
        sessions: [_session()],
        applicationVersion: '1.0.0',
        defaultModelVersion: 'm1',
      ),
      writer,
    );
    expect(writer.texts['sessions/sessions.csv'], contains('sessionName'));
  });

  test('YoloExportStrategy writes placeholder', () async {
    final writer = _MemWriter('/tmp/export');
    final strategy = YoloExportStrategy();
    final result = await strategy.export(
      ExportContext(
        exportRoot: writer.exportRoot,
        settings: const ExportSettings(format: ExportFormat.yolo),
        sessions: [_session()],
        applicationVersion: '1.0.0',
        defaultModelVersion: 'm1',
      ),
      writer,
    );
    expect(writer.texts.containsKey('yolo/PLACEHOLDER.md'), isTrue);
    expect(result.notes.toLowerCase(), contains('placeholder'));
  });

  test('manifest + readme generators', () {
    const manifestGen = ExportManifestGenerator();
    const readmeGen = ExportReadmeGenerator();
    final settings = const ExportSettings(datasetName: 'Demo');
    final sessions = [_session()];
    final manifest = manifestGen.build(
      settings: settings,
      sessions: sessions,
      imageCount: 10,
      metadataCount: 10,
      storageSizeBytes: 100,
      applicationVersion: '1.0.0',
      aiModelVersion: 'm1',
    );
    expect(manifest.sessionCount, 1);
    expect(manifest.frameCount, 30);
    final md = readmeGen.build(
      manifest: manifest,
      settings: settings,
      sessions: sessions,
    );
    expect(md, contains('Demo'));
    expect(md, contains('License'));
  });
}
