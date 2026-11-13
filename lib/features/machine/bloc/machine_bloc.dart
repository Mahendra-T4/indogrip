import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:indogrip/features/machine/models/machine_cal_model.dart';
import 'package:indogrip/features/machine/repositories/repository.dart';

part 'machine_event.dart';
part 'machine_state.dart';

class MachineBloc extends Bloc<MachineEvent, MachineState> {
  MachineBloc() : super(MachineInitial()) {
    on<MachineCalculationEvent>(_machineCalculationEvent);
  }

  FutureOr<void> _machineCalculationEvent(
    MachineCalculationEvent event,
    Emitter<MachineState> emit,
  ) async {
    emit(MachineLoadingState());
    try {
      final result = await MachineCalculationRepository.machineCalculation(
        meters: event.meters,
      );
      emit(MachineCalculationLoadedSuccessState(model: result));
    } catch (e) {
      emit(MachineErrorState(message: e.toString()));
    }
  }
}
