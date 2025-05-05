import 'dart:io';
import 'package:clinic_dr_alla/Constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget {
  final void Function(int) changeTabIndex;
  final Function(String) onLanguageSelected;
  final String languageCode;
  const Profile(
      {Key? key,
      required this.changeTabIndex,
      required this.onLanguageSelected,
      required this.languageCode})
      : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool Login = false;
  setControllers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? login = prefs.getBool('login');
    if (login == true) {
      setState(() {
        Login = true;
      });
    } else {
      setState(() {
        Login = false;
      });
    }
  }

  void initState() {
    // TODO: implement initState
    super.initState();
    setControllers();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "حسابي",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            IconThemeData(color: Colors.black), // Change back button color
        titleTextStyle: TextStyle(
          color: Colors.black, // Change title text color
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 20, right: 15, left: 15, bottom: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 7,
                    blurRadius: 5,
                  ),
                ], borderRadius: BorderRadius.circular(4), color: Colors.white),
                child: Column(
                  children: [
                    addressMethod(name: "المزيد"),
                    lineMethod(),
                    profileCard(
                        name: "من نحن",
                        icon: Icons.info,
                        iconornot: true,
                        NavigatorFunction: () {
                          // pushWithoutNavBar(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => WhoWeAre()));
                        }),
                    lineMethod(),
                    profileCard(
                        name: "سياسة الخصوصية",
                        icon: Icons.privacy_tip,
                        iconornot: true,
                        NavigatorFunction: () {
                          // pushWithoutNavBar(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => Privacy(
                          //               languageCode: widget.languageCode,
                          //             )));
                        }),
                    lineMethod(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 80, left: 80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      launch(
                          "https://www.facebook.com/profile.php?id=61563302551082");
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: kMainColor),
                      child: Center(
                          child: Image.asset("assets/images/facebook.png")),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      launch(
                          "https://www.instagram.com/yolo_beauty.ps?igsh=MXc5d2lkOTBmZjA3bA");
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: kMainColor),
                      child: Center(
                          child: Image.asset("assets/images/instagram.png")),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      var contact = "+972594606276";
                      var androidUrl =
                          "whatsapp://send?phone=$contact&text=Hi, I need some help";
                      var iosUrl =
                          "https://wa.me/$contact?text=${Uri.parse('Hi, I need some help')}";

                      try {
                        if (Platform.isIOS) {
                          await launchUrl(Uri.parse(iosUrl));
                        } else {
                          await launchUrl(Uri.parse(androidUrl));
                        }
                      } on Exception {
                        Fluttertoast.showToast(
                            msg: "WhatsApp is not installed.");
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: kMainColor),
                      child: Center(
                          child: Image.asset("assets/images/whatsapp.png")),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 70,
            )
          ],
        ),
      ),
    );
  }

  Widget addressMethod({String name = ""}) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: 45,
      child: Padding(
        padding: const EdgeInsets.only(right: 20, left: 20),
        child: Row(
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget lineMethod() {
    return Container(
      width: double.infinity,
      height: 1,
      color: Color(0xffD6D3D3),
    );
  }

  Widget profileCard(
      {String name = "",
      IconData? icon,
      Function? NavigatorFunction,
      bool iconornot = false,
      String image = ""}) {
    return InkWell(
      onTap: () {
        NavigatorFunction!();
      },
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: 45,
        child: Padding(
          padding: EdgeInsets.only(
              right: iconornot ? 20 : 10, left: iconornot ? 20 : 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  iconornot
                      ? Icon(
                          icon,
                          color: kMainColor,
                        )
                      : IconButton(
                          icon: ImageIcon(
                            AssetImage(image),
                            color: kMainColor,
                            size:
                                image == "assets/language-choice.png" ? 30 : 25,
                          ),
                          onPressed: () {
                            // Define the action you want to perform when the button is pressed.
                          },
                        ),
                  iconornot
                      ? SizedBox(
                          width: 10,
                        )
                      : SizedBox(),
                  Text(
                    name,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Icon(Icons.arrow_right_sharp)
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLanguageOption(String language) {
    return InkWell(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.5))),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: MaterialButton(
              onPressed: () {
                // Navigator.pop(context);
                widget.onLanguageSelected(language == "العربية"
                    ? 'ar'
                    : language == "English"
                        ? 'en'
                        : 'he');
              },
              textColor: Colors.black,
              height: MediaQuery.of(context).size.height * 0.03,
              // minWidth: MediaQuery.of(context).size.width * 0.30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SizedBox(
                  //   width: MediaQuery.of(context).size.width * 0.01,
                  // ),
                  language == "العربية"
                      ? Text(
                          "Ar",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      : language == "English"
                          ? Text(
                              "En",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            )
                          : Text(
                              "He",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                  // SizedBox(
                  //   width: MediaQuery.of(context).size.width * 0.03,
                  // ),
                  // Text(
                  //   language,
                  //   style: const TextStyle(
                  //       fontSize: 14, fontWeight: FontWeight.w600),
                  // )
                ],
              ),
            ),
          ),
        ));
  }
}
