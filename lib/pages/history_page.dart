import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'record_page/text_record_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _dailyRecords = [];
  Map<String, double> _monthlyStats = {
    'calories': 0,
    'protein': 0,
    'carbohydrate': 0,
    'fat': 0,
  };
  bool _isMonthView = false;
  final Map<String, IconData> _tagIcons = {
    'Breakfast': Icons.breakfast_dining,
    'Lunch': Icons.lunch_dining,
    'Dinner': Icons.dinner_dining,
    'Dessert': Icons.icecream,
    'Snack': Icons.local_cafe,
    'Midnight': FontAwesomeIcons.ghost,
  };

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    if (_isMonthView) {
      await _fetchMonthlyRecords();
    } else {
      await _fetchDailyRecords();
    }
  }

  Future<void> _fetchMonthlyRecords() async {
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    // Get user account
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(account)
            .collection('nutrition_records')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
            )
            .where(
              'timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
            )
            .get();

    _monthlyStats = {'calories': 0, 'protein': 0, 'carbohydrate': 0, 'fat': 0};

    // Group records by date
    final Map<String, List<Map<String, dynamic>>> groupedRecords = {};
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      data['documentId'] = doc.id; // 添加文件 ID
      final timestamp = data['timestamp'] as Timestamp;
      final date = DateFormat('yyyy-MM-dd').format(timestamp.toDate());

      if (!groupedRecords.containsKey(date)) {
        groupedRecords[date] = [];
      }
      groupedRecords[date]!.add(data);

      // Update monthly stats
      _monthlyStats['calories'] =
          (_monthlyStats['calories'] ?? 0) + (data['calories'] ?? 0);
      _monthlyStats['protein'] =
          (_monthlyStats['protein'] ?? 0) + (data['protein'] ?? 0);
      _monthlyStats['carbohydrate'] =
          (_monthlyStats['carbohydrate'] ?? 0) + (data['carbohydrate'] ?? 0);
      _monthlyStats['fat'] = (_monthlyStats['fat'] ?? 0) + (data['fat'] ?? 0);
    }

    // Convert grouped records to list
    _dailyRecords =
        groupedRecords.entries.map((entry) {
          final totalCalories = entry.value.fold<double>(
            0,
            (sum, record) => sum + (record['calories'] ?? 0),
          );

          return {
            'date': DateTime.parse(entry.key), // Convert string to DateTime
            'totalCalories': totalCalories,
            'foods': entry.value,
          };
        }).toList();

    // Sort by date
    _dailyRecords.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    setState(() {});
  }

  Future<void> _fetchDailyRecords() async {
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get user account
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(account)
            .collection('nutrition_records')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where(
              'timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
            )
            .get();

    _dailyRecords =
        querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['documentId'] = doc.id; // 添加文件 ID
          return data;
        }).toList();
    _dailyRecords.sort(
      (a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp),
    );

    // Calculate daily totals
    _monthlyStats = {'calories': 0, 'protein': 0, 'carbohydrate': 0, 'fat': 0};

    for (var record in _dailyRecords) {
      _monthlyStats['calories'] =
          (_monthlyStats['calories'] ?? 0) + (record['calories'] ?? 0);
      _monthlyStats['protein'] =
          (_monthlyStats['protein'] ?? 0) + (record['protein'] ?? 0);
      _monthlyStats['carbohydrate'] =
          (_monthlyStats['carbohydrate'] ?? 0) + (record['carbohydrate'] ?? 0);
      _monthlyStats['fat'] = (_monthlyStats['fat'] ?? 0) + (record['fat'] ?? 0);
    }

    setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_isMonthView) {
      // Show year and month picker
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDatePickerMode: DatePickerMode.year,
        builder:
            (context, child) => Theme(
              data: ThemeData().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFFFFB74D), // 主色
                  onPrimary: Colors.black, // icon color
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                dialogBackgroundColor: Colors.white,
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black, // Cancel / OK 按鈕文字顏色
                  ),
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              child: child!,
            ),
      );
      if (picked != null) {
        setState(() {
          _selectedDate = DateTime(picked.year, picked.month, 1);
          _fetchRecords();
        });
      }
    } else {
      // Show full date picker
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder:
            (context, child) => Theme(
              data: ThemeData().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFFFFB74D), // 主色
                  onPrimary: Colors.black, // icon color
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                dialogBackgroundColor: Colors.white,
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black, // Cancel / OK 按鈕文字顏色
                  ),
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              child: child!,
            ),
      );
      if (picked != null) {
        setState(() {
          _selectedDate = picked;
          _fetchRecords();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_isMonthView ? 'Monthly History' : 'Daily History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.black),
            tooltip: '分析',
            onPressed: () => Navigator.pushNamed(context, '/analyze'),
          ),
          IconButton(
            icon: Icon(
              _isMonthView ? Icons.calendar_today : Icons.calendar_month,
            ),
            onPressed: () {
              setState(() {
                _isMonthView = !_isMonthView;
                _fetchRecords();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _isMonthView
                        ? DateFormat('yyyy/MM').format(_selectedDate)
                        : DateFormat('yyyy/MM/dd').format(_selectedDate),
                    style: const TextStyle(color: Colors.black), // 文字顏色
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black, // ripple 特效顏色
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _isMonthView ? 'Monthly Summary' : 'Daily Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Total Calories',
                  '${_monthlyStats['calories']?.toStringAsFixed(1)} kcal',
                ),
                _buildSummaryRow(
                  'Total Protein',
                  '${_monthlyStats['protein']?.toStringAsFixed(1)} g',
                ),
                _buildSummaryRow(
                  'Total Carbs',
                  '${_monthlyStats['carbohydrate']?.toStringAsFixed(1)} g',
                ),
                _buildSummaryRow(
                  'Total Fat',
                  '${_monthlyStats['fat']?.toStringAsFixed(1)} g',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                _isMonthView
                    ? ListView.builder(
                      itemCount: _dailyRecords.length,
                      itemBuilder: (context, index) {
                        final dayData = _dailyRecords[index];
                        if (dayData['date'] == null) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              DateFormat(
                                'MM/dd',
                              ).format(dayData['date'] as DateTime),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Total Calories: ${dayData['totalCalories'].toStringAsFixed(1)} kcal',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                            collapsedBackgroundColor: Colors.white,
                            children:
                                (dayData['foods'] as List<Map<String, dynamic>>)
                                    .map((record) => _buildRecordItem(record))
                                    .toList(),
                          ),
                        );
                      },
                    )
                    : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _dailyRecords.length,
                            itemBuilder: (context, index) {
                              return _buildRecordItem(_dailyRecords[index]);
                            },
                          ),
                        ),
                        if (_dailyRecords.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Click on any item to see more information',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    final tag = record['tag'] as String? ?? 'Other';
    final icon = _tagIcons[tag] ?? Icons.fastfood;

    return Dismissible(
      key: Key(record['timestamp'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text(
                'Are you sure you want to delete this record?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          // Get user account
          final prefs = await SharedPreferences.getInstance();
          final account = prefs.getString('account');
          if (account == null) return;

          // Get the document ID from the record
          final querySnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(account)
                  .collection('nutrition_records')
                  .where('timestamp', isEqualTo: record['timestamp'])
                  .where('imageName', isEqualTo: record['imageName'])
                  .get();

          if (querySnapshot.docs.isNotEmpty) {
            final docId = querySnapshot.docs.first.id;
            await querySnapshot.docs.first.reference.delete();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Record deleted successfully',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
                backgroundColor: Colors.orange[100],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.all(8),
              ),
            );
            // Refresh the records
            _fetchRecords();
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting record',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
              backgroundColor: Colors.orange[100],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.all(8),
            ),
          );
        }
      },
      child: ListTile(
        leading: Icon(icon),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tag, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              record['imageName'] ?? 'Unnamed food',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Text(
          'Calories: ${record['calories']} kcal',
          style: const TextStyle(color: Colors.black),
        ),
        onTap: () => _showDetailBottomSheet(record),
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
          (BuildContext context) => GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {}, // Prevent tap from propagating to parent
                child: DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  minChildSize: 0.4,
                  maxChildSize: 0.9,
                  builder:
                      (
                        BuildContext context,
                        ScrollController scrollController,
                      ) => Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
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
                                    child: _buildImageFromBase64(
                                      record['base64Image'],
                                    ),
                                  ),
                                ),
                              Padding(
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
                                    _buildDetailRow(
                                      'Protein',
                                      '${record['protein']} g',
                                    ),
                                    _buildDetailRow(
                                      'Carbs',
                                      '${record['carbohydrate']} g',
                                    ),
                                    _buildDetailRow(
                                      'Fat',
                                      '${record['fat']} g',
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Additional Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (record['tag'] != null)
                                      _buildDetailRow(
                                        'Category',
                                        record['tag'],
                                      ),
                                    if (record['comment'] != null)
                                      _buildDetailRow(
                                        'Comment',
                                        record['comment'],
                                      ),
                                    _buildDetailRow(
                                      'Source',
                                      record['source'] == 'image_input'
                                          ? 'Image Input'
                                          : 'Text Input',
                                    ),
                                    _buildDetailRow(
                                      'Time',
                                      DateFormat('yyyy/MM/dd HH:mm').format(
                                        (record['timestamp'] as Timestamp)
                                            .toDate(),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          Navigator.pop(context); // 關閉詳情頁面
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => TextRecordPage(
                                                    initialRecord: record,
                                                  ),
                                            ),
                                          );
                                          if (result == true) {
                                            _fetchRecords(); // 重新載入資料
                                          }
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit Record'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFFFB74D),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }

  Widget _buildImageFromBase64(String base64String) {
    try {
      if (base64String.isEmpty) {
        return const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
        );
      }

      // Remove data URL prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains('base64,')) {
        cleanBase64 = base64String.split('base64,')[1];
      }

      // Check if the string is valid base64
      if (!cleanBase64.contains(RegExp(r'^[a-zA-Z0-9+/=]+$'))) {
        return const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 50),
        );
      }

      // Add padding if needed
      String paddedBase64 = cleanBase64;
      while (paddedBase64.length % 4 != 0) {
        paddedBase64 += '=';
      }

      // Try to decode the base64 string
      final bytes = base64Decode(paddedBase64);
      if (bytes.isEmpty) {
        return const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 50),
        );
      }

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 50),
          );
        },
      );
    } catch (e) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.red, size: 50),
      );
    }
  }
}
