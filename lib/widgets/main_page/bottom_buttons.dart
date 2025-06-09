import 'package:flutter/material.dart';

class BottomButtons extends StatelessWidget {
  final double iconSize;
  final bool showSubButtons;
  final VoidCallback onAddPressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback onEditNotePressed;
  final VoidCallback onCameraPressed;
  final GlobalKey addKey;
  final GlobalKey historyKey;
  final GlobalKey editNoteKey;
  final GlobalKey cameraAltKey;

  const BottomButtons({
    super.key,
    required this.iconSize,
    required this.showSubButtons,
    required this.onAddPressed,
    required this.onHistoryPressed,
    required this.onEditNotePressed,
    required this.onCameraPressed,
    required this.addKey,
    required this.historyKey,
    required this.editNoteKey,
    required this.cameraAltKey,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: screenHeight * 0.01,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: addKey,
                icon: Icon(
                  Icons.lunch_dining,
                  size: iconSize,
                  color: showSubButtons ? Colors.grey : Colors.black,
                ),
                onPressed: onAddPressed,
              ),
              IconButton(
                key: historyKey,
                icon: Icon(Icons.access_time, size: iconSize),
                onPressed: onHistoryPressed,
              ),
            ],
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          bottom: showSubButtons ? screenHeight * 0.2 : 100,
          left: showSubButtons ? 0 : -100,
          right: showSubButtons ? screenWidth * 0.25 : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: showSubButtons ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !showSubButtons,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    key: editNoteKey,
                    icon: Icon(Icons.edit_note, size: iconSize),
                    onPressed: onEditNotePressed,
                  ),
                  SizedBox(width: screenWidth * 0.1),
                ],
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          bottom: showSubButtons ? screenHeight * 0.12 : screenHeight * 0.1,
          left: showSubButtons ? -screenWidth : -screenWidth,
          right: showSubButtons ? 0 : screenWidth * 0.25,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: showSubButtons ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !showSubButtons,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: screenWidth * 0.1),
                  IconButton(
                    key: cameraAltKey,
                    icon: Icon(Icons.camera_alt, size: iconSize),
                    onPressed: onCameraPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
