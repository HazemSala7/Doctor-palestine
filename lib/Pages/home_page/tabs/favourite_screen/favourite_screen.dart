import 'package:clinic_dr_alla/Local/Model/FavoriteItem/FavoriteItem.dart';
import 'package:clinic_dr_alla/Local/Provider/favourite_provider/favourite_provider.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../../constants/constants.dart';

class Favourite extends StatefulWidget {
  final void Function(int) changeTabIndex;
  final Function(String) onLanguageSelected;
  final String languageCode;
  const Favourite(
      {Key? key,
      required this.changeTabIndex,
      required this.onLanguageSelected,
      required this.languageCode})
      : super(key: key);

  @override
  State<Favourite> createState() => _FavouriteState();
}

class _FavouriteState extends State<Favourite> {
  @override
  Widget build(BuildContext context) {
    return Consumer<FavouriteProvider>(builder: (context, favoriteProvider, _) {
      List<FavoriteItem> favoritesItems = favoriteProvider.favoriteItems;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "المفضلة",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              favoritesItems.isNotEmpty
                  ? ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: favoritesItems.length,
                      itemBuilder: (context, index) {
                        FavoriteItem item = favoritesItems[index];

                        return Padding(
                            padding: const EdgeInsets.only(
                                right: 15, left: 15, top: 20),
                            child: Dismissible(
                              key: Key(item.productId.toString()),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                // Show the confirmation dialog and wait for user input
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Text(
                                        "حذف العيادة من المفضلة",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      actions: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                // Confirm deletion and pop dialog
                                                Navigator.pop(context, true);
                                              },
                                              child: Container(
                                                height: 50,
                                                width: 100,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: kMainColor,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "حسنا",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                // Cancel deletion and pop dialog
                                                Navigator.pop(context, false);
                                              },
                                              child: Container(
                                                height: 50,
                                                width: 100,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: kMainColor,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "لا",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              background: Container(
                                alignment: AlignmentDirectional.centerEnd,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Animated sliding appearance for the text and icon
                                    Container(
                                      margin: EdgeInsets.only(right: 10),
                                      child: Text(
                                        "حذف",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.delete,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (direction) {
                                // Once the user has confirmed, remove the item
                                favoriteProvider
                                    .removeFromFavorite(item.productId);
                                Fluttertoast.showToast(
                                  msg: "تم الحذف بنجاح!",
                                );
                              },
                              child: favoriteCard(
                                id: item.productId,
                                price: item.price.toString(),
                                name: item.name,
                                name_en: item.name_en,
                                name_he: item.name_he,
                                desc: item.desc,
                                discount: item.discount,
                                removeProduct: () {
                                  favoriteProvider
                                      .removeFromFavorite(item.productId);
                                  setState(() {});
                                },
                                image: item.image,
                              ),
                            ));
                      },
                    )
                  : Container(
                      height: MediaQuery.of(context).size.height,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "لا يوجد أي طبيب أو عيادة بالمفضلة",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          SizedBox(height: 10),
                          ImageIcon(
                            AssetImage("assets/box.png"),
                            size: 40,
                          ),
                          SizedBox(
                            height: 80,
                          )
                        ],
                      ),
                    ),
              SizedBox(height: 100),
            ],
          ),
        ),
      );
    });
  }

  Widget favoriteCard(
      {String image = "",
      String price = "",
      String name = "",
      String name_en = "",
      String name_he = "",
      String desc = "",
      String category_id = "",
      int fav_id = 0,
      Function? removeProduct,
      int id = 0,
      String discount = "0",
      String categry = ""}) {
    return InkWell(
      onTap: () {
        // var ImagesArray = [
        //   {id: 265, 'url': image, 'product_id': id}
        // ];

        // pushWithoutNavBar(
        //     context,
        //     MaterialPageRoute(
        //         builder: (context) => SingleProduct(
        //             Images: ImagesArray,
        //             price: price,
        //             originalPrice: price,
        //             id: id,
        //             name: widget.languageCode == "ar"
        //                 ? name
        //                 : widget.languageCode == "en"
        //                     ? name_en
        //                     : name_he,
        //             name_en: name_en,
        //             name_he: name_he,
        //             description: desc,
        //             image: image,
        //             category_id: category_id,
        //             colors: [],
        //             sizes: [],
        //             discount: discount,
        //             changeTabIndex: widget.changeTabIndex,
        //             onLanguageSelected: widget.onLanguageSelected)));
      },
      child: Stack(
        children: [
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 7,
                    blurRadius: 5,
                  ),
                ],
                color: Color(0xffF6F6F6)),
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FancyShimmerImage(
                      imageUrl: image,
                      height: 180,
                      width: 120,
                      errorWidget: Image.asset('assets/Yolo-Logo.png'),
                      //Image.asset('assets/no-image.png'),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            widget.languageCode == "ar"
                                ? name
                                : widget.languageCode == "en"
                                    ? name_en
                                    : name_he,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Container(
                              width: 180,
                              child: Text(
                                desc.length > 45 ? desc.substring(0, 45) : desc,
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 3,
            right: widget.languageCode == "en" ? 3 : null,
            left: widget.languageCode != "en" ? 3 : null,
            child: IconButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: Text("حذف العياده من المفضلة"),
                        actions: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  removeProduct!();
                                  Fluttertoast.showToast(
                                      msg: "تم الحذف بنجاح!");
                                },
                                child: Container(
                                  height: 50,
                                  width: 100,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: kMainColor),
                                  child: Center(
                                    child: Text(
                                      "حسنا",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  height: 50,
                                  width: 100,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: kMainColor),
                                  child: Center(
                                    child: Text(
                                      "لا",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      );
                    },
                  );
                },
                icon: Icon(
                  Icons.delete,
                  color: kMainColor,
                  size: 30,
                )),
          )
        ],
      ),
    );
  }
}
