import 'dart:async';
import 'package:flutter/material.dart';
import '../model/nutrition_result.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<NutritionResult> getNutritionFromPhoto(
  String imageBase64, {
  Duration timeout = const Duration(seconds: 540),
}) async {
  try {
    final response = await http.post(
      // Uri.parse('http://<你的 emulator 或 deploy URL>/foodPhotoNutrition'),
      // Uri.parse('http://10.0.2.2:5001/calh2o/us-central1/foodPhotoNutrition'),
      Uri.parse(
        'https://us-central1-calh2o.cloudfunctions.net/foodPhotoNutrition',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image': imageBase64}),
    );
    debugPrint("Response: ${response.body}");
    return NutritionResult.fromJson(jsonDecode(response.body));
  } catch (e) {
    debugPrint("Error: $e");
    rethrow;
  }
}
