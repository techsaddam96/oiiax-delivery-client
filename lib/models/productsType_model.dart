class ProductsTypeData {
  late String status;
  late String message;
  late List<ProductsTypes> productsTypes;

  ProductsTypeData.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['products_types'] != null) {
      productsTypes = <ProductsTypes>[];
      json['products_types'].forEach((v) {
        productsTypes.add(ProductsTypes.fromJson(v));
      });
    }
  }
}

class ProductsTypes {
  late String id;
  late String typeNameEn;
  late String typeNameAr;
  late String descriptionEn;
  late String descriptionAr;

  ProductsTypes.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    typeNameEn = json['type_name_en'];
    typeNameAr = json['type_name_ar'];
    descriptionEn = json['description_en'];
    descriptionAr = json['description_ar'];
  }
}
