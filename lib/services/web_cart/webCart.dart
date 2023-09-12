import 'package:flutter/foundation.dart';
import 'package:custom_food/services/web_cart/webCarProduct.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/ProductModel.dart';
import '../../ui/productDetailsScreen/ProductDetailsScreen.dart';

class WebCart extends ChangeNotifier {
  List<WebCartProduct> _items = [];
  List<WebCartProduct> get items {
    return [..._items];
  }

  int get itemsCount {
    return _items.length;
  }

  void deleteAll() {
    _items = [];
  }

  Future<void> addProduct(ProductModel model, WebCart cartDatabase,
      bool isIncerementQuantity) async {
    var joinTitleString = "";
    String mainPrice = "";
    List<AddAddonsDemo> lstAddOns = [];
    List<String> lstAddOnsTemp = [];
    double extrasPrice = 0.0;

    SharedPreferences sp = await SharedPreferences.getInstance();
    String addOns =
        sp.getString("musics_key") != null ? sp.getString('musics_key')! : "";

    bool isAddSame = false;

    if (!isAddSame) {
      if (model.disPrice != null &&
          model.disPrice!.isNotEmpty &&
          double.parse(model.disPrice!) != 0) {
        mainPrice = model.disPrice!;
      } else {
        mainPrice = model.price;
      }
    }

    if (addOns.isNotEmpty) {
      lstAddOns = AddAddonsDemo.decode(addOns);
      for (int a = 0; a < lstAddOns.length; a++) {
        AddAddonsDemo newAddonsObject = lstAddOns[a];
        if (newAddonsObject.categoryID == model.id) {
          if (newAddonsObject.isCheck == true) {
            lstAddOnsTemp.add(newAddonsObject.name!);
            extrasPrice += (double.parse(newAddonsObject.price!));
          }
        }
      }

      joinTitleString = lstAddOnsTemp.isEmpty ? "" : lstAddOnsTemp.join(",");
    }

    final bool _productIsInList = _items.any((product) =>
        product.id ==
        (model.id +
            "~" +
            (model.variantInfo != null
                ? model.variantInfo!.variantId.toString()
                : "")));
    if (_productIsInList) {
      WebCartProduct element = _items.firstWhere((product) =>
          product.id ==
          (model.id +
              "~" +
              (model.variantInfo != null
                  ? model.variantInfo!.variantId.toString()
                  : "")));
      await cartDatabase.updateProduct(WebCartProduct(
          id: element.id,
          name: element.name,
          photo: element.photo,
          price: element.price,
          vendorID: element.vendorID,
          quantity:
              isIncerementQuantity ? element.quantity + 1 : element.quantity,
          category_id: element.category_id,
          extras_price: extrasPrice.toString(),
          extras: joinTitleString,
          discountPrice: element.discountPrice!));
    } else {
      print("Estoy en la función interna");
      WebCartProduct entity = WebCartProduct(
          id: model.id +
              "~" +
              (model.variantInfo != null
                  ? model.variantInfo!.variantId.toString()
                  : ""),
          name: model.name,
          photo: model.photo,
          price: mainPrice,
          discountPrice: model.disPrice,
          vendorID: model.vendorID,
          quantity: isIncerementQuantity ? 1 : 0,
          extras_price: extrasPrice.toString(),
          extras: joinTitleString,
          category_id: model.categoryID,
          variant_info: model.variantInfo);
      if (_items.where((element) => element.id == model.id).isEmpty) {
        _items.add(entity);
        print("Ya lo agregué");
        print(_items);
      } else {
        updateProduct(entity);
      }
    }
    notifyListeners();
  }

  reAddProduct(WebCartProduct cartProduct) {
    _items.add(cartProduct);
    notifyListeners();
  }

  removeProduct(String productID) {
    _items.removeWhere((product) => product.id == (productID));
    notifyListeners();
  }

  deleteAllProducts() {
    _items = [];
    notifyListeners();
  }

  updateProduct(WebCartProduct entity) {
    _items[_items.indexWhere((element) => element.id == entity.id)] = entity;
    notifyListeners();
  }
}
