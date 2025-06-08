import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_barrage/flutter_barrage.dart';

class SpeechBubble extends StatefulWidget {
  const SpeechBubble({super.key});

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble> {
  final List<String> _messages = [
    "so hungry",
    "please eat",
    "too full",
    "so unhealthy",
    "please don't eat junk food",
  ];

  late final BarrageWallController _barrageController;
  Timer? _addBulletTimer;

  @override
  void initState() {
    super.initState();
    _barrageController = BarrageWallController();

    // 啟動彈幕
    _startBarrage();
  }

  void _startBarrage() {
    _addBulletTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _messages.shuffle();
      _barrageController.send([
        Bullet(
          child: Text(
            _messages.first,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          showTime: 0,
        ),
      ]);
    });
  }

  @override
  void dispose() {
    _addBulletTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BarrageWall(
          controller: _barrageController,
          speed: 6,
          debug: false,
          child: Container(),
        ),
        // 你可以在 Stack 內加上其他 Widget，
        // 例如漸層背景或其他 overlay。
      ],
    );
  }
}
