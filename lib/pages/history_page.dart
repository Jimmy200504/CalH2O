import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

    final querySnapshot =
        await FirebaseFirestore.instance
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

    _dailyRecords = [];
    Map<DateTime, List<Map<String, dynamic>>> dailyRecordsMap = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

      if (!dailyRecordsMap.containsKey(date)) {
        dailyRecordsMap[date] = [];
      }
      dailyRecordsMap[date]!.add(data);

      _monthlyStats['calories'] =
          (_monthlyStats['calories'] ?? 0) + (data['calories'] ?? 0);
      _monthlyStats['protein'] =
          (_monthlyStats['protein'] ?? 0) + (data['protein'] ?? 0);
      _monthlyStats['carbohydrate'] =
          (_monthlyStats['carbohydrate'] ?? 0) + (data['carbohydrate'] ?? 0);
      _monthlyStats['fat'] = (_monthlyStats['fat'] ?? 0) + (data['fat'] ?? 0);
    }

    _dailyRecords =
        dailyRecordsMap.entries
            .map(
              (entry) => {
                'date': entry.key,
                'records': entry.value,
                'totalCalories': entry.value.fold<double>(
                  0,
                  (sum, record) => sum + (record['calories'] ?? 0),
                ),
              },
            )
            .toList();

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
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );

    final querySnapshot =
        await FirebaseFirestore.instance
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

    _dailyRecords = querySnapshot.docs.map((doc) => doc.data()).toList();
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
      appBar: AppBar(
        title: Text(_isMonthView ? 'Monthly History' : 'Daily History'),
        actions: [
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
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
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
                            children:
                                (dayData['records']
                                        as List<Map<String, dynamic>>)
                                    .map((record) => _buildRecordItem(record))
                                    .toList(),
                          ),
                        );
                      },
                    )
                    : ListView.builder(
                      itemCount: _dailyRecords.length,
                      itemBuilder: (context, index) {
                        return _buildRecordItem(_dailyRecords[index]);
                      },
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
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          // Get the document ID from the record
          final querySnapshot =
              await FirebaseFirestore.instance
                  .collection('nutrition_records')
                  .where('timestamp', isEqualTo: record['timestamp'])
                  .where('imageName', isEqualTo: record['imageName'])
                  .get();

          if (querySnapshot.docs.isNotEmpty) {
            await querySnapshot.docs.first.reference.delete();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Record deleted successfully'),
                duration: Duration(seconds: 2),
              ),
            );
            // Refresh the records
            _fetchRecords();
          }
        } catch (e) {
          print('Error deleting record: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error deleting record'),
              duration: Duration(seconds: 2),
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
    print('Showing detail for record: ${record['imageName']}');
    print('Base64 image length: ${record['base64Image']?.length ?? 0}');

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
                                      'Carbohydrates',
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
                                    _buildDetailRow(
                                      'Source',
                                      record['source'] == 'image_input'
                                          ? 'Image Input'
                                          : 'Text Input',
                                    ),
                                    if (record['tags'] != null)
                                      _buildDetailRow(
                                        'Tags',
                                        record['tags'].join(', '),
                                      ),
                                    if (record['commit'] != null)
                                      _buildDetailRow(
                                        'Commit',
                                        record['commit'],
                                      ),
                                    _buildDetailRow(
                                      'Time',
                                      DateFormat('yyyy/MM/dd HH:mm').format(
                                        (record['timestamp'] as Timestamp)
                                            .toDate(),
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
        print('Empty base64 string');
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
        print('Invalid base64 string format');
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
        print('Decoded bytes are empty');
        return const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 50),
        );
      }

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          print('Stack trace: $stackTrace');
          return const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 50),
          );
        },
      );
    } catch (e, stackTrace) {
      print('Error decoding base64: $e');
      print('Stack trace: $stackTrace');
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.red, size: 50),
      );
    }
  }

  Widget _buildMonthlySummary(Map<String, dynamic> record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedIconColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            DateFormat(
              'MM/dd',
            ).format((record['timestamp'] as Timestamp).toDate()),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Total Calories: ${record['totalCalories']} kcal',
            style: const TextStyle(color: Colors.grey),
          ),
          children: [
            if (record['foods'] != null)
              ...record['foods']
                  .map<Widget>(
                    (food) => ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(
                        food['imageName'] ?? 'Unnamed food',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${food['calories']} kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      onTap: () => _showDetailBottomSheet(food),
                    ),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }
}
