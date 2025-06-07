import 'package:flutter/material.dart';
import '../../services/camera_service.dart';

class CameraControlsWidget extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onTakePicture;
  final VoidCallback onSwitchCamera;
  final CameraService cameraService;

  const CameraControlsWidget({
    super.key,
    required this.onPickImage,
    required this.onTakePicture,
    required this.onSwitchCamera,
    required this.cameraService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: cameraService.isInitialized,
        builder: (context, isInitialized, child) {
          return ValueListenableBuilder<String?>(
            valueListenable: cameraService.error,
            builder: (context, error, child) {
              final bool hasError = error != null;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.photo_library,
                      color: Colors.black87,
                      size: 32,
                    ),
                    onPressed: onPickImage,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.black87,
                      size: 32,
                    ),
                    onPressed:
                        (isInitialized && !hasError) ? onTakePicture : null,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.black87,
                      size: 32,
                    ),
                    onPressed:
                        (isInitialized && !hasError) ? onSwitchCamera : null,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
