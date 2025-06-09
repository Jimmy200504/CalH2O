import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:lottie/lottie.dart';

class ComboBadge extends StatefulWidget {
  final int comboCount;

  const ComboBadge({super.key, required this.comboCount});

  @override
  State<ComboBadge> createState() => _ComboBadgeState();
}

class _ComboBadgeState extends State<ComboBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late int _oldCombo;

  @override
  void initState() {
    super.initState();
    _oldCombo = widget.comboCount;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_controller);

    _controller.forward().then((_) => _controller.reverse());
  }

  @override
  void didUpdateWidget(covariant ComboBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comboCount != widget.comboCount) {
      _oldCombo = oldWidget.comboCount;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showFlame = widget.comboCount > 1;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showFlame)
              Transform.translate(
                offset: const Offset(0, -20),
                child: Transform.scale(
                  scale: 1.4,
                  child: Lottie.asset(
                    'assets/animation/fire.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxWidth: 60, maxHeight: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            Transform.translate(
              offset: const Offset(0, 2), // 數字向下對齊
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                child: Text(
                  '${widget.comboCount}',
                  key: ValueKey<int>(widget.comboCount),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
