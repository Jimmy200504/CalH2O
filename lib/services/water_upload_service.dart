import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Water upload service: record daily water intake (ml) by delta and upsert for today's record
/// under each user's subcollection /users/{account}/water_records.
class WaterUploadService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 新增或減少今日飲水量 [mlDelta]
  /// 如果已有今日資料，則使用 FieldValue.increment 累加；否則新增一筆初始 ml 值為 mlDelta
  static Future<void> saveTodayWaterIntake(int mlDelta) async {
    // 1. 先取得 user account
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) {
      throw Exception('User not logged in');
    }

    // 2. 準備時間範圍
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startTs = Timestamp.fromDate(startOfDay);
    final endTs = Timestamp.fromDate(endOfDay);

    // 3. 指定到該 user 的 water_records collection
    final collection = _firestore
        .collection('users')
        .doc(account)
        .collection('water_records');

    // 4. 查詢今日已有的紀錄
    final query = await collection
        .where('timestamp', isGreaterThanOrEqualTo: startTs)
        .where('timestamp', isLessThan: endTs)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // 已有，直接增量更新 + 重設 timestamp
      final docRef = query.docs.first.reference;
      await docRef.update({
        'ml': FieldValue.increment(mlDelta),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // 首次新增
      await collection.add({
        'timestamp': FieldValue.serverTimestamp(),
        'ml': mlDelta,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// 取回今日的 ml 值（若無則新增一筆 ml=0，並回傳 0）
  static Future<int> fetchOrInitTodayWater() async {
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) {
      throw Exception('User not logged in');
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final collection = _firestore
        .collection('users')
        .doc(account)
        .collection('water_records');

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