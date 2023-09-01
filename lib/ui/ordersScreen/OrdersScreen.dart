// ignore_for_file: must_be_immutable

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/OrderModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/orderDetailsScreen/OrderDetailsScreen.dart';
import 'package:provider/provider.dart';

class OrdersScreen extends StatefulWidget {
  bool? isAnimation = true;

  OrdersScreen({super.key, this.isAnimation});
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Stream<List<OrderModel>> ordersFuture;
  FireStoreUtils _fireStoreUtils = FireStoreUtils();
  List<OrderModel> ordersList = [];
  late CartDatabase cartDatabase;

  @override
  void initState() {
    super.initState();
    ordersFuture = _fireStoreUtils.getOrders(MyAppState.currentUser!.userID);
    if (widget.isAnimation != null && widget.isAnimation!) {
      Future.delayed(
          Duration(milliseconds: 500),
          () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  margin: EdgeInsets.only(left: 40, right: 40, bottom: 10),
                  behavior: SnackBarBehavior.floating,
                  dismissDirection: DismissDirection.down,
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 120),
                        child: Text(
                          "placedOrder".tr(),
                          style: TextStyle(
                              fontFamily: "Oswald",
                              color: Colors.white,
                              fontWeight: FontWeight.normal),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  duration: Duration(milliseconds: 4000),
                  backgroundColor: const Color(COLOR_APPBAR),
                ),
              ));
    }
  }

  @override
  void didChangeDependencies() {
    cartDatabase = Provider.of<CartDatabase>(context, listen: false);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    FireStoreUtils().closeOrdersStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode(context) ? Color(DARK_COLOR) : Color(0xffFFFFFF),
      // Color(0XFFF1F4F7),
      body: StreamBuilder<List<OrderModel>>(
          stream: ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Container(
                child: Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  ),
                ),
              );
            if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
              return SizedBox(
                width: MediaQuery.of(context).size.width * 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/delivery.png",
                        height: 90,
                        width: 90,
                      ),
                      showEmptyState('No Previous Orders'.tr(), context,
                          description: "orders-food".tr()),
                    ],
                  ),
                ),
              );
            } else {
              // ordersList = snapshot.data!;
              return ListView.builder(
                  itemCount: snapshot.data!.toSet().toList().length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) =>
                      buildOrderItem(snapshot.data!.toSet().toList()[index]));
            }
          }),
    );
  }

  Widget buildOrderItem(OrderModel orderModel) {
    double total = 0.0;
    var asset = "";
    orderModel.products.forEach((element) {
      try {
        if (element.extras_price!.isNotEmpty &&
            double.parse(element.extras_price!) != 0.0) {
          total += element.quantity * double.parse(element.extras_price!);
        }
        total += element.quantity * double.parse(element.price);
      } catch (ex) {}
    });
    total = total - orderModel.discount!;
    total = total + (double.tryParse(orderModel.deliveryCharge!) ?? 0);
    switch (orderModel.status) {
      case ORDER_STATUS_CONFIRMED:
        asset = "assets/images/aprobado.png";
        break;
      case ORDER_STATUS_COMPLETED:
        asset = "assets/images/entregado.png";
        break;
      case ORDER_STATUS_DELIVERY:
        asset = "assets/images/delivery.png";
        break;
      case ORDER_STATUS_REJECTED:
        asset = "assets/images/rechazado.png";
        break;
      default:
        asset = "assets/images/en_revision.png";
    }
    return Card(
        color:
            isDarkMode(context) ? Color(DARK_CARD_BG_COLOR) : Color(0xffFFFFFF),
        margin: EdgeInsets.only(bottom: 30, right: 5, left: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding:
              const EdgeInsets.only(top: 5, bottom: 15, right: 10, left: 10),
          child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => push(
                  context,
                  OrderDetailsScreen(
                    orderModel: orderModel,
                  )),
              child: Column(children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        CachedNetworkImage(
                          height: 55,
                          width: 55,
                          // width: 50,
                          imageUrl: getImageVAlidUrl(orderModel
                                      .products.first.photo
                                      .toString()) ==
                                  placeholderImage
                              ? ""
                              : getImageVAlidUrl(
                                  orderModel.products.first.photo.toString()),

                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                )),
                          ),
                          placeholder: (context, url) => Image.asset(
                            "assets/images/plato_generico.png",
                            height: 55,
                            width: 55,
                            cacheHeight:
                                (MediaQuery.of(context).size.height * 0.11)
                                    .toInt(),
                            cacheWidth:
                                (MediaQuery.of(context).size.width * 0.23)
                                    .toInt(),
                          ),
                          errorWidget: (context, url, widget) => Image.asset(
                            "assets/images/plato_generico.png",
                            height: 55,
                            width: 55,
                            cacheHeight:
                                (MediaQuery.of(context).size.height * 0.11)
                                    .toInt(),
                            cacheWidth:
                                (MediaQuery.of(context).size.width * 0.23)
                                    .toInt(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Image.asset(
                            asset,
                            height: 25,
                            width: 25,
                            cacheHeight:
                                (MediaQuery.of(context).size.height * 0.11)
                                    .toInt(),
                            cacheWidth:
                                (MediaQuery.of(context).size.width * 0.23)
                                    .toInt(),
                          ),
                        ),
                      ],
                    ),
                    // Container(
                    //   height: 90,
                    //   width: 90,

                    //   decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.circular(12),
                    //     image: DecorationImage(
                    //       image: NetworkImage(
                    //           (orderModel.products.first.photo.isNotEmpty)
                    //               ? orderModel.products.first.photo
                    //               : placeholderImage),
                    //       fit: BoxFit.cover,
                    //       colorFilter: ColorFilter.mode(
                    //           Colors.black.withOpacity(0.5), BlendMode.darken),
                    //     ),
                    //   ),

                    //   // child: Center(
                    //   //   child: Text(
                    //   //     '${orderDate(orderModel.createdAt)} - ${orderModel.status}',
                    //   //     style: TextStyle(color: Colors.white, fontSize: 17),
                    //   //   ),
                    //   // ),
                    // ),
                    SizedBox(
                      width: 15,
                    ),
                    Expanded(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'ORDER ID:'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Poppinsm',
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                    color: isDarkMode(context)
                                        ? Colors.grey.shade300
                                        : Color(0xff9091A4),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  orderModel.id.substring(0, 4),
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: isDarkMode(context)
                                          ? Colors.grey.shade200
                                          : Color(0XFF000000),
                                      fontFamily: "Oswald"),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text(orderModel.status.tr(),
                                    style: TextStyle(
                                        color: isDarkMode(context)
                                            ? Colors.grey.shade200
                                            : Color(0XFF555353),
                                        fontFamily: "Poppinsr"))),
                            SizedBox(width: 3),
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                orderModel.paymentMethod != "Pago Móvil".tr()
                                    ? symbol +
                                        (((total -
                                                        double.parse(orderModel
                                                            .deliveryCharge!)) *
                                                    1.03) +
                                                double.parse(
                                                    orderModel.deliveryCharge!))
                                            .toStringAsFixed(decimal)
                                    : symbol + total.toStringAsFixed(decimal),
                                style: TextStyle(
                                    fontSize: 20,
                                    color: isDarkMode(context)
                                        ? Colors.grey.shade200
                                        : Color(COLOR_PRIMARY),
                                    fontFamily: "Poppinssm",
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Image(
                              image:
                                  AssetImage("assets/images/verti_divider.png"),
                              height: 10,
                              width: 10,
                              color: Color(0XFF555353),
                            ),
                            Text(orderDate(orderModel.createdAt),
                                style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.grey.shade200
                                        : Color(0XFF555353),
                                    fontFamily: "Poppinsr")),
                          ],
                        ),
                      ],
                    )),
                  ],
                ),
                SizedBox(height: 0),
              ])),
        ));
  }

  String? getPrice(OrderModel product, int index, CartProduct cartProduct) {
    /*double.parse(product.price)
        .toStringAsFixed(decimal)*/
    var subTotal;
    var price = cartProduct.extras_price == "" ||
            cartProduct.extras_price == null ||
            cartProduct.extras_price == "0.0"
        ? 0.0
        : cartProduct.extras_price;
    var tipValue = product.tipValue.toString() == "" || product.tipValue == null
        ? 0.0
        : product.tipValue.toString();
    var dCharge = product.deliveryCharge == null ||
            product.deliveryCharge.toString().isEmpty
        ? 0.0
        : double.parse(product.deliveryCharge.toString());
    var dis = product.discount.toString() == "" || product.discount == null
        ? 0.0
        : product.discount.toString();

    subTotal = double.parse(price.toString()) +
        double.parse(tipValue.toString()) +
        double.parse(dCharge.toString()) -
        double.parse(dis.toString());

    return subTotal.toString();
  }

  String? getPriceTotal(String price, int quantity) {
    double ans = double.parse(price) * double.parse(quantity.toString());
    return ans.toString();
  }

  getPriceTotalText(CartProduct s) {
    double total = 0.0;
    print("price $s");
    if (s.extras_price != null &&
        s.extras_price!.isNotEmpty &&
        double.parse(s.extras_price!) != 0.0) {
      total += s.quantity * double.parse(s.extras_price!);
    }
    total += s.quantity * double.parse(s.price);

    return Text(
      symbol + total.toStringAsFixed(decimal),
      style: TextStyle(
          fontSize: 20,
          color:
              isDarkMode(context) ? Colors.grey.shade200 : Color(COLOR_PRIMARY),
          fontFamily: "Poppinssm"),
    );
  }
}
