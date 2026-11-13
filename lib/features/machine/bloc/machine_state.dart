part of 'machine_bloc.dart';

sealed class MachineState extends Equatable {
  const MachineState();

  @override
  List<Object> get props => [];
}

final class MachineInitial extends MachineState {}

final class MachineLoadingState extends MachineState {}

final class MachineCalculationLoadedSuccessState extends MachineState {
  final MachineCalculationModel model;
  const MachineCalculationLoadedSuccessState({required this.model});
  @override
  List<Object> get props => [model];
}

final class MachineErrorState extends MachineState {
  final String message;
  const MachineErrorState({required this.message});
  @override
  List<Object> get props => [message];
}