import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/get_nutrition_from_photo.dart';

import '../../model/message.dart';
import '../../model/nutrition_result.dart';
import '../../widgets/record_page/text_container.dart';
import '../../widgets/record_page/nutrition_input_form.dart';
import 'nutrition_chat_page.dart';
import '../../services/image_upload_service.dart';

class TextRecordPage_2 extends StatefulWidget {
  const TextRecordPage_2({super.key});

  @override
  _TextRecordPageState createState() => _TextRecordPageState();
}

class _TextRecordPageState extends State<TextRecordPage_2> {
  // 聊天狀態
  final List<Message> _messages = [
    Message(
      text:
          'Hello. I can help you track your daily water and nutrition intake. You can tell me what you ate or drank today.',
      isUser: false,
    ),
  ];

  final TextEditingController _textController = TextEditingController();
  int _selectedTagIndex = 0;

  // 營養狀態
  NutritionResult _nutritionResult = NutritionResult(
    foods: [],
    imageName: '',
    calories: 0,
    carbohydrate: 0,
    protein: 0,
    fat: 0,
  );

  // 紀錄備註
  String _comment = '';

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
    // 標籤資料：icon 與文字
    final List<Map<String, dynamic>> _mealTags = [
      {'icon': Icons.breakfast_dining, 'label': 'Breakfast'},
      {'icon': Icons.lunch_dining, 'label': 'Lunch'},
      {'icon': Icons.dinner_dining, 'label': 'Dinner'},
      {'icon': Icons.icecream, 'label': 'Dessert'},
      {'icon': Icons.local_cafe, 'label': 'Snack'},
      {'icon': FontAwesomeIcons.ghost, 'label': 'Midnight'},
    ];

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
          // 上半部(flex : 1):Tag 拖拉條，左右拖曳
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mealTags.length,
              itemBuilder: (context, idx) {
                final tag = _mealTags[idx];
                final isSelected = idx == _selectedTagIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTagIndex = idx;
                      // TODO: 你可以把選中的類別存到 state，以便後續用到
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      left: idx == 0 ? 16 : 8,
                      right: idx == _mealTags.length - 1 ? 16 : 0,
                    ),
                    width: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orangeAccent : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tag['icon'],
                          size: 32,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tag['label'],
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
          // 第二部(flex : 2):相機，[名字，時間]
          Expanded(
            flex: 2,
            child: NameDateRow(
              initialName: _nutritionResult.imageName,
              onNameChanged: (name) {
                setState(() {
                  _nutritionResult = _nutritionResult.copyWith(imageName: name);
                });
              },
              onImageCaptured: (base64Image) {
                // 只更新照片，不進行營養分析
                setState(() {
                  // 保持原有的營養數據不變
                });
              },
            ),
          ),
          // 第三部(flex : 4)：營養數據
          Expanded(
            flex: 4,
            child: NutritionInputForm(
              initial: _nutritionResult,
              onChanged: (newData) {
                setState(() {
                  _nutritionResult = newData;
                });
              },
              onCommentChanged: (text) {
                setState(() => _comment = text);
              },
            ),
          ),

          // 第四部(flex : 1)Space bar
          //左邊要可以save
          //右邊可能要有一個按鈕導入到與AI聊天的畫面
          Expanded(
            flex: 1,
            child: Row(
              children: [
                // 左：Save 按鈕
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                      onPressed: () async {
                        await ImageUploadService.saveNutritionResult(
                          // imageUrl: imageUrl,
                          base64Image: '',
                          comment: _comment,
                          nutritionResult: _nutritionResult,
                        );
                        // // 將 _nutritionResult 和 _comment 一起存進 Firestore
                        // await FirebaseFirestore.instance.collection('nutrition_records').add({
                        //   'timestamp': FieldValue.serverTimestamp(),
                        //   'calories': _nutritionResult.calories,
                        //   'protein': _nutritionResult.protein,
                        //   'carbohydrate': _nutritionResult.carbohydrate,
                        //   'fat': _nutritionResult.fat,
                        //   'comment': _comment,
                        //   'source': 'text_input',
                        // });
                        // 可顯示提示訊息或返回上一頁
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('資料已儲存')));
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ),
                // 右：進入 AI Chat 按鈕
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                      onPressed: () async {
                        final updated = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => NutritionChatPage(
                                  initial: _nutritionResult,
                                ),
                          ),
                        );
                        if (updated != null) {
                          setState(() {
                            _nutritionResult = updated;
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
}
