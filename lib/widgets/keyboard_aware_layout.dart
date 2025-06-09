import 'package:flutter/material.dart';

/// 一個可以處理鍵盤顯示的佈局組件。
/// 當鍵盤出現時，此組件會將UI向上推，而不是調整其內部大小。
///
/// **重要:** 使用此佈局的頁面，其Scaffold必須設置 `resizeToAvoidBottomInset: false`。
class KeyboardAwareLayout extends StatelessWidget {
  /// 子組件
  final Widget child;

  const KeyboardAwareLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: CustomScrollView(
        // Use bouncing physics for a natural iOS feel
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverFillRemaining(hasScrollBody: false, child: child),
          // This sliver adds space for the keyboard at the bottom
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ),
        ],
      ),
    );
  }
}
