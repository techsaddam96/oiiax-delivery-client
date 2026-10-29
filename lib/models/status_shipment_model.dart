class StatusShipmentData {
  late bool success;
  late int count;
  late List<Status> status;

  StatusShipmentData.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    count = json['count'];
    if (json['status'] != null) {
      status = <Status>[];
      json['status'].forEach((v) {
        status.add(Status.fromJson(v));
      });
    }
  }
}

class Status {
  late int id;
  late String statusNameEn;
  late String statusNameAr;
  late String statusOrder;
  late String typeColor;
  late String messageEn;
  late String messageAr;

  Status.fromJson(Map<String, dynamic> json) {
    id = int.parse(json['id'].toString());
    statusNameEn = json['status_name_en'];
    statusNameAr = json['status_name_ar'];
    statusOrder = json['status_order'];
    typeColor = json['type_color'];
    messageEn = json['message_en'];
    messageAr = json['message_ar'];
  }
}
