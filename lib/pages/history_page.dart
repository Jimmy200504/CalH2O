import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _dailyRecords = [];
  bool _isLoading = false;
  Map<String, double> _nutritionTargets = {
    'calories': 2000,
    'protein': 50,
    'carbohydrate': 250,
    'fat': 65,
  };

  @override
  void initState() {
    super.initState();
    _loadNutritionTargets();
    _loadDailyRecords();
  }

  Future<void> _loadNutritionTargets() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseFirestore.instance.app.options.projectId)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nutritionTargets = {
            'calories': (data['caloriesTarget'] ?? 2000).toDouble(),
            'protein': (data['proteinTarget'] ?? 50).toDouble(),
            'carbohydrate': (data['carbohydrateTarget'] ?? 250).toDouble(),
            'fat': (data['fatTarget'] ?? 65).toDouble(),
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading nutrition targets: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailyRecords();
    }
  }

  Future<void> _loadDailyRecords() async {
    setState(() => _isLoading = true);
    try {
      // 獲取選定日期的開始和結束時間
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // 從 Firestore 獲取該日期的所有記錄
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('nutrition_records')
              .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
              .where('timestamp', isLessThan: endOfDay)
              .orderBy('timestamp', descending: true)
              .get();

      List<Map<String, dynamic>> records = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // 添加文檔ID到數據中
        data['id'] = doc.id;
        records.add(data);
      }

      setState(() {
        _dailyRecords = records;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading records: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord(String docId) async {
    try {
      // 先從本地列表中移除
      setState(() {
        _dailyRecords.removeWhere((record) => record['id'] == docId);
      });

      // 從數據庫中刪除
      await FirebaseFirestore.instance
          .collection('nutrition_records')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted successfully')),
        );
      }
    } catch (e) {
      // 如果刪除失敗，重新加載數據
      _loadDailyRecords();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImageFromBase64(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      // 移除 data:image/jpeg;base64, 前綴
      final String base64String = base64Image.split(',')[1];
      final bytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, width: 60, height: 60, fit: BoxFit.cover),
      );
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildNutritionRow(
    String label,
    String value,
    String type,
    String unit,
  ) {
    final double currentValue = double.tryParse(value.split(' ')[0]) ?? 0;
    final double targetValue = _nutritionTargets[type] ?? 0;
    final bool isExceeded = currentValue > targetValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isExceeded ? Colors.red : Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${targetValue.toStringAsFixed(1)} $unit',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailBottomSheet(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                if (record['base64Image'] != null &&
                    record['base64Image'].toString().isNotEmpty)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: _buildImageFromBase64(record['base64Image']),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record['imageName'] ?? 'Unnamed food',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nutrition Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Calories',
                            '${record['calories']} kcal',
                          ),
                          _buildDetailRow('Protein', '${record['protein']}g'),
                          _buildDetailRow(
                            'Carbohydrates',
                            '${record['carbohydrate']}g',
                          ),
                          _buildDetailRow('Fat', '${record['fat']}g'),
                          const SizedBox(height: 16),
                          const Text(
                            'Additional Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Source',
                            record['source'] == 'image_input'
                                ? 'Image Input'
                                : 'Text Input',
                          ),
                          if (record['tags'] != null)
                            _buildDetailRow('Tags', record['tags'].join(', ')),
                          if (record['commit'] != null)
                            _buildDetailRow('Commit', record['commit']),
                          _buildDetailRow(
                            'Time',
                            DateFormat('yyyy/MM/dd HH:mm').format(
                              (record['timestamp'] as Timestamp).toDate(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('History Page'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 日期選擇器
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('yyyy/MM/dd').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ),

          // 總營養攝取摘要
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Intake of the Day',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildNutritionRow(
                  'Calories',
                  '${_dailyRecords.fold<double>(0, (sum, record) => sum + (record['calories'] ?? 0)).toStringAsFixed(1)} kcal',
                  'calories',
                  'kcal',
                ),
                _buildNutritionRow(
                  'Protein',
                  '${_dailyRecords.fold<double>(0, (sum, record) => sum + (record['protein'] ?? 0)).toStringAsFixed(1)} g',
                  'protein',
                  'g',
                ),
                _buildNutritionRow(
                  'Carbs',
                  '${_dailyRecords.fold<double>(0, (sum, record) => sum + (record['carbohydrate'] ?? 0)).toStringAsFixed(1)} g',
                  'carbohydrate',
                  'g',
                ),
                _buildNutritionRow(
                  'Fat',
                  '${_dailyRecords.fold<double>(0, (sum, record) => sum + (record['fat'] ?? 0)).toStringAsFixed(1)} g',
                  'fat',
                  'g',
                ),
              ],
            ),
          ),

          // 食物記錄列表
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dailyRecords.isEmpty
                    ? const Center(child: Text('No records on this day'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _dailyRecords.length,
                      itemBuilder: (context, index) {
                        final record = _dailyRecords[index];
                        return Dismissible(
                          key: Key(record['id'] ?? index.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            if (record['id'] != null) {
                              _deleteRecord(record['id']);
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showDetailBottomSheet(record),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child:
                                          record['base64Image'] != null &&
                                                  record['base64Image']
                                                      .toString()
                                                      .isNotEmpty
                                              ? _buildImageFromBase64(
                                                record['base64Image'],
                                              )
                                              : const Icon(
                                                Icons.text_fields,
                                                color: Colors.grey,
                                                size: 24,
                                              ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record['imageName'] ??
                                                'Unnamed food',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Calories: ${record['calories']} kcal',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            'Protein: ${record['protein']}g | Carbs: ${record['carbohydrate']}g | Fat: ${record['fat']}g',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      record['source'] == 'image_input'
                                          ? Icons.image
                                          : Icons.text_fields,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
