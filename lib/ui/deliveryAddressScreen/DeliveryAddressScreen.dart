import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/AddressModel.dart';
import 'package:foodie_customer/model/DeliveryChargeModel.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/payment/PaymentScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:place_picker/place_picker.dart';

import '../../model/TaxModel.dart';
import '../../widget/customMap.dart';

class DeliveryAddressScreen extends StatefulWidget {
  static final kInitialPosition = LatLng(-33.8567844, 151.213108);

  final double total;
  final double? discount;
  final String? couponCode;
  final String? couponId, notes;
  final List<CartProduct> products;
  final List<String>? extraAddons;
  final String? extraSize;
  final String? tipValue;
  final String? deliveryCharge;
  final VendorModel? vendorModel;
  final bool? takeAway;
  final TaxModel? taxModel;
  final Map<String, dynamic>? specialDiscountMap;

  const DeliveryAddressScreen(
      {Key? key,
      required this.total,
      this.discount,
      this.couponCode,
      this.couponId,
      required this.products,
      this.vendorModel,
      this.extraAddons,
      this.extraSize,
      this.tipValue,
      this.takeAway,
      this.specialDiscountMap,
      this.deliveryCharge,
      this.taxModel,
      this.notes})
      : super(key: key);

  @override
  _DeliveryAddressScreenState createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  String? country;
  var street = TextEditingController();
  var street1 = TextEditingController();
  var landmark = TextEditingController();
  var landmark1 = TextEditingController();
  var zipcode = TextEditingController();
  var zipcode1 = TextEditingController();
  var city = TextEditingController();
  var city1 = TextEditingController();
  var cutries = TextEditingController();
  var cutries1 = TextEditingController();
  var lat;
  var long;
  bool charging = false;

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    street.dispose();
    landmark.dispose();
    city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MyAppState.currentUser!.shippingAddress.country != '') {
      country = MyAppState.currentUser!.shippingAddress.country;
    }
    street.text = MyAppState.currentUser!.shippingAddress.line1;
    landmark.text = MyAppState.currentUser!.shippingAddress.line2;
    city.text = MyAppState.currentUser!.shippingAddress.city;
    zipcode.text = MyAppState.currentUser!.shippingAddress.postalCode;
    cutries.text = MyAppState.currentUser!.shippingAddress.country;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delivery Address'.tr(),
          style: TextStyle(
              color: isDarkMode(context) ? Colors.white : Colors.black),
        ).tr(),
      ),
      body: Container(
          color: isDarkMode(context) ? null : Color(0XFFF1F4F7),
          child: Form(
              key: _formKey,
              autovalidateMode: _autoValidateMode,
              child: SingleChildScrollView(
                  child: Column(children: [
                SizedBox(
                  height: 40,
                ),
                Card(
                  elevation: 0.5,
                  color: isDarkMode(context)
                      ? Color(DARK_BG_COLOR)
                      : Color(0XFFFFFFFF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: EdgeInsets.only(left: 20, right: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.only(
                            start: 20, end: 20, bottom: 10),
                        child: TextFormField(
                            // controller: street,
                            controller: street1.text.isEmpty ? street : street1,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            validator: validateEmptyField,
                            // onSaved: (text) => line1 = text,
                            onSaved: (text) => street.text = text!,
                            style: TextStyle(fontSize: 18.0),
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Color(COLOR_PRIMARY),
                            // initialValue:
                            //     MyAppState.currentUser!.shippingAddress.line1,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                              labelText: 'Street 1'.tr(),
                              labelStyle: TextStyle(
                                  color: Color(0Xff696A75), fontSize: 17),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              focusedBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(COLOR_PRIMARY)),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0XFFB1BCCA)),
                                // borderRadius: BorderRadius.circular(8.0),
                              ),
                            )),
                      ),
                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'Street 2'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),
                      Container(
                        padding: const EdgeInsetsDirectional.only(
                            start: 20, end: 20, bottom: 10),
                        child: TextFormField(
                          // controller: _controller,
                          controller:
                              landmark1.text.isEmpty ? landmark : landmark1,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          validator: validateEmptyField,
                          onSaved: (text) => landmark.text = text!,
                          style: TextStyle(fontSize: 18.0),
                          keyboardType: TextInputType.streetAddress,
                          cursorColor: Color(COLOR_PRIMARY),
                          // initialValue:
                          //     MyAppState.currentUser!.shippingAddress.line2,
                          decoration: InputDecoration(
                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                            labelText: 'Landmark'.tr(),
                            labelStyle: TextStyle(
                                color: Color(0Xff696A75), fontSize: 17),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Color(COLOR_PRIMARY)),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).errorColor),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).errorColor),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                              // borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'Zip Code'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),
                      Container(
                        padding: const EdgeInsetsDirectional.only(
                            start: 20, end: 20, bottom: 10),
                        child: TextFormField(
                          controller:
                              zipcode1.text.isEmpty ? zipcode : zipcode1,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          validator: validateEmptyField,
                          onSaved: (text) => zipcode.text = text!,
                          style: TextStyle(fontSize: 18.0),
                          keyboardType: TextInputType.phone,
                          cursorColor: Color(COLOR_PRIMARY),
                          // initialValue: MyAppState
                          //     .currentUser!.shippingAddress.postalCode,
                          decoration: InputDecoration(
                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                            labelText: 'Zip Code'.tr(),
                            labelStyle: TextStyle(
                                color: Color(0Xff696A75), fontSize: 17),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Color(COLOR_PRIMARY)),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).errorColor),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).errorColor),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                              // borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'City'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),
                      Container(
                          padding: const EdgeInsetsDirectional.only(
                              start: 20, end: 20, bottom: 10),
                          child: TextFormField(
                            controller: city1.text.isEmpty ? city : city1,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            validator: validateEmptyField,
                            onSaved: (text) => city.text = text!,
                            style: TextStyle(fontSize: 18.0),
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Color(COLOR_PRIMARY),
                            // initialValue:
                            //     MyAppState.currentUser!.shippingAddress.city,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                              labelText: 'City'.tr(),
                              labelStyle: TextStyle(
                                  color: Color(0Xff696A75), fontSize: 17),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              focusedBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(COLOR_PRIMARY)),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0XFFB1BCCA)),
                                // borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          )),

                      Container(
                          padding: const EdgeInsetsDirectional.only(
                              start: 20, end: 20, bottom: 10),
                          child: TextFormField(
                            controller:
                                cutries1.text.isEmpty ? cutries : cutries1,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            validator: validateEmptyField,
                            onSaved: (text) => cutries.text = text!,
                            style: TextStyle(fontSize: 18.0),
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Color(COLOR_PRIMARY),
                            // initialValue:
                            //     MyAppState.currentUser!.shippingAddress.city,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                              labelText: 'Country'.tr(),
                              labelStyle: TextStyle(
                                  color: Color(0Xff696A75), fontSize: 17),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              focusedBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(COLOR_PRIMARY)),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0XFFB1BCCA)),
                                // borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          )),

                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'Country'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),

                      // ListTile(
                      //     contentPadding: const EdgeInsetsDirectional.only(
                      //         start: 5, end: 10),
                      //     subtitle: Padding(
                      //         padding: EdgeInsets.only(left: 16, right: 10),
                      //         child: Divider(
                      //           color: Color(0XFFB1BCCA),
                      //           thickness: 1.5,
                      //         )),
                      //     title: ButtonTheme(
                      //         alignedDropdown: true,
                      //         child: DropdownButtonHideUnderline(
                      //             child: DropdownButton<String>(
                      //           icon: Icon(Icons.keyboard_arrow_down_outlined),
                      //           hint: country == null
                      //               ? Text('Country'.tr())
                      //               : Text(
                      //                   country!,
                      //                   style: TextStyle(
                      //                       color: Color(COLOR_PRIMARY)),
                      //                 ),
                      //           items: <String>[
                      //             'USA',
                      //             'UK',
                      //             'India',
                      //             'France',
                      //             'Russia',
                      //             'Japan',
                      //             'UAE',
                      //             'Qatar',
                      //             'Netherland',
                      //             'Canada'
                      //           ].map((String value) {
                      //             return DropdownMenuItem<String>(
                      //               value: value,
                      //               child: Text(value),
                      //             );
                      //           }).toList(),
                      //           isExpanded: true,
                      //           iconSize: 30.0,
                      //           onChanged: (value) {
                      //             setState(() {
                      //               country = value;
                      //             });
                      //           },
                      //         )))
                      // ),
                      // leading: Container(
                      //   width: 60,
                      //   child: Text(
                      //     'Country'.tr(),
                      //     style: TextStyle(fontWeight: FontWeight.bold),
                      //   ),
                      // ),
                      // title: TextFormField(
                      //   textAlignVertical: TextAlignVertical.center,
                      //   textInputAction: TextInputAction.done,
                      //   validator: validateEmptyField,
                      //   onFieldSubmitted: (_) => validateForm(),
                      //   maxLength: 2,
                      //   onSaved: (text) => country = text,
                      //   style: TextStyle(fontSize: 18.0),
                      //   keyboardType: TextInputType.streetAddress,
                      //   cursorColor: Color(COLOR_PRIMARY),
                      //   initialValue: MyAppState.currentUser!.shippingAddress.country,
                      //   decoration: InputDecoration(
                      //     contentPadding: EdgeInsets.symmetric(horizontal: 24),
                      //     hintText: 'UK'.tr(),
                      //     hintStyle: TextStyle(color: Colors.grey.shade400),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(8.0),
                      //       borderSide:
                      //           BorderSide(color: Color(COLOR_PRIMARY), width: 2.0),
                      //     ),
                      //     errorBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Theme.of(context).errorColor),
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //     focusedErrorBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Theme.of(context).errorColor),
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //     enabledBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Colors.grey.shade300),
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //   ),
                      // ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Card(
                            child: IgnorePointer(
                              ignoring: charging,
                              child: ListTile(
                                  leading: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // ImageIcon(
                                      //   AssetImage('assets/images/current_location1.png'),
                                      //   size: 23,
                                      //   color: Color(COLOR_PRIMARY),
                                      // ),
                                      charging ? CircularProgressIndicator(color: Color(COLOR_PRIMARY),) :
                                      Icon(
                                        Icons.location_searching_rounded,
                                        color: Color(COLOR_PRIMARY),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    "Current Location".tr(),
                                    style: TextStyle(color: Color(COLOR_PRIMARY)),
                                  ),
                                  subtitle: Text(
                                    "Using GPS".tr(),
                                    style: TextStyle(color: Color(COLOR_PRIMARY)),
                                  ),
                                  onTap: () async {
                                    setState(() => charging = true);
                                    Position position =
                                        await Geolocator.getCurrentPosition(
                                                desiredAccuracy:
                                                    LocationAccuracy.high)
                                            .whenComplete(() {});
                                    setState(() => charging = false);
                                    var result = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MapLocationPicker(
                                          currentLatLng: LatLng(position.latitude,
                                              position.longitude),
                                          apiKey: GOOGLE_API_KEY,
                                          canPopOnNextButtonTaped: true,
                                          language: "es",
                                          bottomCardMargin: EdgeInsets.zero,
                                          bottomCardShape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(
                                                  top: Radius.circular(15))),
                                          onNext: (p) {
                                            String name = "";
                                            String? locality,
                                                postalCode,
                                                country,
                                                administrativeAreaLevel1,
                                                administrativeAreaLevel2,
                                                city,
                                                subLocalityLevel1,
                                                subLocalityLevel2;
                                            bool isOnStreet = false;
                                            if (p!.addressComponents.length !=
                                                    null &&
                                                p.addressComponents.length > 0) {
                                              for (var i = 0;
                                                  i < p.addressComponents.length;
                                                  i++) {
                                                var tmp = p.addressComponents[i];
                                                var types = tmp.types;
                                                var shortName = tmp.shortName;
                                                var longName = tmp.longName;
                                                if (types == null) {
                                                  continue;
                                                }
                                                if (i == 0) {
                                                  // [street_number]
                                                  name = shortName;
                                                  isOnStreet = types
                                                      .contains('street_number');
                                                  // other index 0 types
                                                  // [establishment, point_of_interest, subway_station, transit_station]
                                                  // [premise]
                                                  // [route]
                                                } else if (i == 1 && isOnStreet) {
                                                  if (types.contains('route')) {
                                                    name += ", $shortName";
                                                  }
                                                } else {
                                                  if (types.contains(
                                                      "sublocality_level_1")) {
                                                    subLocalityLevel1 = shortName;
                                                  } else if (types.contains(
                                                      "sublocality_level_2")) {
                                                    subLocalityLevel2 = shortName;
                                                  } else if (types
                                                      .contains("locality")) {
                                                    locality = longName;
                                                  } else if (types.contains(
                                                      "administrative_area_level_2")) {
                                                    administrativeAreaLevel2 =
                                                        shortName;
                                                  } else if (types.contains(
                                                      "administrative_area_level_1")) {
                                                    administrativeAreaLevel1 =
                                                        longName;
                                                  } else if (types
                                                      .contains("country")) {
                                                    country = longName;
                                                  } else if (types
                                                      .contains('postal_code')) {
                                                    postalCode = shortName;
                                                  }
                                                }
                                              }
                                            }
                                            locality = locality ??
                                                administrativeAreaLevel1;
                                            city = locality;
                                            var result = LocationResult()
                                              ..name = name
                                              ..locality = locality
                                              ..latLng = LatLng(
                                                  p.geometry.location.lat,
                                                  p.geometry.location.lng)
                                              ..formattedAddress =
                                                  p.formattedAddress
                                              ..placeId = p.placeId
                                              ..postalCode = postalCode
                                              ..country = AddressComponent(
                                                  name: country,
                                                  shortName: country)
                                              ..administrativeAreaLevel1 =
                                                  AddressComponent(
                                                      name:
                                                          administrativeAreaLevel1,
                                                      shortName:
                                                          administrativeAreaLevel1)
                                              ..administrativeAreaLevel2 =
                                                  AddressComponent(
                                                      name:
                                                          administrativeAreaLevel2,
                                                      shortName:
                                                          administrativeAreaLevel2)
                                              ..city = AddressComponent(
                                                  name: city, shortName: city)
                                              ..subLocalityLevel1 =
                                                  AddressComponent(
                                                      name: subLocalityLevel1,
                                                      shortName:
                                                          subLocalityLevel1)
                                              ..subLocalityLevel2 =
                                                  AddressComponent(
                                                      name: subLocalityLevel2,
                                                      shortName:
                                                          subLocalityLevel2);
                            
                                            street1.text = result.name.toString();
                                            landmark1.text = "";
                                            city1.text =
                                                result.city!.shortName.toString();
                                            cutries1.text =
                                                result.country!.shortName.toString();
                                            zipcode1.text =
                                                result.postalCode.toString();
                                            lat = result.latLng!.latitude;
                                            long = result.latLng!.longitude;
                                          },
                                        ),
                                      ),
                                    );
                                    await getDeliveyData();
                                    setState(() {});
                                  }),
                            )),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Visibility(
                        child: Text(
                            "new-delivery-charge".tr() +
                                " $symbol$deliveryCharges",
                            style: TextStyle(
                              fontFamily: "Oswald",
                            )),
                        visible: isLocationChange,
                      ),
                      if(isLocationChange)
                      SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
                SizedBox()
              ])))),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(15),
            backgroundColor: Color(COLOR_PRIMARY),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => validateForm(),
          child: Text(
            'CONTINUE'.tr(),
            style: TextStyle(
                color: isDarkMode(context) ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
      ),
    );
  }

  VendorModel? vendorModel;
  var deliveryCharges = "0.0";
  bool isLocationChange = false;

  getDeliveyData() async {
    print("delivery called");
    if (!widget.takeAway!) {
      print("caen id ${widget.vendorModel!.id} ");
      await FireStoreUtils()
          .getVendorByVendorID(widget.vendorModel!.id)
          .then((value) {
        vendorModel = value;
      });
      num km = num.parse(getKm(
          Position.fromMap({'latitude': lat, 'longitude': long}),
          Position.fromMap({
            'latitude': vendorModel!.latitude,
            'longitude': vendorModel!.longitude
          })));
      await FireStoreUtils().getDeliveryCharges().then((value) {
        if (value != null) {
          DeliveryChargeModel deliveryChargeModel = value;

          if (!deliveryChargeModel.vendorCanModify) {
            if (km > deliveryChargeModel.minimumDeliveryChargesWithinKm) {
              deliveryCharges = (km * deliveryChargeModel.deliveryChargesPerKm)
                  .toDouble()
                  .toStringAsFixed(decimal);
              if (widget.deliveryCharge != deliveryCharges) {
                isLocationChange = true;
              }
              setState(() {});
            } else {
              deliveryCharges = deliveryChargeModel.minimumDeliveryCharges
                  .toDouble()
                  .toStringAsFixed(decimal);
              if (widget.deliveryCharge != deliveryCharges) {
                isLocationChange = true;
              }
              setState(() {});
            }
          } else {
            if (vendorModel != null && vendorModel!.deliveryCharge != null) {
              if (km >
                  vendorModel!.deliveryCharge!.minimumDeliveryChargesWithinKm) {
                deliveryCharges =
                    (km * vendorModel!.deliveryCharge!.deliveryChargesPerKm)
                        .toDouble()
                        .toStringAsFixed(decimal);
                if (widget.deliveryCharge != deliveryCharges) {
                  isLocationChange = true;
                }
                setState(() {});
              } else {
                deliveryCharges = vendorModel!
                    .deliveryCharge!.minimumDeliveryCharges
                    .toDouble()
                    .toStringAsFixed(decimal);
                if (widget.deliveryCharge != deliveryCharges) {
                  isLocationChange = true;
                }
                setState(() {});
              }
              print(
                  "delivery charges ${widget.deliveryCharge!}  dd $deliveryCharges");
            } else {
              if (km > deliveryChargeModel.minimumDeliveryChargesWithinKm) {
                deliveryCharges =
                    (km * deliveryChargeModel.deliveryChargesPerKm)
                        .toDouble()
                        .toStringAsFixed(decimal);
                if (widget.deliveryCharge != deliveryCharges) {
                  isLocationChange = true;
                }
                setState(() {});
              } else {
                deliveryCharges = deliveryChargeModel.minimumDeliveryCharges
                    .toDouble()
                    .toStringAsFixed(decimal);
                if (widget.deliveryCharge != deliveryCharges) {
                  isLocationChange = true;
                }
                setState(() {});
              }
            }
          }
        }
      });
    }
  }

  validateForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      // if (country == null) {
      //   showDialog(
      //     context: context,
      //     builder: (BuildContext context) => ShowDialogToDismiss(
      //       title: 'Error'.tr(),
      //       content: 'Please Select Country'.tr(),
      //       buttonText: 'CLOSE'.tr(),
      //     ),
      //   );
      // } else
      {
        showProgress(context, 'Saving Address...'.tr(), true);

        MyAppState.currentUser!.location = UserLocation(
          latitude: lat == null
              ? MyAppState.currentUser!.shippingAddress.location.latitude ==
                      0.01
                  ? showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          content: Text("select-current-location".tr()),
                          actions: [
                            // FlatButton(
                            //   onPressed: () => Navigator.pop(
                            //       context, false), // passing false
                            //   child: Text('No'),
                            // ),
                            TextButton(
                              onPressed: () {
                                hideProgress();
                                Navigator.pop(context, true);
                              }, // passing true
                              child: Text('OK'.tr()),
                            ),
                          ],
                        );
                      }).then((exit) {
                      if (exit == null) return;

                      if (exit) {
                        // user pressed Yes button
                      } else {
                        // user pressed No button
                      }
                    })
                  : MyAppState.currentUser!.shippingAddress.location.latitude
              : lat,
          longitude: long == null
              ? MyAppState.currentUser!.shippingAddress.location.longitude ==
                      0.01
                  ? showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          content: Text("select-current-location".tr()),
                          actions: [
                            // FlatButton(
                            //   onPressed: () => Navigator.pop(
                            //       context, false), // passing false
                            //   child: Text('No'),
                            // ),
                            TextButton(
                              onPressed: () {
                                hideProgress();
                                Navigator.pop(context, true);
                              }, // passing true
                              child: Text('OK'.tr()),
                            ),
                          ],
                        );
                      }).then((exit) {
                      if (exit == null) return;

                      if (exit) {
                        // user pressed Yes button
                      } else {
                        // user pressed No button
                      }
                    })
                  : MyAppState.currentUser!.shippingAddress.location.longitude
              : long,
          // locationData!.longitude,
        );

        AddressModel userAddress = AddressModel(
            name: MyAppState.currentUser!.fullName(),
            postalCode: zipcode.text.toString(),
            line1: street.text.toString(),
            line2: landmark.text.toString(),
            country: cutries.text.toString(),
            city: city.text.toString(),
            location: MyAppState.currentUser!.location,
            email: MyAppState.currentUser!.email.toString());
        MyAppState.currentUser!.shippingAddress = userAddress;
        await FireStoreUtils.updateCurrentUserAddress(userAddress);
        print(widget.vendorModel!.title);
        var payments =
            await FireStoreUtils().getPayments(widget.vendorModel!.id);
          
        var rate = double.tryParse((await FireStoreUtils().getRate()) ?? 0) ?? 0;
        hideProgress();
        hideProgress();
        debugPrint('==>-  $isLocationChange');
        debugPrint(widget.total.toString());
        debugPrint(isLocationChange
            ? deliveryCharges.toString()
            : widget.deliveryCharge);
        debugPrint(widget.couponCode!);
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PaymentScreen(
                  total: 
                  isLocationChange ? ((widget.total - num.parse(widget.deliveryCharge!)) + num.parse(deliveryCharges)) : widget.total,
                  discount: widget.discount!,
                  couponCode: widget.couponCode,
                  couponId: widget.couponId,
                  products: widget.products,
                  extraAddons: widget.extraAddons,
                  tipValue: widget.tipValue,
                  takeAway: widget.takeAway,
                  rate: rate,
                  vendorModel: widget.vendorModel,
                  deliveryCharge: isLocationChange
                      ? deliveryCharges.toString()
                      : widget.deliveryCharge,
                  notes: widget.notes,
                  specialDiscountMap: widget.specialDiscountMap,
                  taxModel: widget.taxModel,
                  payments: payments,
                )));
        // push(
        //   context,
        //   PaymentScreen(
        //     total: widget.total,
        //     // isLocationChange ? ((widget.total - num.parse(widget.deliveryCharge!)) + num.parse(deliveryCharges)) : widget.total,
        //     discount: widget.discount!,
        //     couponCode: widget.couponCode,
        //     couponId: widget.couponId,
        //     products: widget.products!,
        //     extraAddons: widget.extraAddons,
        //     tipValue: widget.tipValue,
        //     takeAway: widget.takeAway,
        //     vendorModel: widget.vendorModel,
        //     deliveryCharge: isLocationChange
        //         ? deliveryCharges.toString()
        //         : widget.deliveryCharge,
        //     notes: widget.notes,
        //     specialDiscountMap: widget.specialDiscountMap,
        //     taxModel: widget.taxModel,
        //   ),
        // );
      }
    } else {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }
}
