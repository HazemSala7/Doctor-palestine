import 'dart:convert';
import 'package:clinic_dr_alla/Constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WhoWeAre extends StatefulWidget {
  const WhoWeAre({Key? key}) : super(key: key);

  @override
  _WhoWeAreState createState() => _WhoWeAreState();
}

class _WhoWeAreState extends State<WhoWeAre> {
  late Future<Map<String, dynamic>> futureAboutData;
  String languageCode = "ar";

  @override
  void initState() {
    super.initState();
    futureAboutData = fetchAboutData(); // Fetch data on init
    loadData();
  }

  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    languageCode = prefs.getString('language_code') ?? 'ar';
  }

  Future<Map<String, dynamic>> fetchAboutData() async {
    final response =
        await http.get(Uri.parse('https://yolo.ps/admin/api/about'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: Text(
              "من نحن",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back_sharp,
                color: kMainColor,
                size: 25,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Html(data: _htmlContent),
          ),
        ),
      ),
    );
  }
}

final _htmlContent = """
  <div>
    <p>من نحن</p>
    <p>عزيزي المستخدم، عزيزتي المستعملة ..</p>
    <p>أهلاً بكم في تطبيق دليل الأطباء والعيادات في فلسطين، الدليل الطبي الأول الذي يجمع بين الراحة والدقة في الوصول إلى خدمات الرعاية الصحية.</p>

    <p>يرجى من حضرتكم الإحاطة بالنقاط التالية:</p>
    
    <p>- التطبيق يتيح لكم البحث بسهولة عن الأطباء حسب التخصص، المدينة، والاسم.</p>
    
    <p>- يمكنكم تصفح معلومات العيادات، أوقات الدوام، أرقام التواصل، ومواقعها على الخريطة.</p>
    
    <p>- وفرنا لكم إمكانية إضافة الأطباء إلى قائمة المفضلة للرجوع إليهم لاحقاً بسرعة.</p>
    
    
    <p>- لا يشمل التطبيق أي معاملات مالية، وهو مجاني تماماً للاستخدام.</p>
    
    <p>مع كامل التقدير لحضراتكم .. نتمنى لكم الصحة والسلامة ونسعد بخدمتكم دائماً عبر تطبيق دليل الأطباء في فلسطين.</p>
  </div>
""";
