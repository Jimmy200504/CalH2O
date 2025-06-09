import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;
  final double? width; // 可選的寬度參數

  const LoadingOverlay({
    super.key,
    this.message = 'Analyzing Photo',
    this.width, // 允許從外部傳入寬度
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, // 使用傳入的寬度，如果為 null 則自動調整
      margin: const EdgeInsets.only(top: 16, right: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[700]!),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
