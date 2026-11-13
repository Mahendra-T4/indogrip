class MachineCalculationModel {
  int? status;
  String? message;
  MachineOne? machineOne;
  MachineOne? machineTwo;

  MachineCalculationModel(
      {this.status, this.message, this.machineOne, this.machineTwo});

  MachineCalculationModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    machineOne = json['machineOne'] != null
        ? new MachineOne.fromJson(json['machineOne'])
        : null;
    machineTwo = json['machineTwo'] != null
        ? new MachineOne.fromJson(json['machineTwo'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.machineOne != null) {
      data['machineOne'] = this.machineOne!.toJson();
    }
    if (this.machineTwo != null) {
      data['machineTwo'] = this.machineTwo!.toJson();
    }
    return data;
  }
}

class MachineOne {
  String? firstStep;
  String? secondStep;
  String? finalStep;

  MachineOne({this.firstStep, this.secondStep, this.finalStep});

  MachineOne.fromJson(Map<String, dynamic> json) {
    firstStep = json['firstStep'];
    secondStep = json['secondStep'];
    finalStep = json['finalStep'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['firstStep'] = this.firstStep;
    data['secondStep'] = this.secondStep;
    data['finalStep'] = this.finalStep;
    return data;
  }
}