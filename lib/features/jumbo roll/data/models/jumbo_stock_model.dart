class JumboStockModel {
  int? status;
  int? availableJumbo;
  int? availableLength;
  String? message;

  JumboStockModel({
    this.status,
    this.availableJumbo,
    this.availableLength,
    this.message,
  });

  JumboStockModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    availableJumbo = json['availableJumbo'];
    availableLength = json['availableLength'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['availableJumbo'] = this.availableJumbo;
    data['availableLength'] = this.availableLength;
    data['message'] = this.message;
    return data;
  }
}
