import 'package:flutter/material.dart';

/// 一個可以處理鍵盤顯示的佈局組件
/// 當鍵盤出現時，內容會自動調整並可滾動
/// 點擊空白處會自動收起鍵盤
class KeyboardAwareLayout extends StatelessWidget {
  /// 子組件
  final Widget child;

  /// 是否啟用點擊空白處收起鍵盤
  final bool enableDismissOnTap;

  /// 是否啟用自動調整大小
  final bool enableResizeToAvoidBottomInset;

  const KeyboardAwareLayout({
    super.key,
    required this.child,
    this.enableDismissOnTap = true,
    this.enableResizeToAvoidBottomInset = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 點擊空白處收起鍵盤
      onTap: enableDismissOnTap ? () => FocusScope.of(context).unfocus() : null,
      // 確保點擊事件不會影響子組件
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                child,
                // 添加底部空間，確保內容不會被鍵盤遮擋
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
