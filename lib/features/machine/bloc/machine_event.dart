part of 'machine_bloc.dart';

sealed class MachineEvent extends Equatable {
  const MachineEvent();

  @override
  List<Object> get props => [];
}

final class MachineCalculationEvent extends MachineEvent {
  final String meters;
  const MachineCalculationEvent({required this.meters});
  @override
  List<Object> get props => [meters];
}
