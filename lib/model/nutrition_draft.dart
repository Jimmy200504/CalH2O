import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/nutrition_result.dart';
import '../services/image_upload_service.dart';

/// 用於暫存拍照/選圖後的營養分析結果，並在使用者確認後才真正上傳
class NutritionDraft extends ChangeNotifier {
  /// 圖片的 Base64 字串
  String? base64Image;

  /// 營養分析結果
  NutritionResult? nutritionResult;

  /// 使用者輸入的備註
  String comment = '';

  /// 分析時間戳
  Timestamp? timestamp;

  /// 使用者選擇的餐別標籤
  String tag = 'Breakfast';

  /// 設定草稿內容
  void setDraft({
    required String image,
    required NutritionResult result,
  }) {
    base64Image = image;
    nutritionResult = result;
    timestamp = Timestamp.now();
    notifyListeners();
  }

  /// 清除目前草稿
  void clearDraft() {
    base64Image = null;
    nutritionResult = null;
    comment = '';
    timestamp = null;
    tag = '';
    notifyListeners();
  }

  /// 真正呼叫上傳到 Firestore
  Future<void> save() async {
    if (base64Image == null || nutritionResult == null || timestamp == null) return;

    // 假設 ImageUploadService.saveNutritionResult 已支援 time 與 tag 參數
    await ImageUploadService.saveNutritionResult(
      base64Image: base64Image!,
      comment: comment,
      nutritionResult: nutritionResult!,
      time: timestamp!,
      tag: tag,
    );

    // 上傳後清除草稿
    clearDraft();
  }
}
