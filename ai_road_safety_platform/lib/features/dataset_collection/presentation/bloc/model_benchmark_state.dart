import 'package:ai_road_safety_platform/core/errors/failures.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/model_benchmark_entities.dart';
import 'package:equatable/equatable.dart';

sealed class ModelBenchmarkState extends Equatable {
  const ModelBenchmarkState();
  @override
  List<Object?> get props => [];
}

class ModelBenchmarkInitial extends ModelBenchmarkState {
  const ModelBenchmarkInitial();
}

class ModelBenchmarkLoading extends ModelBenchmarkState {
  final String? message;
  const ModelBenchmarkLoading({this.message});
  @override
  List<Object?> get props => [message];
}

class ModelBenchmarkLoaded extends ModelBenchmarkState {
  final BenchmarkSnapshot snapshot;
  final String? statusMessage;

  const ModelBenchmarkLoaded({
    required this.snapshot,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [snapshot, statusMessage];
}

class ModelBenchmarkError extends ModelBenchmarkState {
  final Failure failure;
  final BenchmarkSnapshot? snapshot;

  const ModelBenchmarkError({required this.failure, this.snapshot});

  @override
  List<Object?> get props => [failure, snapshot];
}
