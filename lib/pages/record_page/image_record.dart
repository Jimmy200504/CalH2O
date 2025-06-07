import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/image_picker.dart';
import '../../services/camera_service.dart';
import '../../widgets/camera_preview_widget.dart';
import '../../widgets/camera_controls_widget.dart';

class ImageRecordPage extends StatefulWidget {
  const ImageRecordPage({super.key});

  @override
  _ImageRecordPageState createState() => _ImageRecordPageState();
}

class _ImageRecordPageState extends State<ImageRecordPage>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraService.controller == null ||
        !_cameraService.controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _takePicture() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final photo = await _cameraService.takePicture();
      if (photo != null && mounted) {
        Navigator.pop(context, photo.path);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final file = await ImagePickerService.pickAndSaveImage();
      if (file != null && mounted) {
        Navigator.pop(context, file.path);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // 頂部返回按鈕
              Padding(
                padding: const EdgeInsets.only(top: 40, left: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed:
                          _isProcessing ? null : () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
              // 相機預覽區域
              Expanded(
                child: CameraPreviewWidget(cameraService: _cameraService),
              ),
              // 底部控制按鈕
              CameraControlsWidget(
                onPickImage: _pickImage,
                onTakePicture: _takePicture,
                onSwitchCamera: _cameraService.switchCamera,
                cameraService: _cameraService,
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
