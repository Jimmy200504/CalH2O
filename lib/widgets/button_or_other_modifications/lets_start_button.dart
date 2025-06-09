import 'dart:async';
import 'package:flutter/material.dart';

class LetsStartButton extends StatefulWidget {
  final String text;
  final bool isSaving;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const LetsStartButton({
    super.key,
    this.text = 'Let\'s Start!',
    this.isSaving = false,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 56,
  });

  @override
  State<LetsStartButton> createState() => _LetsStartButtonState();
}

class _LetsStartButtonState extends State<LetsStartButton> {
  int _dotCount = 1;
  Timer? _dotTimer;

  @override
  void didUpdateWidget(covariant LetsStartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSaving && _dotTimer == null) {
      _startDotAnimation();
    } else if (!widget.isSaving && _dotTimer != null) {
      _stopDotAnimation();
    }
  }

  void _startDotAnimation() {
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _dotCount = (_dotCount % 3) + 1;
      });
    });
  }

  void _stopDotAnimation() {
    _dotTimer?.cancel();
    _dotTimer = null;
    setState(() {
      _dotCount = 1;
    });
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isSaving ? null : widget.onPressed,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFFFB74D),
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
        child: widget.isSaving
            ? Text(
                '.' * _dotCount,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
