import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/nutrition_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageUploadService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveNutritionResult({
    required String base64Image,
    required String comment,
    required NutritionResult nutritionResult,
    final Timestamp? time,
    final String? tag,
    final String? documentId,
  }) async {
    try {
      // Get user account from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final account = prefs.getString('account');

      if (account == null) {
        throw Exception('User not logged in');
      }

      final data = {
        'tag': tag ?? 'default',
        'timestamp': time ?? FieldValue.serverTimestamp(),
        'base64Image': base64Image,
        'imageName': nutritionResult.imageName,
        'calories': nutritionResult.calories,
        'protein': nutritionResult.protein,
        'carbohydrate': nutritionResult.carbohydrate,
        'fat': nutritionResult.fat,
        'comment': comment,
        'source': base64Image.isEmpty ? 'text_input' : 'image_input',
      };

      if (documentId != null) {
        // 更新現有記錄
        await _firestore
            .collection('users')
            .doc(account)
            .collection('nutrition_records')
            .doc(documentId)
            .update(data);
      } else {
        // 新增記錄
        await _firestore
            .collection('users')
            .doc(account)
            .collection('nutrition_records')
            .add(data);
      }
    } catch (e) {
      throw Exception('Failed to save nutrition result: $e');
    }
  }
}
