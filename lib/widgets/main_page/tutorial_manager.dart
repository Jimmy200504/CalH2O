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
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "SKIP", 
      // onClickTarget: (target) => tutorialCoachMark.next(),
      onFinish: onTutorialFinish,
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
                "Add a new record",
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
