import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/image_picker.dart';
import '../../services/get_nutrition_from_photo.dart';
import '../../services/image_upload_service.dart';
import '../../model/message.dart';
import '../../model/nutrition_result.dart';
import '../../widgets/record_page/message_list.dart';
import '../../widgets/upload_bar.dart';
import '../../services/message_sent.dart';

class RecordPage extends StatefulWidget {
  final Function(NutritionResult)? onNutritionUpdate;
  const RecordPage({super.key, this.onNutritionUpdate});

  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  File? _localImage;
  NutritionResult? _nutritionResult;
  bool _loadingNutrition = false;
  bool _sendingMessage = false;
  final List<Message> _messages = [
    Message(
      text:
          'Hello. I can help you track your daily water and nutrition intake. You can tell me what you ate or drank today.',
      isUser: false,
    ),
  ];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 目標值
  final int _proteinTarget = 50;
  final int _carbsTarget = 250;
  final int _fatsTarget = 65;
  final int _caloriesTarget = 2000;

  Future<void> _pickImage() async {
    final file = await ImagePickerService.pickAndSaveImage();
    if (file != null) {
      setState(() {
        _localImage = file;
        _nutritionResult = null;
      });
      debugPrint('[DEBUG] Picked image: \\${file.path}');
      await _analyzeNutrition(file);
    }
  }

  Future<void> _analyzeNutrition(File file) async {
    setState(() {
      _loadingNutrition = true;
    });
    try {
      // Show analysis progress
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在分析營養成分...'),
          duration: Duration(seconds: 1),
        ),
      );
      debugPrint('正在分析營養成分...');

      // Get nutrition analysis
      final bytes = await file.readAsBytes();
      String base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
      final nutrition = await getNutritionFromPhoto(base64Image);

      // // Show upload progress
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('正在上傳圖片...'),
      //     duration: Duration(seconds: 1),
      //   ),
      // );
      // debugPrint('正在上傳圖片到database...');

      // // Upload image to Firebase Storage
      // String imageUrl = await ImageUploadService.uploadImage(file);

      // Save results to Firestore
      await ImageUploadService.saveNutritionResult(
        // imageUrl: imageUrl,
        base64Image: base64Image,
        comment: '',
        nutritionResult: nutrition,
      );

      debugPrint("Analyzed food and nutrition finished");
      setState(() {
        _nutritionResult = nutrition;
      });
    } catch (e, st) {
      debugPrint('[ERROR] Failed to get nutrition: \\${e.toString()}');
      debugPrint(st.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('獲取營養資訊失敗: \\${e.toString()}')));
    } finally {
      setState(() {
        _loadingNutrition = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sendingMessage) return;
    setState(() {
      _sendingMessage = true;
      _messages.add(Message(text: text, isUser: true));
    });
    _textController.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    try {
      final messageWithNutrition = await messageSent(
        text,
        _nutritionResult ??
            NutritionResult(
              foods: [],
              imageName: '',
              calories: 0,
              carbohydrate: 0,
              protein: 0,
              fat: 0,
            ),
        _messages
            .map((e) => e.isUser ? 'User: ${e.text}' : 'AI: ${e.text}')
            .toList()
            .sublist(0, _messages.length - 1),
      );
      setState(() {
        _messages.add(Message(text: messageWithNutrition.text, isUser: false));
        _nutritionResult = messageWithNutrition.nutrition;
      });

      // Update main page nutrition data
      if (widget.onNutritionUpdate != null) {
        widget.onNutritionUpdate!(_nutritionResult!);
      }
    } catch (e) {
      debugPrint('[ERROR] Failed to send message: \\${e.toString()}');
      setState(() {
        _messages.add(Message(text: '[AI 回應失敗]', isUser: false));
      });
    } finally {
      setState(() {
        _sendingMessage = false;
      });
    }
  }

  void _resetChatAndNutrition() {
    setState(() {
      _messages.clear();
      _messages.add(
        Message(
          text:
              'Hello. I can help you track your daily water and nutrition intake. You can tell me what you ate or drank today.',
          isUser: false,
        ),
      );
      _textController.clear();
      _nutritionResult = null;
      _localImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final protein = _nutritionResult?.protein ?? 0;
    final carbs = _nutritionResult?.carbohydrate ?? 0;
    final fats = _nutritionResult?.fat ?? 0;
    final calories = _nutritionResult?.calories ?? 0;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('上傳圖片'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新聊天室與營養資訊',
            onPressed: _resetChatAndNutrition,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 上半部
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 圖片與按鈕
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child:
                                _localImage != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _localImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: const Text('選擇圖片'),
                            onPressed: _loadingNutrition ? null : _pickImage,
                          ),
                          if (_loadingNutrition)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                    // 營養進度條
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            NutrientBar(
                              label: 'Protein',
                              value: (protein / _proteinTarget).clamp(0.0, 1.0),
                              leftText: '${protein}g',
                            ),
                            NutrientBar(
                              label: 'Carbs',
                              value: (carbs / _carbsTarget).clamp(0.0, 1.0),
                              leftText: '${carbs}g',
                            ),
                            NutrientBar(
                              label: 'Fats',
                              value: (fats / _fatsTarget).clamp(0.0, 1.0),
                              leftText: '${fats}g',
                            ),
                            NutrientBar(
                              label: 'Calories',
                              value: (calories / _caloriesTarget).clamp(
                                0.0,
                                1.0,
                              ),
                              leftText: '$calories cal',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 下半部：聊天區
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: MessageList(
                        messages: _messages,
                        scrollController: _scrollController,
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              decoration: const InputDecoration(
                                hintText: '輸入訊息...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon:
                                _sendingMessage
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.send,
                                      color: Colors.blueAccent,
                                    ),
                            onPressed: _sendingMessage ? null : _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
