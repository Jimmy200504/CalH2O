import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/nutrition_result.dart';

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> uploadImage(File imageFile) async {
    try {
      // Create a unique filename using timestamp
      String fileName =
          'food_images/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload the file to Firebase Storage
      final storageRef = _storage.ref().child(fileName);
      await storageRef.putFile(imageFile);

      // Get the download URL
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<void> saveNutritionResult({
    // required String imageUrl,
    required NutritionResult nutritionResult,
  }) async {
    try {
      // Save the nutrition result to Firestore
      await _firestore.collection('nutrition_records').add({
        // 'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'calories': nutritionResult.calories,
        'protein': nutritionResult.protein,
        'carbohydrate': nutritionResult.carbohydrate,
        'fat': nutritionResult.fat
      });
    } catch (e) {
      throw Exception('Failed to save nutrition result: $e');
    }
  }
}
