import 'package:clinic_dr_alla/services/apis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

var headers = {'ContentType': 'application/json', "Connection": "Keep-Alive"};

NavigatorFunction(BuildContext context, Widget) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => Widget()));
}

getSliders() async {
  try {
    final response = await http.get(Uri.parse(urlSliders), headers: headers);
    if (response.statusCode == 200 || response.statusCode == 201) {
      print("jsonDecode(response.body)");
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  } catch (e) {
    // Log the error or handle it accordingly
    print('Error fetching data: $e');
    throw Exception('Failed to fetch data');
  }
}
