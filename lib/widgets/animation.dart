import 'dart:async';
import 'package:flutter/material.dart';

enum BodyType { slim, normal, fat }
enum AnimationPhase { main, transition }

class FrameAnimationWidget extends StatefulWidget {
  final double size;
  final BodyType bodyType; // 新增：外部輸入

  const FrameAnimationWidget({
    super.key,
    this.size = 250,
    required this.bodyType, // 記得 required
  });

  @override
  State<FrameAnimationWidget> createState() => _FrameAnimationWidgetState();
}

class _FrameAnimationWidgetState extends State<FrameAnimationWidget> {
  BodyType currentBody = BodyType.slim;
  BodyType targetBody = BodyType.normal;
  AnimationPhase phase = AnimationPhase.main;
  int frameIndex = 0;
  Timer? timer;

  final Map<BodyType, int> frameCounts = {
    BodyType.slim: 16,
    BodyType.normal: 10,
    BodyType.fat: 16,
  };

  final Map<String, int> transitionFrameCounts = {
    'normal_to_fat': 6,
    'fat_to_normal': 6,
    'normal_to_slim': 6,
    'slim_to_normal': 6,
  };

  @override
  void initState() {
    super.initState();
    startAnimation();
  }

  @override
  void didUpdateWidget(FrameAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當外部輸入的 bodyType 改變，就呼叫 changeBody
    if (oldWidget.bodyType != widget.bodyType) {
      changeBody(widget.bodyType);
    }
  }

  void startAnimation() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        int totalFrames;
        if (phase == AnimationPhase.main) {
          totalFrames = frameCounts[currentBody]!;
          frameIndex = (frameIndex + 1) % totalFrames;
        } else {
          final key = '${currentBody.name}_to_${targetBody.name}';
          totalFrames = transitionFrameCounts[key]!;
          frameIndex++;
          if (frameIndex >= totalFrames) {
            currentBody = targetBody;
            phase = AnimationPhase.main;
            frameIndex = 0;
          }
        }
      });
    });
  }

  void changeBody(BodyType newBody) {
    if (currentBody == newBody) return;

    if (_isDirectTransition(currentBody, newBody)) {
      // 直接播放
      setState(() {
        targetBody = newBody;
        phase = AnimationPhase.transition;
        frameIndex = 0;
      });
    } else {
      // 分段播放
      _playTransitionSequence(currentBody, newBody);
    }
  }

  bool _isDirectTransition(BodyType from, BodyType to) {
    if (from == BodyType.slim && to == BodyType.normal) return true;
    if (from == BodyType.normal && to == BodyType.fat) return true;
    if (from == BodyType.fat && to == BodyType.normal) return true;
    if (from == BodyType.normal && to == BodyType.slim) return true;
    return false;
  }


  void _playTransitionSequence(BodyType from, BodyType to) async {
  // 例如 slim ➔ fat，就拆成 slim ➔ normal ➔ fat
  List<BodyType> sequence = [];

  if (from == BodyType.slim && to == BodyType.fat) {
    sequence = [BodyType.normal, BodyType.fat];
  } else if (from == BodyType.fat && to == BodyType.slim) {
    sequence = [BodyType.normal, BodyType.slim];
  } else {
    // 理論上這邊不會進來，但保險起見
    sequence = [to];
  }

  for (BodyType intermediateTarget in sequence) {
    setState(() {
      targetBody = intermediateTarget;
      phase = AnimationPhase.transition;
      frameIndex = 0;
    });

    // 等待動畫完成
    int totalFrames = transitionFrameCounts['${currentBody.name}_to_${targetBody.name}']!;
    await Future.delayed(Duration(milliseconds: 100 * totalFrames));

    setState(() {
      currentBody = intermediateTarget;
      phase = AnimationPhase.main;
      frameIndex = 0;
    });
  }
}


  String getFramePath() {
    if (phase == AnimationPhase.main) {
      return 'assets/animation/${currentBody.name}/frame_$frameIndex.png';
    } else {
      final key = '${currentBody.name}_to_${targetBody.name}';
      return 'assets/animation/$key/frame_$frameIndex.png';
    }
  }

  BodyType getLeftBodyTarget() {
    switch (currentBody) {
      case BodyType.fat:
        return BodyType.normal;
      case BodyType.normal:
        return BodyType.slim;
      case BodyType.slim:
        return BodyType.slim;
    }
  }

  BodyType getRightBodyTarget() {
    switch (currentBody) {
      case BodyType.slim:
        return BodyType.normal;
      case BodyType.normal:
        return BodyType.fat;
      case BodyType.fat:
        return BodyType.fat;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Image.asset(
            getFramePath(),
            width: widget.size,
            height: widget.size,
            gaplessPlayback: true,
          ),
        ),
      ],
    );
  }
}
