// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:foodie_customer/model/CurrencyModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:geolocator/geolocator.dart';

import 'model/TaxModel.dart';

const FINISHED_ON_BOARDING = 'finishedOnBoarding';
const COLOR_ACCENT = 0xFF984D65;
const COLOR_PRIMARY_DARK = 0xFF683A;
const COLOR_PRIMARY = 0xFF984D65;
const COLOR_APPBAR = 0xFF551631;
const COLOR_CHOICE = 0xFFDDBE7D;
const FACEBOOK_BUTTON_COLOR = 0xFF415893;
const googleButtonColor = 0xFFefeeee;
const DARK_COLOR = 0xff191A1C;
const DARK_VIEWBG_COLOR = 0xff191A1C;
const DARK_CARD_BG_COLOR = 0xff242528;
const DARK_BG_COLOR = 0xff121212;
const COUPON_BG_COLOR = 0xFFFCF8F3;
const COUPON_DASH_COLOR = 0xFFCACFDA;
const GREY_TEXT_COLOR = 0xff5E5C5C;
const DARK_GREY_TEXT_COLOR = 0xff9F9F9F;
const DarkContainerColor = 0xff26272C;
const DarkContainerBorderColor = 0xff515151;

double radiusValue = 0.0;

const STORY = 'story';
const MENU_ITEM = 'menu_items';
const USERS = 'users';
const REPORTS = 'reports';
const Deliverycharge = 6;
const VENDOR_ATTRIBUTES = "vendor_attributes";
const REVIEW_ATTRIBUTES = "review_attributes";
const FavouriteItem = "favorite_item";
const VENDORS = 'vendors';
const PRODUCTS = 'vendor_products';
const ORDERS = 'restaurant_orders';
const ORDERS_TABLE = 'booked_table';
const SECOND_MILLIS = 1000;
const MINUTE_MILLIS = 60 * SECOND_MILLIS;
const HOUR_MILLIS = 60 * MINUTE_MILLIS;
const SERVER_KEY = 'AAAAxUfjYN8:APA91bF3WICu-Of9Prfqt6IMwQ92YgoewBJctnHu3ic2LQ4jgilIvLm0LqX4f3BdwRFQrzTxy38HKIUIh7Y1CHrkXdrirfW2quqqp78m3hkk7TlFgRgW0J1eaDCr4w7s1NsnuoevUbg6';
const GOOGLE_API_KEY = 'AIzaSyDzOIl96S1mWYUF9C5R9CdXpdA10LvL4ic';
const JS_API_KEY = 'AIzaSyBiUIRQGEGMcMDdLX25U2QZ_sM-JhoMW_w';

const ORDER_STATUS_PAYMENT_PENDING = 'Pending Payment';
const ORDER_STATUS_CONFIRMATION_PENDING = 'Pending Confirmation';
const ORDER_STATUS_CONFIRMED = 'Confirmed';
const ORDER_STATUS_COMPLETED = 'Completed';
const ORDER_STATUS_DELIVERY = 'On the Way';
const ORDER_STATUS_REJECTED = 'Rejected';

const ORDER_STATUS_DRIVER_PENDING = 'Driver Pending';
const ORDER_STATUS_DRIVER_REJECTED = 'Driver Rejected';
const ORDER_STATUS_SHIPPED = 'Order Shipped';
const ORDER_STATUS_IN_TRANSIT = 'In Transit';
const ORDERREQUEST = 'Order';
const BOOKREQUEST = 'TableBook';

const PAYMENT_SERVER_URL = 'https://murmuring-caverns-94283.herokuapp.com/';

const USER_ROLE_DRIVER = 'driver';
const USER_ROLE_CUSTOMER = 'customer';
const USER_ROLE_VENDOR = 'vendor';
const VENDORS_CATEGORIES = 'vendor_categories';
const Order_Rating = 'foods_review';
const CONTACT_US = 'ContactUs';
const COUPON = 'coupons';
const TOP_SELLING = 'top_selling';
const Wallet = "wallet";

const Setting = 'settings';
const StripeSetting = 'stripeSettings';
const FavouriteRestaurant = "favorite_restaurant";

const COD = 'CODSettings';

const GlobalURL = "https://foodie.siswebapp.com/";

const Currency = 'currencies';
String symbol = '\$';
bool isRight = false;
bool isDineInEnable = false;
int decimal = 2;
String currName = "";
CurrencyModel? currencyData;
List<VendorModel> allstoreList = [];
String appVersion = '1.0.0';

bool isRazorPayEnabled = false;
bool isRazorPaySandboxEnabled = false;
String razorpayKey = "";
String razorpaySecret = "";

String placeholderImage =
    'https://firebasestorage.googleapis.com/v0/b/saloncantontest.appspot.com/o/gallery%2Fplaceholder.jpg?alt=media&token=60d95ebf-1cf8-466e-b9d8-9606fb03a123';

List countries = [];

double getDoubleVal(dynamic input) {
  if (input == null) {
    return 0.1;
  }

  if (input is int) {
    return double.parse(input.toString());
  }

  if (input is double) {
    return input;
  }
  return 0.1;
}

double getTaxValue(TaxModel? taxModel, double amount) {
  double taxVal = 0;
  if (taxModel != null && taxModel.tax != null && taxModel.tax! > 0) {
    if (taxModel.type == "fix") {
      taxVal = taxModel.tax!.toDouble();
    } else {
      taxVal = (amount * taxModel.tax!.toDouble()) / 100;
    }
  }
  return double.parse(taxVal.toStringAsFixed(2));
}

Uri createCoordinatesUrl(double latitude, double longitude, [String? label]) {
  var uri;
  if (kIsWeb) {
    uri = Uri.https('www.google.com', '/maps/search/',
        {'api': '1', 'query': '$latitude,$longitude'});
  } else if (Platform.isAndroid) {
    var query = '$latitude,$longitude';
    if (label != null) query += '($label)';
    uri = Uri(scheme: 'geo', host: '0,0', queryParameters: {'q': query});
  } else if (Platform.isIOS) {
    var params = {'ll': '$latitude,$longitude'};
    if (label != null) params['q'] = label;
    uri = Uri.https('maps.apple.com', '/', params);
  } else {
    uri = Uri.https('www.google.com', '/maps/search/',
        {'api': '1', 'query': '$latitude,$longitude'});
  }

  return uri;
}

String getKm(Position pos1, Position pos2) {
  double distanceInMeters = Geolocator.distanceBetween(
      pos1.latitude, pos1.longitude, pos2.latitude, pos2.longitude);
  double kilometer = distanceInMeters / 1000;
  debugPrint("KiloMeter$kilometer");
  return kilometer.toStringAsFixed(2).toString();
}

String getImageVAlidUrl(String url) {
  String imageUrl = placeholderImage;
  if (url.isNotEmpty) {
    imageUrl = url;
  }
  return imageUrl;
}
