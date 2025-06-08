import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'package:intl/intl.dart';

enum Period { week, month, year }

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({Key? key}) : super(key: key);
  @override
  _AnalyzePageState createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  Period _period = Period.month;
  DateTime _selectedDate = DateTime.now();

  // 放到 JS option 裡的資料
  List<Map<String, dynamic>> _pieData = [];
  List<List<dynamic>> _lineData = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalyzeData();
  }

  Future<void> _fetchAnalyzeData() async {
    // 取 account
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    // 計算 start/end
    DateTime start, end = _selectedDate;
    switch (_period) {
      case Period.week:
        start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        end = start.add(const Duration(days: 6));
        break;
      case Period.month:
        start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        break;
      case Period.year:
        start = DateTime(_selectedDate.year, 1, 1);
        end = DateTime(_selectedDate.year, 12, 31);
        break;
    }

    final base = FirebaseFirestore.instance.collection('users').doc(account);

    // 撈營養資料
    final nutSnap = await base
      .collection('nutrition_records')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .get();
    double cal=0, pro=0, carb=0, fat=0;
    for (var doc in nutSnap.docs) {
      final d = doc.data();
      cal  += (d['calories'] ?? 0);
      pro  += (d['protein']  ?? 0);
      carb += (d['carbohydrate'] ?? 0);
      fat  += (d['fat'] ?? 0);
    }
    _pieData = [
      {'value': cal,  'name': '熱量'},
      {'value': pro,  'name': '蛋白質'},
      {'value': carb, 'name': '碳水'},
      {'value': fat,  'name': '脂肪'},
    ];

    // 撈體重資料
    final wSnap = await base
      .collection('weight_records')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .orderBy('timestamp')
      .get();
    _lineData = wSnap.docs.map((doc) {
      final d = doc.data();
      final dt = (d['timestamp'] as Timestamp).toDate();
      final w  = (d['weight'] as num).toDouble();
      // ECharts 期望：['YYYY-MM-DD', weight]
      return [DateFormat('yyyy-MM-dd').format(dt), w];
    }).toList();

    setState(() {});
  }

  void _onPeriodSelected(Period p) {
    setState(() {
      _period = p;
      _selectedDate = DateTime.now();
    });
    _fetchAnalyzeData();
  }

  @override
  Widget build(BuildContext context) {
    // JS Option for pie
    final pieOption = '''
    {
      tooltip: { trigger: 'item' },
      legend: { bottom: 0 },
      series: [{
        name: '營養分布',
        type: 'pie',
        radius: ['40%', '70%'],
        data: ${_pieData.toString()},
        label: { formatter: '{b}: {c} ({d}%)' }
      }]
    }
    ''';

    // JS Option for line
    final lineOption = '''
    {
      tooltip: { trigger: 'axis' },
      xAxis: {
        type: 'category',
        data: ${_lineData.map((e) => "'${e[0]}'").toList()}
      },
      yAxis: { type: 'value' },
      series: [{
        name: '體重',
        type: 'line',
        data: ${_lineData.map((e) => e[1]).toList()},
        smooth: true,
        symbol: 'circle',
        symbolSize: 6
      }]
    }
    ''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('營養 & 體重分析', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        actions: [
          PopupMenuButton<Period>(
            icon: const Icon(Icons.date_range, color: Colors.black),
            onSelected: _onPeriodSelected,
            itemBuilder: (_) => const [
              PopupMenuItem(value: Period.week,  child: Text('本週')),
              PopupMenuItem(value: Period.month, child: Text('本月')),
              PopupMenuItem(value: Period.year,  child: Text('本年')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 圓餅圖
          Expanded(
            child: Echarts(
              option: pieOption,
            ),
          ),
          const SizedBox(height: 16),
          // 折線圖
          Expanded(
            child: Echarts(
              option: lineOption,
            ),
          ),
        ],
      ),
    );
  }
}
