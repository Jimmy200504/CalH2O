import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/image_picker.dart';
import '../services/get_nutrition_from_photo.dart';
import '../model/message.dart';
import '../model/nutrition_result.dart';
import '../widgets/message_list.dart';
import '../widgets/upload_bar.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _localImage;
  NutritionResult? _nutritionResult;
  bool _loadingNutrition = false;
  final List<Message> _messages = [
    Message(text: '您好！我可以協助您追蹤每天的水分和營養攝取。', isUser: false),
    Message(text: '今天我已經喝了 1.5 公升的水，還有蛋白質 30g。', isUser: true),
    Message(text: '很棒！水分攝取量已達成 60%。建議再補充一些蔬菜中的纖維素。', isUser: false),
    Message(text: '好的，謝謝！', isUser: true),
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
      final bytes = await file.readAsBytes();
      String base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
      debugPrint("img_path : $base64Image");
      final nutrition = await getNutritionFromPhoto(base64Image);
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

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _messages.add(Message(text: '已收到：$text', isUser: false));
    });
    _textController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
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
                            icon: const Icon(
                              Icons.send,
                              color: Colors.blueAccent,
                            ),
                            onPressed: _sendMessage,
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
