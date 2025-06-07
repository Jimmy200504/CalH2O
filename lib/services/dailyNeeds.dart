import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DailyNeedsResult {
  final int calories;
  final int water;
  final int proteinTarget;
  final int carbsTarget;
  final int fatsTarget;

  DailyNeedsResult({
    required this.calories,
    required this.water,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatsTarget,
  });

  factory DailyNeedsResult.fromJson(Map<String, dynamic> json) {
    return DailyNeedsResult(
      calories: (json['calories'] as num).toInt(),
      water: (json['water'] as num).toInt(),
      proteinTarget: (json['proteinTarget'] as num).toInt(),
      carbsTarget: (json['carbsTarget'] as num).toInt(),
      fatsTarget: (json['fatsTarget'] as num).toInt(),
    );
  }
}

Future<DailyNeedsResult> getDailyNeeds({
  required String userId,
  required String gender,
  required String birthday,
  required int height,
  required int weight,
  required String activityLevel,
  required String goal,
  Duration timeout = const Duration(seconds: 30),
}) async {
  // final uri = Uri.parse(
  //   'https://us-central1-calh2o.cloudfunctions.net/dailyNeeds',
  // );
  final uri = Uri.parse('http://10.0.2.2:5001/calh2o/us-central1/dailyNeeds');

  final payload = {
    'userId': userId,
    'gender': gender,
    'birthday': birthday,
    'height': height,
    'weight': weight,
    'activityLevel': activityLevel,
    'goal': goal,
  };

  debugPrint("Start getting target");
  debugPrint('→ payload = ${jsonEncode(payload)}');
  final response = await http
      .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
      .timeout(timeout);

  if (response.statusCode != 200) {
    debugPrint('dailyNeeds error: ${response.statusCode} ${response.body}');
    throw Exception('Failed to fetch daily needs');
  }

  return DailyNeedsResult.fromJson(jsonDecode(response.body));
}
