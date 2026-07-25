class ChallaninfoParam {
  final String challanRemark;
  final String challanNumber;
  final String challanDate;
  final String challanKey;
  final String? clientUnitName;
  final String? clientKey;
  final String? invoiceChallanNumber;
  final String? invoiceChallanDate;

  ChallaninfoParam({
    required this.challanRemark,
    required this.challanNumber,
    required this.challanDate,
    required this.challanKey,
    required this.clientUnitName,
    required this.clientKey,
    this.invoiceChallanDate,
    this.invoiceChallanNumber
  });
}
