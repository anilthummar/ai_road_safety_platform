import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/imu/domain/entities/imu_entities.dart';
import 'package:equatable/equatable.dart';

/// IMU presentation states.
sealed class ImuState extends Equatable {
  const ImuState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state.
final class ImuInitial extends ImuState {
  const ImuInitial();
}

/// Intermediate loading.
final class ImuLoading extends ImuState {
  /// Human-readable status.
  final String message;

  /// Creates [ImuLoading].
  const ImuLoading({this.message = 'Preparing IMU…'});

  @override
  List<Object?> get props => [message];
}

/// Active sensing (or idle after stop with last known session).
final class ImuActive extends ImuState {
  /// Session meta + optional last sample on session.
  final ImuSession session;

  /// Latest fused sample (may be null if not yet received).
  final ImuSample? sample;

  /// Creates [ImuActive].
  const ImuActive({
    required this.session,
    this.sample,
  });

  /// Copy helper.
  ImuActive copyWith({
    ImuSession? session,
    ImuSample? sample,
  }) {
    return ImuActive(
      session: session ?? this.session,
      sample: sample ?? this.sample,
    );
  }

  @override
  List<Object?> get props => [session, sample];
}

/// Unrecoverable / surfaced failure.
final class ImuError extends ImuState {
  /// Failure detail.
  final Failure failure;

  /// Creates [ImuError].
  const ImuError(this.failure);

  @override
  List<Object?> get props => [failure];
}
