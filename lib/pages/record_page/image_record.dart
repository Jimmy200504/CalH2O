import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/image_picker.dart';
import '../../services/camera_service.dart';
import '../../widgets/camera/camera_preview_widget.dart';
import '../../widgets/camera/camera_controls_widget.dart';

class ImageRecordPage extends StatefulWidget {
  const ImageRecordPage({super.key});

  @override
  _ImageRecordPageState createState() => _ImageRecordPageState();
}

class _ImageRecordPageState extends State<ImageRecordPage>
    with WidgetsBindingObserver {
  late CameraService _cameraService;
  bool _isProcessing = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraService = CameraService();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;
    await _cameraService.initializeCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_isDisposed) {
      return;
    }
    if (_cameraService.controller == null ||
        !_cameraService.controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      await _cameraService.pause();
    } else if (state == AppLifecycleState.resumed) {
      await _cameraService.resume();
    }
  }

  Future<void> _handleNavigation(String? result) async {
    if (!mounted || _isDisposed) {
      return;
    }

    try {
      setState(() => _isProcessing = true);
      await _cameraService.pause();
      if (mounted && !_isDisposed) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      debugPrint("Error during navigation: $e");
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _takePicture() async {
    if (_isProcessing || _isDisposed) {
      debugPrint("Cannot take picture: processing or disposed");
      return;
    }

    debugPrint("Taking picture");
    setState(() => _isProcessing = true);
    try {
      final photo = await _cameraService.takePicture();
      if (photo != null && mounted && !_isDisposed) {
        debugPrint("Picture taken, converting to base64");
        final bytes = await photo.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await _handleNavigation(base64Image);
      } else {
        // 如果拍照失敗，也要返回主畫面
        await _handleNavigation(null);
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
      await _handleNavigation(null);
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isProcessing || _isDisposed) {
      debugPrint("Cannot pick image: processing or disposed");
      return;
    }

    debugPrint("Picking image");
    setState(() => _isProcessing = true);
    try {
      final file = await ImagePickerService.pickAndSaveImage();
      if (file != null && mounted && !_isDisposed) {
        debugPrint("Image picked, converting to base64");
        final bytes = await file.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await _handleNavigation(base64Image);
      } else {
        // 如果選擇圖片失敗或取消，不需要返回主畫面，因為我們還在相機畫面
        debugPrint("Image picking cancelled or failed, staying on camera page");
        if (mounted && !_isDisposed) {
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      // 發生錯誤時也不需要返回主畫面
      if (mounted && !_isDisposed) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleNavigation(null);
      },
      child: Scaffold(
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
                            _isProcessing
                                ? null
                                : () => _handleNavigation(null),
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
      ),
    );
  }
}
