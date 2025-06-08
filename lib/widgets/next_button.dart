import 'package:flutter/material.dart';

class NextButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const NextButton({
    super.key,
    this.text = 'Next',
    required this.onPressed,
    this.width = double.infinity,
    this.height = 56,
  });

  @override
  State<NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<NextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.reverse(); // 按下縮小
  }

  void _onTapUp(TapUpDetails details) {
    // 不再調回正常大小
    widget.onPressed();
  }

  void _onTapCancel() {
    // 不再調回正常大小
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _animationController,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color(0xFFFFB74D),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 4),
                blurRadius: 6,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
