import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/nutrition_result.dart';

class ImageUploadService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveNutritionResult({
    required String base64Image,
    required String comment,
    required NutritionResult nutritionResult,
    final Timestamp? time,  // 新增
  }) async {
    try {
      // Save the nutrition result and base64 image to Firestore
      await _firestore.collection('nutrition_records').add({
        'timestamp': time ?? FieldValue.serverTimestamp(),
        'base64Image': base64Image, // Store base64 image data
        'imageName': nutritionResult.imageName,
        'calories': nutritionResult.calories,
        'protein': nutritionResult.protein,
        'carbohydrate': nutritionResult.carbohydrate,
        'fat': nutritionResult.fat,
        'comment': comment,
        'source':
            base64Image.isEmpty
                ? 'text_input'
                : 'image_input', // Set source based on base64Image
      });
    } catch (e) {
      throw Exception('Failed to save nutrition result: $e');
    }
  }
}
