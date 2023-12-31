import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:custom_food/AppGlobal.dart';
import 'package:custom_food/constants.dart';
import 'package:custom_food/main.dart';
import 'package:custom_food/model/AddressModel.dart';
import 'package:custom_food/model/BannerModel.dart';
import 'package:custom_food/model/FavouriteModel.dart';
import 'package:custom_food/model/ProductModel.dart';
import 'package:custom_food/model/User.dart';
import 'package:custom_food/model/VendorCategoryModel.dart';
import 'package:custom_food/model/VendorModel.dart';
import 'package:custom_food/model/offer_model.dart';
import 'package:custom_food/model/story_model.dart';
import 'package:custom_food/services/FirebaseHelper.dart';
import 'package:custom_food/services/helper.dart';
import 'package:custom_food/services/localDatabase.dart';
import 'package:custom_food/ui/categoryDetailsScreen/CategoryDetailsScreen.dart';
import 'package:custom_food/ui/cuisinesScreen/CuisinesScreen.dart';
import 'package:custom_food/ui/home/CurrentAddressChangeScreen.dart';
import 'package:custom_food/ui/home/view_all_category_product_screen.dart';
import 'package:custom_food/ui/home/view_all_new_arrival_restaurant_screen.dart';
import 'package:custom_food/ui/home/view_all_offer_screen.dart';
import 'package:custom_food/ui/home/view_all_popular_food_near_by_screen.dart';
import 'package:custom_food/ui/home/view_all_popular_restaurant_screen.dart';
import 'package:custom_food/ui/home/view_all_restaurant.dart';
import 'package:custom_food/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:custom_food/ui/vendorProductsScreen/newVendorProductsScreen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_geocoding/google_geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:place_picker/place_picker.dart' as pp;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story_view/story_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/TopSellingModel.dart';
import '../../services/web_cart/webCart.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  final String vendorId;

  HomeScreen({
    Key? key,
    required this.user,
    vendorId,
  })  : vendorId = vendorId ?? "",
        super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final fireStoreUtils = FireStoreUtils();

  late Future<List<ProductModel>> productsFuture;
  final PageController _controller =
      PageController(viewportFraction: 0.8, keepPage: true);
  List<VendorModel> vendors = [];
  List<VendorModel> popularRestaurantLst = [];
  List<VendorModel> newArrivalLst = [];
  List<VendorModel> offerVendorList = [];
  List<OfferModel> offersList = [];
  Stream<List<VendorModel>>? lstAllRestaurant;
  List<ProductModel> lstNearByFood = [];
  bool islocationGet = false;
  VendorModel? selectedRest;
  String? selectedCountry = "VE";

  //Stream<List<FavouriteModel>>? lstFavourites;
  late Future<List<FavouriteModel>> lstFavourites;
  List<String> lstFav = [];

  String? name = "";

  String? currentLocation = "";

  String? selctedOrderTypeValue = "Delivery".tr();

  late Placemark placeMark;

  _getLocation() async {
    islocationGet = true;
    if (MyAppState.selectedPosotion.longitude == 0 &&
        MyAppState.selectedPosotion.latitude == 0) {
      Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .whenComplete(() {});
      MyAppState.selectedPosotion = position;
      islocationGet = false;
    }

    List<Placemark> placemarks = await placemarkFromCoordinates(
            MyAppState.selectedPosotion.latitude,
            MyAppState.selectedPosotion.longitude)
        .catchError((error) {
      debugPrint("------>${error.toString()}");
    });
    placeMark = placemarks[0];
    if (mounted) {
      setState(() {
        currentLocation = placeMark.name.toString() +
            ", " +
            placeMark.subLocality.toString() +
            ", " +
            placeMark.locality.toString();
      });
      getData(placeMark.isoCountryCode);
    }
    if (MyAppState.currentUser != null) {
      if (MyAppState.currentUser!.location.longitude == 0.01 &&
          MyAppState.currentUser!.location.longitude == 0.01) {
        await FirebaseFirestore.instance
            .collection(USERS)
            .doc(MyAppState.currentUser!.userID)
            .update(
          {
            "location": UserLocation(
                    latitude: MyAppState.selectedPosotion.latitude,
                    longitude: MyAppState.selectedPosotion.longitude)
                .toJson()
          },
        );
      }
      MyAppState.currentUser!.location = UserLocation(
          latitude: MyAppState.selectedPosotion.latitude,
          longitude: MyAppState.selectedPosotion.longitude);
      AddressModel userAddress = AddressModel(
          name: MyAppState.currentUser!.fullName(),
          postalCode: placeMark.postalCode.toString(),
          line1: placeMark.name.toString() +
              ", " +
              placeMark.subLocality.toString(),
          line2: placeMark.administrativeArea.toString(),
          country: placeMark.country.toString(),
          city: placeMark.locality.toString(),
          location: MyAppState.currentUser!.location,
          email: MyAppState.currentUser!.email);
      MyAppState.currentUser!.shippingAddress = userAddress;
      await FireStoreUtils.updateCurrentUserAddress(userAddress);
      var query = await FirebaseFirestore.instance
          .collection(USERS)
          .doc(MyAppState.currentUser!.userID)
          .collection("addresses")
          .get();
      if (query.docs.length == 0) {
        NewAddressModel userAddress = NewAddressModel(
            addressName: 'mainAdd'.tr(),
            name: MyAppState.currentUser!.fullName(),
            def: true,
            zipcode: placeMark.postalCode.toString(),
            line1: placeMark.name.toString() +
                ", " +
                placeMark.subLocality.toString(),
            line2: placeMark.administrativeArea.toString(),
            country: placeMark.country.toString(),
            city: placeMark.locality.toString(),
            lat: MyAppState.currentUser!.location.latitude.toString(),
            lon: MyAppState.currentUser!.location.longitude.toString(),
            phone: MyAppState.currentUser!.phoneNumber,
            zone: placeMark.subLocality.toString());
        await FireStoreUtils.updateAddressList(userAddress);
      }
    }
  }

  bool isLocationPermissionAllowed = false;
  loc.Location location = loc.Location();

  getLoc() async {
    print("LOC 1");
    bool _serviceEnabled;
    if (!(await location.serviceEnabled())) {
      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: AlertDialog(
                actionsAlignment: MainAxisAlignment.center,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                title: Text("Antes de continuar...",
                        style: TextStyle(
                            fontFamily: "Oswald", fontWeight: FontWeight.bold))
                    .tr(),
                content: Text(
                  "Salón Cantón necesita acceso a tu ubicación, verifica que el servicio esté activado antes de continuar.",
                  style: TextStyle(fontFamily: "Oswald"),
                ).tr(),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      side: BorderSide(color: Color(COLOR_PRIMARY)),
                    ),
                    child: Text(
                      "He activado la localización",
                      style: TextStyle(
                          fontFamily: "Oswald", color: Color(COLOR_PRIMARY)),
                    ).tr(),
                    onPressed: () async {
                      if (await location.serviceEnabled()) {
                        Navigator.pop(context);
                      }
                    },
                  )
                ]),
          );
        },
      );
    }
    _serviceEnabled = await location.requestService();
    if (_serviceEnabled) {
      var status = await Permission.location.status;
      if (status.isDenied && !kIsWeb) {
        if (Platform.isIOS) {
          status = await Permission.locationWhenInUse.request();
        } else {
          status = await Permission.location.request();
        }

        if (status.isGranted) {
          _getLocation();
        } else if (status.isPermanentlyDenied) {
          if (Platform.isIOS && !kIsWeb) {
            openAppSettings();
          } else {
            await Permission.contacts.shouldShowRequestRationale;
            if (status.isPermanentlyDenied) {
              getTempLocation();
            }
          }
        }
      } else if (status.isRestricted) {
        getTempLocation();
      } else if (status.isPermanentlyDenied) {
        if (Platform.isIOS && !kIsWeb) {
          openAppSettings();
        } else {
          await Permission.contacts.shouldShowRequestRationale;
        }
      } else {
        _getLocation();
      }
      return;
    } else {
      getTempLocation();
    }
    //_currentPosition = await location.getLocation();
  }

  // Database db;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      if (MyAppState.activatedLocation != null &&
          MyAppState.activatedLocation! && MyAppState.locationActive != null &&
                        MyAppState.locationActive!) {
        getLoc();
      } else {
        getData(null);
      }
    } else {
      getData(null);
    }
    getBanner();
  }

  List<VendorCategoryModel> categoryWiseProductList = [];

  List<BannerModel> bannerTopHome = [];
  List<BannerModel> bannerMiddleHome = [];

  bool isHomeBannerLoading = true;
  bool isHomeBannerMiddleLoading = true;
  List<OfferModel> offerList = [];
  bool? storyEnable = false;

  getBanner() async {
    await fireStoreUtils.getHomeTopBanner().then((value) {
      setState(() {
        bannerTopHome = value;
        isHomeBannerLoading = false;
      });
    });

    await fireStoreUtils.getHomePageShowCategory().then((value) {
      setState(() {
        categoryWiseProductList = value;
      });
    });

    await fireStoreUtils.getHomeMiddleBanner().then((value) {
      setState(() {
        bannerMiddleHome = value;
        isHomeBannerMiddleLoading = false;
      });
    });
    await FireStoreUtils().getAllCoupons().then((value) {
      setState(() {
        offerList = value;
      });
    });

    await FirebaseFirestore.instance
        .collection(Setting)
        .doc('story')
        .get()
        .then((value) {
      setState(() {
        storyEnable = value.data()!['isEnabled'];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLocationAvail =
        kIsWeb ? false : ((MyAppState.activatedLocation ?? false) == true && (MyAppState.locationActive ?? false) == true);
    return SafeArea(
      child: Scaffold(
          backgroundColor: const Color(0xffE7E7E7),
          body: !kIsWeb &&
                  isLocationAvail &&
                  MyAppState.activatedLocation != null && MyAppState.locationActive != null &&
                  (MyAppState.selectedPosotion.latitude == 0 &&
                      MyAppState.selectedPosotion.longitude == 0)
              ? Center(
                  child: showEmptyState("notHaveLocation".tr(), context,
                      description: "locationSearchingRestaurants".tr(),
                      action: () async {
                    if (islocationGet) {
                    } else {
                      pp.LocationResult result = await Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (context) =>
                                  pp.PlacePicker(GOOGLE_API_KEY)));

                      setState(() {
                        MyAppState.selectedPosotion = Position.fromMap({
                          'latitude': result.latLng!.latitude,
                          'longitude': result.latLng!.longitude
                        });

                        currentLocation = result.formattedAddress;
                        getData(null);
                      });
                    }
                  }, buttonTitle: 'Select'.tr()),
                )
              : SingleChildScrollView(
                  child: Container(
                    color: const Color(0xffE7E7E7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!kIsWeb &&
                            MyAppState.activatedLocation != null &&
                            MyAppState.activatedLocation! && MyAppState.locationActive != null &&
                        MyAppState.locationActive!)
                          Container(
                            padding: EdgeInsets.only(bottom: 10),
                            color: Color(COLOR_APPBAR),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          Expanded(
                                            child: Text(
                                                    currentLocation.toString(),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontFamily: "Oswald",
                                                        color: Colors.white,
                                                        fontSize: 16))
                                                .tr(),
                                          ),
                                          ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .push(PageRouteBuilder(
                                                  pageBuilder: (context,
                                                          animation,
                                                          secondaryAnimation) =>
                                                      const CurrentAddressChangeScreen(),
                                                  transitionsBuilder: (context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child) {
                                                    return child;
                                                  },
                                                ))
                                                    .then((value) {
                                                  if (value != null &&
                                                      mounted) {
                                                    setState(() {
                                                      currentLocation = value;
                                                      getData(null);
                                                    });
                                                  }
                                                });
                                              },
                                              child: Text(
                                                  "Change".tr().toUpperCase(),
                                                  style: TextStyle(
                                                      fontFamily: "Oswald",
                                                      fontSize: 13)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor:
                                                    Color(COLOR_PRIMARY),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                elevation: 4.0,
                                              )),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                        ],
                                      )),
                                ]),
                          ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          color: Color(COLOR_CHOICE),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    padding: const EdgeInsets.only(
                                        left: 20, right: 10, bottom: 5),
                                    child: Row(
                                      children: [
                                        DropdownButton(
                                          // Not necessary for Option 1
                                          value: vendors.isEmpty
                                              ? null
                                              : selectedRest,
                                          isDense: true,
                                          style: TextStyle(
                                              fontSize: 17,
                                              color: Color(COLOR_APPBAR)
                                                  .withOpacity(0.9),
                                              fontFamily: "Oswald",
                                              fontWeight: FontWeight.w600),
                                          dropdownColor: Colors.white,
                                          underline: Container(
                                              height: 1,
                                              color: Color(COLOR_APPBAR)
                                                  .withOpacity(0.2)),
                                          onChanged: (newValue) async {
                                            int cartProd = 0;
                                            if (!kIsWeb) {
                                              await Provider.of<CartDatabase>(
                                                      context,
                                                      listen: false)
                                                  .allCartProducts
                                                  .then((value) {
                                                cartProd = value.length;
                                              });
                                            } else {
                                              Provider.of<WebCart>(context,
                                                      listen: false)
                                                  .items
                                                  .forEach((value) {
                                                cartProd =
                                                    cartProd + value.quantity;
                                              });
                                            }

                                            if (cartProd > 0) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) =>
                                                        ShowDialogToDismiss(
                                                  title:
                                                      "wantChangeRestaurantOption"
                                                          .tr(),
                                                  content:
                                                      "Your cart will be empty"
                                                          .tr(),
                                                  buttonText: 'CLOSE'.tr(),
                                                  secondaryButtonText:
                                                      'OK'.tr(),
                                                  action: () {
                                                    Navigator.of(context).pop();
                                                    if (!kIsWeb) {
                                                      Provider.of<CartDatabase>(
                                                              context,
                                                              listen: false)
                                                          .deleteAllProducts();
                                                    } else {
                                                      Provider.of<WebCart>(
                                                              context,
                                                              listen: false)
                                                          .deleteAll();
                                                    }
                                                    setState(() {
                                                      selectedRest = newValue
                                                          as VendorModel?;
                                                    });
                                                    MyAppState.currentUser!
                                                        .defaultRestaurant = {
                                                      "id": (newValue
                                                              as VendorModel?)
                                                          ?.id,
                                                      "title": newValue?.title
                                                    };
                                                  },
                                                ),
                                              );
                                            } else {
                                              setState(() {
                                                selectedRest =
                                                    newValue as VendorModel?;
                                              });
                                              MyAppState.currentUser!
                                                  .defaultRestaurant = {
                                                "id": (newValue as VendorModel?)
                                                    ?.id,
                                                "title": newValue?.title
                                              };
                                            }
                                            FireStoreUtils.updateCurrentUser(
                                                MyAppState.currentUser!);
                                          },
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Color(COLOR_PRIMARY),
                                          ),
                                          items: vendors.isEmpty
                                              ? []
                                              : vendors
                                                  .where((e) =>
                                                      e.country ==
                                                      selectedCountry)
                                                  .map<
                                                          DropdownMenuItem<
                                                              VendorModel>>(
                                                      (restaurant) {
                                                    return DropdownMenuItem<
                                                        VendorModel>(
                                                      child: Text(
                                                          restaurant.title,
                                                          style: TextStyle(
                                                              color: Color(
                                                                      COLOR_APPBAR)
                                                                  .withOpacity(
                                                                      0.9))),
                                                      value: restaurant,
                                                    );
                                                  })
                                                  .toSet()
                                                  .toList(),
                                        ),
                                        Spacer(),
                                        DropdownButton(
                                          // Not necessary for Option 1
                                          value: AppGlobal.countries.isEmpty
                                              ? null
                                              : selectedCountry,
                                          isDense: true,
                                          style: TextStyle(
                                              fontSize: 17,
                                              color: Color(COLOR_APPBAR)
                                                  .withOpacity(0.9),
                                              fontFamily: "Oswald",
                                              fontWeight: FontWeight.w600),
                                          dropdownColor: Colors.white,
                                          underline: Container(
                                              height: 1,
                                              color: Color(COLOR_APPBAR)
                                                  .withOpacity(0.2)),
                                          onChanged: (newValue) async {
                                            int cartProd = 0;
                                            if (!kIsWeb) {
                                              await Provider.of<CartDatabase>(
                                                      context,
                                                      listen: false)
                                                  .allCartProducts
                                                  .then((value) {
                                                cartProd = value.length;
                                              });
                                            } else {
                                              Provider.of<WebCart>(context,
                                                      listen: false)
                                                  .items
                                                  .forEach((value) {
                                                cartProd =
                                                    cartProd + value.quantity;
                                              });
                                            }

                                            if (cartProd > 0) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) =>
                                                        ShowDialogToDismiss(
                                                  title:
                                                      "wantChangeCountryOption"
                                                          .tr(),
                                                  content:
                                                      "Your cart will be empty"
                                                          .tr(),
                                                  buttonText: 'CLOSE'.tr(),
                                                  secondaryButtonText:
                                                      'OK'.tr(),
                                                  action: () {
                                                    Navigator.of(context).pop();
                                                    if (!kIsWeb) {
                                                      Provider.of<CartDatabase>(
                                                              context,
                                                              listen: false)
                                                          .deleteAllProducts();
                                                    } else {
                                                      Provider.of<WebCart>(
                                                              context,
                                                              listen: false)
                                                          .deleteAll();
                                                    }
                                                    setState(() {
                                                      setState(() {
                                                        if (newValue !=
                                                            selectedCountry) {
                                                          selectedCountry =
                                                              newValue
                                                                  as String?;

                                                          selectedRest = vendors
                                                              .firstWhere(
                                                                  (element) =>
                                                                      element
                                                                          .country ==
                                                                      newValue);

                                                          MyAppState
                                                              .currentUser!
                                                              .defaultRestaurant = {
                                                            "id": (selectedRest
                                                                    as VendorModel?)
                                                                ?.id,
                                                            "title":
                                                                selectedRest
                                                                    ?.title
                                                          };
                                                        }
                                                      });
                                                      MyAppState.currentUser!
                                                          .defaultRestaurant = {
                                                        "id": (newValue
                                                                as VendorModel?)
                                                            ?.id,
                                                        "title": newValue?.title
                                                      };
                                                    });
                                                  },
                                                ),
                                              );
                                            } else {
                                              setState(() {
                                                if (newValue !=
                                                    selectedCountry) {
                                                  selectedCountry =
                                                      newValue as String?;

                                                  selectedRest = vendors
                                                      .firstWhere((element) =>
                                                          element.country ==
                                                          newValue);

                                                  MyAppState.currentUser!
                                                      .defaultRestaurant = {
                                                    "id": (selectedRest
                                                            as VendorModel?)
                                                        ?.id,
                                                    "title": selectedRest?.title
                                                  };
                                                }
                                              });
                                              MyAppState.currentUser!
                                                  .defaultRestaurant = {
                                                "id": (newValue as VendorModel?)
                                                    ?.id,
                                                "title": newValue?.title
                                              };
                                            }
                                            FireStoreUtils.updateCurrentUser(
                                                MyAppState.currentUser!);
                                          },
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Color(COLOR_PRIMARY),
                                          ),
                                          items: AppGlobal.countries.isEmpty
                                              ? []
                                              : AppGlobal.countries.map<
                                                      DropdownMenuItem<String>>(
                                                  (country) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    child: Text(country["name"],
                                                            style: TextStyle(
                                                                color: Color(
                                                                        COLOR_APPBAR)
                                                                    .withOpacity(
                                                                        0.9)))
                                                        .tr(),
                                                    value: country["iso"],
                                                  );
                                                }).toList(),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                    )),
                                Visibility(
                                    visible: storyEnable == true,
                                    child: storyWidget()),
                              ]),
                        ),
                        const SizedBox(height: 0),
                        Visibility(
                          visible: bannerTopHome.isNotEmpty,
                          child: Container(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: isHomeBannerLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.17),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 0),
                                        child: buildBestDealPage(
                                            bannerTopHome.first),
                                      ))),
                        ),
                        buildTitleRow(
                          titleValue: "Categories".tr(),
                          onClick: () {
                            push(
                              context,
                              NewVendorProductsScreen(
                                  vendorModel: selectedRest!),
                            );
                          },
                        ),
                        Container(
                          child: FutureBuilder<List<VendorCategoryModel>>(
                              future: getCategories(),
                              initialData: const [],
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator.adaptive(
                                      valueColor: AlwaysStoppedAnimation(
                                          Color(COLOR_PRIMARY)),
                                    ),
                                  );
                                }

                                if ((snapshot.hasData ||
                                        (snapshot.data?.isNotEmpty ?? false)) &&
                                    mounted) {
                                  return Container(
                                      padding: const EdgeInsets.only(left: 10),
                                      constraints:
                                          BoxConstraints(maxHeight: 180),
                                      child: ScrollConfiguration(
                                        behavior: MyCustomScrollBehavior(),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          scrollDirection: Axis.horizontal,
                                          itemCount: snapshot.data!.length >= 15
                                              ? 15
                                              : snapshot.data!.length,
                                          itemBuilder: (context, index) {
                                            return buildCategoryItem(
                                                snapshot.data![index]);
                                          },
                                        ),
                                      ));
                                } else {
                                  return showEmptyState(
                                      'No Categories'.tr(), context);
                                }
                              }),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            buildTitleRow(
                              titleValue: "Promotions".tr(),
                              onClick: () {},
                              isViewAll: true,
                            ),
                          ],
                        ),
                        Container(
                          child: FutureBuilder<List<OfferModel>>(
                              future: fireStoreUtils.getCoupons(
                                  selectedRest == null ? "" : selectedRest!.id),
                              initialData: const [],
                              builder: (context, snapshot) {
                                print(snapshot.data!.length);
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator.adaptive(
                                      valueColor: AlwaysStoppedAnimation(
                                          Color(COLOR_PRIMARY)),
                                    ),
                                  );
                                }
                                if ((snapshot.hasData &&
                                        (snapshot.data?.isNotEmpty ?? false)) &&
                                    mounted) {
                                  return Container(
                                      padding: const EdgeInsets.only(left: 10),
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.5,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: snapshot.data!.length >= 15
                                            ? 15
                                            : snapshot.data!.length,
                                        itemBuilder: (context, index) {
                                          return buildPromoItem(
                                              snapshot.data![index]);
                                        },
                                      ));
                                } else {
                                  return showEmptyState(
                                      'No Deals'.tr(), context);
                                }
                              }),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            buildTitleRow(
                              titleValue: "Top Selling".tr(),
                              onClick: () {},
                              isViewAll: true,
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.only(bottom: 20),
                          child: FutureBuilder<List<TopSellingModel>>(
                              future: fireStoreUtils.getTopSelling(),
                              initialData: const [],
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator.adaptive(
                                      valueColor: AlwaysStoppedAnimation(
                                          Color(COLOR_PRIMARY)),
                                    ),
                                  );
                                }

                                if ((snapshot.hasData ||
                                        (snapshot.data?.isNotEmpty ?? false)) &&
                                    mounted) {
                                  return Container(
                                      padding: const EdgeInsets.only(left: 10),
                                      constraints:
                                          BoxConstraints(maxHeight: 110),
                                      child: ScrollConfiguration(
                                        behavior: MyCustomScrollBehavior(),
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: snapshot.data!.length >= 15
                                              ? 15
                                              : snapshot.data!.length,
                                          itemBuilder: (context, index) {
                                            return buildTopSellingItem(
                                                snapshot.data![index]);
                                          },
                                        ),
                                      ));
                                } else {
                                  return showEmptyState(
                                      'No popular Item found'.tr(), context);
                                }
                              }),
                        ),
                        // Column(
                        //   mainAxisAlignment: MainAxisAlignment.start,
                        //   children: [
                        //     buildTitleRow(
                        //       titleValue: "New Arrivals".tr(),
                        //       onClick: () {
                        //         push(
                        //           context,
                        //           const ViewAllNewArrivalRestaurantScreen(),
                        //         );
                        //       },
                        //     ),
                        //     StreamBuilder<List<VendorModel>>(
                        //         stream: fireStoreUtils.getVendorsForNewArrival().asBroadcastStream(),
                        //         initialData: const [],
                        //         builder: (context, snapshot) {
                        //           if (snapshot.connectionState == ConnectionState.waiting) {
                        //             return Center(
                        //               child: CircularProgressIndicator.adaptive(
                        //                 valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                        //               ),
                        //             );
                        //           }

                        //           if ((snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) && mounted) {
                        //             newArrivalLst = snapshot.data!;

                        //             return newArrivalLst.isEmpty
                        //                 ? showEmptyState('No Vendors'.tr(), context)
                        //                 : Container(
                        //                     width: MediaQuery.of(context).size.width,
                        //                     height: 260,
                        //                     margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                        //                     child: ListView.builder(
                        //                         shrinkWrap: true,
                        //                         scrollDirection: Axis.horizontal,
                        //                         physics: const BouncingScrollPhysics(),
                        //                         itemCount: newArrivalLst.length >= 15 ? 15 : newArrivalLst.length,
                        //                         itemBuilder: (context, index) => buildNewArrivalItem(newArrivalLst[index])));
                        //           } else {
                        //             return showEmptyState('No Vendors'.tr(), context);
                        //           }
                        //         }),
                        //   ],
                        // ),

                        // Column(
                        //   children: [
                        //     buildTitleRow(
                        //       titleValue: "Popular Restaurant".tr(),
                        //       onClick: () {
                        //         push(
                        //           context,
                        //           const ViewAllPopularRestaurantScreen(),
                        //         );
                        //       },
                        //     ),
                        //     popularRestaurantLst.isEmpty
                        //         ? showEmptyState('No Popular restaurant'.tr(), context)
                        //         : Container(
                        //             width: MediaQuery.of(context).size.width,
                        //             height: 260,
                        //             margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                        //             child: ListView.builder(
                        //                 shrinkWrap: true,
                        //                 scrollDirection: Axis.horizontal,
                        //                 physics: const BouncingScrollPhysics(),
                        //                 itemCount: popularRestaurantLst.length >= 5 ? 5 : popularRestaurantLst.length,
                        //                 itemBuilder: (context, index) => buildPopularsItem(popularRestaurantLst[index]))),
                        //   ],
                        // ),
                        // ListView.builder(
                        //   itemCount: categoryWiseProductList.length,
                        //   shrinkWrap: true,
                        //   physics: const BouncingScrollPhysics(),
                        //   padding: EdgeInsets.zero,
                        //   itemBuilder: (context, index) {
                        //     return StreamBuilder<List<VendorModel>>(
                        //       stream: FireStoreUtils().getCategoryRestaurants(categoryWiseProductList[index].id.toString()),
                        //       builder: (context, snapshot) {
                        //         if (snapshot.connectionState == ConnectionState.waiting) {
                        //           return Center(
                        //             child: CircularProgressIndicator.adaptive(
                        //               valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                        //             ),
                        //           );
                        //         }
                        //         if ((snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) && mounted) {
                        //           return snapshot.data!.isEmpty
                        //               ? Container()
                        //               : Column(
                        //                   children: [
                        //                     buildTitleRow(
                        //                       titleValue: categoryWiseProductList[index].title.toString(),
                        //                       onClick: () {
                        //                         push(
                        //                           context,
                        //                           ViewAllCategoryProductScreen(
                        //                             vendorCategoryModel: categoryWiseProductList[index],
                        //                           ),
                        //                         );
                        //                       },
                        //                       isViewAll: false,
                        //                     ),
                        //                     SizedBox(
                        //                         width: MediaQuery.of(context).size.width,
                        //                         height: MediaQuery.of(context).size.height * 0.28,
                        //                         child: Padding(
                        //                           padding: const EdgeInsets.symmetric(horizontal: 10),
                        //                           child: ListView.builder(
                        //                             shrinkWrap: true,
                        //                             scrollDirection: Axis.horizontal,
                        //                             physics: const BouncingScrollPhysics(),
                        //                             padding: EdgeInsets.zero,
                        //                             itemCount: snapshot.data!.length,
                        //                             itemBuilder: (context, index) {
                        //                               VendorModel vendorModel = snapshot.data![index];
                        //                               double distanceInMeters = Geolocator.distanceBetween(
                        //                                   vendorModel.latitude, vendorModel.longitude, MyAppState.selectedPosotion.latitude, MyAppState.selectedPosotion.longitude);
                        //                               double kilometer = distanceInMeters / 1000;
                        //                               double minutes = 1.2;
                        //                               double value = minutes * kilometer;
                        //                               final int hour = value ~/ 60;
                        //                               final double minute = value % 60;
                        //                               return Container(
                        //                                 margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        //                                 child: GestureDetector(
                        //                                   onTap: () async {
                        //                                     push(
                        //                                       context,
                        //                                       NewVendorProductsScreen(vendorModel: vendorModel),
                        //                                     );
                        //                                   },
                        //                                   child: SizedBox(
                        //                                     width: MediaQuery.of(context).size.width * 0.65,
                        //                                     child: Container(
                        //                                       decoration: BoxDecoration(
                        //                                         borderRadius: BorderRadius.circular(20),
                        //                                         border: Border.all(color: isDarkMode(context) ? const Color(DarkContainerBorderColor) : Colors.grey.shade100, width: 1),
                        //                                         color: isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
                        //                                         boxShadow: [
                        //                                           isDarkMode(context)
                        //                                               ? const BoxShadow()
                        //                                               : BoxShadow(
                        //                                                   color: Colors.grey.withOpacity(0.5),
                        //                                                   blurRadius: 5,
                        //                                                 ),
                        //                                         ],
                        //                                       ),
                        //                                       child: Column(
                        //                                         crossAxisAlignment: CrossAxisAlignment.start,
                        //                                         children: [
                        //                                           Expanded(
                        //                                               child: Stack(
                        //                                             children: [
                        //                                               CachedNetworkImage(
                        //                                                 imageUrl: getImageVAlidUrl(vendorModel.photo),
                        //                                                 imageBuilder: (context, imageProvider) => Container(
                        //                                                   decoration: BoxDecoration(
                        //                                                     borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                        //                                                     image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                        //                                                   ),
                        //                                                 ),
                        //                                                 placeholder: (context, url) => Center(
                        //                                                     child: CircularProgressIndicator.adaptive(
                        //                                                   valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                        //                                                 )),
                        //                                                 errorWidget: (context, url, error) => ClipRRect(
                        //                                                   borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                        //                                                   child: Image.network(
                        //                                                     AppGlobal.placeHolderImage!,
                        //                                                     width: MediaQuery.of(context).size.width * 0.75,
                        //                                                     fit: BoxFit.contain,
                        //                                                   ),
                        //                                                 ),
                        //                                                 fit: BoxFit.cover,
                        //                                               ),
                        //                                               Positioned(
                        //                                                 bottom: 10,
                        //                                                 right: 10,
                        //                                                 child: Container(
                        //                                                   decoration: BoxDecoration(
                        //                                                     color: Colors.green,
                        //                                                     borderRadius: BorderRadius.circular(5),
                        //                                                   ),
                        //                                                   child: Padding(
                        //                                                     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        //                                                     child: Row(
                        //                                                       mainAxisSize: MainAxisSize.min,
                        //                                                       children: [
                        //                                                         Text(
                        //                                                             vendorModel.reviewsCount != 0
                        //                                                                 ? (vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)
                        //                                                                 : 0.toString(),
                        //                                                             style: const TextStyle(
                        //                                                               fontFamily: "Oswald",
                        //                                                               letterSpacing: 0.5,
                        //                                                               fontSize: 12,
                        //                                                               color: Colors.white,
                        //                                                             )),
                        //                                                         const SizedBox(width: 3),
                        //                                                         const Icon(
                        //                                                           Icons.star,
                        //                                                           size: 16,
                        //                                                           color: Colors.white,
                        //                                                         ),
                        //                                                       ],
                        //                                                     ),
                        //                                                   ),
                        //                                                 ),
                        //                                               ),
                        //                                             ],
                        //                                           )),
                        //                                           const SizedBox(height: 5),
                        //                                           Padding(
                        //                                             padding: const EdgeInsets.symmetric(horizontal: 5),
                        //                                             child: Column(
                        //                                               crossAxisAlignment: CrossAxisAlignment.start,
                        //                                               children: [
                        //                                                 Text(vendorModel.title,
                        //                                                         maxLines: 1, style: TextStyle(fontFamily: "Oswald", fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2))
                        //                                                     .tr(),
                        //                                                 const SizedBox(
                        //                                                   height: 5,
                        //                                                 ),
                        //                                                 Row(
                        //                                                   children: [
                        //                                                     Icon(
                        //                                                       Icons.location_pin,
                        //                                                       color: Color(COLOR_PRIMARY),
                        //                                                       size: 20,
                        //                                                     ),
                        //                                                     SizedBox(width: 5),
                        //                                                     Expanded(
                        //                                                       child: Text(vendorModel.location,
                        //                                                               maxLines: 1,
                        //                                                               style:
                        //                                                                   TextStyle(fontFamily: "Oswald", color: isDarkMode(context) ? Colors.white : Colors.black.withOpacity(0.60)))
                        //                                                           .tr(),
                        //                                                     ),
                        //                                                   ],
                        //                                                 ),
                        //                                                 const SizedBox(
                        //                                                   height: 5,
                        //                                                 ),
                        //                                                 Row(
                        //                                                   children: [
                        //                                                     Icon(
                        //                                                       Icons.timer_sharp,
                        //                                                       color: Color(COLOR_PRIMARY),
                        //                                                       size: 20,
                        //                                                     ),
                        //                                                     SizedBox(
                        //                                                       width: 5,
                        //                                                     ),
                        //                                                     Text(
                        //                                                       '${hour.toString().padLeft(2, "0")}h ${minute.toStringAsFixed(0).padLeft(2, "0")}m',
                        //                                                       style: TextStyle(
                        //                                                           fontFamily: "Oswald",
                        //                                                           letterSpacing: 0.5,
                        //                                                           color: isDarkMode(context) ? Colors.white : Colors.black.withOpacity(0.60)),
                        //                                                     ),
                        //                                                     SizedBox(
                        //                                                       width: 10,
                        //                                                     ),
                        //                                                     Icon(
                        //                                                       Icons.my_location_sharp,
                        //                                                       color: Color(COLOR_PRIMARY),
                        //                                                       size: 20,
                        //                                                     ),
                        //                                                     SizedBox(
                        //                                                       width: 10,
                        //                                                     ),
                        //                                                     Text(
                        //                                                       "${kilometer.toDouble().toStringAsFixed(decimal)} km",
                        //                                                       style: TextStyle(
                        //                                                           fontFamily: "Oswald",
                        //                                                           letterSpacing: 0.5,
                        //                                                           color: isDarkMode(context) ? Colors.white : Colors.black.withOpacity(0.60)),
                        //                                                     ).tr(),
                        //                                                   ],
                        //                                                 ),
                        //                                                 SizedBox(
                        //                                                   height: 5,
                        //                                                 ),
                        //                                               ],
                        //                                             ),
                        //                                           ),
                        //                                         ],
                        //                                       ),
                        //                                     ),
                        //                                   ),
                        //                                 ),
                        //                               );
                        //                             },
                        //                           ),
                        //                         )),
                        //                   ],
                        //                 );
                        //         } else {
                        //           return showEmptyState('No Categories'.tr(), context);
                        //         }
                        //       },
                        //     );
                        //   },
                        // ),
                        // buildTitleRow(
                        //   titleValue: "All Restaurant".tr(),
                        //   onClick: () {},
                        //   isViewAll: true,
                        // ),
                        // vendors.isEmpty
                        //     ? showEmptyState('No Vendors'.tr(), context)
                        //     : Container(
                        //         width: MediaQuery.of(context).size.width,
                        //         margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                        //         child: ListView.builder(
                        //           shrinkWrap: true,
                        //           scrollDirection: Axis.vertical,
                        //           physics: const BouncingScrollPhysics(),
                        //           itemCount:
                        //               vendors.length > 15 ? 15 : vendors.length,
                        //           itemBuilder: (context, index) {
                        //             VendorModel vendorModel = vendors[index];
                        //             return buildAllRestaurantsData(vendorModel);
                        //           },
                        //         ),
                        //       ),
                        // Center(
                        //   child: Padding(
                        //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        //     child: SizedBox(
                        //       width: MediaQuery.of(context).size.width,
                        //       height: MediaQuery.of(context).size.height * 0.06,
                        //       child: ElevatedButton(
                        //         style: ElevatedButton.styleFrom(
                        //           backgroundColor: Color(COLOR_PRIMARY),
                        //           shape: RoundedRectangleBorder(
                        //             borderRadius: BorderRadius.circular(10.0),
                        //             side: BorderSide(
                        //               color: Color(COLOR_PRIMARY),
                        //             ),
                        //           ),
                        //         ),
                        //         child: Text(
                        //           'See All restaurant around you'.tr(),
                        //           style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                        //         ).tr(),
                        //         onPressed: () {
                        //           push(
                        //             context,
                        //             const ViewAllRestaurant(),
                        //           );
                        //         },
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                )),
    );
  }

  final StoryController controller = StoryController();

  Widget storyWidget() {
    return storyList.isEmpty
        ? Container()
        : Container(
            height: 190,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ListView.builder(
                itemCount: storyList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MoreStories(
                                  storyList: storyList,
                                  index: index,
                                )));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        child: Container(
                          height: 180,
                          width: 130,
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                  imageUrl: storyList[index]
                                      .videoThumbnail
                                      .toString(),
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover)),
                                      ),
                                  errorWidget: (context, url, error) =>
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: Image.network(
                                            AppGlobal.placeHolderImage!,
                                            fit: BoxFit.cover,
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: MediaQuery.of(context)
                                                .size
                                                .height,
                                          ))),
                              FutureBuilder(
                                  future: FireStoreUtils().getVendorByVendorID(
                                      storyList[index].vendorID.toString()),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    } else {
                                      if (snapshot.hasError)
                                        return Center(
                                            child: Text(
                                                'Error: ${snapshot.error}'));
                                      else
                                        return Positioned(
                                            bottom: 0,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8,
                                                  right: 10,
                                                  bottom: 10,
                                                  top: 10),
                                              child: Text(
                                                snapshot.data != null
                                                    ? snapshot.data!.title
                                                        .toString()
                                                    : "cdc",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ));
                                    }
                                  }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
  }

  Future<List<VendorCategoryModel>> getCategories() async {
    var productModel = [];
    List<VendorCategoryModel> vendorCateoryModel = [];
    List a = [];
    await fireStoreUtils
        .getVendorProductsDelivery(selectedRest!.id)
        .then((value) async {
      productModel.clear();
      productModel.addAll(value);
      vendorCateoryModel.clear();
      for (int i = 0; i < productModel.length; i++) {
        if (a.isNotEmpty && a.contains(productModel[i].categoryID)) {
        } else if (!a.contains(productModel[i].categoryID)) {
          a.add(productModel[i].categoryID);

          await fireStoreUtils
              .getVendorCategoryById(productModel[i].categoryID)
              .then((value) {
            if (value != null) {
              vendorCateoryModel.add(value);
            }
          });
          vendorCateoryModel.sort((a, b) => a.order!.compareTo(b.order!));
        }
      }
    });
    return Future.value(vendorCateoryModel);
  }

  Widget buildVendorItemData(
    BuildContext context,
    ProductModel product,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      width: MediaQuery.of(context).size.width * 0.8,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: getImageVAlidUrl(product.photo),
              height: 100,
              width: 100,
              memCacheHeight: 100,
              memCacheWidth: 100,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image:
                      DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              placeholder: (context, url) => Center(
                  child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
              )),
              errorWidget: (context, url, error) => ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  AppGlobal.placeHolderImage!,
                ),
              ),
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 10,
                ),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: "Oswald",
                    fontSize: 18,
                    color: Color(0xff000000),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  product.description,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: "Oswald",
                    fontSize: 16,
                    color: Color(0xff9091A4),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "$symbol${product.price}",
                  style: TextStyle(
                    fontFamily: "Oswald",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(COLOR_PRIMARY),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget popularFoodItem(
    BuildContext context,
    ProductModel product,
    VendorModel popularNearFoodVendorModel,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        VendorModel? vendorModel =
            await FireStoreUtils.getVendor(product.vendorID);
        if (vendorModel != null) {
          push(
            context,
            ProductDetailsScreen(
              vendorModel: vendorModel,
              productModel: product,
            ),
          );
        }
      },
      // onTap: () => push(
      //   context,
      //   NewVendorProductsScreen(vendorModel: popularNearFoodVendorModel),
      // ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDarkMode(context)
                  ? const Color(DarkContainerBorderColor)
                  : Colors.grey.shade100,
              width: 1),
          color: isDarkMode(context)
              ? const Color(DarkContainerColor)
              : Colors.white,
          boxShadow: [
            isDarkMode(context)
                ? const BoxShadow()
                : BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                  ),
          ],
        ),
        width: MediaQuery.of(context).size.width * 0.8,
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: getImageVAlidUrl(product.photo),
                height: 100,
                width: 100,
                memCacheHeight: 100,
                memCacheWidth: 100,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                        image: imageProvider, fit: BoxFit.cover),
                  ),
                ),
                placeholder: (context, url) => Center(
                    child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                )),
                errorWidget: (context, url, error) => ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      AppGlobal.placeHolderImage!,
                      fit: BoxFit.cover,
                    )),
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontFamily: "Oswald",
                      fontSize: 18,
                      color: isDarkMode(context) ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    product.description,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: "Oswald",
                      fontSize: 16,
                      color: Color(0xff9091A4),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  /*Text(
                    product.disPrice=="" || product.disPrice =="0"?"\$${product.price}":"\$${product.disPrice}",
                    style: TextStyle(
                      fontFamily: "Oswald",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffE87034),
                    ),
                  ),*/
                  product.disPrice == "" || product.disPrice == "0"
                      ? Text(
                          symbol +
                              double.parse(product.price)
                                  .toStringAsFixed(decimal),
                          style: TextStyle(
                              fontSize: 16,
                              fontFamily: "Oswald",
                              letterSpacing: 0.5,
                              color: Color(COLOR_PRIMARY)),
                        )
                      : Row(
                          children: [
                            Text(
                              "$symbol${double.parse(product.disPrice.toString()).toStringAsFixed(decimal)}",
                              style: TextStyle(
                                fontFamily: "Oswald",
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(COLOR_PRIMARY),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              '$symbol${double.parse(product.price).toStringAsFixed(decimal)}',
                              style: const TextStyle(
                                  fontFamily: "Oswald",
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough),
                            ),
                          ],
                        ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildAllRestaurantsData(VendorModel vendorModel) {
    debugPrint(vendorModel.photo);
    List<OfferModel> tempList = [];
    List<double> discountAmountTempList = [];
    offerList.forEach((element) {
      if (vendorModel.id == element.restaurantId &&
          element.expireOfferDate!.toDate().isAfter(DateTime.now())) {
        tempList.add(element);
        discountAmountTempList
            .add(double.parse(element.discountOffer.toString()));
      }
    });
    return GestureDetector(
      onTap: () {},
      // push(
      //   context,
      //   NewVendorProductsScreen(vendorModel: vendorModel),
      // ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDarkMode(context)
                    ? const Color(DarkContainerBorderColor)
                    : Colors.grey.shade100,
                width: 1),
            color: isDarkMode(context)
                ? const Color(DarkContainerColor)
                : Colors.white,
            boxShadow: [
              isDarkMode(context)
                  ? const BoxShadow()
                  : BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 5,
                    ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      // child: Image.network(height: 80,
                      //     width: 80,vendorModel.photo),
                      child: CachedNetworkImage(
                        imageUrl: vendorModel.photo,
                        height: 80,
                        width: 80,
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              AppGlobal.placeHolderImage!,
                            )),
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (discountAmountTempList.isNotEmpty)
                      Positioned(
                        bottom: -6,
                        left: -1,
                        child: Container(
                          decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/offer_badge.png'))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              discountAmountTempList
                                      .reduce(min)
                                      .toStringAsFixed(decimal) +
                                  "% off",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )
                  ],
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vendorModel.title,
                              style: TextStyle(
                                fontFamily: "Oswald",
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_pin,
                            size: 20,
                            color: Color(COLOR_PRIMARY),
                          ),
                          Expanded(
                            child: Text(
                              vendorModel.location,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: "Oswald",
                                color: isDarkMode(context)
                                    ? Colors.white70
                                    : const Color(0xff9091A4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 20,
                            color: Color(COLOR_PRIMARY),
                          ),
                          const SizedBox(width: 3),
                          Text(
                              vendorModel.reviewsCount != 0
                                  ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                  : 0.toString(),
                              style: TextStyle(
                                fontFamily: "Oswald",
                                letterSpacing: 0.5,
                                color: isDarkMode(context)
                                    ? Colors.white
                                    : const Color(0xff000000),
                              )),
                          const SizedBox(width: 3),
                          Text(
                              '(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                              style: TextStyle(
                                fontFamily: "Oswald",
                                letterSpacing: 0.5,
                                color: isDarkMode(context)
                                    ? Colors.white60
                                    : const Color(0xff666666),
                              )),
                          const SizedBox(width: 5),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  buildCategoryItem(VendorCategoryModel model) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          push(
            context,
            NewVendorProductsScreen(
                vendorModel: selectedRest!, objective: model.id),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(
              imageUrl:
                  getImageVAlidUrl(model.photo.toString()) == placeholderImage
                      ? ""
                      : getImageVAlidUrl(model.photo.toString()),
              imageBuilder: (context, imageProvider) => Container(
                height: MediaQuery.of(context).size.height * 0.11,
                width: kIsWeb
                    ? MediaQuery.of(context).size.height * 0.11
                    : MediaQuery.of(context).size.width * 0.23,
                decoration: BoxDecoration(
                    border: Border.all(width: 6, color: Color(COLOR_PRIMARY)),
                    borderRadius: BorderRadius.circular(30)),
                child: Container(
                  // height: 80,width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDarkMode(context)
                            ? const Color(DarkContainerBorderColor)
                            : Colors.grey.shade100,
                        width: 1),
                    color: isDarkMode(context)
                        ? const Color(DarkContainerColor)
                        : Colors.white,
                    boxShadow: [
                      isDarkMode(context)
                          ? const BoxShadow()
                          : BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              blurRadius: 5,
                            ),
                    ],
                  ),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        )),
                  ),
                ),
              ),
              memCacheHeight:
                  (MediaQuery.of(context).size.height * 0.11).toInt(),
              memCacheWidth: (MediaQuery.of(context).size.width * 0.23).toInt(),
              placeholder: (context, url) => Image.asset(
                "assets/images/plato_generico.png",
                height: 60,
                width: 60,
                cacheHeight:
                    (MediaQuery.of(context).size.height * 0.11).toInt(),
                cacheWidth: kIsWeb
                    ? (MediaQuery.of(context).size.height * 0.11).toInt()
                    : (MediaQuery.of(context).size.width * 0.23).toInt(),
              ),
              // ClipOval(
              //   child: Container(
              //     // padding: EdgeInsets.only(top: 10),
              //     decoration: BoxDecoration(
              //       borderRadius:
              //           const BorderRadius.all(Radius.circular(75 / 1)),
              //       border: Border.all(
              //         color: Color(COLOR_PRIMARY),
              //         style: BorderStyle.solid,
              //         width: 2.0,
              //       ),
              //     ),
              //     width: 75,
              //     height: 75,
              //     child: Icon(
              //       Icons.fastfood,
              //       color: Color(COLOR_PRIMARY),
              //     ),
              //   ),
              // ),
              errorWidget: (context, url, error) => ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ClipOval(
                  child: Container(
                    // padding: EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(75 / 1)),
                      border: Border.all(
                        color: Color(COLOR_PRIMARY),
                        style: BorderStyle.solid,
                        width: 2.0,
                      ),
                    ),
                    width: 75,
                    height: 75,
                    child: Icon(
                      Icons.fastfood,
                      color: Color(COLOR_PRIMARY),
                    ),
                  ),
                ),
              ),
            ),
            // displayCircleImage(model.photo, 90, false),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                  child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.23),
                child: Text(model.title.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode(context)
                          ? Colors.white
                          : const Color(0xFF000000),
                      fontFamily: "Poppinsr",
                    )).tr(),
              )),
            )
          ],
        ),
      ),
    );
  }

  buildPromoItem(OfferModel model) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          push(
            context,
            NewVendorProductsScreen(
                vendorModel: selectedRest!, objective: model.categoryID),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(
              imageUrl: getImageVAlidUrl(model.imageOffer.toString()),
              imageBuilder: (context, imageProvider) {
                return Container(
                  height: MediaQuery.of(context).size.width * 0.43,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Container(
                    // height: 80,width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        isDarkMode(context)
                            ? const BoxShadow()
                            : BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 5,
                              ),
                      ],
                    ),
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.fitHeight,
                          )),
                    ),
                  ),
                );
              },
              memCacheHeight:
                  (MediaQuery.of(context).size.width * 0.45).toInt(),
              memCacheWidth: (MediaQuery.of(context).size.width * 0.9).toInt(),
              placeholder: (context, url) => ClipOval(
                child: Container(
                  // padding: EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.all(Radius.circular(75 / 1)),
                    border: Border.all(
                      color: Color(COLOR_PRIMARY),
                      style: BorderStyle.solid,
                      width: 2.0,
                    ),
                  ),
                  width: 75,
                  height: 75,
                  child: Icon(
                    Icons.fastfood,
                    color: Color(COLOR_PRIMARY),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    AppGlobal.placeHolderImage!,
                    fit: BoxFit.cover,
                  )),
            ),
            // displayCircleImage(model.photo, 90, false),
          ],
        ),
      ),
    );
  }

  buildTopSellingItem(TopSellingModel model) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: GestureDetector(
        onTap: () async {
          var product = await fireStoreUtils.getProductByID(model.productID!);
          await Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(
                      productModel: product, vendorModel: selectedRest!)))
              .whenComplete(() => {setState(() {})});
        },
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CachedNetworkImage(
                  imageUrl: getImageVAlidUrl(model.image.toString()) ==
                          placeholderImage
                      ? ""
                      : getImageVAlidUrl(model.image.toString()),
                  imageBuilder: (context, imageProvider) => Container(
                    height: 70,
                    width: 70,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )),
                    ),
                  ),
                  memCacheHeight: 70,
                  memCacheWidth: 70,
                  placeholder: (context, url) => Image.asset(
                    "assets/images/plato_generico.png",
                    height: 40,
                    width: 40,
                    cacheHeight:
                        (MediaQuery.of(context).size.height * 0.11).toInt(),
                    cacheWidth:
                        (MediaQuery.of(context).size.width * 0.23).toInt(),
                  ),
                  errorWidget: (context, url, error) => ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ClipOval(
                      child: Container(
                        // padding: EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(75 / 1)),
                          border: Border.all(
                            color: Color(COLOR_PRIMARY),
                            style: BorderStyle.solid,
                            width: 2.0,
                          ),
                        ),
                        width: 70,
                        height: 70,
                        child: Icon(
                          Icons.fastfood,
                          color: Color(COLOR_PRIMARY),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 120),
                        child: Text(model.name!,
                            style: TextStyle(
                                fontFamily: "Oswald",
                                fontSize: 17,
                                fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(symbol + model.price!,
                          style: TextStyle(
                              color: const Color(COLOR_APPBAR).withOpacity(0.9),
                              fontFamily: "Oswald",
                              fontSize: 19,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fireStoreUtils.closeVendorStream();
    fireStoreUtils.closeNewArrivalStream();
    super.dispose();
  }

  Widget buildBestDealPage(BannerModel categoriesModel) {
    return InkWell(
      onTap: () async {
        if (categoriesModel.redirect_type == "store") {
          push(
            context,
            NewVendorProductsScreen(vendorModel: selectedRest!),
          );
        } else if (categoriesModel.redirect_type == "product") {
          ProductModel? productModel = await fireStoreUtils
              .getProductByProductID(categoriesModel.redirect_id.toString());
          VendorModel? vendorModel =
              await FireStoreUtils.getVendor(productModel.vendorID);

          if (vendorModel != null) {
            push(
              context,
              ProductDetailsScreen(
                vendorModel: vendorModel,
                productModel: productModel,
              ),
            );
          }
        } else if (categoriesModel.redirect_type == "external_link") {
          final uri = Uri.parse(categoriesModel.redirect_id.toString());
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            throw 'Could not launch ${categoriesModel.redirect_id.toString()}';
          }
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 20 : 0),
        child: Container(
          child: CachedNetworkImage(
            imageUrl: getImageVAlidUrl(categoriesModel.photo.toString()),
            imageBuilder: (context, imageProvider) => Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kIsWeb ? 20 : 0),
              ),
              child: Image(
                image: imageProvider,
                fit: BoxFit.fill,
              ),
            ),
            color: Colors.black.withOpacity(0.5),
            placeholder: (context, url) => Center(
                child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
            )),
            errorWidget: (context, url, error) => ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  AppGlobal.placeHolderImage!,
                  width: MediaQuery.of(context).size.width * 0.9,
                  fit: BoxFit.fitWidth,
                )),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  openCouponCode(
    BuildContext context,
    OfferModel offerModel,
  ) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              margin: const EdgeInsets.only(
                left: 40,
                right: 40,
              ),
              padding: const EdgeInsets.only(
                left: 50,
                right: 50,
              ),
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/images/offer_code_bg.png"))),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  offerModel.offerCode!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.9),
                ),
              )),
          GestureDetector(
            onTap: () {
              FlutterClipboard.copy(offerModel.offerCode!).then((value) {
                final SnackBar snackBar = SnackBar(
                  content: Text(
                    "Coupon code copied".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.black38,
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                return Navigator.pop(context);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 30, bottom: 30),
              child: Text(
                "COPY CODE".tr(),
                style: TextStyle(
                    color: Color(COLOR_PRIMARY),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            child: RichText(
              text: TextSpan(
                text: "Use code".tr(),
                style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                    fontWeight: FontWeight.w700),
                children: <TextSpan>[
                  TextSpan(
                    text: offerModel.offerCode,
                    style: TextStyle(
                        color: Color(COLOR_PRIMARY),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1),
                  ),
                  TextSpan(
                    text: " & get".tr() +
                        " ${offerModel.discountTypeOffer == "Fix Price" ? "$symbol" : ""}${offerModel.discountOffer}${offerModel.discountTypeOffer == "Percentage" ? "% off" : " off"} ",
                    style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNewArrivalItem(VendorModel vendorModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => push(
          context,
          NewVendorProductsScreen(vendorModel: vendorModel),
        ),
        child: SizedBox(
          // margin: EdgeInsets.all(5),
          width: MediaQuery.of(context).size.width * 0.75,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDarkMode(context)
                      ? const Color(DarkContainerBorderColor)
                      : Colors.grey.shade100,
                  width: 1),
              color: isDarkMode(context)
                  ? const Color(DarkContainerColor)
                  : Colors.white,
              boxShadow: [
                isDarkMode(context)
                    ? const BoxShadow()
                    : BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 5,
                      ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                    child: CachedNetworkImage(
                  imageUrl: getImageVAlidUrl(vendorModel.photo),
                  width: MediaQuery.of(context).size.width * 0.75,
                  memCacheWidth:
                      (MediaQuery.of(context).size.width * 0.75).toInt(),
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                          image: imageProvider, fit: BoxFit.cover),
                    ),
                  ),
                  placeholder: (context, url) => Center(
                      child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  )),
                  errorWidget: (context, url, error) => ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        AppGlobal.placeHolderImage!,
                        width: MediaQuery.of(context).size.width * 0.75,
                        fit: BoxFit.fitWidth,
                      )),
                  fit: BoxFit.cover,
                )),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.fromLTRB(15, 0, 5, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendorModel.title,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: "Oswald",
                            letterSpacing: 0.5,
                            color: isDarkMode(context)
                                ? Colors.white
                                : Colors.black,
                          )).tr(),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ImageIcon(
                            const AssetImage('assets/images/location3x.png'),
                            size: 15,
                            color: Color(COLOR_PRIMARY),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: Text(vendorModel.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: "Oswald",
                                  letterSpacing: 0.5,
                                  color: isDarkMode(context)
                                      ? Colors.white60
                                      : const Color(0xff555353),
                                )),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 20,
                                  color: Color(COLOR_PRIMARY),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                    vendorModel.reviewsCount != 0
                                        ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                        : 0.toString(),
                                    style: TextStyle(
                                      fontFamily: "Oswald",
                                      letterSpacing: 0.5,
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : const Color(0xff000000),
                                    )),
                                const SizedBox(width: 3),
                                Text(
                                    '(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                                    style: TextStyle(
                                      fontFamily: "Oswald",
                                      letterSpacing: 0.5,
                                      color: isDarkMode(context)
                                          ? Colors.white70
                                          : const Color(0xff666666),
                                    )),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPopularsItem(VendorModel vendorModel) {
    if (!mounted) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => push(
          context,
          NewVendorProductsScreen(vendorModel: vendorModel),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDarkMode(context)
                    ? const Color(DarkContainerBorderColor)
                    : Colors.grey.shade100,
                width: 1),
            color: isDarkMode(context)
                ? const Color(DarkContainerColor)
                : Colors.white,
            boxShadow: [
              isDarkMode(context)
                  ? const BoxShadow()
                  : BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 5,
                    ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  child: CachedNetworkImage(
                imageUrl: getImageVAlidUrl(vendorModel.photo),
                memCacheWidth:
                    (MediaQuery.of(context).size.width * 0.75).toInt(),
                memCacheHeight: 250,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                        image: imageProvider, fit: BoxFit.cover),
                  ),
                ),
                placeholder: (context, url) => Center(
                    child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                )),
                errorWidget: (context, url, error) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    AppGlobal.placeHolderImage!,
                    width: MediaQuery.of(context).size.width * 0.75,
                    fit: BoxFit.fitHeight,
                  ),
                ),
                fit: BoxFit.cover,
              )),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.fromLTRB(15, 0, 5, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendorModel.title,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: "Oswald",
                          letterSpacing: 0.5,
                          color: isDarkMode(context)
                              ? Colors.white
                              : const Color(0xff000000),
                        )).tr(),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ImageIcon(
                          const AssetImage('assets/images/location3x.png'),
                          size: 15,
                          color: Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(vendorModel.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: "Oswald",
                                letterSpacing: 0.5,
                                color: isDarkMode(context)
                                    ? Colors.white70
                                    : const Color(0xff555353),
                              )),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 20,
                                color: Color(COLOR_PRIMARY),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                  vendorModel.reviewsCount != 0
                                      ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                      : 0.toString(),
                                  style: TextStyle(
                                    fontFamily: "Oswald",
                                    letterSpacing: 0.5,
                                    color: isDarkMode(context)
                                        ? Colors.white70
                                        : const Color(0xff000000),
                                  )),
                              const SizedBox(width: 3),
                              Text(
                                  '(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                                  style: TextStyle(
                                    fontFamily: "Oswald",
                                    letterSpacing: 0.5,
                                    color: isDarkMode(context)
                                        ? Colors.white60
                                        : const Color(0xff666666),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCouponsForYouItem(
      BuildContext context1, VendorModel? vendorModel, OfferModel offerModel) {
    return vendorModel == null
        ? Container()
        : Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: GestureDetector(
              onTap: () {
                if (vendorModel.id.toString() ==
                    offerModel.restaurantId.toString()) {
                  push(
                    context,
                    NewVendorProductsScreen(vendorModel: vendorModel),
                  );
                } else {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    isDismissible: true,
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    backgroundColor: Colors.transparent,
                    enableDrag: true,
                    builder: (context) => openCouponCode(context, offerModel),
                  );
                }
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  alignment: AlignmentDirectional.bottomStart,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.grey.shade100, width: 0.1),
                          boxShadow: [
                            isDarkMode(context)
                                ? const BoxShadow()
                                : BoxShadow(
                                    color: Colors.grey.shade400,
                                    blurRadius: 8.0,
                                    spreadRadius: 1.2,
                                    offset: const Offset(0.2, 0.2),
                                  ),
                          ],
                          color: isDarkMode(context)
                              ? const Color(DARK_BG_COLOR)
                              : Colors.white),
                      child: Column(
                        children: [
                          Expanded(
                              child: CachedNetworkImage(
                            imageUrl: getImageVAlidUrl(offerModel.imageOffer!),
                            memCacheWidth:
                                (MediaQuery.of(context).size.width * 0.75)
                                    .toInt(),
                            memCacheHeight:
                                MediaQuery.of(context).size.width.toInt(),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                    image: imageProvider, fit: BoxFit.cover),
                              ),
                            ),
                            placeholder: (context, url) => Center(
                                child: CircularProgressIndicator.adaptive(
                              valueColor:
                                  AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                            )),
                            errorWidget: (context, url, error) => ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                AppGlobal.placeHolderImage!,
                                width: MediaQuery.of(context).size.width * 0.75,
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                            fit: BoxFit.cover,
                          )),
                          const SizedBox(height: 8),
                          vendorModel.id.toString() ==
                                  offerModel.restaurantId.toString()
                              ? Container(
                                  margin:
                                      const EdgeInsets.fromLTRB(15, 0, 5, 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(vendorModel.title,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontFamily: "Oswald",
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : const Color(0xff000000),
                                          )).tr(),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ImageIcon(
                                            const AssetImage(
                                                'assets/images/location3x.png'),
                                            size: 15,
                                            color: Color(COLOR_PRIMARY),
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          Expanded(
                                            child: Text(vendorModel.location,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: "Oswald",
                                                  letterSpacing: 0.5,
                                                  color: isDarkMode(context)
                                                      ? Colors.white70
                                                      : const Color(0xff555353),
                                                )),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8.0, bottom: 10),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  offerModel.offerCode!,
                                                  style: TextStyle(
                                                    fontFamily: "Oswald",
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(COLOR_PRIMARY),
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      size: 20,
                                                      color:
                                                          Color(COLOR_PRIMARY),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                        vendorModel.reviewsCount !=
                                                                0
                                                            ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                                            : 0.toString(),
                                                        style: TextStyle(
                                                          fontFamily: "Oswald",
                                                          letterSpacing: 0.5,
                                                          color: isDarkMode(
                                                                  context)
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xff000000),
                                                        )),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                        '(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                                                        style: TextStyle(
                                                          fontFamily: "Oswald",
                                                          letterSpacing: 0.5,
                                                          color: isDarkMode(
                                                                  context)
                                                              ? Colors.white60
                                                              : const Color(
                                                                  0xff666666),
                                                        )),
                                                    const SizedBox(width: 5),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : Container(
                                  margin:
                                      const EdgeInsets.fromLTRB(15, 0, 5, 8),
                                  width: MediaQuery.of(context).size.width,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Foodie's Offer".tr(),
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "Oswald",
                                            letterSpacing: 0.5,
                                            color: Color(0xff000000),
                                          )),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text("Apply Offer".tr(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: "Oswald",
                                            letterSpacing: 0.5,
                                            color: Color(0xff555353),
                                          )),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          FlutterClipboard.copy(
                                                  offerModel.offerCode!)
                                              .then((value) => print('copied'));
                                        },
                                        child: Text(
                                          offerModel.offerCode!,
                                          style: TextStyle(
                                            fontFamily: "Oswald",
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(COLOR_PRIMARY),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                        ],
                      ),
                    ),
                    /* vendorModel.id.toString()==offerModel.restaurantId.toString()?*/
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        margin: const EdgeInsets.only(top: 150),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: const Image(
                                        image: AssetImage(
                                            "assets/images/offer_badge.png"))),
                                Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    "${offerModel.discountTypeOffer == "Fix Price" ? "$symbol" : ""}${offerModel.discountOffer}${offerModel.discountTypeOffer == "Percentage" ? "% Off" : " Off"} ",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.7),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ) /*:Container()*/
                  ],
                ),
              ),
            ),
          );
  }

  Widget buildVendorItem(VendorModel vendorModel) {
    return GestureDetector(
      onTap: () => push(
        context,
        NewVendorProductsScreen(vendorModel: vendorModel),
      ),
      child: Container(
        height: 120,
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDarkMode(context)
                  ? const Color(DarkContainerBorderColor)
                  : Colors.grey.shade100,
              width: 1),
          color: isDarkMode(context)
              ? const Color(DarkContainerColor)
              : Colors.white,
          boxShadow: [
            isDarkMode(context)
                ? const BoxShadow()
                : BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                  ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
                child: CachedNetworkImage(
              imageUrl: getImageVAlidUrl(vendorModel.photo),
              memCacheWidth: (MediaQuery.of(context).size.width).toInt(),
              memCacheHeight: 120,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image:
                      DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              placeholder: (context, url) => Center(
                  child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
              )),
              errorWidget: (context, url, error) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(AppGlobal.placeHolderImage!)),
              fit: BoxFit.cover,
            )),
            const SizedBox(height: 8),
            ListTile(
              title: Text(vendorModel.title,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: "Oswald",
                    letterSpacing: 0.5,
                    color: Color(0xff000000),
                  )).tr(),
              subtitle: Row(
                children: [
                  ImageIcon(
                    AssetImage('assets/images/location3x.png'),
                    size: 15,
                    color: Color(COLOR_PRIMARY),
                  ),
                  SizedBox(
                    width: 200,
                    child: Text(vendorModel.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Oswald",
                          letterSpacing: 0.5,
                          color: Color(0xff555353),
                        )),
                  ),
                ],
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 20,
                          color: Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(width: 3),
                        Text(
                            vendorModel.reviewsCount != 0
                                ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}'
                                : 0.toString(),
                            style: const TextStyle(
                              fontFamily: "Oswald",
                              letterSpacing: 0.5,
                              color: Color(0xff000000),
                            )),
                        const SizedBox(width: 3),
                        Text('(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                            style: const TextStyle(
                              fontFamily: "Oswald",
                              letterSpacing: 0.5,
                              color: Color(0xff666666),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> saveFoodTypeValue() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString('foodType', selctedOrderTypeValue!);
  }

  getFoodType() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        selctedOrderTypeValue =
            sp.getString("foodType") == "" || sp.getString("foodType") == null
                ? "Delivery"
                : sp.getString("foodType");
      });
    }
    if (selctedOrderTypeValue == "Takeaway") {
      productsFuture = fireStoreUtils.getAllTakeAWayProducts();
    } else {
      productsFuture = fireStoreUtils.getAllDelevryProducts();
    }
  }

  Future<void> getData(count) async {
    getFoodType();
    lstNearByFood.clear();
    fireStoreUtils.getRestaurants().then((value) async {
      setState(() {
        vendors = value.toSet().toList();
        vendors.forEach((e) => print(e.title));
        print("EL PAÍS ES $count");
        if (count != null &&
            MyAppState.currentUser!.defaultRestaurant == null) {
          selectedCountry = count;
        } else {
          selectedCountry = vendors.isNotEmpty
              ? (MyAppState.currentUser!.defaultRestaurant != null)
                  ? vendors
                      .firstWhere(
                          (e) =>
                              e.title ==
                              MyAppState
                                  .currentUser!.defaultRestaurant!["title"],
                          orElse: () => vendors.first)
                      .country
                  : vendors.first.country
              : placeMark.isoCountryCode;
        }
        print(MyAppState.currentUser!.defaultRestaurant);
        selectedRest = vendors.isNotEmpty
            ? (MyAppState.currentUser!.defaultRestaurant != null)
                ? vendors.firstWhere(
                    (e) =>
                        e.title ==
                        MyAppState.currentUser!.defaultRestaurant!["title"],
                    orElse: () => vendors.first)
                : vendors.firstWhere((e) => e.country == selectedCountry)
            : null;
      });
      if (MyAppState.currentUser!.defaultRestaurant == null) {
        MyAppState.currentUser!.defaultRestaurant = {
          "id": selectedRest!.id,
          "title": selectedRest!.title
        };
        await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);
      }
    });
    // fireStoreUtils.getRestaurantNearBy().whenComplete(() async {
    //   lstAllRestaurant = fireStoreUtils.getAllRestaurants().asBroadcastStream();

    //   if (MyAppState.currentUser != null) {
    //     lstFavourites = fireStoreUtils.getFavouriteRestaurant(MyAppState.currentUser!.userID);
    //     lstFavourites.then((event) {
    //       lstFav.clear();
    //       for (int a = 0; a < event.length; a++) {
    //         lstFav.add(event[a].restaurantId!);
    //       }
    //     });
    //     name = toBeginningOfSentenceCase(widget.user!.firstName);
    //   }

    //   lstAllRestaurant!.listen((event) {
    //     vendors.clear();
    //     vendors.addAll(event);
    //     allstoreList.clear();
    //     allstoreList.addAll(event);
    //     productsFuture.then((value) {
    //       for (int a = 0; a < event.length; a++) {
    //         for (int d = 0; d < (value.length > 20 ? 20 : value.length); d++) {
    //           if (event[a].id == value[d].vendorID && !lstNearByFood.contains(value[d])) {
    //             lstNearByFood.add(value[d]);
    //           }
    //         }
    //       }
    //     });

    //     popularRestaurantLst.addAll(event);
    //     List<VendorModel> temp5 = popularRestaurantLst.where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) == 5).toList();
    //     List<VendorModel> temp5_ = popularRestaurantLst
    //         .where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) > 4 && num.parse((element.reviewsSum / element.reviewsCount).toString()) < 5)
    //         .toList();
    //     List<VendorModel> temp4 = popularRestaurantLst
    //         .where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) > 3 && num.parse((element.reviewsSum / element.reviewsCount).toString()) < 4)
    //         .toList();
    //     List<VendorModel> temp3 = popularRestaurantLst
    //         .where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) > 2 && num.parse((element.reviewsSum / element.reviewsCount).toString()) < 3)
    //         .toList();
    //     List<VendorModel> temp2 = popularRestaurantLst
    //         .where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) > 1 && num.parse((element.reviewsSum / element.reviewsCount).toString()) < 2)
    //         .toList();
    //     List<VendorModel> temp1 = popularRestaurantLst.where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) == 1).toList();
    //     List<VendorModel> temp0 = popularRestaurantLst.where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) == 0).toList();
    //     List<VendorModel> temp0_ = popularRestaurantLst.where((element) => element.reviewsSum == 0 && element.reviewsCount == 0).toList();

    //     popularRestaurantLst.clear();
    //     popularRestaurantLst.addAll(temp5);
    //     popularRestaurantLst.addAll(temp5_);
    //     popularRestaurantLst.addAll(temp4);
    //     popularRestaurantLst.addAll(temp3);
    //     popularRestaurantLst.addAll(temp2);
    //     popularRestaurantLst.addAll(temp1);
    //     popularRestaurantLst.addAll(temp0);
    //     popularRestaurantLst.addAll(temp0_);

    //     FireStoreUtils().getAllCoupons().then((value) {
    //       offersList.clear();
    //       offerVendorList.clear();
    //       value.forEach((element1) {
    //         event.forEach((element) {
    //           if (element1.restaurantId == element.id && element1.expireOfferDate!.toDate().isAfter(DateTime.now())) {
    //             offersList.add(element1);
    //             offerVendorList.add(element);
    //           }
    //         });
    //       });
    //       setState(() {});
    //     });

    //     FireStoreUtils().getStory().then((value) {
    //       storyList.clear();
    //       value.forEach((element1) {
    //         vendors.forEach((element) {
    //           if (element1.vendorID == element.id) {
    //             storyList.add(element1);
    //           }
    //         });
    //       });
    //       setState(() {});
    //     });
    //   });

    //   setState(() {});
    // });
  }

  List<StoryModel> storyList = [];

  Future<void> getTempLocation() async {
    if (MyAppState.currentUser == null &&
        MyAppState.selectedPosotion.longitude != 0 &&
        MyAppState.selectedPosotion.latitude != 0) {
      List<Placemark> placemarks = await placemarkFromCoordinates(
              MyAppState.selectedPosotion.latitude,
              MyAppState.selectedPosotion.longitude)
          .catchError((error) {
        debugPrint("------>$error");
      });
      Placemark placeMark = placemarks[0];
      if (mounted) {
        setState(() {
          currentLocation = placeMark.name.toString() +
              ", " +
              placeMark.subLocality.toString() +
              ", " +
              placeMark.locality.toString() +
              ", " +
              placeMark.administrativeArea.toString() +
              ", " +
              placeMark.postalCode.toString() +
              ", " +
              placeMark.country.toString();
        });
      }
      getData(null);
    }
    if (MyAppState.currentUser != null) {
      if (MyAppState.currentUser!.location.latitude != 0 &&
          MyAppState.currentUser!.location.longitude != 0) {
        MyAppState.selectedPosotion = Position.fromMap({
          'latitude': MyAppState.currentUser!.location.latitude,
          'longitude': MyAppState.currentUser!.location.longitude
        });
        List<Placemark> placeMarks = await placemarkFromCoordinates(
                MyAppState.selectedPosotion.latitude,
                MyAppState.selectedPosotion.longitude)
            .catchError((error) {
          debugPrint("------>${error.toString()}");
        });
        Placemark placeMark = placeMarks[0];
        if (mounted) {
          setState(() {
            currentLocation = placeMark.name.toString() +
                ", " +
                placeMark.subLocality.toString() +
                ", " +
                placeMark.locality.toString() +
                ", " +
                placeMark.administrativeArea.toString() +
                ", " +
                placeMark.postalCode.toString() +
                ", " +
                placeMark.country.toString();
          });
        }
        getData(null);
      }
    }
  }
}

// ignore: camel_case_types
class buildTitleRow extends StatelessWidget {
  final String titleValue;
  final Function? onClick;
  final bool? isViewAll;

  const buildTitleRow({
    Key? key,
    required this.titleValue,
    this.onClick,
    this.isViewAll = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titleValue.tr(),
                  style: TextStyle(
                      color: const Color(COLOR_APPBAR).withOpacity(0.9),
                      fontFamily: "Oswald",
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              isViewAll!
                  ? Container()
                  : GestureDetector(
                      onTap: () {
                        onClick!.call();
                      },
                      child: Text('View All'.tr(),
                          style: TextStyle(
                              color: Color(COLOR_PRIMARY),
                              fontFamily: "Oswald")),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class MoreStories extends StatefulWidget {
  List<StoryModel> storyList = [];
  int index;

  MoreStories({Key? key, required this.index, required this.storyList})
      : super(key: key);

  @override
  _MoreStoriesState createState() => _MoreStoriesState();
}

class _MoreStoriesState extends State<MoreStories> {
  final storyController = StoryController();

  @override
  void dispose() {
    storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        StoryView(
            storyItems: List.generate(
              widget.storyList[widget.index].videoUrl.length,
              (i) {
                return StoryItem.pageVideo(
                  widget.storyList[widget.index].videoUrl[i],
                  controller: storyController,
                );
              },
            ).toList(),
            onStoryShow: (s) {
              debugPrint("Showing a story");
            },
            onComplete: () {
              debugPrint("--------->");
              debugPrint(widget.storyList.length.toString());
              debugPrint(widget.index.toString());
              if (widget.storyList.length - 1 != widget.index) {
                // Navigator.pop(context);
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (context) => MoreStories(
                //       storyList: widget.storyList,
                //       index: widget.index + 1,
                //     )));

                setState(() {
                  widget.index = widget.index + 1;
                });
              } else {
                Navigator.pop(context);
              }
            },
            progressPosition: ProgressPosition.top,
            repeat: true,
            controller: storyController,
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Navigator.pop(context);
              }
            }),
        FutureBuilder(
          future: FireStoreUtils().getVendorByVendorID(
              widget.storyList[widget.index].vendorID.toString()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Container());
            } else {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                VendorModel? vendorModel = snapshot.data;
                double distanceInMeters = Geolocator.distanceBetween(
                    vendorModel!.latitude,
                    vendorModel.longitude,
                    MyAppState.selectedPosotion.latitude,
                    MyAppState.selectedPosotion.longitude);
                double kilometer = distanceInMeters / 1000;
                return Positioned(
                  top: 55,
                  child: InkWell(
                    onTap: () {
                      push(
                        context,
                        NewVendorProductsScreen(vendorModel: vendorModel),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: CachedNetworkImage(
                              imageUrl: vendorModel.photo,
                              height: 50,
                              width: 50,
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  image: DecorationImage(
                                      image: imageProvider, fit: BoxFit.cover),
                                ),
                              ),
                              placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator.adaptive(
                                valueColor: AlwaysStoppedAnimation(
                                    Color(COLOR_PRIMARY)),
                              )),
                              errorWidget: (context, url, error) => ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.network(
                                    AppGlobal.placeHolderImage!,
                                    fit: BoxFit.cover,
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height,
                                  )),
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vendorModel.title.toString(),
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              vendorModel.reviewsCount != 0
                                                  ? (vendorModel.reviewsSum /
                                                          vendorModel
                                                              .reviewsCount)
                                                      .toStringAsFixed(1)
                                                  : 0.toString(),
                                              style: const TextStyle(
                                                fontFamily: "Oswald",
                                                letterSpacing: 0.5,
                                                fontSize: 12,
                                                color: Colors.white,
                                              )),
                                          const SizedBox(width: 3),
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Icon(
                                    Icons.location_pin,
                                    size: 16,
                                    color: Color(COLOR_PRIMARY),
                                  ),
                                  SizedBox(
                                    width: 3,
                                  ),
                                  Text(
                                      "${kilometer.toDouble().toStringAsFixed(decimal)} KM",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "Poppinsr")),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Container(
                                    height: 15,
                                    child: VerticalDivider(
                                      color: Colors.white,
                                      thickness: 2,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                      DateTime.now()
                                                  .difference(widget
                                                      .storyList[widget.index]
                                                      .createdAt!
                                                      .toDate())
                                                  .inDays ==
                                              0
                                          ? 'Today'
                                          : "${DateTime.now().difference(widget.storyList[widget.index].createdAt!.toDate()).inDays.toString()} d",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "Poppinsr")),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }
            }
          },
        )
      ],
    ));
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
