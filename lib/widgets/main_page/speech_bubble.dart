import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_barrage/flutter_barrage.dart';
import 'package:flutter/foundation.dart';

class SpeechBubble extends StatefulWidget {
  final List<String> messages;
  const SpeechBubble({super.key, required this.messages});

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble> {
  late final BarrageWallController _barrageController;
  Timer? _addBulletTimer;

  List<String> _messages = [];
  final Random _random = Random();

  @override
  void initState() {
    debugPrint("InitState.");
    super.initState();
    _barrageController = BarrageWallController();
    _messages = widget.messages..shuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRouteChange();
    });
  }

  @override
  void didUpdateWidget(SpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.messages, widget.messages)) {
      if (mounted) {
        setState(() {
          _messages = widget.messages..shuffle();
        });
      }
    }
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
    _stopBarrage(); // Ensure barrage stops before restarting
    _addBulletTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _messages.isEmpty) return;

      final message = _messages[_random.nextInt(_messages.length)];
      _barrageController.send([
        Bullet(
          child: Text(
            message,
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
    _barrageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Build Message Bubble.");
    return BarrageWall(
      controller: _barrageController,
      speed: 6,
      child: Container(),
    );
  }
}
