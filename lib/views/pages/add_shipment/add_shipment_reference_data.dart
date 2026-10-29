import 'package:blockatie/services/delivery_type_service.dart';
import 'package:blockatie/services/regions_service.dart';

/// Where the Add Shipment page gets its area and delivery-type lists.
///
/// The default reads the app's existing services, unchanged. Tests hand in
/// fixed lists so the page can be pumped without the network.
abstract class AddShipmentReferenceData {
  const AddShipmentReferenceData();

  Future<void> load({required bool force});

  List<Region> get regions;

  List<Map<String, dynamic>> get deliveryTypes;
}

class ServiceAddShipmentReferenceData extends AddShipmentReferenceData {
  const ServiceAddShipmentReferenceData();

  @override
  Future<void> load({required bool force}) async {
    await DeliveryTypeService.loadDeliveryTypes(forceRefresh: force);
    await RegionsService.loadRegions(forceRefresh: force);
  }

  @override
  List<Region> get regions => RegionsService.regions;

  @override
  List<Map<String, dynamic>> get deliveryTypes =>
      DeliveryTypeService.getAllDeliveryTypes();
}
