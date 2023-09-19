import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:custom_food/AppGlobal.dart';
import 'package:custom_food/constants.dart';
import 'package:custom_food/main.dart';
import 'package:custom_food/model/User.dart';
import 'package:custom_food/services/FirebaseHelper.dart';
import 'package:custom_food/services/helper.dart';
import 'package:custom_food/services/localDatabase.dart';
import 'package:custom_food/ui/Language/language_choose_screen.dart';
import 'package:custom_food/ui/QrCodeScanner/QrCodeScanner.dart';
import 'package:custom_food/ui/auth/AuthScreen.dart';
import 'package:custom_food/ui/cartScreen/CartScreen.dart';
import 'package:custom_food/ui/chat_screen/inbox_driver_screen.dart';
import 'package:custom_food/ui/chat_screen/inbox_screen.dart';
import 'package:custom_food/ui/cuisinesScreen/CuisinesScreen.dart';
import 'package:custom_food/ui/dineInScreen/dine_in_screen.dart';
import 'package:custom_food/ui/dineInScreen/my_booking_screen.dart';
import 'package:custom_food/ui/home/HomeScreen.dart';
import 'package:custom_food/ui/home/favourite_item.dart';
import 'package:custom_food/ui/home/favourite_restaurant.dart';
import 'package:custom_food/ui/mapView/MapViewScreen.dart';
import 'package:custom_food/ui/ordersScreen/OrdersScreen.dart';
import 'package:custom_food/ui/privacy_policy/privacy_policy.dart';
import 'package:custom_food/ui/profile/ProfileScreen.dart';
import 'package:custom_food/ui/searchScreen/SearchScreen.dart';
import 'package:custom_food/ui/termsAndCondition/terms_and_codition.dart';
import 'package:custom_food/ui/wallet/walletScreen.dart';
import 'package:custom_food/userPrefrence.dart';
import 'package:custom_food/utils/DarkThemeProvider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../services/web_cart/webCarProduct.dart';
import '../../services/web_cart/webCart.dart';

enum DrawerSelection {
  Home,
  Wallet,
  dineIn,
  Search,
  Cuisines,
  Cart,
  Profile,
  Orders,
  MyBooking,
  termsCondition,
  privacyPolicy,
  chooseLanguage,
  inbox,
  driver,
  Logout,
  LikedRestaurant,
  LikedProduct
}

class ContainerScreen extends StatefulWidget {
  final User? user;
  final Widget currentWidget;
  final String appBarTitle;
  final DrawerSelection drawerSelection;

  ContainerScreen(
      {Key? key,
      required this.user,
      currentWidget,
      appBarTitle,
      this.drawerSelection = DrawerSelection.Home})
      : this.appBarTitle = appBarTitle ?? 'Home'.tr(),
        this.currentWidget = currentWidget ??
            HomeScreen(
              user: MyAppState.currentUser,
            ),
        super(key: key);

  @override
  ContainerScreenState createState() {
    return ContainerScreenState();
  }
}

class ContainerScreenState extends State<ContainerScreen> {
  var key = GlobalKey<ScaffoldState>();

  late CartDatabase? cartDatabase;
  late WebCart? webCart;
  late User user;
  late String _appBarTitle;
  final fireStoreUtils = FireStoreUtils();

  late Widget _currentWidget;
  late DrawerSelection _drawerSelection;

  int cartCount = 0;
  bool? isWalletEnable;

  @override
  void initState() {
    super.initState();
    setCurrency();
    if (widget.user != null) {
      user = widget.user!;
    } else {
      user = new User();
    }
    _currentWidget = widget.currentWidget;
    _appBarTitle = widget.appBarTitle;
    _drawerSelection = widget.drawerSelection;
    //getKeyHash();
    /// On iOS, we request notification permissions, Does nothing and returns null on Android
    if(!kIsWeb)
    FireStoreUtils.firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    fireStoreUtils.getplaceholderimage().then((value) {
      AppGlobal.placeHolderImage = value;
    });
    fireStoreUtils.getcountryList().then((value) {
      AppGlobal.countries = value;
    });
  }

  setCurrency() async {
    await FireStoreUtils().getCurrency().then((value) {
      for (var element in value) {
        if (element.isactive = true) {
          symbol = element.symbol;
          isRight = element.symbolatright;
          currName = element.code;
          decimal = element.decimal;
          currencyData = element;
        }
      }
    });

    // await FireStoreUtils().getRazorPayDemo();
    // await FireStoreUtils.getPaypalSettingData();
    // await FireStoreUtils.getStripeSettingData();
    // await FireStoreUtils.getPayStackSettingData();
    // await FireStoreUtils.getFlutterWaveSettingData();
    // await FireStoreUtils.getPaytmSettingData();
    // await FireStoreUtils.getWalletSettingData();
    // await FireStoreUtils.getPayFastSettingData();
    // await FireStoreUtils.getMercadoPagoSettingData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb)
      cartDatabase = Provider.of<CartDatabase>(context);
    else {
      webCart = Provider.of<WebCart>(context);
      webCart!.addListener(() {
        var products = 0;
        webCart!.items.forEach((e) => products += e.quantity);
        setState(() {
          cartCount = products;
          print(cartCount);
        });
      });
    }
  }

  DateTime preBackpress = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (!(_currentWidget is HomeScreen)) {
          setState(() {
            _drawerSelection = DrawerSelection.Home;
            _appBarTitle = 'Restaurants'.tr();
            _currentWidget = HomeScreen(
              user: MyAppState.currentUser,
            );
          });
          return false;
        } else {
          final timegap = DateTime.now().difference(preBackpress);
          final cantExit = timegap >= Duration(seconds: 2);
          preBackpress = DateTime.now();
          if (cantExit) {
            //show snackbar
            final snack = SnackBar(
              content: Text(
                'Press Back button again to Exit'.tr(),
                style: TextStyle(color: Colors.white),
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.black,
            );
            ScaffoldMessenger.of(context).showSnackBar(snack);
            return false; // false will do nothing when back press
          } else {
            return true; // true will exit the app
          }
        }
      },
      child: ChangeNotifierProvider.value(
        value: user,
        child: Consumer<User>(
          builder: (context, user, _) {
            return Scaffold(
              extendBodyBehindAppBar:
                  _drawerSelection == DrawerSelection.Wallet ? true : false,
              key: key,
              drawer: Drawer(
                child: Container(
                    color:
                        isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : null,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              Consumer<User>(builder: (context, user, _) {
                                return DrawerHeader(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      displayCircleImage(
                                          user.profilePictureURL, 75, false),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: Text(
                                                    user.fullName(),
                                                    style: const TextStyle(
                                                        fontFamily: "Oswald",
                                                        color: Colors.white),
                                                  ),
                                                ),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 5.0),
                                                    child: Text(
                                                      user.email,
                                                      style: const TextStyle(
                                                          fontFamily: "Oswald",
                                                          color: Colors.white),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(COLOR_PRIMARY),
                                  ),
                                );
                              }),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: Color(COLOR_PRIMARY),
                                child: ListTile(
                                  selected:
                                      _drawerSelection == DrawerSelection.Home,
                                  title: Text('Home',
                                      style: TextStyle(
                                        fontFamily: "Oswald",
                                      )).tr(),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _drawerSelection = DrawerSelection.Home;
                                      _appBarTitle = 'Home'.tr();
                                      _currentWidget = HomeScreen(
                                        user: MyAppState.currentUser,
                                      );
                                    });
                                  },
                                  leading: Icon(CupertinoIcons.home),
                                ),
                              ),
                              // ListTileTheme(
                              //   style: ListTileStyle.drawer,
                              //   selectedColor: Color(COLOR_PRIMARY),
                              //   child: ListTile(
                              //       selected: _drawerSelection ==
                              //           DrawerSelection.dineIn,
                              //       leading: Icon(Icons.restaurant),
                              //       title: Text('Dine-in').tr(),
                              //       onTap: () {
                              //         Navigator.pop(context);
                              //         // setState(() {
                              //         //   _drawerSelection =
                              //         //       DrawerSelection.dineIn;
                              //         //   _appBarTitle = 'Dine-In'.tr();
                              //         //   _currentWidget = HomeScreen(
                              //         //     user: MyAppState.currentUser,
                              //         //   );
                              //         // });
                              //       }),
                              // ),
                              // ListTileTheme(
                              //   style: ListTileStyle.drawer,
                              //   selectedColor: Color(COLOR_PRIMARY),
                              //   child: ListTile(
                              //       selected: _drawerSelection ==
                              //           DrawerSelection.Search,
                              //       title: Text('search',style: TextStyle(fontFamily: "Oswald",)).tr(),
                              //       leading: Icon(Icons.search),
                              //       onTap: () async {
                              //         // push(context, const SearchScreen());
                              //       }),
                              // ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: Color(COLOR_PRIMARY),
                                child: ListTile(
                                  selected:
                                      _drawerSelection == DrawerSelection.Cart,
                                  leading: Icon(CupertinoIcons.cart),
                                  title: Text('Cart',
                                      style: TextStyle(
                                        fontFamily: "Oswald",
                                      )).tr(),
                                  onTap: () {
                                    if (MyAppState.currentUser == null) {
                                      Navigator.pop(context);
                                      // push(context, AuthScreen());
                                    } else {
                                      Navigator.pop(context);
                                      setState(() {
                                        _drawerSelection = DrawerSelection.Cart;
                                        _appBarTitle = 'Your Cart'.tr();
                                        _currentWidget = CartScreen(
                                          fromContainer: true,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: Color(COLOR_PRIMARY),
                                child: ListTile(
                                  selected: _drawerSelection ==
                                      DrawerSelection.Orders,
                                  leading: Image.asset(
                                    'assets/images/truck.png',
                                    color: _drawerSelection ==
                                            DrawerSelection.Orders
                                        ? Color(COLOR_PRIMARY)
                                        : isDarkMode(context)
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade600,
                                    width: 24,
                                    height: 24,
                                  ),
                                  title: Text('Orders',
                                      style: TextStyle(
                                        fontFamily: "Oswald",
                                      )).tr(),
                                  onTap: () {
                                    if (MyAppState.currentUser == null) {
                                      Navigator.pop(context);
                                      push(context, AuthScreen());
                                    } else {
                                      Navigator.pop(context);
                                      setState(() {
                                        _drawerSelection =
                                            DrawerSelection.Orders;
                                        _appBarTitle = 'Orders'.tr();
                                        _currentWidget = OrdersScreen();
                                      });
                                    }
                                  },
                                ),
                              ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: Color(COLOR_PRIMARY),
                                child: ListTile(
                                  selected: _drawerSelection ==
                                      DrawerSelection.Profile,
                                  leading: Icon(CupertinoIcons.person),
                                  title: Text('Profile',
                                      style: TextStyle(
                                        fontFamily: "Oswald",
                                      )).tr(),
                                  onTap: () {
                                    if (MyAppState.currentUser == null) {
                                      Navigator.pop(context);
                                      push(context, AuthScreen());
                                    } else {
                                      Navigator.pop(context);
                                      setState(() {
                                        _drawerSelection =
                                            DrawerSelection.Profile;
                                        _appBarTitle = 'My Profile'.tr();
                                        _currentWidget = ProfileScreen(
                                          user: user,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ),

                              // !isDineInEnable
                              //     ? Container()
                              //     : ListTileTheme(
                              //         style: ListTileStyle.drawer,
                              //         selectedColor: Color(COLOR_PRIMARY),
                              //         child: ListTile(
                              //           selected: _drawerSelection ==
                              //               DrawerSelection.MyBooking,
                              //           leading: Image.asset(
                              //             'assets/images/your_booking.png',
                              //             color: _drawerSelection ==
                              //                     DrawerSelection.MyBooking
                              //                 ? Color(COLOR_PRIMARY)
                              //                 : isDarkMode(context)
                              //                     ? Colors.grey.shade200
                              //                     : Colors.grey.shade600,
                              //             width: 24,
                              //             height: 24,
                              //           ),
                              //           title: Text('Dine-In Bookings').tr(),
                              //           onTap: () {
                              //             if (MyAppState.currentUser == null) {
                              //               Navigator.pop(context);
                              //               // push(context, AuthScreen());
                              //             } else {
                              //               Navigator.pop(context);
                              //               // setState(() {
                              //               //   _drawerSelection =
                              //               //       DrawerSelection.MyBooking;
                              //               //   _appBarTitle =
                              //               //       'Dine-In Bookings'.tr();
                              //               //   _currentWidget =
                              //               //       MyBookingScreen();
                              //               // });
                              //             }
                              //           },
                              //         ),
                              //       ),
                              // ListTileTheme(
                              //   style: ListTileStyle.drawer,
                              //   selectedColor: Color(COLOR_PRIMARY),
                              //   child: ListTile(
                              //     selected: _drawerSelection ==
                              //         DrawerSelection.chooseLanguage,
                              //     leading: Icon(
                              //       Icons.language,
                              //       color: _drawerSelection ==
                              //               DrawerSelection.chooseLanguage
                              //           ? Color(COLOR_PRIMARY)
                              //           : isDarkMode(context)
                              //               ? Colors.grey.shade200
                              //               : Colors.grey.shade600,
                              //     ),
                              //     title: const Text('Language',style: TextStyle(fontFamily: "Oswald",)).tr(),
                              //     onTap: () {
                              //       Navigator.pop(context);
                              //       setState(() {
                              //         _drawerSelection =
                              //             DrawerSelection.chooseLanguage;
                              //         _appBarTitle = 'Language'.tr();
                              //         _currentWidget = LanguageChooseScreen(
                              //           isContainer: true,
                              //         );
                              //       });
                              //     },
                              //   ),
                              // ),
                              ListTileTheme(
                                style: ListTileStyle.drawer,
                                selectedColor: Color(COLOR_PRIMARY),
                                child: ListTile(
                                    selected: _drawerSelection ==
                                        DrawerSelection.Logout,
                                    leading: Icon(Icons.logout),
                                    title: Text(
                                        MyAppState.currentUser == null
                                            ? 'Login'
                                            : 'Log Out',
                                        style: TextStyle(
                                          fontFamily: "Oswald",
                                        )).tr(),
                                    onTap: () async {
                                      if (MyAppState.currentUser == null) {
                                        pushAndRemoveUntil(
                                            context, AuthScreen(), false);
                                      } else {
                                        Navigator.pop(context);
                                        //user.active = false;
                                        user.lastOnlineTimestamp =
                                            Timestamp.now();
                                        user.fcmToken = "";
                                        await FireStoreUtils.updateCurrentUser(
                                            user);
                                        await auth.FirebaseAuth.instance
                                            .signOut();
                                        MyAppState.currentUser = null;
                                        MyAppState.selectedPosotion =
                                            Position.fromMap({
                                          'latitude': 0.0,
                                          'longitude': 0.0
                                        });
                                        if (!kIsWeb) {
                                          Provider.of<CartDatabase>(context,
                                                  listen: false)
                                              .deleteAllProducts();
                                        } else {
                                          Provider.of<WebCart>(context,
                                                  listen: false)
                                              .deleteAll();
                                        }
                                        pushAndRemoveUntil(
                                            context, AuthScreen(), false);
                                      }
                                    }),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("V : $appVersion",
                              style: TextStyle(
                                fontFamily: "Oswald",
                              )),
                        )
                      ],
                    )),
              ),
              appBar: AppBar(
                elevation: 0,
                centerTitle:
                    _drawerSelection == DrawerSelection.Wallet ? true : false,
                backgroundColor: Color(COLOR_APPBAR),
                //isDarkMode(context) ? Color(DARK_COLOR) : null,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: IconButton(
                      splashRadius: 25,
                      visualDensity: VisualDensity(horizontal: 0),
                      padding: EdgeInsets.zero,
                      icon: Image(
                          image: AssetImage("assets/images/menu.png"),
                          width: 20,
                          color: Colors.white),
                      onPressed: () => key.currentState!.openDrawer()),
                ),
                // iconTheme: IconThemeData(color: Colors.blue),
                title: Text(
                  _appBarTitle,
                  style: TextStyle(
                      fontFamily: "Oswald",
                      color: Colors.white,
                      //isDarkMode(context) ? Colors.white : Colors.black,
                      fontWeight: FontWeight.normal),
                ),
                actions: _drawerSelection == DrawerSelection.Wallet ||
                        _drawerSelection == DrawerSelection.MyBooking
                    ? []
                    : _drawerSelection == DrawerSelection.dineIn
                        ? [
                            IconButton(
                                splashRadius: 25,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity(horizontal: 0),
                                tooltip: 'QrCode'.tr(),
                                icon: Image(
                                  image: AssetImage("assets/images/qrscan.png"),
                                  width: 20,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // push(
                                  //   context,
                                  //   QrCodeScanner(),
                                  // );
                                }),
                            IconButton(
                                visualDensity:
                                    const VisualDensity(horizontal: 0),
                                padding: EdgeInsets.zero,
                                icon: Image(
                                  image: AssetImage("assets/images/search.png"),
                                  width: 20,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // setState(() {
                                  //   push(context, const SearchScreen());
                                  // });
                                }),
                            if (!(_currentWidget is CartScreen) ||
                                !(_currentWidget is ProfileScreen))
                              IconButton(
                                splashRadius: 25,
                                visualDensity: VisualDensity(horizontal: 0),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.location_on_outlined,
                                  size: 24,
                                  color: Colors.white,
                                ),
                                onPressed: () => push(
                                  context,
                                  MapViewScreen(),
                                ),
                              )
                          ]
                        : [
                            if (!(_currentWidget is CartScreen) ||
                                !(_currentWidget is ProfileScreen))
                              IconButton(
                                  splashRadius: 25,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(horizontal: 0),
                                  tooltip: 'Cart'.tr(),
                                  icon: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Image(
                                        image: AssetImage(
                                            "assets/images/cart.png"),
                                        width: 20,
                                        color: Colors.white,
                                      ),
                                      kIsWeb
                                          ? Visibility(
                                              visible: cartCount >= 1,
                                              child: Positioned(
                                                right: -6,
                                                top: -8,
                                                child: Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Color(COLOR_PRIMARY),
                                                  ),
                                                  constraints: BoxConstraints(
                                                    minWidth: 12,
                                                    minHeight: 12,
                                                  ),
                                                  child: Center(
                                                    child: new Text(
                                                      cartCount <= 99
                                                          ? '$cartCount'
                                                          : '+99',
                                                      style: new TextStyle(
                                                        color: Colors.white,
                                                        // fontSize: 10,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : StreamBuilder<List<CartProduct>>(
                                              stream:
                                                  cartDatabase!.watchProducts,
                                              builder: (context, snapshot) {
                                                cartCount = 0;
                                                if (snapshot.hasData) {
                                                  snapshot.data!
                                                      .forEach((element) {
                                                    cartCount +=
                                                        element.quantity;
                                                  });
                                                }
                                                return Visibility(
                                                  visible: cartCount >= 1,
                                                  child: Positioned(
                                                    right: -6,
                                                    top: -8,
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Color(
                                                            COLOR_PRIMARY),
                                                      ),
                                                      constraints:
                                                          BoxConstraints(
                                                        minWidth: 12,
                                                        minHeight: 12,
                                                      ),
                                                      child: Center(
                                                        child: new Text(
                                                          cartCount <= 99
                                                              ? '$cartCount'
                                                              : '+99',
                                                          style: new TextStyle(
                                                            color: Colors.white,
                                                            // fontSize: 10,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                    ],
                                  ),
                                  onPressed: () {
                                    if (MyAppState.currentUser == null) {
                                      Navigator.pop(context);
                                      // push(context, AuthScreen());
                                    } else {
                                      setState(() {
                                        _drawerSelection = DrawerSelection.Cart;
                                        _appBarTitle = 'Tu Carrito'.tr();
                                        _currentWidget = CartScreen(
                                          fromContainer: true,
                                        );
                                      });
                                    }
                                  }),
                            const SizedBox(width: 15),
                          ],
              ),
              body: _currentWidget,
            );
          },
        ),
      ),
    );
  }
}
