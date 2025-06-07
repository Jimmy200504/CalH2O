class NutritionResult {
  final List<Map<String, dynamic>> foods;
  final String imageName;
  final num calories;
  final num carbohydrate;
  final num protein;
  final num fat;

  NutritionResult({
    required this.foods,
    required this.imageName,
    required this.calories,
    required this.carbohydrate,
    required this.protein,
    required this.fat,
  });

  // 可複製營養資料
  NutritionResult copyWith({
    List<Map<String, dynamic>>? foods,
    String? imageName,
    num? calories,
    num? carbohydrate,
    num? protein,
    num? fat,
  }) {
    return NutritionResult(
      foods: foods ?? this.foods,
      imageName: imageName ?? this.imageName,
      calories: calories ?? this.calories,
      carbohydrate: carbohydrate ?? this.carbohydrate,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
    );
  }

  factory NutritionResult.fromJson(Map<String, dynamic> json) {
    return NutritionResult(
      foods: List<Map<String, dynamic>>.from(json['foods'] ?? []),
      imageName: json['imageName'] ?? '',
      calories: json['calories'] ?? 0,
      carbohydrate: json['carbohydrate'] ?? 0,
      protein: json['protein'] ?? 0,
      fat: json['fat'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foods': foods,
      'imageName': imageName,
      'calories': calories,
      'carbohydrate': carbohydrate,
      'protein': protein,
      'fat': fat,
    };
  }
}
