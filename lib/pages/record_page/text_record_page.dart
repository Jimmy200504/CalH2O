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
import '../../widgets/keyboard_aware_layout.dart';
import 'nutrition_chat_page.dart';
import '../../model/nutrition_draft.dart';

class TextRecordPage extends StatefulWidget {
  final Map<String, dynamic>? initialRecord;

  const TextRecordPage({super.key, this.initialRecord});

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

  // Saving state
  bool _isSaving = false;

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
    // 如果有初始記錄，使用它來初始化資料
    if (widget.initialRecord != null) {
      _nutritionResult = NutritionResult(
        foods: [],
        imageName: widget.initialRecord!['imageName'] ?? '',
        calories: widget.initialRecord!['calories'] ?? 0,
        carbohydrate: widget.initialRecord!['carbohydrate'] ?? 0,
        protein: widget.initialRecord!['protein'] ?? 0,
        fat: widget.initialRecord!['fat'] ?? 0,
      );
      _comment = widget.initialRecord!['comment'] ?? '';
      _timestamp = widget.initialRecord!['timestamp'] as Timestamp?;
      _tag = widget.initialRecord!['tag'] ?? 'Breakfast';
      _selectedTagIndex = _getMealTags()
          .indexWhere((m) => m['label'] == _tag)
          .clamp(0, _getMealTags().length - 1);
      _capturedImageBase64 = widget.initialRecord!['base64Image'];
    } else {
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
      resizeToAvoidBottomInset: false,
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
          if (_isSaving)
            const Padding(
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
          else
            IconButton(
              iconSize: 30,
              icon: const Icon(Icons.done),
              onPressed: () async {
                if (_nutritionResult.imageName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a name',
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                      backgroundColor: Colors.orange[100],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(8),
                    ),
                  );
                  return;
                }

                setState(() {
                  _isSaving = true;
                });

                // Hide keyboard before saving and popping to avoid render errors.
                final isKeyboardVisible =
                    MediaQuery.of(context).viewInsets.bottom > 0;
                if (isKeyboardVisible) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  await Future.delayed(const Duration(milliseconds: 300));
                }

                if (!mounted) return;

                try {
                  await ImageUploadService.saveNutritionResult(
                    base64Image: _capturedImageBase64 ?? '',
                    comment: _comment,
                    nutritionResult: _nutritionResult,
                    time: _timestamp,
                    tag: _tag,
                    documentId: widget.initialRecord?['documentId'],
                  );

                  // Clear the draft after successful save
                  context.read<NutritionDraft>().clearDraft();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Nutrition record saved',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                        backgroundColor: Colors.orange[100],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.all(8),
                      ),
                    );
                    Navigator.of(context).pop(true); // 返回 true 表示已更新
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error saving record: $e',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                        backgroundColor: Colors.orange[100],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.all(8),
                      ),
                    );
                    setState(() {
                      _isSaving = false;
                    });
                  }
                }
              },
            ),
        ],
      ),
      body: KeyboardAwareLayout(
        child: Column(
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
                        color: isSelected ? Color(0xFFFFB74D) : Colors.white,
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
              initialDateTime: _timestamp?.toDate(),
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

            // 第三部：營養數據
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              child: NutritionInputForm(
                initial: _nutritionResult,
                initialComment: _comment,
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

            // 第四部：聊天按鈕
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  backgroundColor: Color(0xFFFFB74D),
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
          ],
        ),
      ),
    );
  }
}
