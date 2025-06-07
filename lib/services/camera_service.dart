import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../main.dart' show cameras;

class CameraService {
  CameraController? _controller;
  late final ValueNotifier<bool> isInitialized;
  late final ValueNotifier<String?> error;
  bool _isRearCameraSelected = true;
  bool _isDisposed = false;
  bool _isInitializing = false;

  CameraService() {
    debugPrint("Creating new CameraService instance");
    isInitialized = ValueNotifier<bool>(false);
    error = ValueNotifier<String?>(null);
  }

  bool get isCameraInitialized => isInitialized.value;
  bool get isRearCameraSelected => _isRearCameraSelected;
  CameraController? get controller => _controller;

  void _setError(String? message) {
    if (!_isDisposed) {
      error.value = message;
    }
  }

  void _setInitialized(bool value) {
    if (!_isDisposed) {
      isInitialized.value = value;
    }
  }

  Future<void> initializeCamera() async {
    if (_isDisposed) {
      debugPrint("CameraService is disposed, cannot initialize");
      return;
    }
    if (_isInitializing) {
      debugPrint("Camera is already initializing");
      return;
    }

    _isInitializing = true;
    debugPrint("Starting camera initialization");

    try {
      if (cameras.isEmpty) {
        _setError('No cameras available on this device');
        _setInitialized(false);
        return;
      }

      final cameraIndex = _isRearCameraSelected ? 0 : 1;
      if (cameraIndex >= cameras.length) {
        _setError('Selected camera is not available');
        _setInitialized(false);
        return;
      }

      final camera = cameras[cameraIndex];
      debugPrint("Initializing camera: ${camera.name}");

      // Dispose existing controller if any
      if (_controller != null) {
        debugPrint("Disposing existing controller");
        await _controller!.dispose();
        _controller = null;
      }

      _controller = CameraController(
        camera,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (_isDisposed) {
        debugPrint("CameraService was disposed during initialization");
        await _controller?.dispose();
        return;
      }

      if (_controller!.value.isInitialized) {
        debugPrint("Camera initialized successfully");
        _setInitialized(true);
        _setError(null);
      } else {
        debugPrint("Camera failed to initialize");
        _setError('Failed to initialize camera');
        _setInitialized(false);
      }
    } on CameraException catch (e) {
      debugPrint("CameraException during initialization: ${e.description}");
      if (!_isDisposed) {
        switch (e.code) {
          case 'CameraAccessDenied':
            _setError('Camera access was denied');
            break;
          case 'CameraAccessDeniedWithoutPrompt':
            _setError('Camera access was denied without prompt');
            break;
          case 'CameraAccessRestricted':
            _setError('Camera access is restricted');
            break;
          default:
            _setError('Error initializing camera: ${e.description}');
        }
        _setInitialized(false);
      }
    } catch (e) {
      debugPrint("Error during camera initialization: $e");
      if (!_isDisposed) {
        _setError('Error initializing camera: $e');
        _setInitialized(false);
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<XFile?> takePicture() async {
    if (_isDisposed) {
      debugPrint("Cannot take picture: CameraService is disposed");
      return null;
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint("Cannot take picture: Camera not initialized");
      _setError('Camera not initialized');
      return null;
    }

    try {
      debugPrint("Taking picture...");
      final XFile photo = await _controller!.takePicture();
      debugPrint("Picture taken successfully");
      return photo;
    } on CameraException catch (e) {
      debugPrint("Error taking picture: ${e.description}");
      if (!_isDisposed) {
        _setError('Error taking picture: ${e.description}');
      }
      return null;
    }
  }

  Future<void> switchCamera() async {
    if (_isDisposed) {
      debugPrint("Cannot switch camera: CameraService is disposed");
      return;
    }
    if (cameras.length < 2) {
      debugPrint("Cannot switch camera: No other camera available");
      _setError('No other camera available');
      return;
    }

    debugPrint("Switching camera...");
    _isRearCameraSelected = !_isRearCameraSelected;
    _setInitialized(false);
    await _controller?.dispose();
    await initializeCamera();
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    if (_controller != null && _controller!.value.isInitialized) {
      debugPrint("Pausing camera preview");
      await _controller!.pausePreview();
      _setInitialized(false);
    }
  }

  Future<void> resume() async {
    if (_isDisposed) return;
    if (_controller != null && _controller!.value.isInitialized) {
      debugPrint("Resuming camera preview");
      await _controller!.resumePreview();
      _setInitialized(true);
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      debugPrint("CameraService already disposed");
      return;
    }

    debugPrint("Starting CameraService disposal");
    _isDisposed = true;

    // Clear any existing values
    isInitialized.value = false;
    error.value = null;

    // Dispose the controller first
    if (_controller != null) {
      debugPrint("Disposing camera controller");
      await _controller!.dispose();
      _controller = null;
    }

    // Finally dispose the ValueNotifiers
    debugPrint("Disposing ValueNotifiers");
    isInitialized.dispose();
    error.dispose();

    debugPrint("CameraService disposed");
  }
}
