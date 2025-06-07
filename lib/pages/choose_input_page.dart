import 'package:flutter/material.dart';

class ChooseInputPage extends StatelessWidget {
  const ChooseInputPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('選擇輸入方式'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 7,
              child: _FloatingButton(
                asset: 'assets/selfie_cartoon.png',
                label: '點擊上傳圖片',
                onTap: () => Navigator.pushNamed(context, '/choose/image'),
              ),
            ),
            Expanded(
              flex: 7,
              child: _FloatingButton(
                asset: 'assets/text_input_cartoon.png',
                label: '點擊輸入文字',
                onTap: () => Navigator.pushNamed(context, '/choose/text'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback onTap;

  const _FloatingButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Ink.image(
          image: AssetImage(asset),
          fit: BoxFit.cover,
          child: InkWell(
            onTap: onTap,
            highlightColor: const Color.fromARGB(148, 255, 255, 255),
            child: Stack(
              children: [
                // 改為底部對齊提示
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 16, color: const Color.fromARGB(179, 54, 54, 54)),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color.fromARGB(179, 54, 54, 54),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}