import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/nutrition_result.dart';

class ImageUploadService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveNutritionResult({
    required String base64Image,
    required NutritionResult nutritionResult,
  }) async {
    try {
      // Save the nutrition result and base64 image to Firestore
      await _firestore.collection('nutrition_records').add({
        'timestamp': FieldValue.serverTimestamp(),
        'base64Image': base64Image, // Store base64 image data
        'FoodName': nutritionResult.FoodName, 
        'calories': nutritionResult.calories,
        'protein': nutritionResult.protein,
        'carbohydrate': nutritionResult.carbohydrate,
        'fat': nutritionResult.fat,
        'source': 'image_input', // 標記來源是圖片輸入
      });
    } catch (e) {
      throw Exception('Failed to save nutrition result: $e');
    }
  }
}
