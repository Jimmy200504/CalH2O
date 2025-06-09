import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'dart:convert';

class WaterChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> waterData;

  const WaterChartWidget({Key? key, required this.waterData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (waterData.isEmpty) {
      return const Center(child: Text("No data available for this period."));
    }

    final lineChartOption = '''
    {
      title: {
        text: 'Water Intake Analysis',
        left: 'center',
        textStyle: {
          color: '#333',
          fontSize: 18,
          fontWeight: 'bold'
        }
      },
      tooltip: {
        trigger: 'axis',
        formatter: '{b0}<br/>Intake: {c0} ml'
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        boundaryGap: false,
        data: ${jsonEncode(waterData.map((e) => e['date']).toList())},
        axisLine: { lineStyle: { color: '#888' } },
        name: 'Date',
        nameLocation: 'middle',
        nameGap: 30
      },
      yAxis: {
        type: 'value',
        name: 'Intake (ml)',
        nameLocation: 'middle',
        nameGap: 50,
        axisLine: { show: true, lineStyle: { color: '#888' } },
        splitLine: { lineStyle: { color: '#eee' } }
      },
      series: [{
        name: 'Water Intake',
        type: 'line',
        data: ${jsonEncode(waterData.map((e) => (e['ml'] as num).round()).toList())},
        smooth: true,
        symbol: 'circle',
        symbolSize: 8,
        lineStyle: {
          color: '#5470C6',
          width: 3
        },
        itemStyle: {
          color: '#5470C6',
          borderColor: '#fff',
          borderWidth: 2
        },
        areaStyle: {
          color: {
            type: 'linear',
            x: 0,
            y: 0,
            x2: 0,
            y2: 1,
            colorStops: [{
                offset: 0, color: 'rgba(84, 112, 198, 0.5)'
            }, {
                offset: 1, color: 'rgba(84, 112, 198, 0.1)'
            }]
          }
        }
      }]
    }
    ''';

    return Echarts(option: lineChartOption);
  }
}
