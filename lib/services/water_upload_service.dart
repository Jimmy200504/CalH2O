// lib/services/water_upload_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Water upload service: record daily water intake (ml) by delta and upsert for today's record.
class WaterUploadService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 新增或減少今日飲水量 [mlDelta]
  /// 如果已有今日資料，則使用 FieldValue.increment 累加；否則新增一筆初始 ml 值為 mlDelta
  static Future<void> saveTodayWaterIntake(int mlDelta) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final startTs = Timestamp.fromDate(startOfDay);
    final endTs = Timestamp.fromDate(endOfDay);
    final collection = _firestore.collection('water_records');

    // 查詢今日已有的紀錄
    final query = await collection
        .where('timestamp', isGreaterThanOrEqualTo: startTs)
        .where('timestamp', isLessThan: endTs)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;
      // 使用增量更新，正值為加、負值為減，同步更新 timestamp
      await docRef.update({
        'ml': FieldValue.increment(mlDelta),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // 首次新增今日記錄
      await collection.add({
        'timestamp': FieldValue.serverTimestamp(),
        'ml': mlDelta,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// 取回今日的 ml 值（若無則新增一筆 ml=0，並回傳 0）
  static Future<int> fetchOrInitTodayWater() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final collection = _firestore.collection('water_records');
    final query = await collection
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('timestamp', isLessThan:     Timestamp.fromDate(endOfDay))
      .limit(1)
      .get();

    if (query.docs.isNotEmpty) {
      return (query.docs.first['ml'] as num).toInt();
    } else {
      // 新增一筆 ml=0 的初始紀錄
      await collection.add({
        'timestamp': FieldValue.serverTimestamp(),
        'ml': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return 0;
    }
  }
}
