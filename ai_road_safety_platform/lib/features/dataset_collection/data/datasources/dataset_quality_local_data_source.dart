import 'dart:convert';
import 'dart:io';

import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/annotation_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_analytics_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_quality_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';
import 'package:path/path.dart' as p;

/// Local JSON persistence for quality assessments & thresholds.
abstract class DatasetQualityLocalDataSource {
  Future<QualityGateThresholds> loadThresholds();
  Future<void> saveThresholds(QualityGateThresholds thresholds);
  Future<DatasetQualityAssessmentReport?> loadLastReport();
  Future<void> saveReport(DatasetQualityAssessmentReport report);
}

class DatasetQualityLocalDataSourceImpl implements DatasetQualityLocalDataSource {
  final DatasetFileManager _files;
  final AppLogger _logger;

  DatasetQualityLocalDataSourceImpl({
    required DatasetFileManager fileManager,
    required AppLogger logger,
  })  : _files = fileManager,
        _logger = logger;

  Future<String> _qualityRoot() async {
    await _files.ensureRootLayout();
    final root = p.join(_files.paths.root, 'quality');
    await Directory(root).create(recursive: true);
    return root;
  }

  Future<String> _thresholdsPath() async =>
      p.join(await _qualityRoot(), 'gate_thresholds.json');

  Future<String> _lastReportPath() async =>
      p.join(await _qualityRoot(), 'last_assessment.json');

  @override
  Future<QualityGateThresholds> loadThresholds() async {
    final file = File(await _thresholdsPath());
    if (!await file.exists()) return QualityGateThresholds.defaults;
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map) return QualityGateThresholds.defaults;
      return QualityGateThresholds.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      _logger.warning('Thresholds load failed: $e', tag: 'DatasetQuality');
      return QualityGateThresholds.defaults;
    }
  }

  @override
  Future<void> saveThresholds(QualityGateThresholds thresholds) async {
    final file = File(await _thresholdsPath());
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(thresholds.toJson()),
    );
  }

  @override
  Future<DatasetQualityAssessmentReport?> loadLastReport() async {
    final file = File(await _lastReportPath());
    if (!await file.exists()) return null;
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map) return null;
      return _reportFromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      _logger.warning('Last report load failed: $e', tag: 'DatasetQuality');
      return null;
    }
  }

  @override
  Future<void> saveReport(DatasetQualityAssessmentReport report) async {
    final file = File(await _lastReportPath());
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report.toJson()),
    );
    _logger.info(
      'Quality report saved decision=${report.decision.name}',
      tag: 'DatasetQuality',
    );
  }

  DatasetQualityAssessmentReport _reportFromJson(Map<String, dynamic> json) {
    try {
      return DatasetQualityAssessmentReport(
        generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        thresholds: json['thresholds'] is Map
            ? QualityGateThresholds.fromJson(
                Map<String, dynamic>.from(json['thresholds'] as Map),
              )
            : QualityGateThresholds.defaults,
        decision: QualityGateDecision.values.firstWhere(
          (d) => d.name == json['decision'],
          orElse: () => QualityGateDecision.fail,
        ),
        overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0,
        trainingAllowed: json['trainingAllowed'] as bool? ?? false,
        gateSummary: json['gateSummary'] as String? ?? '',
        dimensions: [
          for (final d in (json['dimensions'] as List? ?? const []))
            DimensionScore.fromJson(Map<String, dynamic>.from(d as Map)),
        ],
        issues: [
          for (final i in (json['issues'] as List? ?? const []))
            QualityIssue.fromJson(Map<String, dynamic>.from(i as Map)),
        ],
        sessions: [
          for (final s in (json['sessions'] as List? ?? const []))
            SessionQualityAssessment.fromJson(
              Map<String, dynamic>.from(s as Map),
            ),
        ],
        labelCoverage: [
          for (final l in (json['labelCoverage'] as List? ?? const []))
            LabelCoverageStat.fromJson(Map<String, dynamic>.from(l as Map)),
        ],
        captureMetrics: const DatasetQualityMetrics.empty(),
        annotationMetrics: const AnnotationQualityMetrics.empty(),
        totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
        totalFrames: (json['totalFrames'] as num?)?.toInt() ?? 0,
        passSessions: (json['passSessions'] as num?)?.toInt() ?? 0,
        conditionalSessions:
            (json['conditionalSessions'] as num?)?.toInt() ?? 0,
        failSessions: (json['failSessions'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw CacheException(message: 'Corrupt quality report: $e');
    }
  }
}
