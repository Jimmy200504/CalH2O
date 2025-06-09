import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/analyze/water_chart.dart';  // 引入WaterChartWidget
import '../widgets/analyze/water_dialog_widget.dart';  // 引入WaterDialogWidget

enum Period { last7Days, last30Days, last360Days }

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({Key? key}) : super(key: key);

  @override
  _AnalyzePageState createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  Period _period = Period.last7Days;
  DateTime _selectedDate = DateTime.now();

  // 用於顯示圖表的數據
  List<Map<String, dynamic>> _pieData = [];
  double _calories = 0, _protein = 0, _carbohydrate = 0, _fat = 0;
  double _total = 0;

  // 水的折線圖數據
  List<Map<String, dynamic>> _waterData = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalyzeData();
    _fetchWaterData();
  }

  // Fetch Nutrition Data for Pie Chart
  Future<void> _fetchAnalyzeData() async {
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    DateTime start, end = _selectedDate;
    switch (_period) {
      case Period.last7Days:
        start = _selectedDate.subtract(Duration(days: 7));
        end = _selectedDate;
        break;
      case Period.last30Days:
        start = _selectedDate.subtract(Duration(days: 30));
        end = _selectedDate;
        break;
      case Period.last360Days:
        start = _selectedDate.subtract(Duration(days: 360));
        end = _selectedDate;
        break;
    }

    final base = FirebaseFirestore.instance.collection('users').doc(account);

    final nutSnap = await base
        .collection('nutrition_records')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    double pro = 0, carb = 0, fat = 0;

    for (var doc in nutSnap.docs) {
      final d = doc.data();
      pro += (d['protein'] ?? 0);
      carb += (d['carbohydrate'] ?? 0);
      fat += (d['fat'] ?? 0);
    }

    _total = pro + carb + fat;

    double proPercentage = (_total == 0) ? 0 : (pro / _total) * 100;
    double carbPercentage = (_total == 0) ? 0 : (carb / _total) * 100;
    double fatPercentage = (_total == 0) ? 0 : (fat / _total) * 100;

    double totalPercentage = proPercentage + carbPercentage + fatPercentage;
    if (totalPercentage != 100) {
      double diff = 100 - totalPercentage;
      fatPercentage += diff;
    }

    _pieData = [
      {'value': proPercentage, 'name': 'protein'},
      {'value': carbPercentage, 'name': 'carbohydrate'},
      {'value': fatPercentage, 'name': 'fat'},
    ];

    _protein = pro;
    _carbohydrate = carb;
    _fat = fat;

    setState(() {});
  }

  // Fetch Water Data for Line Chart
  Future<void> _fetchWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    DateTime start, end = _selectedDate;
    switch (_period) {
      case Period.last7Days:
        start = _selectedDate.subtract(Duration(days: 7));
        end = _selectedDate;
        break;
      case Period.last30Days:
        start = _selectedDate.subtract(Duration(days: 30));
        end = _selectedDate;
        break;
      case Period.last360Days:
        start = _selectedDate.subtract(Duration(days: 360));
        end = _selectedDate;
        break;
    }

    final base = FirebaseFirestore.instance.collection('users').doc(account);

    final waterSnap = await base
        .collection('water_records')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp')
        .get();

    _waterData = waterSnap.docs.map((doc) {
      final d = doc.data();
      final dt = (d['timestamp'] as Timestamp).toDate();
      final ml = (d['ml'] as num).toDouble();
      return {'date': DateFormat('yyyy-MM-dd').format(dt), 'ml': ml};
    }).toList();

    setState(() {});
  }

  // Handle period selection
  void _onPeriodSelected(Period p) {
    setState(() {
      _period = p;
      _selectedDate = DateTime.now();
    });
    _fetchAnalyzeData();
    _fetchWaterData();
  }

  // Show the water upload dialog
  void _showWaterUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return WaterUploadWidget(
          onSuccess: () {
            _fetchWaterData();  // Refresh water data after upload
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        actions: [
          PopupMenuButton<Period>(
            color: Colors.white,
            icon: const Icon(Icons.date_range, color: Colors.black),
            onSelected: _onPeriodSelected,
            itemBuilder: (_) => const [
              PopupMenuItem(value: Period.last7Days, child: Text('week')),
              PopupMenuItem(value: Period.last30Days, child: Text('month')),
              PopupMenuItem(value: Period.last360Days, child: Text('year')),
            ],
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // 圓餅圖
            Expanded(
              flex: 1,
              child: Echarts(
                option: '''
                {
                  tooltip: { trigger: 'item' },
                  legend: {
                    orient: 'horizontal',
                    left: 'center',
                    bottom: '0%',
                    data: ${jsonEncode(_pieData.map((e) => e['name']).toList())},
                    formatter: function(name) {
                      var targetData = ${jsonEncode(_pieData)}; 
                      var current = targetData.find(e => e.name == name);
                      return name + ' (' + current.value.toFixed(1) + 'g)';
                    }
                  },
                  series: [{
                    name: '營養分布',
                    type: 'pie',
                    radius: ['40%', '70%'],
                    data: ${jsonEncode(_pieData)},
                    label: { show: false },
                    itemStyle: {
                      normal: {
                        color: function(params) {
                          var colorList = ['#fccb4e', '#fc6ff3', '#fc6f87'];
                          return colorList[params.dataIndex];
                        }
                      }
                    }
                  }]
                }
                '''
              ),
            ),
            // 水量折線圖
            WaterChartWidget(waterData: _waterData, period: _period == Period.last7Days ? 7 : (_period == Period.last30Days ? 30 : 360)),
            // 上傳水資料的按鈕
            // ElevatedButton(
            //   onPressed: _showWaterUploadDialog,
            //   child: const Text('上傳水量資料'),
            // ),
          ],
        ),
      ),
    );
  }
}
