import 'package:flutter/material.dart';

class NutritionCard extends StatelessWidget {
  final String label;
  final double value;
  final String left;
  final IconData icon;
  const NutritionCard({
    required this.label,
    required this.value,
    required this.left,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                Icon(icon, size: 32, color: Colors.orange),
              ],
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(left, style: TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }
}
