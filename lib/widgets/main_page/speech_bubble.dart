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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRouteChange();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRouteChange();
    });
  }

  void _handleRouteChange() {
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (isCurrent) {
      _startBarrage();
    } else {
      _stopBarrage();
    }
  }

  void _startBarrage() {
    _stopBarrage(); // 保險：先停掉
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

  void _stopBarrage() {
    _addBulletTimer?.cancel();
    _addBulletTimer = null;
  }

  @override
  void dispose() {
    _stopBarrage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BarrageWall(
      controller: _barrageController,
      speed: 6,
      child: Container(),
    );
  }
}
