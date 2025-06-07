import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/message.dart';
import '../../model/nutrition_result.dart';
import '../../services/message_sent.dart';
import '../../widgets/message_list.dart';
import '../../widgets/upload_bar.dart';
import '../../services/image_upload_service.dart';

class TextRecordPage extends StatefulWidget {
  const TextRecordPage({super.key});

  @override
  _TextRecordPageState createState() => _TextRecordPageState();
}

class _TextRecordPageState extends State<TextRecordPage> {
  // 聊天狀態
  final List<Message> _messages = [
    Message(
      text:
          'Hello. I can help you track your daily water and nutrition intake. You can tell me what you ate or drank today.',
      isUser: false,
    ),
  ];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sendingMessage = false;

  // 營養狀態
  NutritionResult _nutritionResult = NutritionResult(
    foods: [],
    imageName: '',
    calories: 0,
    carbohydrate: 0,
    protein: 0,
    fat: 0,
  );

  // 目標值
  final int _proteinTarget = 50;
  final int _carbsTarget = 250;
  final int _fatsTarget = 65;
  final int _caloriesTarget = 2000;

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sendingMessage) return;

    setState(() {
      _sendingMessage = true;
      _messages.add(Message(text: text, isUser: true));
    });
    _textController.clear();
    // 滾到最底
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );

    try {
      final result = await messageSent(
        text,
        _nutritionResult,
        _messages
            .map((e) => e.isUser ? 'User: ${e.text}' : 'AI: ${e.text}')
            .toList()
            .sublist(0, _messages.length - 1),
      );

      // Save nutrition data using ImageUploadService
      await ImageUploadService.saveNutritionResult(
        base64Image: '', // Empty base64 string for text input
        comment: '',
        nutritionResult: result.nutrition,
      );

      setState(() {
        _messages.add(Message(text: result.text, isUser: false));
        _nutritionResult = result.nutrition;
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(text: '[AI 回應失敗]', isUser: false));
      });
    } finally {
      setState(() => _sendingMessage = false);
    }
  }

  void _resetAll() {
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
      _nutritionResult = NutritionResult(
        foods: [],
        imageName: '',
        calories: 0,
        carbohydrate: 0,
        protein: 0,
        fat: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 讀取當前營養數值
    final protein = _nutritionResult.protein;
    final carbs = _nutritionResult.carbohydrate;
    final fats = _nutritionResult.fat;
    final calories = _nutritionResult.calories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('文字輸入'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetAll),
        ],
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 上半部：聊天區
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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

          // 下半部：營養條
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                NutrientBar(
                  label: 'Protein',
                  value: (protein / _proteinTarget).clamp(0.0, 1.0),
                  leftText: '${protein}g / $_proteinTarget g',
                ),
                NutrientBar(
                  label: 'Carbs',
                  value: (carbs / _carbsTarget).clamp(0.0, 1.0),
                  leftText: '${carbs}g / $_carbsTarget g',
                ),
                NutrientBar(
                  label: 'Fats',
                  value: (fats / _fatsTarget).clamp(0.0, 1.0),
                  leftText: '${fats}g / $_fatsTarget g',
                ),
                NutrientBar(
                  label: 'Calories',
                  value: (calories / _caloriesTarget).clamp(0.0, 1.0),
                  leftText: '$calories cal / $_caloriesTarget cal',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
