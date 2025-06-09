import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialManager {
  static void showTutorial({
    required BuildContext context,
    required GlobalKey addKey,
    required GlobalKey historyKey,
    required GlobalKey comboKey,
    required GlobalKey editNoteKey,
    required GlobalKey cameraAltKey,
    required GlobalKey petKey,
    required VoidCallback onTutorialStart,
    required VoidCallback onTutorialFinish,
    required VoidCallback expandSubButtonsCallback,
    required VoidCallback hideSubButtonsCallback,
  }) {
    // This callback will trigger the state change in MainPage to show the sub-buttons
    onTutorialStart();

    List<TargetFocus> targets = _createTargets(
      addKey: addKey,
      historyKey: historyKey,
      comboKey: comboKey,
      editNoteKey: editNoteKey,
      cameraAltKey: cameraAltKey,
      petKey: petKey,
    );

    late TutorialCoachMark tutorialCoachMark;

    bool isAdvancing = false;
    void advance([String? targetIdentify]) {
      if (isAdvancing) return;
      isAdvancing = true;

      // When the user taps the 'Add' target, trigger the button expansion
      if (targetIdentify == 'Add') {
        expandSubButtonsCallback();
      }

      // When the user taps the 'Camera' target, trigger the button retraction
      if (targetIdentify == 'Camera') {
        hideSubButtonsCallback();
      }

      // Wait for the animation to finish ONLY when advancing from 'Add'
      final delay =
          targetIdentify == 'Add'
              ? const Duration(milliseconds: 450)
              : Duration.zero;

      Future.delayed(delay, () {
        tutorialCoachMark.next();
        // Standard debounce to prevent any double-taps
        Future.delayed(const Duration(milliseconds: 300), () {
          isAdvancing = false;
        });
      });
    }

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "SKIP",
      onFinish: () {
        isAdvancing = false;
        onTutorialFinish();
      },
      onClickTarget: (target) => advance(target.identify),
      onClickOverlay: (target) => advance(target.identify),
    )..show(context: context);
  }

  static List<TargetFocus> _createTargets({
    required GlobalKey addKey,
    required GlobalKey historyKey,
    required GlobalKey comboKey,
    required GlobalKey editNoteKey,
    required GlobalKey cameraAltKey,
    required GlobalKey petKey,
  }) {
    return [
      TargetFocus(
        identify: "Combo",
        keyTarget: comboKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controllerTarget) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(height: 50),
                  Text(
                    "This shows your combo streak of daily records!",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Add",
        keyTarget: addKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controllerTarget) {
              return const Text(
                "Tap here to see more options",
                style: TextStyle(color: Colors.white, fontSize: 20),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "EditNote",
        keyTarget: editNoteKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controllerTarget) {
              return FutureBuilder(
                future: Future.delayed(const Duration(milliseconds: 100)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox.shrink(); // Show nothing while waiting
                  }
                  // Show the content after the delay
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(height: 8),
                      Text(
                        "Add notes to your entry",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Camera",
        keyTarget: cameraAltKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controllerTarget) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(height: 8),
                  Text(
                    "Use the camera to scan food",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "History",
        keyTarget: historyKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controllerTarget) {
              return const Text(
                "Check the history",
                style: TextStyle(color: Colors.white, fontSize: 20),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Pet",
        keyTarget: petKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controllerTarget) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "The pet in the middle shows your health status.\nPlease pay attention to your diet.",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];
  }
}
