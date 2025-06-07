// import 'dart:async';
// import 'package:flutter/material.dart';

// enum BodyType { slim, normal, fat }
// enum AnimationPhase { main, transition }

// class FrameAnimationWidget extends StatefulWidget {
//   final double size;
//   const FrameAnimationWidget({super.key, this.size = 250});

//   @override
//   State<FrameAnimationWidget> createState() => _FrameAnimationWidgetState();
// }

// class _FrameAnimationWidgetState extends State<FrameAnimationWidget> {
//   BodyType currentBody = BodyType.normal;
//   BodyType targetBody = BodyType.normal;
//   AnimationPhase phase = AnimationPhase.main;
//   int frameIndex = 0;
//   Timer? timer;

//   final Map<BodyType, int> frameCounts = {
//     BodyType.slim: 16,
//     BodyType.normal: 10,
//     BodyType.fat: 16,
//   };

//   final Map<String, int> transitionFrameCounts = {
//     'normal_to_fat': 6,
//     'fat_to_normal': 6,
//     'normal_to_slim': 6,
//     'slim_to_normal': 6,
//   };

//   @override
//   void initState() {
//     super.initState();
//     startAnimation();
//   }

//   void startAnimation() {
//     timer?.cancel();
//     timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
//       setState(() {
//         int totalFrames;
//         if (phase == AnimationPhase.main) {
//           totalFrames = frameCounts[currentBody]!;
//           frameIndex = (frameIndex + 1) % totalFrames;
//         } else {
//           final key = '${currentBody.name}_to_${targetBody.name}';
//           totalFrames = transitionFrameCounts[key]!;
//           frameIndex++;
//           if (frameIndex >= totalFrames) {
//             currentBody = targetBody;
//             phase = AnimationPhase.main;
//             frameIndex = 0;
//           }
//         }
//       });
//     });
//   }

//   void changeBody(BodyType newBody) {
//     if (currentBody == newBody) return;
//     setState(() {
//       targetBody = newBody;
//       phase = AnimationPhase.transition;
//       frameIndex = 0;
//     });
//   }

//   String getFramePath() {
//     if (phase == AnimationPhase.main) {
//       return 'assets/animation/${currentBody.name}/frame_$frameIndex.png';
//     } else {
//       final key = '${currentBody.name}_to_${targetBody.name}';
//       return 'assets/animation/$key/frame_$frameIndex.png';
//     }
//   }

//   @override
//   void dispose() {
//     timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         BodyType next = BodyType.values[
//           (BodyType.values.indexOf(currentBody) + 1) % BodyType.values.length
//         ];
//         changeBody(next);
//       },
//       child: SizedBox(
//         width: widget.size,
//         height: widget.size,
//         child: Image.asset(
//           getFramePath(),
//           width: widget.size,
//           height: widget.size,
//           gaplessPlayback: true,
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';

enum BodyType { slim, normal, fat }
enum AnimationPhase { main, transition }

class FrameAnimationWidget extends StatefulWidget {
  final double size;
  const FrameAnimationWidget({super.key, this.size = 250});

  @override
  State<FrameAnimationWidget> createState() => _FrameAnimationWidgetState();
}

class _FrameAnimationWidgetState extends State<FrameAnimationWidget> {
  BodyType currentBody = BodyType.normal;
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
    setState(() {
      targetBody = newBody;
      phase = AnimationPhase.transition;
      frameIndex = 0;
    });
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
        return BodyType.slim; // 沒有 slimmer
    }
  }

  BodyType getRightBodyTarget() {
    switch (currentBody) {
      case BodyType.slim:
        return BodyType.normal;
      case BodyType.normal:
        return BodyType.fat;
      case BodyType.fat:
        return BodyType.fat; // 沒有更 fat
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
        Positioned.fill(
          child: Row(
            children: [
              // 左半邊
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    BodyType next = getLeftBodyTarget();
                    if (next != currentBody) {
                      changeBody(next);
                    }
                  },
                ),
              ),
              // 右半邊
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    BodyType next = getRightBodyTarget();
                    if (next != currentBody) {
                      changeBody(next);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
