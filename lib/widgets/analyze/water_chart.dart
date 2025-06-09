import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'dart:convert';

class WaterChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> waterData;
  final int period;

  const WaterChartWidget({Key? key, required this.waterData, required this.period}) : super(key: key);

  List<Map<String, dynamic>> _getGroupedWaterData() {
    List<Map<String, dynamic>> groupedData = [];

    if (period == 7) {
      // 前7天，每一天顯示一個點
      groupedData = waterData;
    } else if (period == 30) {
      // 前30天，每5天顯示一個點
      for (int i = 0; i < waterData.length; i += 5) {
        double totalMl = 0;
        String date = waterData[i]['date'];
        // 累加每5天的水量
        for (int j = i; j < i + 5 && j < waterData.length; j++) {
          totalMl += waterData[j]['ml'];
        }
        groupedData.add({'date': date, 'ml': totalMl});
      }
    } else if (period == 360) {
      // 前360天，每30天顯示一個點
      for (int i = 0; i < waterData.length; i += 30) {
        double totalMl = 0;
        String date = waterData[i]['date'];
        // 累加每30天的水量
        for (int j = i; j < i + 30 && j < waterData.length; j++) {
          totalMl += waterData[j]['ml'];
        }
        groupedData.add({'date': date, 'ml': totalMl});
      }
    }

    return groupedData;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> groupedData = _getGroupedWaterData();

    // JS Option for water line chart
    final lineChartOption = '''
    {
      tooltip: { trigger: 'axis' },
      xAxis: { type: 'category', data: ${jsonEncode(groupedData.map((e) => e['date']).toList())} },
      yAxis: { type: 'value' },
      series: [{
        name: '水量',
        type: 'line',
        data: ${jsonEncode(groupedData.map((e) => e['ml']).toList())},
        smooth: true,
        symbol: 'circle',
        symbolSize: 6
      }]
    }
    ''';

    return Expanded(
      flex: 1,
      child: Echarts(
        option: lineChartOption,
      ),
    );
  }
}
