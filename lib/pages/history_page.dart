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
    final endOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    ).add(const Duration(days: 1));

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
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfMonth))
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
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
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
      showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDatePickerMode: DatePickerMode.year,
        builder:
            (context, child) => Theme(
              data: ThemeData().copyWith(
                colorScheme: const ColorScheme.light(
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
              ),
              child: child!,
            ),
      ).then((picked) {
        if (picked != null) {
          setState(() {
            _selectedDate = DateTime(picked.year, picked.month, 1);
            _fetchRecords();
          });
        }
      });
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
                colorScheme: const ColorScheme.light(
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

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ActionChip(
            onPressed: () => _selectDate(context),
            avatar: const Icon(
              Icons.calendar_today,
              size: 18,
              color: Color(0xFFFFB74D),
            ),
            label: Text(
              _isMonthView
                  ? DateFormat('yyyy / MM').format(_selectedDate)
                  : DateFormat('yyyy / MM / dd').format(_selectedDate),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final summaryData = [
      {
        'label': 'Calories',
        'value': '${_monthlyStats['calories']?.toStringAsFixed(0)} kcal',
        'icon': FontAwesomeIcons.fire,
        'color': Colors.redAccent,
      },
      {
        'label': 'Protein',
        'value': '${_monthlyStats['protein']?.toStringAsFixed(1)} g',
        'icon': FontAwesomeIcons.drumstickBite,
        'color': Colors.blueAccent,
      },
      {
        'label': 'Carbs',
        'value': '${_monthlyStats['carbohydrate']?.toStringAsFixed(1)} g',
        'icon': FontAwesomeIcons.breadSlice,
        'color': Colors.green,
      },
      {
        'label': 'Fat',
        'value': '${_monthlyStats['fat']?.toStringAsFixed(1)} g',
        'icon': FontAwesomeIcons.cheese,
        'color': Colors.orangeAccent,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              _isMonthView ? 'Monthly Summary' : 'Daily Summary',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summaryData.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.95,
            ),
            itemBuilder: (context, index) {
              final item = summaryData[index];
              return _buildSummaryCard(
                item['label'] as String,
                item['value'] as String,
                item['icon'] as IconData,
                item['color'] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.folderOpen, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No records found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _isMonthView
                ? 'There are no records for this month.'
                : 'There are no records for this day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _dailyRecords.length,
      itemBuilder: (context, index) {
        final dayData = _dailyRecords[index];
        if (dayData['date'] == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            iconColor: Colors.orange,
            collapsedIconColor: Colors.grey[600],
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            title: Text(
              DateFormat('MM / dd (E)').format(dayData['date'] as DateTime),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Total Calories: ${dayData['totalCalories'].toStringAsFixed(0)} kcal',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            children:
                (dayData['foods'] as List<Map<String, dynamic>>)
                    .map((record) => _buildMonthlyRecordItem(record))
                    .toList(),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyRecordItem(Map<String, dynamic> record) {
    final tag = record['tag'] as String? ?? 'Other';
    final icon = _tagIcons[tag] ?? Icons.fastfood;

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.orange.withOpacity(0.1),
        child: Icon(icon, size: 18, color: Colors.orange[800]),
      ),
      title: Text(record['imageName'] ?? 'Unnamed food'),
      trailing: Text(
        '${record['calories']?.toStringAsFixed(0) ?? 0} kcal',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () => _showDetailBottomSheet(record),
    );
  }

  Widget _buildDailyList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _dailyRecords.length,
      itemBuilder: (context, index) {
        return _buildRecordItem(_dailyRecords[index]);
      },
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    final tag = record['tag'] as String? ?? 'Other';
    final icon = _tagIcons[tag] ?? Icons.fastfood;

    // Safeguard against records without a documentId
    if (record['documentId'] == null) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key("${record['documentId']}-${record['timestamp']}"),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Confirm Delete'),
              content: const Text(
                'Are you sure you want to delete this record?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final account = prefs.getString('account');
          if (account == null) return;

          final docId = record['documentId'] as String;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(account)
              .collection('nutrition_records')
              .doc(docId)
              .delete();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Record deleted successfully',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
              backgroundColor: Colors.orange[100],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(8),
            ),
          );
          _fetchRecords();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Error deleting record',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
              backgroundColor: Colors.red[100],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(8),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: Icon(icon, color: Colors.orange[800]),
          ),
          title: Text(
            record['imageName'] ?? 'Unnamed food',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(tag, style: TextStyle(color: Colors.grey[600])),
          trailing: Text(
            '${record['calories']?.toStringAsFixed(0) ?? 0} kcal',
            style: TextStyle(
              color: Colors.orange[800],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          onTap: () => _showDetailBottomSheet(record),
        ),
      ),
    );
  }

  void _showDetailBottomSheet(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder:
                (_, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (record['base64Image'] != null &&
                                  record['base64Image'].toString().isNotEmpty)
                                SizedBox(
                                  height: 200,
                                  width: double.infinity,
                                  child: _buildImageFromBase64(
                                    record['base64Image'],
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(24),
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
                                    const SizedBox(height: 24),
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
                                    const SizedBox(height: 24),
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
                                    if (record['comment'] != null &&
                                        record['comment'].isNotEmpty)
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
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          Navigator.pop(
                                            context,
                                          ); // Close details
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
                                            _fetchRecords();
                                          }
                                        },
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Edit Record'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFFB74D,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ],
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

      String cleanBase64 = base64String;
      if (base64String.contains('base64,')) {
        cleanBase64 = base64String.split('base64,')[1];
      }

      if (cleanBase64.length % 4 != 0) {
        cleanBase64 += '=' * (4 - cleanBase64.length % 4);
      }

      final bytes = base64Decode(cleanBase64);
      if (bytes.isEmpty) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          _isMonthView ? 'Monthly History' : 'Daily History',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.black),
            tooltip: 'Analysis',
            onPressed: () => Navigator.pushNamed(context, '/analyze'),
          ),
          IconButton(
            icon: Icon(
              _isMonthView
                  ? Icons.calendar_today_outlined
                  : Icons.calendar_month_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isMonthView = !_isMonthView;
                if (_isMonthView) {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    1,
                  );
                }
                _fetchRecords();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildSummarySection(),
          Expanded(
            child:
                _dailyRecords.isEmpty
                    ? _buildEmptyState()
                    : _isMonthView
                    ? _buildMonthlyList()
                    : _buildDailyList(),
          ),
        ],
      ),
    );
  }
}
