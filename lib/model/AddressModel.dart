import 'package:custom_food/model/User.dart';

class AddressModel {
  String city;

  String country;

  String email;

  String line1;

  String line2;

  UserLocation location;

  String name;

  String postalCode;

  AddressModel({this.city = '', this.country = '', this.email = '', this.line1 = '', this.line2 = '', location, this.name = '', this.postalCode = ''}) : this.location = location ?? UserLocation();

  factory AddressModel.fromJson(Map<String, dynamic> parsedJson) {
    return AddressModel(
      city: parsedJson['city'] ?? '',
      country: parsedJson['country'] ?? '',
      email: parsedJson['email'] ?? '',
      line1: parsedJson['line1'] ?? '',
      line2: parsedJson['line2'] ?? '',
      location: parsedJson.containsKey('location') ? UserLocation.fromJson(parsedJson['location']) : UserLocation(),
      name: parsedJson['name'] ?? '',
      postalCode: parsedJson['postalCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': this.city,
      'country': this.country,
      'email': this.email,
      'line1': this.line1,
      'line2': this.line2,
      'location': this.location.toJson(),
      'name': this.name,
      'postalCode': this.postalCode,
    };
  }
}

class NewAddressModel {
  String addressName;

  String city;

  String country;

  bool def;

  String lat;

  String line1;

  String line2;

  String lon;

  String name;

  String phone;

  String zipcode;

  String zone;

  NewAddressModel({this.addressName = '', this.city = '', this.country = '', this.def = false, this.line1 = '', this.line2 = '', lat, lon, this.name = '', this.phone = '', this.zipcode = '', this.zone = ''}) : this.lat = lat ?? UserLocation().latitude.toString(), this.lon = lon ?? UserLocation().longitude.toString();

  factory NewAddressModel.fromJson(Map<String, dynamic> parsedJson) {
    return NewAddressModel(
      addressName: parsedJson['addressName'] ?? '',
      city: parsedJson['city'] ?? '',
      country: parsedJson['country'] ?? '',
      def: parsedJson['default'] ?? false,
      lat: parsedJson['lat'] ?? UserLocation().latitude.toString(),
      line1: parsedJson['line1'] ?? '',
      line2: parsedJson['line2'] ?? '',
      lon: parsedJson['lon'] ?? UserLocation().longitude.toString(),
      name: parsedJson['name'] ?? '',
      phone: parsedJson['phone'] ?? '',
      zipcode: parsedJson['zipcode'] ?? '',
      zone: parsedJson['zone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressName': this.addressName,
      'city': this.city,
      'country': this.country,
      'default': this.def,
      'lat':this.lat,
      'line1': this.line1,
      'line2': this.line2,
      'lon':this.lon,
      'name': this.name,
      'phone': this.phone,
      'zipcode': this.zipcode,
      'zone': this.zone,
    };
  }
}
