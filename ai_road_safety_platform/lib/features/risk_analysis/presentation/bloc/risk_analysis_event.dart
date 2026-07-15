import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:equatable/equatable.dart';

/// Risk analysis presentation events.
sealed class RiskAnalysisEvent extends Equatable {
  const RiskAnalysisEvent();

  @override
  List<Object?> get props => [];
}

/// Bootstraps streams (idle until monitoring or evaluate).
final class RiskAnalysisStarted extends RiskAnalysisEvent {
  const RiskAnalysisStarted();
}

/// Starts continuous fusion.
final class RiskMonitoringStarted extends RiskAnalysisEvent {
  const RiskMonitoringStarted();
}

/// Stops continuous fusion.
final class RiskMonitoringStopped extends RiskAnalysisEvent {
  const RiskMonitoringStopped();
}

/// One-shot evaluation with explicit inputs (demo / scenarios).
final class RiskEvaluateRequested extends RiskAnalysisEvent {
  /// Snapshot to evaluate.
  final RiskInputSnapshot snapshot;

  /// Creates [RiskEvaluateRequested].
  const RiskEvaluateRequested(this.snapshot);

  @override
  List<Object?> get props => [snapshot];
}

/// Releases resources.
final class RiskAnalysisDisposed extends RiskAnalysisEvent {
  const RiskAnalysisDisposed();
}

/// Internal session update.
final class RiskSessionUpdated extends RiskAnalysisEvent {
  /// Latest session.
  final RiskSession session;

  /// Creates [RiskSessionUpdated].
  const RiskSessionUpdated(this.session);

  @override
  List<Object?> get props => [session];
}

/// Internal assessment update.
final class RiskAssessmentUpdated extends RiskAnalysisEvent {
  /// Latest assessment.
  final RiskAssessment assessment;

  /// Creates [RiskAssessmentUpdated].
  const RiskAssessmentUpdated(this.assessment);

  @override
  List<Object?> get props => [assessment];
}
