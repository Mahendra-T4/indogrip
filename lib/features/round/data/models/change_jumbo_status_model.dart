class ChangeJumboStatusModel {
  int? status;
  String? newStatus;
  String? message;

  ChangeJumboStatusModel({this.status, this.newStatus, this.message});

  ChangeJumboStatusModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    newStatus = json['newStatus'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['newStatus'] = this.newStatus;
    data['message'] = this.message;
    return data;
  }
}
