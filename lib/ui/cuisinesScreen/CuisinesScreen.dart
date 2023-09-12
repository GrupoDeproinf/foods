import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:custom_food/AppGlobal.dart';
import 'package:custom_food/constants.dart';
import 'package:custom_food/model/VendorCategoryModel.dart';
import 'package:custom_food/services/FirebaseHelper.dart';
import 'package:custom_food/services/helper.dart';
import 'package:custom_food/ui/categoryDetailsScreen/CategoryDetailsScreen.dart';

class CuisinesScreen extends StatefulWidget {
  const CuisinesScreen(
      {Key? key,
      this.isPageCallFromHomeScreen = false,
      this.isPageCallForDineIn = false})
      : super(key: key);

  @override
  _CuisinesScreenState createState() => _CuisinesScreenState();
  final bool? isPageCallFromHomeScreen;
  final bool? isPageCallForDineIn;
}

class _CuisinesScreenState extends State<CuisinesScreen> {
  final fireStoreUtils = FireStoreUtils();
  late Future<List<VendorCategoryModel>> categoriesFuture;

  @override
  void initState() {
    super.initState();
    categoriesFuture = fireStoreUtils.getCuisines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : null,
        appBar: widget.isPageCallFromHomeScreen!
            ? AppGlobal.buildAppBar(context, "Categories")
            : null,
        body: FutureBuilder<List<VendorCategoryModel>>(
            future: categoriesFuture,
            initialData: [],
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  ),
                );

              if (snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) {
                return ListView.builder(
                    padding: EdgeInsets.all(10),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return snapshot.data != null
                          ? buildCuisineCell(snapshot.data![index])
                          : showEmptyState('No Categories'.tr(), context,
                              description: "add-categories".tr());
                    });
              }
              return CircularProgressIndicator();
            }));
  }

  Widget buildCuisineCell(VendorCategoryModel cuisineModel) {
    return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => push(
            context,
            CategoryDetailsScreen(
              category: cuisineModel,
              isDineIn: widget.isPageCallForDineIn!,
            ),
          ),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              image: DecorationImage(
                image: NetworkImage(cuisineModel.photo.toString()),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5), BlendMode.darken),
              ),
            ),
            child: Center(
              child: Text(
                cuisineModel.title.toString(),
                style: TextStyle(
                    color: Colors.white, fontFamily: "Oswald", fontSize: 27),
              ).tr(),
            ),
          ),
        ));
  }
}
