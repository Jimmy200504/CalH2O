import '../../model/message_with_nutrition.dart';
import '../../model/nutrition_result.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<MessageWithNutrition> messageSent(
  String message,
  NutritionResult currentNutrition,
  List<String> chatHistory,
) async {
  // I just ate a cheese burger.
  final chatHistoryString = chatHistory.join('\n');
  try {
    debugPrint("textToNutritionFlow Start");
    final response = await http.post(
      // Uri.parse('http://10.0.2.2:5001/calh2o/us-central1/textToNutrition'),
      Uri.parse(
        'https://us-central1-calh2o.cloudfunctions.net/textToNutrition',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chatHistory': chatHistoryString,
        'prevNutrition': {
          'calories': currentNutrition.calories,
          'carbohydrate': currentNutrition.carbohydrate,
          'protein': currentNutrition.protein,
          'fat': currentNutrition.fat,
        },
        'text': message,
      }),
    );
    debugPrint("textToNutritionFlow Response: \\${response.body}");
    debugPrint("textToNutritionFlow End");
    final data = jsonDecode(response.body);
    return MessageWithNutrition(
      text: data['comment'],
      nutrition: NutritionResult.fromJson(data),
    );
  } catch (e) {
    debugPrint("Error: $e");
    rethrow;
  }
}
