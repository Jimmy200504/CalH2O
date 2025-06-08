import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../model/message.dart';
import '../../model/nutrition_result.dart';
import '../../widgets/record_page/text_container.dart';
import '../../widgets/record_page/nutrition_input_form.dart';
import 'nutrition_chat_page.dart';
import '../../main.dart'; // for rootScaffoldMessengerKey
import '../../model/nutrition_draft.dart';

class TextRecordPage extends StatefulWidget {
  const TextRecordPage({super.key});

  @override
  _TextRecordPageState createState() => _TextRecordPageState();
}

class _TextRecordPageState extends State<TextRecordPage> {
  // 本地顯示狀態
  final TextEditingController _textController = TextEditingController();
  NutritionResult _nutritionResult = NutritionResult(
    foods: [],
    imageName: '',
    calories: 0,
    carbohydrate: 0,
    protein: 0,
    fat: 0,
  );
  String _comment = '';
  Timestamp? _timestamp;
  String _tag = 'Breakfast';
  int _selectedTagIndex = 0;

  @override
  void initState() {
    super.initState();
    // 從 Provider 讀取 Draft
    final draft = context.read<NutritionDraft>();
    if (draft.nutritionResult != null) {
      _nutritionResult = draft.nutritionResult!;
      _comment = draft.comment;
      _timestamp = draft.timestamp;
      _tag = 'Breakfast';
    }
  }

  void _resetAll() {
    setState(() {
      _textController.clear();
      _nutritionResult = NutritionResult(
        foods: [],
        imageName: '',
        calories: 0,
        carbohydrate: 0,
        protein: 0,
        fat: 0,
      );
      _comment = '';
      _timestamp = null;
      _tag = '';
      _selectedTagIndex = 0;
      // 同步清除 Draft
      context.read<NutritionDraft>().clearDraft();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 監聽 Draft
    final draft = context.watch<NutritionDraft>();
    // 如果 Draft 更新且本地未同步，先同步一次
    if (draft.nutritionResult != null && draft.nutritionResult != _nutritionResult) {
      _nutritionResult = draft.nutritionResult!;
      _comment = draft.comment;
      _timestamp = draft.timestamp;
      _tag = 'Breakfast';
      _selectedTagIndex =
          _getMealTags().indexWhere((m) => m['label'] == _tag).clamp(0, _getMealTags().length - 1);
    }

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
          // 標籤列
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _getMealTags().length,
              itemBuilder: (context, idx) {
                final tagData = _getMealTags()[idx];
                final isSelected = idx == _selectedTagIndex;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedTagIndex = idx;
                    _tag = tagData['label'] as String;
                    draft.tag = _tag;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      left: idx == 0 ? 16 : 8,
                      right: idx == _getMealTags().length - 1 ? 16 : 0,
                    ),
                    width: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orangeAccent : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.orangeAccent.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tagData['icon'],
                          size: 32,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tagData['label'],
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 名稱 + 日期 + 圖片...
          Expanded(
            flex: 2,
            child: NameDateRow(
              initialName: _nutritionResult.imageName,
              onNameChanged: (name) {
                setState(() {
                  _nutritionResult = _nutritionResult.copyWith(imageName: name);
                  draft.nutritionResult = _nutritionResult;
                });
              },
              onDateChanged: (d) {
                setState(() {
                  final prev = _timestamp?.toDate() ?? DateTime.now();
                  _timestamp = Timestamp.fromDate(
                    DateTime(d.year, d.month, d.day, prev.hour, prev.minute),
                  );
                  draft.timestamp = _timestamp;
                });
              },
              onTimeChanged: (t) {
                setState(() {
                  final prev = _timestamp?.toDate() ?? DateTime.now();
                  _timestamp = Timestamp.fromDate(
                    DateTime(prev.year, prev.month, prev.day, t.hour, t.minute),
                  );
                  draft.timestamp = _timestamp;
                });
              },
              onImageCaptured: (base64Image) {
                // 可以傳回圖片，但不做分析
              },
            ),
          ),
          // 營養輸入表單
          Expanded(
            flex: 4,
            child: NutritionInputForm(
              initial: _nutritionResult,
              onChanged: (newData) => setState(() {
                _nutritionResult = newData;
                draft.nutritionResult = newData;
              }),
              onCommentChanged: (text) => setState(() {
                _comment = text;
                draft.comment = text;
              }),
            ),
          ),
          // Save & Chat Buttons
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      onPressed: () async {
                        await draft.save();
                        rootScaffoldMessengerKey.currentState!
                            .showSnackBar(const SnackBar(content: Text('資料已儲存')));
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      onPressed: () async {
                        final updated = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NutritionChatPage(initial: _nutritionResult),
                          ),
                        );
                        if (updated != null) {
                          setState(() {
                            _nutritionResult = updated;
                            draft.nutritionResult = updated;
                          });
                        }
                      },
                      child: const Text('Chat with AI'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMealTags() {
    return [
      {'icon': Icons.breakfast_dining, 'label': 'Breakfast'},
      {'icon': Icons.lunch_dining, 'label': 'Lunch'},
      {'icon': Icons.dinner_dining, 'label': 'Dinner'},
      {'icon': Icons.icecream, 'label': 'Dessert'},
      {'icon': Icons.local_cafe, 'label': 'Snack'},
      {'icon': FontAwesomeIcons.ghost, 'label': 'Midnight'},
    ];
  }
}
