import 'package:flutter/material.dart';
import '../../model/message.dart';
import '../../model/nutrition_result.dart';
import '../../services/cloud_function_fetch/message_sent.dart';

/// 與 AI 聊天並更新營養數值的頁面
class NutritionChatPage extends StatefulWidget {
  /// 初始營養數值
  final NutritionResult initial;

  /// 初始聊天記錄
  final List<Message> initialMessages;

  const NutritionChatPage({
    super.key,
    required this.initial,
    required this.initialMessages,
  });

  @override
  _NutritionChatPageState createState() => _NutritionChatPageState();
}

class _NutritionChatPageState extends State<NutritionChatPage> {
  late NutritionResult _nutritionResult;
  late List<Message> _messages;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;
  bool _isNavigatingBack = false;

  @override
  void initState() {
    super.initState();
    _nutritionResult = widget.initial;
    _messages = List.from(widget.initialMessages);
    if (_messages.isEmpty) {
      _messages.add(
        Message(
          text:
              'Hi there! Let\'s review your nutrition details. Ask me to update any value.',
          isUser: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _navigateBack() async {
    if (_isNavigatingBack) return;
    setState(() => _isNavigatingBack = true);

    // Unfocus to hide keyboard and wait for it to animate off-screen
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.pop(context, {
        'nutrition': _nutritionResult,
        'messages': _messages,
      });
    }
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
        _messages
            .map((e) => e.isUser ? 'User: \${e.text}' : 'AI: \${e.text}')
            .toList()
            .sublist(0, _messages.length - 1),
      );
      setState(() {
        _nutritionResult = result.nutrition.copyWith(
          imageName: _nutritionResult.imageName,
        );
        // AI 原始回覆
        _messages.add(Message(text: result.text, isUser: false));
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
        leading:
            _isNavigatingBack
                ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black87,
                    ),
                  ),
                )
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                ),
      ),
      body: Column(
        children: [
          // 營養資訊輸入區
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monitor_heart,
                      color: Colors.orange[400],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Nutrition Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionInput(
                        label: 'Calories',
                        value: _nutritionResult.calories.toInt(),
                        icon: Icons.local_fire_department,
                        color: Colors.orange,
                        onChanged: (value) {
                          setState(() {
                            _nutritionResult = _nutritionResult.copyWith(
                              calories: int.tryParse(value) ?? 0,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNutritionInput(
                        label: 'Protein (g)',
                        value: _nutritionResult.protein.toInt(),
                        icon: Icons.fitness_center,
                        color: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            _nutritionResult = _nutritionResult.copyWith(
                              protein: int.tryParse(value) ?? 0,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionInput(
                        label: 'Carbs (g)',
                        value: _nutritionResult.carbohydrate.toInt(),
                        icon: Icons.grain,
                        color: Colors.green,
                        onChanged: (value) {
                          setState(() {
                            _nutritionResult = _nutritionResult.copyWith(
                              carbohydrate: int.tryParse(value) ?? 0,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNutritionInput(
                        label: 'Fats (g)',
                        value: _nutritionResult.fat.toInt(),
                        icon: Icons.water_drop,
                        color: Colors.amber,
                        onChanged: (value) {
                          setState(() {
                            _nutritionResult = _nutritionResult.copyWith(
                              fat: int.tryParse(value) ?? 0,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 聊天記錄
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment:
                        msg.isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!msg.isUser) ...[
                        CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: const Icon(
                            Icons.smart_toy,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                msg.isUser
                                    ? Colors.blue[400]
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
                              bottomRight: Radius.circular(msg.isUser ? 4 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isUser ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      if (msg.isUser) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.amber[100],
                          child: const Icon(Icons.person, color: Colors.amber),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // 輸入區域
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '輸入訊息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.orange[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange[400],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon:
                        _sending
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(Icons.send, color: Colors.white),
                    onPressed: _sending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionInput({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.orange[700]),
          prefixIcon: Icon(icon, color: Colors.orange[400], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          isDense: true,
        ),
        controller: TextEditingController(text: value.toString()),
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }
}
