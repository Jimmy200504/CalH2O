import 'package:flutter/material.dart';

/// 用來顯示可變數值的營養進度條，使用活力水藍色
class NutrientBar extends StatelessWidget {
  final String label;
  final double value;
  final String leftText;

  const NutrientBar({
    super.key,
    required this.label,
    required this.value,
    required this.leftText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent,
                ),
              ),
              Text(
                leftText,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
            ),
          ),
        ],
      ),
    );
  }
}
