import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmotionalBlackmailResult {
  final List<String> messages;

  EmotionalBlackmailResult({required this.messages});

  factory EmotionalBlackmailResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> msgs = json['messages'] ?? [];
    return EmotionalBlackmailResult(messages: msgs.cast<String>());
  }
}

Future<EmotionalBlackmailResult> getEmotionalBlackmail({
  required int waterIntake,
  required int waterNeed,
  required int caloriesIntake,
  required int caloriesNeed,
  required String EB_Type,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final uri = Uri.parse(
    'https://us-central1-calh2o.cloudfunctions.net/emotionalBlackmail',
  );
  // 若在本機測試可改用下面這行
  // final uri = Uri.parse('http://10.0.2.2:5001/calh2o/us-central1/emotionalBlackmail');

  final payload = {
    'waterIntake': waterIntake,
    'waterNeed': waterNeed,
    'caloriesIntake': caloriesIntake,
    'caloriesNeed': caloriesNeed,
    'EB_Type': EB_Type,
  };

  debugPrint('Start fetching emotional blackmail');
  debugPrint('→ payload = ${jsonEncode(payload)}');
  final response = await http
      .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
      .timeout(timeout);

  if (response.statusCode != 200) {
    debugPrint(
      'emotionalBlackmail error: '
      '${response.statusCode} ${response.body}',
    );
    throw Exception('Failed to fetch emotional blackmail');
  }

  final Map<String, dynamic> data = jsonDecode(response.body);
  return EmotionalBlackmailResult.fromJson(data);
}
