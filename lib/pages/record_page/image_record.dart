import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
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

  Future<String?> _compressAndEncodeImage(List<int> bytes) async {
    try {
      // Decode the image
      final image = img.decodeImage(Uint8List.fromList(bytes));
      if (image == null) return null;

      // Resize the image to 400x400
      final resizedImage = img.copyResize(
        image,
        width: 400,
        height: 400,
        interpolation: img.Interpolation.linear,
      );

      // Encode the resized image to JPEG
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);

      // Convert to base64
      debugPrint("Compressed and encoded image to base64 for upload finished");
      return 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
    } catch (e) {
      debugPrint("Error compressing image: $e");
      return null;
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
      // Pause camera before processing image
      await _cameraService.pause();

      final photo = await _cameraService.takePicture();
      if (photo != null && mounted && !_isDisposed) {
        debugPrint("Picture taken, compressing and converting to base64");
        final bytes = await photo.readAsBytes();
        final base64Image = await _compressAndEncodeImage(bytes);
        await _handleNavigation(base64Image);
      } else {
        // 如果拍照失敗，恢復相機預覽並返回主畫面
        if (mounted && !_isDisposed) {
          await _cameraService.resume();
        }
        await _handleNavigation(null);
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
      // 發生錯誤時恢復相機預覽
      if (mounted && !_isDisposed) {
        await _cameraService.resume();
      }
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
      // Pause camera before processing image
      await _cameraService.pause();

      final file = await ImagePickerService.pickAndSaveImage();
      if (file != null && mounted && !_isDisposed) {
        debugPrint("Image picked, compressing and converting to base64");
        final bytes = await file.readAsBytes();
        final base64Image = await _compressAndEncodeImage(bytes);
        await _handleNavigation(base64Image);
      } else {
        // 如果選擇圖片失敗或取消，恢復相機預覽
        debugPrint("Image picking cancelled or failed, staying on camera page");
        if (mounted && !_isDisposed) {
          await _cameraService.resume();
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      // 發生錯誤時恢復相機預覽
      if (mounted && !_isDisposed) {
        await _cameraService.resume();
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
