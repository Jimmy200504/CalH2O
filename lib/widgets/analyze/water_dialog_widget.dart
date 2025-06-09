import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WaterUploadWidget extends StatefulWidget {
  final Function onSuccess;

  const WaterUploadWidget({Key? key, required this.onSuccess}) : super(key: key);

  @override
  _WaterUploadWidgetState createState() => _WaterUploadWidgetState();
}

class _WaterUploadWidgetState extends State<WaterUploadWidget> {
  TextEditingController _waterController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 預設日期為當前日期
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  Future<void> _uploadWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) {
      throw Exception('User not logged in');
    }

    // 手動輸入的水量
    final waterAmount = double.tryParse(_waterController.text);
    if (waterAmount == null || waterAmount <= 0) {
      // Invalid water amount
      return;
    }

    // 手動輸入的日期，將時間部分移除，只比較日期
    DateTime selectedDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);

    // 設置時間為中午12點
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0); // 強制將時間設為 12:00 PM

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(account)
        .collection('water_records');

    // 查找是否已經有該日期的紀錄，這裡只比較日期，不考慮時間
    final querySnapshot = await collection
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(startOfDay.add(const Duration(days: 1))))
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // 如果已有相同日期的紀錄，更新該紀錄
      final docRef = querySnapshot.docs.first.reference;
      await docRef.update({
        'ml': waterAmount,
        'timestamp': Timestamp.fromDate(startOfDay), // 更新timestamp為 12:00 PM
      });
    } else {
      // 沒有相同日期紀錄，新增一條紀錄
      await collection.add({
        'timestamp': Timestamp.fromDate(startOfDay), // 設置timestamp為 12:00 PM
        'ml': waterAmount,
        'createdAt': FieldValue.serverTimestamp(),  // 新增時間
      });
    }

    widget.onSuccess();  // 成功後刷新水量資料
    Navigator.pop(context);  // 關閉對話框
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增/更新水量'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _dateController,
            decoration: const InputDecoration(
              labelText: '選擇日期',
            ),
            readOnly: false,  // 讓用戶可以手動輸入
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _waterController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '水量 (ml)',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),  // 取消
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: _uploadWaterData,  // 確認
                child: const Text('確認'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
