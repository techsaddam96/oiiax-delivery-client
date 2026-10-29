class DriverData {
  late bool success;
  late int count;
  late List<Drivers> drivers;

  DriverData.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    count = json['count'];
    if (json['drivers'] != null) {
      drivers = <Drivers>[];
      json['drivers'].forEach((v) {
        drivers.add(Drivers.fromJson(v));
      });
    }
  }
}

class Drivers {
  late String id;
  late String dname;
  late String dpercent;
  late String dphone;
  late String latitude;
  late String longitude;
  late String subscription;

  Drivers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dname = json['dname'];
    dpercent = json['dpercent'];
    dphone = json['dphone'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    subscription = json['subscription'];
  }
}
