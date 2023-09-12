import 'dart:convert';

class WebCartProduct {
  String id;
  String category_id;
  String name;
  String photo;
  String price;
  String? discountPrice;
  String vendorID;
  int quantity;
  String? extras_price;
  dynamic extras;
  dynamic variant_info;

  WebCartProduct({
    required this.id,
    required this.category_id,
    required this.name,
    required this.photo,
    required this.price,
    this.discountPrice = "",
    required this.vendorID,
    required this.quantity,
    this.extras_price,
    this.extras,
    this.variant_info,
  });

  factory WebCartProduct.fromJson(Map<String, dynamic> parsedJson) {
    dynamic extrasVal;
    if (parsedJson['extras'] == null) {
      extrasVal = List<String>.empty();
    } else {
      if (parsedJson['extras'] is String) {
        if (parsedJson['extras'] == '[]') {
          extrasVal = List<String>.empty();
        } else {
          String extraDecode = parsedJson['extras']
              .toString()
              .replaceAll("[", "")
              .replaceAll("]", "")
              .replaceAll("\"", "");
          if (extraDecode.contains(",")) {
            extrasVal = extraDecode.split(",");
          } else {
            extrasVal = [extraDecode];
          }
        }
      }
      if (parsedJson['extras'] is List) {
        extrasVal = parsedJson['extras'].cast<String>();
      }
    }
    return WebCartProduct(
      id: parsedJson["id"],
      category_id: parsedJson["category_id"],
      name: parsedJson["name"],
      photo: parsedJson["photo"],
      price: parsedJson["price"],
      discountPrice: parsedJson["discountPrice"],
      vendorID: parsedJson["vendorID"],
      quantity: parsedJson["quantity"],
      extras_price: extrasVal,
      extras: parsedJson["extras"] ?? [],
      variant_info: parsedJson["variant_info"],
    );
  }

  Map<String, dynamic> toJson() {
    if (extras == null) {
      extras = List<String>.empty();
    } else {
      if (extras is String) {
        extras = extras.toString().replaceAll("\"", "");
        if (extras == '[]' || extras.toString().isEmpty) {
          extras = List<String>.empty();
        } else {
          extras = extras
              .toString()
              .replaceAll("[", "")
              .replaceAll("]", "")
              .replaceAll("\"", "");
          if (extras.toString().contains(",")) {
            extras = extras.toString().split(",");
          } else {
            extras = [(extras.toString())];
          }
        }
      }
      if (extras is List) {
        if ((extras as List).isEmpty) {
          extras = List<String>.empty();
        } else if (extras[0] == "[]") {
          extras = List<String>.empty();
        } else {
          extras = extras;
        }
      }
    }
    return <String, dynamic>{
      'id': (id.split('~').first),
      'category_id': (category_id),
      'name': (name),
      'photo': (photo),
      'price': (price),
      'discountPrice': (discountPrice),
      'vendorID': (vendorID),
      'quantity': (quantity),
      'extras_price': (extras_price),
      'extras': (extras),
      'variant_info': variant_info,
    };
  }
}
