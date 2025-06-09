import 'package:flutter/material.dart';

/// 一個可以處理鍵盤顯示的佈局組件。
/// 當鍵盤出現時，此組件會將UI向上推，而不是調整其內部大小。
///
/// **重要:** 使用此佈局的頁面，其Scaffold必須設置 `resizeToAvoidBottomInset: false`。
class KeyboardAwareLayout extends StatefulWidget {
  /// 子組件
  final Widget child;

  const KeyboardAwareLayout({super.key, required this.child});

  @override
  State<KeyboardAwareLayout> createState() => _KeyboardAwareLayoutState();
}

class _KeyboardAwareLayoutState extends State<KeyboardAwareLayout>
    with WidgetsBindingObserver {
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset != _keyboardHeight) {
      setState(() {
        _keyboardHeight = bottomInset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverFillRemaining(hasScrollBody: false, child: widget.child),
          SliverToBoxAdapter(child: SizedBox(height: _keyboardHeight)),
        ],
      ),
    );
  }
}
