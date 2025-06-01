class NutritionResult {
  final List<Map<String, dynamic>> foods;
  final num calories;
  final num carbohydrate;
  final num protein;
  final num fat;

  NutritionResult({
    required this.foods,
    required this.calories,
    required this.carbohydrate,
    required this.protein,
    required this.fat,
  });

  factory NutritionResult.fromJson(Map<String, dynamic> json) {
    return NutritionResult(
      foods: List<Map<String, dynamic>>.from(json['foods'] ?? []),
      calories: json['calories'] ?? 0,
      carbohydrate: json['carbohydrate'] ?? 0,
      protein: json['protein'] ?? 0,
      fat: json['fat'] ?? 0,
    );
  }
}
