import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:equatable/equatable.dart';

/// Risk analysis presentation states.
sealed class RiskAnalysisState extends Equatable {
  const RiskAnalysisState();

  @override
  List<Object?> get props => [];
}

/// Initial.
final class RiskAnalysisInitial extends RiskAnalysisState {
  const RiskAnalysisInitial();
}

/// Loading.
final class RiskAnalysisLoading extends RiskAnalysisState {
  /// Status message.
  final String message;

  /// Creates [RiskAnalysisLoading].
  const RiskAnalysisLoading({this.message = 'Preparing risk engine…'});

  @override
  List<Object?> get props => [message];
}

/// Ready / active with optional assessment.
final class RiskAnalysisActive extends RiskAnalysisState {
  /// Session meta.
  final RiskSession session;

  /// Latest assessment.
  final RiskAssessment? assessment;

  /// Creates [RiskAnalysisActive].
  const RiskAnalysisActive({
    required this.session,
    this.assessment,
  });

  /// Copy helper.
  RiskAnalysisActive copyWith({
    RiskSession? session,
    RiskAssessment? assessment,
  }) {
    return RiskAnalysisActive(
      session: session ?? this.session,
      assessment: assessment ?? this.assessment,
    );
  }

  @override
  List<Object?> get props => [session, assessment];
}

/// Failure.
final class RiskAnalysisError extends RiskAnalysisState {
  /// Failure detail.
  final Failure failure;

  /// Creates [RiskAnalysisError].
  const RiskAnalysisError(this.failure);

  @override
  List<Object?> get props => [failure];
}
