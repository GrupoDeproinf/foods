import 'dart:developer';

import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:custom_food/constants.dart';
import 'package:custom_food/main.dart';
import 'package:custom_food/model/OrderModel.dart';
import 'package:custom_food/model/ProductModel.dart';
import 'package:custom_food/model/VendorModel.dart';
import 'package:custom_food/services/FirebaseHelper.dart';
import 'package:custom_food/services/helper.dart';
import 'package:custom_food/services/localDatabase.dart';
import 'package:custom_food/services/web_cart/webCart.dart';
import 'package:custom_food/ui/placeOrderScreen/PlaceOrderScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../model/PaymentModel.dart';
import '../../model/TaxModel.dart';
import '../container/ContainerScreen.dart';
import '../ordersScreen/OrdersScreen.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final String paymentOption, paymentType;
  final double total;
  final double? discount;
  final String? couponCode;
  final String? couponId, notes;
  final List<CartProduct> products;
  final List<String>? extraAddons;
  final String? tipValue;
  final bool? takeAway;
  final String? deliveryCharge;
  final String? size;
  final bool isPaymentDone;
  final TaxModel? taxModel;
  final VendorModel? vendorModel;
  final Map<String, dynamic>? specialDiscountMap;
  final List<Map<String, dynamic>>? payments;
  final double? rate;

  const CheckoutScreen({
    Key? key,
    required this.isPaymentDone,
    required this.paymentOption,
    required this.paymentType,
    required this.total,
    this.discount,
    this.couponCode,
    this.couponId,
    this.notes,
    this.rate,
    required this.products,
    this.vendorModel,
    this.extraAddons,
    this.tipValue,
    this.takeAway,
    this.deliveryCharge,
    this.taxModel,
    this.specialDiscountMap,
    this.payments,
    this.size,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final fireStoreUtils = FireStoreUtils();
  late Map<String, dynamic>? adminCommission;
  String? adminCommissionValue = "", addminCommissionType = "";
  bool? isEnableAdminCommission = false;
  PageController controller = PageController(initialPage: 0);
  var phone = TextEditingController();
  var verification = TextEditingController();
  var email = TextEditingController();
  var name = TextEditingController();
  var prefixList = ["0414", "0424", "0412", "0416", "0426"];
  var bankList = [
    "Banco de Venezuela",
    "Banco Venezolano de Crédito",
    "Banco Mercantil",
    "Banco Provincial",
    "Bancaribe",
    "Banco Exterior",
    "Banco Occidental de Descuento",
    "Banco Caroní",
    "Banesco",
    "Sofitasa",
    "Banco Plaza",
    "Banco de la Gente Emprendedora",
    "BFC Banco Fondo Común",
    "100% Banco",
    "DelSur Banco Universal",
    "Banco del Tesoro",
    "Banco Agrícola de Venezuela",
    "Bancrecer",
    "Mi Banco",
    "Banco Activo",
    "Bancamiga",
    "Banco Internacional de Desarrollo",
    "Banplus",
    "Banco Bicentenario",
    "Novo Banco",
    "BANFANB",
    "Citibank",
    "Banco Nacional de Crédito",
    "Instituto Municipal de Crédito Popular"
  ];
  String? prefix;
  String? bank;
  DateTime? fecha = DateTime.now();
  GlobalKey<FormState> _keyPM = GlobalKey();
  GlobalKey<FormState> _keyZelle = GlobalKey();

  @override
  void initState() {
    print(widget.deliveryCharge);
    super.initState();
    prefix = prefixList.first;
    placeAutoOrder();
    fireStoreUtils.getAdminCommission().then((value) {
      if (value != null) {
        setState(() {
          adminCommission = value;
          adminCommissionValue = adminCommission!["adminCommission"].toString();
          addminCommissionType =
              adminCommission!["adminCommissionType"].toString();
          isEnableAdminCommission = adminCommission!["isAdminCommission"];
        });
      }
    });
  }

  placeAutoOrder() {
    if (widget.isPaymentDone) {
      Future.delayed(Duration(seconds: 2), () {
        placeOrder();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor:
          isDarkMode(context) ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(COLOR_PRIMARY)),
          onPressed: () {
            controller.page == 1
                ? controller.previousPage(
                    duration: Duration(milliseconds: 500), curve: Curves.easeIn)
                : Navigator.pop(context);
          },
        ),
      ),
      body: PageView(
        scrollDirection: Axis.vertical,
        controller: controller,
        children: [
          GestureDetector(
            onVerticalDragStart: (_) {},
            onVerticalDragEnd: (_) {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 15),
                  child: Text(
                    'Checkout'.tr(),
                    style: TextStyle(
                        fontSize: 24,
                        color: isDarkMode(context)
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                        child: ListTile(
                          leading: Text(
                            'Payment'.tr(),
                            style: TextStyle(
                                color: Color(COLOR_PRIMARY),
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          trailing: Text(
                            widget.paymentOption,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      Divider(
                        height: 3,
                      ),
                      Container(
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Deliver to'.tr(),
                                style: TextStyle(
                                    color: Color(COLOR_PRIMARY),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 2,
                                child: Text(
                                  '${MyAppState.currentUser!.shippingAddress.line1} ${MyAppState.currentUser!.shippingAddress.line2}',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 3,
                      ),
                      Container(
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                        child: ListTile(
                          leading: Text(
                            "Subtotal".tr(),
                            style: TextStyle(
                                color: Color(COLOR_PRIMARY),
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          trailing: Text(
                            symbol +
                                (widget.total.toDouble() -
                                        double.parse(widget.deliveryCharge!))
                                    .toStringAsFixed(decimal),
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: widget.vendorModel!.country == "VE" &&
                            widget.paymentOption != "Pago Móvil".tr(),
                        child: Container(
                          color:
                              isDarkMode(context) ? Colors.black : Colors.white,
                          child: ListTile(
                            leading: Text(
                              "IGTF (3%)".tr(),
                              style: TextStyle(
                                  color: Color(COLOR_PRIMARY),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            trailing: Text(
                              symbol +
                                  ((widget.total.toDouble() -
                                              double.parse(
                                                  widget.deliveryCharge!)) *
                                          0.03)
                                      .toStringAsFixed(decimal),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                        child: ListTile(
                          leading: Text(
                            "Delivery Option: ".tr(),
                            style: TextStyle(
                                color: Color(COLOR_PRIMARY),
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          trailing: Text(
                            symbol + widget.deliveryCharge!,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: widget.vendorModel!.country == "VE" &&
                            widget.paymentOption == "Pago Móvil".tr(),
                        child: Container(
                          color:
                              isDarkMode(context) ? Colors.black : Colors.white,
                          child: ListTile(
                            leading: Text(
                              "Total".tr(),
                              style: TextStyle(
                                  color: Color(COLOR_PRIMARY),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            trailing: Text(
                              symbol +
                                  (widget.total.toDouble())
                                      .toStringAsFixed(decimal),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: widget.vendorModel!.country == "VE" &&
                            widget.paymentOption != "Pago Móvil".tr(),
                        child: Container(
                          color:
                              isDarkMode(context) ? Colors.black : Colors.white,
                          child: ListTile(
                            leading: Text(
                              "Total".tr(),
                              style: TextStyle(
                                  color: Color(COLOR_PRIMARY),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            trailing: Text(
                              symbol +
                                  (widget.total.toDouble() +
                                          double.parse(((widget.total
                                                          .toDouble() -
                                                      double.parse(widget
                                                          .deliveryCharge!)) *
                                                  0.03)
                                              .toStringAsFixed(decimal)))
                                      .toStringAsFixed(decimal),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: widget.vendorModel!.country != "VE",
                        child: Container(
                          color:
                              isDarkMode(context) ? Colors.black : Colors.white,
                          child: ListTile(
                            leading: Text(
                              "Total".tr(),
                              style: TextStyle(
                                  color: Color(COLOR_PRIMARY),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            trailing: Text(
                              symbol +
                                  (widget.total.toDouble())
                                      .toStringAsFixed(decimal),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                    shrinkWrap: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Color(COLOR_PRIMARY),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (widget.vendorModel!.country == "VE" &&
                          widget.paymentOption != 'Cash on Delivery'.tr()) {
                        controller.nextPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeIn);
                      } else {
                        if (!widget.isPaymentDone) {
                          Future.delayed(Duration(milliseconds: 500), () {
                            placeOrder();
                          });
                        }
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Visibility(
                            visible: widget.isPaymentDone,
                            child: SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ))),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          (widget.vendorModel!.country == "VE" &&
                                  widget.paymentOption !=
                                      'Cash on Delivery'.tr())
                              ? 'PAY'.tr()
                              : 'PLACE ORDER'.tr(),
                          style: TextStyle(
                              color: isDarkMode(context)
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.vendorModel!.country == "VE" &&
              widget.paymentOption != 'Cash on Delivery'.tr())
            GestureDetector(
              onVerticalDragStart:
                  MediaQuery.of(context).viewInsets.bottom == 0 ? (_) {} : null,
              onVerticalDragEnd:
                  MediaQuery.of(context).viewInsets.bottom == 0 ? (_) {} : null,
              child: SingleChildScrollView(
                primary: true,
                child: SafeArea(
                  // height: MediaQuery.of(context).size.height -
                  //     90,
                  // width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 5),
                        child: Text(
                          'Datos para el Pago'.tr(),
                          style: TextStyle(
                              fontSize: 22,
                              color: isDarkMode(context)
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade800,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (widget.paymentOption == "Pago Móvil".tr())
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 13, top: 10, right: 13, bottom: 13),
                              decoration: BoxDecoration(
                                color: isDarkMode(context)
                                    ? Colors.grey.shade700
                                    : Colors.white,
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 2,
                                    offset: const Offset(
                                        0, 2), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Divider(
                                    color: Color(0xffE2E8F0),
                                    height: 0.1,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Text(
                                        "Banco".tr(),
                                        style: const TextStyle(
                                            color: Color(COLOR_PRIMARY),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      trailing: Text(
                                        widget.payments!.firstWhere((element) =>
                                            element["name"] ==
                                            "Pago Móvil")["data"]["banco"],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    color: Color(0xffE2E8F0),
                                    height: 0.1,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 15,
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Text(
                                        "Teléfono".tr(),
                                        style: const TextStyle(
                                            color: Color(COLOR_PRIMARY),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.payments!.firstWhere(
                                                    (element) =>
                                                        element["name"] ==
                                                        "Pago Móvil")["data"]
                                                ["telefono"],
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(width: 5),
                                          GestureDetector(
                                            onTap: () async {
                                              FlutterClipboard.copy(widget
                                                          .payments!
                                                          .firstWhere(
                                                              (element) =>
                                                                  element[
                                                                      "name"] ==
                                                                  "Pago Móvil")[
                                                      "data"]["telefono"])
                                                  .then((value) {
                                                final SnackBar snackBar =
                                                    SnackBar(
                                                  content: Text(
                                                    "Teléfono copiado".tr(),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  backgroundColor:
                                                      Colors.black38,
                                                );
                                                ScaffoldMessenger.of(context)
                                                    .hideCurrentSnackBar();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(snackBar);
                                              });
                                            },
                                            child: const Icon(
                                                Icons.copy_all_rounded,
                                                size: 22),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    color: Color(0xffE2E8F0),
                                    height: 0.1,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 15,
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Text(
                                        "RIF".tr(),
                                        style: const TextStyle(
                                            color: Color(COLOR_PRIMARY),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.payments!.firstWhere(
                                                    (element) =>
                                                        element["name"] ==
                                                        "Pago Móvil")["data"]
                                                ["rif_ci"],
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(width: 5),
                                          GestureDetector(
                                              onTap: () async {
                                                FlutterClipboard.copy(widget
                                                            .payments!
                                                            .firstWhere((element) =>
                                                                element[
                                                                    "name"] ==
                                                                "Pago Móvil")[
                                                        "data"]["rif_ci"])
                                                    .then((value) {
                                                  final SnackBar snackBar =
                                                      SnackBar(
                                                    content: Text(
                                                      "RIF copiado".tr(),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    backgroundColor:
                                                        Colors.black38,
                                                  );
                                                  ScaffoldMessenger.of(context)
                                                      .hideCurrentSnackBar();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(snackBar);
                                                });
                                              },
                                              child: const Icon(
                                                  Icons.copy_all_rounded,
                                                  size: 22))
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    color: Color(0xffE2E8F0),
                                    height: 0.1,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Text(
                                        "Monto".tr(),
                                        style: TextStyle(
                                            color: Color(COLOR_PRIMARY),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      trailing: widget.rate == null
                                          ? Text(
                                              symbol +
                                                  (widget.total.toDouble())
                                                      .toStringAsFixed(decimal),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            )
                                          : Text(
                                              "Bs. " +
                                                  (widget.total.toDouble() *
                                                          widget.rate!)
                                                      .toStringAsFixed(decimal),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 5),
                              child: Text(
                                'Datos del pago realizado'.tr(),
                                style: TextStyle(
                                    fontSize: 20,
                                    color: isDarkMode(context)
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade800,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            formPagoMovil(),
                          ],
                        ),
                      if (widget.paymentOption == "Zelle".tr())
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 13, top: 10, right: 13, bottom: 13),
                              decoration: BoxDecoration(
                                color: isDarkMode(context)
                                    ? Colors.grey.shade700
                                    : Colors.white,
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 2,
                                    offset: const Offset(
                                        0, 2), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Divider(
                                    color: Color(0xffE2E8F0),
                                    height: 0.1,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 0),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Text(
                                        "Correo".tr(),
                                        style: TextStyle(
                                            color: Color(COLOR_PRIMARY),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.payments!.firstWhere(
                                                (element) =>
                                                    element["name"] ==
                                                    "Zelle")["data"]["correo"],
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(width: 5),
                                          GestureDetector(
                                            onTap: () async {
                                              FlutterClipboard.copy(widget
                                                          .payments!
                                                          .firstWhere(
                                                              (element) =>
                                                                  element[
                                                                      "name"] ==
                                                                  "Zelle")[
                                                      "data"]["correo"])
                                                  .then((value) {
                                                final SnackBar snackBar =
                                                    SnackBar(
                                                  content: Text(
                                                    "Correo copiado".tr(),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  backgroundColor:
                                                      Colors.black38,
                                                );
                                                ScaffoldMessenger.of(context)
                                                    .hideCurrentSnackBar();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(snackBar);
                                              });
                                            },
                                            child: const Icon(
                                                Icons.copy_all_rounded,
                                                size: 22),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    color: Color(0xffE2E8F0),
                                    height: 0.1,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 0),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Text(
                                        "Titular".tr(),
                                        style: TextStyle(
                                            color: Color(COLOR_PRIMARY),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      trailing: Text(
                                        widget.payments!.firstWhere((element) =>
                                            element["name"] ==
                                            "Zelle")["data"]["titular"],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    color: Color(0xffE2E8F0),
                                    height: 0.1,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 0),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Text(
                                        "Monto".tr(),
                                        style: TextStyle(
                                            color: Color(COLOR_PRIMARY),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      trailing: Text(
                                        symbol +
                                            (widget.total.toDouble() +
                                                    (widget.total.toDouble() *
                                                        0.03))
                                                .toStringAsFixed(decimal),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 5),
                              child: Text(
                                'Datos del pago realizado'.tr(),
                                style: TextStyle(
                                    fontSize: 20,
                                    color: isDarkMode(context)
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade800,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            formZelle(),
                          ],
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24,
                            MediaQuery.of(context).viewInsets.bottom + 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            backgroundColor: Color(COLOR_PRIMARY),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            if (widget.paymentOption == "Pago Móvil".tr()) {
                              if (_keyPM.currentState?.validate() ?? false) {
                                if (!widget.isPaymentDone)
                                  _keyPM.currentState!.save();
                                placeOrder();
                              }
                            } else {
                              if (_keyZelle.currentState?.validate() ?? false) {
                                if (!widget.isPaymentDone)
                                  _keyZelle.currentState!.save();
                                placeOrder();
                              }
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Visibility(
                                  visible: widget.isPaymentDone,
                                  child: SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ))),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'PLACE ORDER'.tr(),
                                style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> setPrefData() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString("musics_keyPM", "");
    sp.setString("addsize", "");
  }

  placeOrder() async {
    List<CartProduct> tempProduc = [];

    for (CartProduct cartProduct in widget.products) {
      CartProduct tempCart = cartProduct;
      // tempCart.extras = cartProduct.extras?.split(",");
      tempProduc.add(tempCart);
    }
    FireStoreUtils fireStoreUtils = FireStoreUtils();
    //place order
    showProgress(context, 'Placing Order...'.tr(), false);
    VendorModel vendorModel = await fireStoreUtils
        .getVendorByVendorID(MyAppState.currentUser!.defaultRestaurant!["id"])
        .whenComplete(() => setPrefData());
    log(vendorModel.fcmToken.toString() +
        "{}{}{}{======TOKENADD" +
        vendorModel.toJson().toString());
    OrderModel orderModel = OrderModel(
        address: MyAppState.currentUser!.shippingAddress,
        author: MyAppState.currentUser,
        authorID: MyAppState.currentUser!.userID,
        createdAt: Timestamp.now(),
        products: tempProduc,
        status: widget.paymentOption == "Cash on Delivery".tr()
            ? ORDER_STATUS_CONFIRMATION_PENDING
            : ORDER_STATUS_PAYMENT_PENDING,
        vendor: vendorModel,
        vendorID: vendorModel.id,
        discount: widget.discount,
        couponCode: widget.couponCode,
        couponId: widget.couponId,
        payment: vendorModel.country == "VE" &&
                widget.paymentOption != "Cash on Delivery".tr()
            ? PaymentModel(
                amount: vendorModel.country == "VE" &&
                        widget.paymentOption != "Pago Móvil".tr()
                    ? (widget.total.toDouble() +
                        (widget.total.toDouble() * 0.03))
                    : widget.total.toDouble(),
                confirmed: false,
                paymentMethod: widget.paymentOption,
                date: Timestamp.fromDate(fecha ?? DateTime.now()),
                fullName:
                    name.text.isEmpty ? null : name.text.trim().toUpperCase(),
                exchangeRate: 0,
                bank: bank,
                email:
                    email.text.isEmpty ? null : email.text.trim().toUpperCase(),
                phone: widget.paymentOption == "Pago Móvil".tr()
                    ? prefix! + "-" + phone.text
                    : null,
                paymentId: verification.text.isEmpty ? null : verification.text,
                confirmDate: null,
              )
            : null,
        notes: widget.notes,
        taxModel: widget.taxModel,
        paymentMethod: widget.paymentOption,
        specialDiscount: widget.specialDiscountMap,
        //// extra_size: widget.extra_size,
        // extras: widget.extra_addons!,
        tipValue: widget.tipValue,
        adminCommission: isEnableAdminCommission! ? adminCommissionValue : "0",
        adminCommissionType:
            isEnableAdminCommission! ? addminCommissionType : "",
        takeAway: widget.takeAway,
        deliveryCharge: widget.deliveryCharge);

    OrderModel placedOrder = await fireStoreUtils.placeOrder(orderModel);
    for (int i = 0; i < tempProduc.length; i++) {
      await FireStoreUtils()
          .getProductByID(tempProduc[i].id.split('~').first)
          .then((value) async {
        ProductModel? productModel = value;
        log("-----------1>${value.toJson()}");
        if (tempProduc[i].variant_info != null) {
          for (int j = 0;
              j < productModel.itemAttributes!.variants!.length;
              j++) {
            if (productModel.itemAttributes!.variants![j].variantId ==
                tempProduc[i].id.split('~').last) {
              if (productModel.itemAttributes!.variants![j].variantQuantity !=
                  "-1") {
                productModel.itemAttributes!.variants![j].variantQuantity =
                    (int.parse(productModel
                                .itemAttributes!.variants![j].variantQuantity
                                .toString()) -
                            tempProduc[i].quantity)
                        .toString();
              }
            }
          }
        } else {
          if (productModel.quantity != -1) {
            productModel.quantity =
                productModel.quantity - tempProduc[i].quantity;
          }
        }

        // await FireStoreUtils.updateProduct(productModel).then((value) {
        //   log("-----------2>${value!.toJson()}");
        // });
      });
    }

    hideProgress();
    FireStoreUtils.sendFcmMessage(
        "newOrder".tr(),
        '${MyAppState.currentUser!.firstName}' + "hasOrdered",
        placedOrder.vendor.fcmToken);

    if(kIsWeb){
      Provider.of<WebCart>(context, listen: false).deleteAllProducts();
    }
    else{
    Provider.of<CartDatabase>(context, listen: false).deleteAllProducts();
}
    pushAndRemoveUntil(
        context,
        ContainerScreen(
          user: MyAppState.currentUser!,
          currentWidget: OrdersScreen(isAnimation: true),
          appBarTitle: 'Orders'.tr(),
          drawerSelection: DrawerSelection.Orders,
        ),
        false);
  }

  Widget formPagoMovil() {
    return Column(
      children: [
        Form(
          key: _keyPM,
          autovalidateMode: AutovalidateMode.always,
          child: Container(
            margin:
                const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
            decoration: BoxDecoration(
              color: isDarkMode(context) ? Colors.grey.shade700 : Colors.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 2,
                  offset: const Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              children: [
                const Divider(
                  color: Color(0xffE2E8F0),
                  height: 0.1,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 25, end: 20, bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width - 71,
                        child: DropdownButtonFormField(
                            validator: (value) {
                              return (value == null)
                                  ? "Debe escoger un banco".tr()
                                  : null;
                            },
                            alignment: Alignment.center,
                            hint: Text("Banco"),
                            items: bankList
                                .map((e) => DropdownMenuItem(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: Text(e,
                                          style: TextStyle(fontSize: 15.0)),
                                    ),
                                    value: e))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                bank = value;
                              });
                            },
                            value: bank),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Color(0xffE2E8F0),
                  height: 0.1,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 20, end: 20, bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                          flex: 1,
                          child: PopupMenuButton(
                            itemBuilder: (context) => prefixList
                                .map((e) => PopupMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            onSelected: (value) {
                              setState(() {
                                prefix = value;
                              });
                            },
                            child: TextFormField(
                              enabled: false,
                              controller: TextEditingController(text: prefix),
                              textAlignVertical: TextAlignVertical.center,
                              textInputAction: TextInputAction.next,
                              validator: validateEmptyField,
                              onSaved: (text) => prefix = text!,
                              style: TextStyle(fontSize: 15.0),
                              keyboardType: TextInputType.phone,
                              cursorColor: Color(COLOR_PRIMARY),
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Teléfono'.tr(),
                                labelStyle: TextStyle(
                                    color: Color(0Xff696A75), fontSize: 15),
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade400),
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
                            ),
                          )),
                      // Container(
                      //   child: DropdownButton(
                      //       items: prefixList
                      //           .map((e) => DropdownMenuItem(
                      //               child: Padding(
                      //                 padding: const EdgeInsets.symmetric(
                      //                     horizontal: 5),
                      //                 child: Text(e,
                      //                     style: TextStyle(fontSize: 15.0)),
                      //               ),
                      //               value: e))
                      //           .toList(),
                      //       onChanged: (value) {
                      //         setState(() {
                      //           prefix = value;
                      //         });
                      //       },
                      //       value: prefix),
                      // ),

                      Expanded(
                          flex: 6,
                          child: TextFormField(
                            controller: phone,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            validator: validateVEMobile,
                            onSaved: (text) => phone.text = text!,
                            style: TextStyle(fontSize: 15.0),
                            keyboardType: TextInputType.phone,
                            cursorColor: Color(COLOR_PRIMARY),
                            decoration: InputDecoration(
                              labelStyle: TextStyle(
                                  color: Color(0Xff696A75), fontSize: 15),
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
                    ],
                  ),
                ),
                const Divider(
                  color: Color(0xffE2E8F0),
                  height: 0.1,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 20, end: 20, bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await showDatePicker(
                                    builder: (context, child) {
                                      return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: Color(COLOR_APPBAR),
                                            ),
                                          ),
                                          child: child!);
                                    },
                                    context: context,
                                    initialDate: fecha ?? DateTime.now(),
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 7)),
                                    lastDate: DateTime.now())
                                .then((value) {
                              setState(() {
                                fecha = value;
                              });
                            });
                          },
                          child: TextFormField(
                            enabled: false,
                            controller: TextEditingController(
                                text: DateFormat("dd/MM/yyyy")
                                    .format(fecha ?? DateTime.now())),
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            validator: validateEmptyField,
                            style: TextStyle(fontSize: 15.0),
                            keyboardType: TextInputType.phone,
                            cursorColor: Color(COLOR_PRIMARY),
                            decoration: InputDecoration(
                              labelText: 'Fecha de pago'.tr(),
                              labelStyle: TextStyle(
                                  color: Color(0Xff696A75), fontSize: 15),
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Color(0xffE2E8F0),
                  height: 0.1,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 20, end: 20, bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                          child: TextFormField(
                        controller: verification,
                        textAlignVertical: TextAlignVertical.center,
                        textInputAction: TextInputAction.next,
                        validator: (String? value) {
                          return ((value?.length ?? 0) != 4)
                              ? "Máx. 4 dígitos".tr()
                              : null;
                        },
                        onSaved: (text) => verification.text = text!,
                        style: TextStyle(fontSize: 15.0),
                        keyboardType: TextInputType.phone,
                        cursorColor: Color(COLOR_PRIMARY),
                        decoration: InputDecoration(
                          labelText: 'Últimos 4 dígitos'.tr(),
                          labelStyle:
                              TextStyle(color: Color(0Xff696A75), fontSize: 15),
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Theme.of(context).errorColor),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Theme.of(context).errorColor),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                            // borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget formZelle() {
    return Column(
      children: [
        Form(
          key: _keyZelle,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Container(
            margin:
                const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
            decoration: BoxDecoration(
              color: isDarkMode(context) ? Colors.grey.shade700 : Colors.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 2,
                  offset: const Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              children: [
                const Divider(
                  color: Color(0xffE2E8F0),
                  height: 0.1,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 20, end: 20, bottom: 10),
                  child: TextFormField(
                    controller: email,
                    textAlignVertical: TextAlignVertical.center,
                    textInputAction: TextInputAction.next,
                    validator: validateEmail,
                    onSaved: (text) => phone.text = text!,
                    style: TextStyle(fontSize: 15.0),
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: Color(COLOR_PRIMARY),
                    decoration: InputDecoration(
                      labelText: 'emailAddress'.tr(),
                      labelStyle:
                          TextStyle(color: Color(0Xff696A75), fontSize: 15),
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                        // borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const Divider(
                  color: Color(0xffE2E8F0),
                  height: 0.1,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 20, end: 20, bottom: 10),
                  child: TextFormField(
                    controller: name,
                    textAlignVertical: TextAlignVertical.center,
                    textInputAction: TextInputAction.next,
                    validator: validateName,
                    onSaved: (text) => phone.text = text!,
                    style: TextStyle(fontSize: 15.0),
                    keyboardType: TextInputType.name,
                    cursorColor: Color(COLOR_PRIMARY),
                    decoration: InputDecoration(
                      labelText: 'Nombre y Apellido del Titular'.tr(),
                      labelStyle:
                          TextStyle(color: Color(0Xff696A75), fontSize: 15),
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                        // borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 20, end: 20, bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: MediaQuery.of(context).size.width / 3.5,
                          child: GestureDetector(
                            onTap: () async {
                              await showDatePicker(
                                      builder: (context, child) {
                                        return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: Color(COLOR_APPBAR),
                                              ),
                                            ),
                                            child: child!);
                                      },
                                      context: context,
                                      initialDate: fecha ?? DateTime.now(),
                                      firstDate: DateTime.now()
                                          .subtract(const Duration(days: 7)),
                                      lastDate: DateTime.now())
                                  .then((value) {
                                setState(() {
                                  fecha = value;
                                });
                              });
                            },
                            child: TextFormField(
                              enabled: false,
                              controller: TextEditingController(
                                  text: DateFormat("dd/MM/yyyy")
                                      .format(fecha ?? DateTime.now())),
                              textAlignVertical: TextAlignVertical.center,
                              textInputAction: TextInputAction.next,
                              validator: validateEmptyField,
                              style: TextStyle(fontSize: 15.0),
                              keyboardType: TextInputType.phone,
                              cursorColor: Color(COLOR_PRIMARY),
                              decoration: InputDecoration(
                                labelText: 'Fecha de pago'.tr(),
                                labelStyle: TextStyle(
                                    color: Color(0Xff696A75), fontSize: 15),
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade400),
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
                            ),
                          )),
                      const SizedBox(width: 20),
                      Expanded(
                          child: TextFormField(
                        controller: verification,
                        textAlignVertical: TextAlignVertical.center,
                        textInputAction: TextInputAction.next,
                        validator: (String? value) {
                          return ((value?.length ?? 0) != 4)
                              ? "Máx. 4 dígitos".tr()
                              : null;
                        },
                        onSaved: (text) => verification.text = text!,
                        style: TextStyle(fontSize: 15.0),
                        keyboardType: TextInputType.phone,
                        cursorColor: Color(COLOR_PRIMARY),
                        decoration: InputDecoration(
                          labelText: 'Últimos 4 dígitos'.tr(),
                          labelStyle:
                              TextStyle(color: Color(0Xff696A75), fontSize: 15),
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Theme.of(context).errorColor),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Theme.of(context).errorColor),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                            // borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
