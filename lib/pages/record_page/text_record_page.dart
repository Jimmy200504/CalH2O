import 'package:calh2o/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../model/message.dart';
import '../../model/nutrition_result.dart';
import '../../widgets/record_page/name_date_row.dart';
import '../../widgets/record_page/nutrition_input_form.dart';
import '../../widgets/record_page/generate_nutrition_button.dart';
import 'nutrition_chat_page.dart';
import '../../model/nutrition_draft.dart';

class TextRecordPage extends StatefulWidget {
  const TextRecordPage({super.key});

  @override
  _TextRecordPageState createState() => _TextRecordPageState();
}

class _TextRecordPageState extends State<TextRecordPage> {
  // 聊天狀態
  List<Message> _messages = [
    Message(
      text:
          'Hello. I can help you track your daily water and nutrition intake. You can tell me what you ate or drank today.',
      isUser: false,
    ),
  ];

  // 營養狀態
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
  String _tag = '';
  int _selectedTagIndex = 0;
  String? _capturedImageBase64;

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
      _selectedTagIndex = _getMealTags()
          .indexWhere((m) => m['label'] == _tag)
          .clamp(0, _getMealTags().length - 1);
      _capturedImageBase64 = draft.base64Image;
    }
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

  @override
  Widget build(BuildContext context) {
    // 監聽 Draft
    final draft = context.watch<NutritionDraft>();
    // 如果 Draft 更新且本地未同步，先同步一次
    if (draft.nutritionResult != null &&
        draft.nutritionResult != _nutritionResult) {
      _nutritionResult = draft.nutritionResult!;
      _comment = draft.comment;
      _timestamp = draft.timestamp;
      _tag = 'Breakfast';
      _selectedTagIndex = _getMealTags()
          .indexWhere((m) => m['label'] == _tag)
          .clamp(0, _getMealTags().length - 1);
      _capturedImageBase64 = draft.base64Image;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Record Nutrition'),
        actions: [
          IconButton(
            iconSize: 30,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
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
                _tag = 'Breakfast';
                _selectedTagIndex = 0;
                _capturedImageBase64 = null;
                _messages = [
                  Message(
                    text:
                        'Hello. I can help you track your daily water and nutrition intake. You can tell me what you ate or drank today.',
                    isUser: false,
                  ),
                ];
              });
              // Clear the draft
              context.read<NutritionDraft>().clearDraft();
            },
          ),
          IconButton(
            iconSize: 30,
            icon: const Icon(Icons.done),
            onPressed: () async {
              if (_nutritionResult.imageName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a name')),
                );
                return;
              }

              try {
                await ImageUploadService.saveNutritionResult(
                  base64Image: _capturedImageBase64 ?? '',
                  comment: _comment,
                  nutritionResult: _nutritionResult,
                  time: _timestamp,
                  tag: _tag,
                );

                // Clear the draft after successful save
                context.read<NutritionDraft>().clearDraft();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nutrition record saved')),
                  );
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving record: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 第二部(flex : 1)：標籤選擇
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
                  onTap:
                      () => setState(() {
                        _selectedTagIndex = idx;
                        _tag = tagData['label'] as String;
                        draft.tag = _tag;
                      }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      left: idx == 0 ? 16 : 8,
                      right: idx == _getMealTags().length - 1 ? 16 : 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orangeAccent : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: Colors.orangeAccent.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tagData['icon'] as IconData,
                          color: isSelected ? Colors.black87 : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tagData['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.black87 : Colors.grey,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // 第一部(flex : 1)：名稱與日期
          NameDateRow(
            initialName: _nutritionResult.imageName,
            initialImage: _capturedImageBase64,
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
              setState(() {
                _capturedImageBase64 = base64Image;
              });
            },
          ),

          const SizedBox(height: 10),
          // Generate Nutrition Button
          SizedBox(
            // 靠在畫面右邊
            height: 50,
            width: 500,
            child: Align(
              alignment: Alignment.centerRight,

              child: GenerateNutritionButton(
                nutritionResult: _nutritionResult,
                onNutritionGenerated: (newNutrition) {
                  setState(() {
                    _nutritionResult = newNutrition;
                  });
                },
              ),
            ),
          ),

          // 第三部(flex : 4)：營養數據
          Expanded(
            flex: 3,
            child: NutritionInputForm(
              initial: _nutritionResult,
              onChanged:
                  (newData) => setState(() {
                    _nutritionResult = newData;
                    draft.nutritionResult = newData;
                  }),
              onCommentChanged:
                  (text) => setState(() {
                    _comment = text;
                    draft.comment = text;
                  }),
            ),
          ),

          // 第四部(flex : 1)Space bar
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  backgroundColor: Colors.amberAccent,
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => NutritionChatPage(
                              initial: _nutritionResult,
                              initialMessages: _messages,
                            ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _nutritionResult = result['nutrition'];
                        _messages = result['messages'];
                      });
                    }
                  },
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
