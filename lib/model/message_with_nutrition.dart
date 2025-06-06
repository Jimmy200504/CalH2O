import 'package:calh2o/model/nutrition_result.dart';

class MessageWithNutrition {
  final String text;
  final NutritionResult nutrition;

  MessageWithNutrition({required this.text, required this.nutrition});
}