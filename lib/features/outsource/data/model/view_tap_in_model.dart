class ViewTapInventoryModel {
  int? status;
  String? message;
  List<TapRecord>? record;
  int? pageQty;
  String? pageText;
  int? totalPieces;
  int? availableCarton;
  dynamic inventoryCarton;
  dynamic roundCarton;

  dynamic totalNetWeight;
  dynamic totalGrossWeight;

  ViewTapInventoryModel({
    this.status,
    this.message,
    this.record,
    this.pageQty,
    this.availableCarton,
    this.totalPieces,
    this.inventoryCarton,
    this.roundCarton,
    this.totalNetWeight,
    this.totalGrossWeight,
  });

  ViewTapInventoryModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['record'] != null) {
      record = <TapRecord>[];
      json['record'].forEach((v) {
        record!.add(new TapRecord.fromJson(v));
      });
    }
    pageQty = json['pageQty'];
    pageText = json['pageText'];
    totalPieces = json['totalPieces'] ?? 0;
    availableCarton = json['availableCarton'] ?? 0;
    inventoryCarton = json['inventoryCarton'] ?? 0;
    roundCarton = json['roundCarton'] ?? 0;
    totalNetWeight = json['totalNetWeight'];
    totalGrossWeight = json['totalGrossWeight'];
    // batchInformation = json['batchInformation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.record != null) {
      data['record'] = this.record!.map((v) => v.toJson()).toList();
    }
    data['pageQty'] = this.pageQty;
    data['pageText'] = this.pageText;
    data['inventoryCarton'] = this.inventoryCarton;
    data['roundCarton'] = this.roundCarton;
    data['totalNetWeight'] = this.totalNetWeight;
    data['totalGrossWeight'] = this.totalGrossWeight;
    return data;
  }
}

class TapRecord {
  int? sNo;
  String? recordDate;
  dynamic productTypeID;
  dynamic inventoryCode;
  String? productTypeName;
  String? billDate;
  String? billNumber;
  int? cartonPrice;
  int? transportPrice;
  dynamic quantity;
  AdditionalInfo? additionalInfo;
  VendorInfo? vendorInfo;
  dynamic availableQuantity;
  String? remark;
  String? rKey;
  int? rStatus;
  String? inventoryStatusLabel;
  BatchInformation? batchInformation;

  TapRecord({
    this.sNo,
    this.recordDate,
    this.productTypeID,
    this.inventoryCode,
    this.productTypeName,
    this.billDate,
    this.billNumber,
    this.cartonPrice,
    this.transportPrice,
    this.availableQuantity,
    this.quantity,
    this.additionalInfo,
    this.vendorInfo,
    this.remark,
    this.rKey,
    this.rStatus,
    this.inventoryStatusLabel,
    this.batchInformation,
  });

  TapRecord.fromJson(Map<String, dynamic> json) {
    sNo = json['SNo'];
    recordDate = json['recordDate'];
    productTypeID = json['productTypeID'];
    inventoryCode = json['inventoryCode'] ?? '';
    productTypeName = json['productTypeName'];
    availableQuantity = json['availableQuantity'] ?? 0;
    billDate = json['billDate'];
    billNumber = json['billNumber'];
    cartonPrice = json['cartonPrice'];
    transportPrice = json['transportPrice'];
    quantity = json['quantity'];
    additionalInfo = json['additionalInfo'] != null
        ? new AdditionalInfo.fromJson(json['additionalInfo'])
        : null;
    if (json['batchInformation'] != null) {
      if (json['batchInformation'] is Map &&
          (json['batchInformation'] as Map).isNotEmpty) {
        batchInformation = new BatchInformation.fromJson(
          json['batchInformation'],
        );
      } else if (json['batchInformation'] is List &&
          (json['batchInformation'] as List).isNotEmpty) {
        batchInformation = new BatchInformation.fromJson(
          json['batchInformation'][0],
        );
      } else {
        batchInformation = null;
      }
    } else {
      batchInformation = null;
    }

    // Handle vendorInfo - could be null, empty array [], or object {}
    if (json['vendorInfo'] != null &&
        json['vendorInfo'] is Map &&
        (json['vendorInfo'] as Map).isNotEmpty) {
      vendorInfo = new VendorInfo.fromJson(json['vendorInfo']);
    } else {
      // Default for empty array or null or empty map
      vendorInfo = VendorInfo(
        companyName: 'N/A',
        vendorCode: '',
        vendorKey: '',
      );
    }

    remark = json['remark'] ?? '';
    rKey = json['rKey'];
    rStatus = json['rStatus'];
    inventoryStatusLabel = json['inventoryStatusLabel'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['SNo'] = this.sNo;
    data['recordDate'] = this.recordDate;
    data['productTypeID'] = this.productTypeID;
    data['inventoryCode'] = this.inventoryCode;
    data['productTypeName'] = this.productTypeName;
    data['billDate'] = this.billDate;
    data['billNumber'] = this.billNumber;
    data['availableQuantity'] = this.availableQuantity;
    data['cartonPrice'] = this.cartonPrice;
    data['transportPrice'] = this.transportPrice;
    data['quantity'] = this.quantity;
    if (this.additionalInfo != null) {
      data['additionalInfo'] = this.additionalInfo!.toJson();
    }
    if (this.vendorInfo != null) {
      data['vendorInfo'] = this.vendorInfo!.toJson();
    }
    if (this.batchInformation != null) {
      data['batchInformation'] = this.batchInformation!.toJson();
    }
    data['remark'] = this.remark;
    data['rKey'] = this.rKey;
    data['rStatus'] = this.rStatus;
    return data;
  }
}

class AdditionalInfo {
  int? cutMMMeterID;
  int? cutMMMeter;
  int? piecesPerCarton;
  int? baseID;
  String? baseLabel;
  String? tapeLength;
  String? tapeWeight;
  int? micID;
  String? micLabel;

  AdditionalInfo({
    this.cutMMMeterID,
    this.cutMMMeter,
    this.piecesPerCarton,
    this.baseID,
    this.baseLabel,
    this.tapeLength,
    this.tapeWeight,
    this.micID,
    this.micLabel,
  });

  AdditionalInfo.fromJson(Map<String, dynamic> json) {
    cutMMMeterID = json['cutMMMeterID'];
    cutMMMeter = json['cutMMMeter'];
    piecesPerCarton = json['piecesPerCarton'];
    baseID = json['baseID'];
    baseLabel = json['baseLabel'];
    tapeLength = json['tapeLength'];
    tapeWeight = json['tapeWeight'];
    micID = json['micID'];
    micLabel = json['micLabel'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cutMMMeterID'] = this.cutMMMeterID;
    data['cutMMMeter'] = this.cutMMMeter;
    data['piecesPerCarton'] = this.piecesPerCarton;
    data['baseID'] = this.baseID;
    data['baseLabel'] = this.baseLabel;
    data['tapeLength'] = this.tapeLength;
    data['tapeWeight'] = this.tapeWeight;
    data['micID'] = this.micID;
    data['micLabel'] = this.micLabel;
    return data;
  }
}

class VendorInfo {
  String? vendorCode;
  String? companyName;
  String? vendorKey;

  VendorInfo({this.vendorCode, this.companyName, this.vendorKey});

  VendorInfo.fromJson(Map<String, dynamic> json) {
    vendorCode = json['vendorCode'] ?? 'N/A';
    companyName = json['companyName'] ?? 'N/A';
    vendorKey = json['vendorKey'] ?? 'N/A';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['vendorCode'] = this.vendorCode;
    data['companyName'] = this.companyName;
    data['vendorKey'] = this.vendorKey;
    return data;
  }
}

class BatchInformation {
  dynamic batchID;
  String? batchCode;
  String? batchDateText;
  dynamic showFor;
  String? showLabel;
  dynamic displayMic;
  String? displayValue;
  String? displayMFG;
  String? displayMFGLabel;
  String? batchRemark;
  dynamic batchType;
  String? batchMRP;
  String? batchKey;

  BatchInformation({
    this.batchID,
    this.batchCode,
    this.batchDateText,
    this.showFor,
    this.showLabel,
    this.displayMic,
    this.displayValue,
    this.displayMFG,
    this.displayMFGLabel,
    this.batchRemark,
    this.batchType,
    this.batchMRP,
    this.batchKey,
  });

  BatchInformation.fromJson(Map<String, dynamic> json) {
    batchID = json['batchID'];
    batchCode = json['batchCode'];
    batchDateText = json['batchDateText'];
    showFor = json['showFor'];
    showLabel = json['showLabel'];
    displayMic = json['displayMic'];
    displayValue = json['displayValue'];
    displayMFG = json['displayMFG'];
    displayMFGLabel = json['displayMFGLabel'];
    batchRemark = json['batchRemark'];
    batchType = json['batchType'];
    batchMRP = json['batchMRP'];
    batchKey = json['batchKey'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['batchID'] = this.batchID;
    data['batchCode'] = this.batchCode;
    data['batchDateText'] = this.batchDateText;
    data['showFor'] = this.showFor;
    data['showLabel'] = this.showLabel;
    data['displayMic'] = this.displayMic;
    data['displayValue'] = this.displayValue;
    data['displayMFG'] = this.displayMFG;
    data['displayMFGLabel'] = this.displayMFGLabel;
    data['batchRemark'] = this.batchRemark;
    data['batchType'] = this.batchType;
    data['batchMRP'] = this.batchMRP;
    data['batchKey'] = this.batchKey;
    return data;
  }
}
