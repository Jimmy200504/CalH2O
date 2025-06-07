import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../main.dart' show cameras;

class CameraService {
  CameraController? _controller;
  final ValueNotifier<bool> isInitialized = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  bool _isRearCameraSelected = true;

  bool get isCameraInitialized => isInitialized.value;
  bool get isRearCameraSelected => _isRearCameraSelected;
  CameraController? get controller => _controller;

  Future<void> initializeCamera() async {
    try {
      if (cameras.isEmpty) {
        error.value = 'No cameras available on this device';
        isInitialized.value = false;
        return;
      }

      // 確保相機索引有效
      final cameraIndex = _isRearCameraSelected ? 0 : 1;
      if (cameraIndex >= cameras.length) {
        error.value = 'Selected camera is not available';
        isInitialized.value = false;
        return;
      }

      final camera = cameras[cameraIndex];
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (_controller!.value.isInitialized) {
        isInitialized.value = true;
        error.value = null;
      } else {
        error.value = 'Failed to initialize camera';
        isInitialized.value = false;
      }
    } catch (e) {
      error.value = 'Error initializing camera: $e';
      isInitialized.value = false;
    }
  }

  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      error.value = 'Camera not initialized';
      return null;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      return photo;
    } catch (e) {
      error.value = 'Error taking picture: $e';
      return null;
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) {
      error.value = 'No other camera available';
      return;
    }

    _isRearCameraSelected = !_isRearCameraSelected;
    isInitialized.value = false;
    await _controller?.dispose();
    await initializeCamera();
  }

  void dispose() {
    _controller?.dispose();
    isInitialized.dispose();
    error.dispose();
  }
}
