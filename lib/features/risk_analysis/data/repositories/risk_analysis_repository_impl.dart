import 'package:ai_road_safety_platform/core/errors/error_handler.dart';
import 'package:ai_road_safety_platform/core/errors/exceptions.dart';
import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/core/utils/result.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/data/datasources/risk_analysis_local_data_source.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/repositories/risk_analysis_repository.dart';

/// Maps risk data-source exceptions to domain [Result]s.
class RiskAnalysisRepositoryImpl implements RiskAnalysisRepository {
  final RiskAnalysisLocalDataSource _local;
  final ErrorHandler _errorHandler;

  /// Creates [RiskAnalysisRepositoryImpl].
  RiskAnalysisRepositoryImpl({
    required RiskAnalysisLocalDataSource localDataSource,
    required ErrorHandler errorHandler,
  })  : _local = localDataSource,
        _errorHandler = errorHandler;

  @override
  Stream<RiskSession> watchSession() => _local.sessionStream;

  @override
  Stream<RiskAssessment> watchAssessments() => _local.assessmentStream;

  @override
  Future<Result<RiskAssessment>> evaluate(RiskInputSnapshot snapshot) {
    return _guard(() async => _local.evaluate(snapshot));
  }

  @override
  Future<Result<RiskSession>> startMonitoring() {
    return _guard(() async {
      await _local.startMonitoring();
      return const RiskSession(
        isMonitoring: true,
      );
    });
  }

  @override
  Future<Result<RiskSession>> stopMonitoring() {
    return _guard(() async {
      await _local.stopMonitoring();
      return const RiskSession(isMonitoring: false);
    });
  }

  @override
  Future<Result<void>> dispose() {
    return _guard(_local.dispose);
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Failure catch (failure) {
      return Err(failure);
    } on AppException catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    } catch (e, st) {
      return Err(_errorHandler.handle(e, st));
    }
  }
}
