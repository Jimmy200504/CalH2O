import 'package:flutter/material.dart';

class WaterDaySummary extends StatelessWidget {
  final double totalIntake;

  const WaterDaySummary({Key? key, required this.totalIntake})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          totalIntake.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
        ),
        const Text(
          'ml',
          style: TextStyle(fontSize: 20, color: Colors.grey, height: 1.0),
        ),
      ],
    );
  }
}
