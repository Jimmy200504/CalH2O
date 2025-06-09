import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/analyze/water_chart.dart'; // 引入WaterChartWidget
import '../widgets/analyze/water_dialog_widget.dart'; // 引入WaterDialogWidget
import '../widgets/analyze/water_day_summary.dart';

enum Period { day, week, month }

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({Key? key}) : super(key: key);

  @override
  _AnalyzePageState createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  Period _period = Period.week;
  DateTime _selectedDate = DateTime.now();

  // 用於顯示圖表的數據
  List<Map<String, dynamic>> _pieData = [];
  double _protein = 0, _carbohydrate = 0, _fat = 0;
  double _total = 0;

  // 水的折線圖數據
  List<Map<String, dynamic>> _waterData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await _fetchAnalyzeData();
    await _fetchWaterData();
    setState(() => _isLoading = false);
  }

  Map<String, DateTime> _calculateDateRange() {
    DateTime start, end;
    switch (_period) {
      case Period.day:
        start = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
        end = start.add(const Duration(days: 1));
        break;
      case Period.week:
        start = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        start = DateTime(start.year, start.month, start.day);
        end = start.add(const Duration(days: 7));
        break;
      case Period.month:
        start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        end = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
        break;
    }
    return {'start': start, 'end': end};
  }

  Future<void> _fetchAnalyzeData() async {
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    final range = _calculateDateRange();
    final nutSnap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(account)
            .collection('nutrition_records')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range['start']!),
            )
            .where('timestamp', isLessThan: Timestamp.fromDate(range['end']!))
            .get();

    double pro = 0, carb = 0, fat = 0;
    for (var doc in nutSnap.docs) {
      final d = doc.data();
      pro += (d['protein'] ?? 0);
      carb += (d['carbohydrate'] ?? 0);
      fat += (d['fat'] ?? 0);
    }

    final total = pro + carb + fat;

    // Defensively handle the zero-intake case.
    if (total == 0) {
      debugPrint('No nutrition data for this period.');
      _pieData = [];
      return;
    } else {
      _pieData = [
        {'value': pro, 'name': 'Protein'},
        {'value': carb, 'name': 'Carbs'},
        {'value': fat, 'name': 'Fats'},
      ];
    }

    _total = total;

    double proPercentage = (_total == 0) ? 0 : (pro / _total) * 100;
    double carbPercentage = (_total == 0) ? 0 : (carb / _total) * 100;
    double fatPercentage = (_total == 0) ? 0 : (fat / _total) * 100;

    double totalPercentage = proPercentage + carbPercentage + fatPercentage;
    if (totalPercentage != 100) {
      double diff = 100 - totalPercentage;
      fatPercentage += diff;
    }

    _pieData = [
      {'value': proPercentage, 'name': 'Protein'},
      {'value': carbPercentage, 'name': 'Carbs'},
      {'value': fatPercentage, 'name': 'Fats'},
    ];

    _protein = pro;
    _carbohydrate = carb;
    _fat = fat;

    setState(() {});
  }

  Future<void> _fetchWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    final range = _calculateDateRange();
    final waterSnap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(account)
            .collection('water_records')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range['start']!),
            )
            .where('timestamp', isLessThan: Timestamp.fromDate(range['end']!))
            .get();

    // Use a map to sum up the water intake for each day within the range.
    Map<String, double> dailyTotals = {};
    for (var doc in waterSnap.docs) {
      final d = doc.data();
      final dt = (d['timestamp'] as Timestamp).toDate();
      final dateStr = DateFormat('yyyy-MM-dd').format(dt);
      final ml = (d['ml'] as num).toDouble();
      dailyTotals.update(dateStr, (value) => value + ml, ifAbsent: () => ml);
    }

    // Create a complete list of dates for the selected period to ensure the chart
    // shows days with zero intake.
    List<Map<String, dynamic>> processedData = [];
    DateTime currentDate = range['start']!;
    while (currentDate.isBefore(range['end']!)) {
      final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
      processedData.add({'date': dateStr, 'ml': dailyTotals[dateStr] ?? 0.0});
      currentDate = currentDate.add(const Duration(days: 1));
    }

    _waterData = processedData;

    setState(() {});
  }

  bool _isCurrentPeriod() {
    final now = DateTime.now();
    final range = _calculateDateRange();
    // A period is current if `now` is between its start (inclusive) and end (exclusive)
    return !now.isBefore(range['start']!) && now.isBefore(range['end']!);
  }

  void _onPeriodSelected(Period p) {
    if (_period == p) return;
    setState(() {
      _period = p;
      _selectedDate = DateTime.now();
    });
    _fetchData();
  }

  void _changeDate(int amount) {
    setState(() {
      if (_period == Period.day) {
        _selectedDate = _selectedDate.add(Duration(days: amount));
      } else if (_period == Period.week) {
        _selectedDate = _selectedDate.add(Duration(days: 7 * amount));
      } else {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + amount,
          _selectedDate.day,
        );
      }
    });
    _fetchData();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    // Safeguard: Ensure the initial date for the picker is not in the future.
    final initial = _selectedDate.isAfter(now) ? now : _selectedDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData();
    }
  }

  String _getDateNavigatorText() {
    switch (_period) {
      case Period.day:
        return DateFormat.yMMMd().format(_selectedDate);
      case Period.week:
        final range = _calculateDateRange();
        final start = DateFormat.MMMd().format(range['start']!);
        final end = DateFormat.MMMd().format(
          range['end']!.subtract(const Duration(days: 1)),
        );
        return '$start - $end';
      case Period.month:
        return DateFormat.yMMM().format(_selectedDate);
    }
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<Period>(
        segments: const [
          ButtonSegment<Period>(value: Period.day, label: Text('Day')),
          ButtonSegment<Period>(value: Period.week, label: Text('Week')),
          ButtonSegment<Period>(value: Period.month, label: Text('Month')),
        ],
        selected: {_period},
        onSelectionChanged:
            (newSelection) => _onPeriodSelected(newSelection.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          selectedBackgroundColor: Colors.orange[300],
          selectedForegroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDateNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDate(-1),
          ),
          TextButton(
            onPressed: _selectDate,
            child: Text(
              _getDateNavigatorText(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            // Disable the button if we are already viewing the current period.
            onPressed: _isCurrentPeriod() ? null : () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(height: 300, child: chart),
          ],
        ),
      ),
    );
  }

  String getPieChartOption() {
    final total = _pieData.fold<double>(
      0.0,
      (sum, item) => sum + (item['value'] as num),
    );
    return '''
    {
      tooltip: {
        trigger: 'item',
        formatter: function(params) {
          var percent = $total > 0 ? ((params.value / $total) * 100).toFixed(1) : 0;
          return params.name + ': ' + params.value.toFixed(1) + 'g (' + percent + '%)';
        }
      },
      legend: {
        orient: 'horizontal', left: 'center', bottom: '0%',
        data: ${jsonEncode(_pieData.map((e) => e['name']).toList())},
      },
      series: [{
        name: 'Nutrition Ratio', type: 'pie', radius: ['40%', '70%'],
        avoidLabelOverlap: false, label: { show: false },
        emphasis: { label: { show: true, fontSize: '18', fontWeight: 'bold' } },
        labelLine: { show: false },
        data: ${jsonEncode(_pieData)},
        color: ['#fccb4e', '#5470C6', '#fc6f87']
      }]
    }
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSegmentedControl(),
                    _buildDateNavigator(),
                    _buildChartCard(
                      title: 'Nutrition Ratio',
                      chart:
                          _pieData.isEmpty
                              ? const Center(
                                child: Text(
                                  "No nutrition data for this period.",
                                ),
                              )
                              : Echarts(option: getPieChartOption()),
                    ),
                    if (_period != Period.day)
                      _buildChartCard(
                        title: 'Water Intake',
                        chart: WaterChartWidget(waterData: _waterData),
                      )
                    else
                      _buildChartCard(
                        title: 'Water Intake',
                        chart: WaterDaySummary(
                          totalIntake:
                              _waterData.isNotEmpty
                                  ? _waterData.first['ml']
                                  : 0.0,
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
