import 'package:flutter/material.dart';

/// 一個可以處理鍵盤顯示的佈局組件
/// 當鍵盤出現時，內容會自動調整並可滾動
/// 點擊空白處會自動收起鍵盤
class KeyboardAwareLayout extends StatelessWidget {
  /// 子組件
  final Widget child;

  /// 是否啟用點擊空白處收起鍵盤
  final bool enableDismissOnTap;

  const KeyboardAwareLayout({
    super.key,
    required this.child,
    this.enableDismissOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap:
              enableDismissOnTap
                  // Use a safer way to unfocus to prevent edge cases
                  ? () => FocusManager.instance.primaryFocus?.unfocus()
                  : null,
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
            // This physics is more stable during rapid layout changes
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Ensure the content is at least as tall as the viewport
                minHeight: constraints.maxHeight,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
