import 'dart:math';
import 'package:flutter/material.dart';

class WaveProgressBar extends StatefulWidget {
  final String label;
  final double value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String? additionalInfo;

  const WaveProgressBar({
    Key? key,
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.additionalInfo,
  }) : super(key: key);

  @override
  _WaveProgressBarState createState() => _WaveProgressBarState();
}

class _WaveProgressBarState extends State<WaveProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant WaveProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value > oldWidget.value) {
      _controller.forward(from: 0);
    } else if (widget.value < oldWidget.value) {
      _controller.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAdd() {
    widget.onIncrement();
  }

  void _onSubtract() {
    widget.onDecrement();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.value.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // 背景邊框
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
              // 水位波浪
              if (progress > 0)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: ClipPath(
                        clipper: _WaveClipperLeftGravity(
                          wavePhase: _controller.value * 2 * pi,
                          progress: progress,
                        ),
                        child: Container(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
              // 減號按鈕
              Positioned(
                left: 5,
                top: 10,
                bottom: 10,
                child: GestureDetector(
                  onTap: _onSubtract,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove, size: 24),
                  ),
                ),
              ),
              // 加號按鈕
              Positioned(
                right: 5,
                top: 10,
                bottom: 10,
                child: GestureDetector(
                  onTap: _onAdd,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.additionalInfo != null)
                  Text(
                    widget.additionalInfo!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 重力向左的垂直波浪裁剪
class _WaveClipperLeftGravity extends CustomClipper<Path> {
  final double wavePhase;
  final double progress;

  _WaveClipperLeftGravity({required this.wavePhase, required this.progress});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final fillX = w * progress;
    final amp = h * 0.25;

    final path = Path();
    path.moveTo(0, 0);
    for (double y = 0; y <= h; y++) {
      final norm = y / h;
      final x = fillX + sin(wavePhase + pi * norm) * amp;
      path.lineTo(x.clamp(0, w), y);
    }
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WaveClipperLeftGravity old) {
    return old.wavePhase != wavePhase || old.progress != progress;
  }
}

class MainProgressBar extends StatelessWidget {
  final Color color;
  final String label;
  final double value;
  final VoidCallback onIncrement;
  final String? additionalInfo;

  const MainProgressBar({
    super.key,
    required this.color,
    required this.label,
    required this.value,
    required this.onIncrement,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = value >= 0.99;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.centerRight,
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Stack(
                  children: [
                    if (value > 0)
                      Positioned.fill(
                        child: FractionallySizedBox(
                          widthFactor: value.clamp(0.0, 1.0),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(40),
                                right:
                                    isFull ? Radius.circular(40) : Radius.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Positioned(
                    //   right: 16,
                    //   top: 0,
                    //   bottom: 0,
                    //   child: Center(
                    //     child: GestureDetector(
                    //       onTap: onIncrement,
                    //       // child: Container(
                    //       //   width: 44,
                    //       //   height: 44,
                    //       //   decoration: BoxDecoration(
                    //       //     color: Colors.white,
                    //       //     border: Border.all(color: Colors.black, width: 2),
                    //       //     shape: BoxShape.circle,
                    //       //   ),
                    //       //   child: Icon(Icons.add, size: 28),
                    //       // ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (additionalInfo != null)
                  Text(
                    additionalInfo!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
