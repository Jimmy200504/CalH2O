import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_barrage/flutter_barrage.dart';

class SpeechBubble extends StatefulWidget {
  SpeechBubble({Key? key}) : super(key: key);
  @override
  SpeechBubbleState createState() => SpeechBubbleState();
}

class SpeechBubbleState extends State<SpeechBubble> {
  static const List<String> _defaultMessages = [
    "Hello",
    "How are we?",
    "Eat anything yet?",
    "You look dehydrated.",
    "What did you do today?",
    "Let's not eat junk food today?",
    "What's your goal of the day?",
  ];

  List<String> _messages = List.from(_defaultMessages);
  late final BarrageWallController _barrageController;
  Timer? _addBulletTimer;

  @override
  void initState() {
    super.initState();
    _barrageController = BarrageWallController();
    _startBarrage();
  }

  void updateMessages(List<String> newMessages) {
    if (newMessages.isEmpty) return; // 空陣列就不更新
    setState(() {
      _messages = newMessages;
      _barrageController.dispose();
      _barrageController = BarrageWallController();
    });
    // 重新啟動彈幕：先停掉再重開
    _addBulletTimer?.cancel();
    _startBarrage();
  }

  void _startBarrage() {
    if (_messages.isEmpty) return;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _handleRouteChange();
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _handleRouteChange();
//     });
//   }

//   void _handleRouteChange() {
//     final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
//     if (isCurrent) {
//       _startBarrage();
//     } else {
//       _stopBarrage();
//     }
//   }

//   void _startBarrage() {
//     _stopBarrage(); // 保險：先停掉
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
    _addBulletTimer?.cancel();
    _barrageController.dispose();
//     _stopBarrage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BarrageWall(
      controller: _barrageController,
      speed: 6,
      child: Container(color: Colors.transparent),
//       child: Container(),
    );
  }
}
