import 'package:flutter/material.dart';
import '../model/message.dart';
import '../model/nutrition_result.dart';
import '../services/message_sent.dart';

/// 與 AI 聊天並更新營養數值的頁面
class NutritionChatPage extends StatefulWidget {
  /// 初始營養數值
  final NutritionResult initial;

  const NutritionChatPage({Key? key, required this.initial}) : super(key: key);

  @override
  _NutritionChatPageState createState() => _NutritionChatPageState();
}

class _NutritionChatPageState extends State<NutritionChatPage> {
  late NutritionResult _nutritionResult;
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _nutritionResult = widget.initial;
    _messages.add(Message(
      text: 'Hi there! Let\'s review your nutrition details. Ask me to update any value.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
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
      final result = await messageSent(
        text,
        _nutritionResult,
        _messages.map((e) => e.isUser ? 'User: \${e.text}' : 'AI: \${e.text}').toList(),
      );
      setState(() {
        _nutritionResult = result.nutrition;
        // AI 原始回覆
        _messages.add(Message(text: result.text, isUser: false));
        // 顯示更新後的營養資訊
        _messages.add(Message(
          text: 'Updated Nutrition:\n'
                'Calories: ${_nutritionResult.calories} cal, '
                'Protein: ${_nutritionResult.protein} g,\n'
                'Carbs: ${_nutritionResult.carbohydrate} g, '
                'Fats: ${_nutritionResult.fat} g',
          isUser: false,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(text: '[回應失敗，請重試]', isUser: false));
      });
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('AI Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _nutritionResult),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.blueAccent : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  icon: _sending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
