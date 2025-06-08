import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/main_page/main_progress_bar.dart';
import '../widgets/main_page/nutrition_card.dart';
import '../widgets/main_page/loading_overlay.dart';
import '../widgets/animation.dart';
import '../services/cloud_function_fetch/get_nutrition_from_photo.dart';
import '../services/image_upload_service.dart';
import '../model/nutrition_draft.dart';
import '../main.dart';
import '../pages/setting_page.dart';
import '../pages/history_page.dart';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double _waterProgress = 0.0;
  bool _isProcessing = false;

  // Nutrition variables
  int _water = 0;
  int _protein = 0;
  int _carbs = 0;
  int _fats = 0;

  // Nutrition targets
  int _waterTarget = 2500; // 2500ml water target
  int _proteinTarget = 50; // 50g protein target
  int _carbsTarget = 250; // 250g carbs target
  int _fatsTarget = 65; // 65g fats target

  bool _showSubButtons = false;

  final GlobalKey _comboKey = GlobalKey();
  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();
  final GlobalKey _editNoteKey = GlobalKey();
  final GlobalKey _cameraAltKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    // 1. 拿到使用者 ID
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    // 2. 直接從 Firestore 抓 doc 一次
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(account).get();
    final data = doc.data();
    if (data == null) return;

    // 3. 讀欄位並存進變數
    final int waterTarget = (data['water'] as num).toInt();
    final int proteinTarget = (data['proteinTarget'] as num).toInt();
    final int carbsTarget = (data['carbsTarget'] as num).toInt();
    final int fatsTarget = (data['fatsTarget'] as num).toInt();

    // 4. 把它們存到 State 裡
    setState(() {
      _waterTarget = waterTarget;
      _proteinTarget = proteinTarget;
      _carbsTarget = carbsTarget;
      _fatsTarget = fatsTarget;
    });
  }

  String _getLabel(int current, int target, String unit) {
    if (current >= target) {
      return 'Completed';
    }
    return '${target - current}$unit Left';
  }

  void _incrementWater() {
    setState(() {
      if (_water >= _waterTarget) return;

      _water += 250;
      _waterProgress = (_water / _waterTarget).clamp(0.0, 1.0);
    });
  }

  void _toggleSubButtons() {
    setState(() {
      _showSubButtons = !_showSubButtons;
    });
  }

  Future<void> _handleImageResult(String? result) async {
    if (result == null) return;
    debugPrint("Get the base64 string in main page.");
    setState(() => _isProcessing = true);
    try {
      // 分析營養成分
      final nutritionResult = await getNutritionFromPhoto(result);

      // 暫存到 Provider
      final draft = context.read<NutritionDraft>();
      draft.setDraft(image: result, result: nutritionResult);

      // 3. 全域通知 (SnackBar + 前往文字頁按鈕)
      rootScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: const Text('營養分析完成，請到文字頁確認並儲存'),
          action: SnackBarAction(
            label: '前往文字頁',
            onPressed: () {
              Navigator.of(context).pushNamed('/text');
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error processing image: $e');
      // 可以在這裡添加錯誤提示
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  List<TargetFocus> targets = [];

  void _initTargets() {
    targets = [
      TargetFocus(
        identify: "Combo",
        keyTarget: _comboKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controllerTarget) {
              Future.delayed(const Duration(seconds: 1), () {
                controllerTarget.next();
              });
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(height: 50),
                  Text(
                    "This shows your combo streak of daily records!",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Add",
        keyTarget: _addKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controllerTarget) {
              Future.delayed(const Duration(seconds: 1), () {
                controllerTarget.next();
              });
              return const Text(
                "Add a new record",
                style: TextStyle(color: Colors.white, fontSize: 20),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "EditNote",
        keyTarget: _editNoteKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controllerTarget) {
              Future.delayed(const Duration(seconds: 1), () {
                controllerTarget.next();
              });
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(height: 8),
                  Text(
                    "Add notes to your entry",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Camera",
        keyTarget: _cameraAltKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controllerTarget) {
              Future.delayed(const Duration(seconds: 1), () {
                controllerTarget.next();
              });
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(height: 8),
                  Text(
                    "Use the camera to scan food",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "History",
        keyTarget: _historyKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controllerTarget) {
              Future.delayed(const Duration(seconds: 1), () {
                controllerTarget.skip();
              });
              return const Text(
                "Check the history",
                style: TextStyle(color: Colors.white, fontSize: 20),
              );
            },
          ),
        ],
      ),
    ];
  }

  void _showTutorial() {
    setState(() {
      _showSubButtons = true;
    });
    _initTargets();
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "SKIP",
      onFinish: () => print("Tutorial finished"),
    ).show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    // 獲取螢幕尺寸
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final screenHeight = size.height - padding.top - padding.bottom;
    final screenWidth = size.width;

    // 計算相對尺寸
    final iconSize = screenWidth * 0.1; // 圖標大小
    final titleSize = screenWidth * 0.08; // 標題大小
    final cardSpacing = screenHeight * 0.02; // 卡片間距
    final horizontalPadding = screenWidth * 0.05; // 水平內邊距

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: screenHeight * 0.015,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.settings, size: iconSize),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingPage(),
                            ),
                          );
                        },
                      ),
                      Text(
                        'CalH2O',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.info, size: iconSize),
                        onPressed: _showTutorial,
                      ),
                    ],
                  ),
                ),
                MainProgressBar(
                  color: Colors.blue,
                  label: _getLabel(_water, _waterTarget, ' ml Water'),
                  value: _waterProgress,
                  onIncrement: _incrementWater,
                  additionalInfo: 'Total Water: $_water ml',
                ),
                SizedBox(height: cardSpacing),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: NutritionCard(
                          label: 'Protein',
                          value: _protein / _proteinTarget,
                          left: _getLabel(_protein, _proteinTarget, 'g'),
                          icon: Icons.fitness_center,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: NutritionCard(
                          label: 'Carbs',
                          value: _carbs / _carbsTarget,
                          left: _getLabel(_carbs, _carbsTarget, 'g'),
                          icon: Icons.rice_bowl,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: NutritionCard(
                          label: 'Fats',
                          value: _fats / _fatsTarget,
                          left: _getLabel(_fats, _fatsTarget, 'g'),
                          icon: Icons.emoji_food_beverage,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isProcessing)
                      Padding(
                        padding: EdgeInsets.only(right: screenWidth * 0.02),
                        child: const LoadingOverlay(),
                      ),
                    Container(
                      key: _comboKey,
                      margin: EdgeInsets.only(
                        top: screenHeight * 0.02,
                        right: screenWidth * 0.06,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'combo',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FrameAnimationWidget(
                          size: screenWidth * 0.5, // 動畫大小為螢幕寬度的一半
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.01,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        key: _addKey,
                        icon: Icon(
                          Icons.lunch_dining,
                          size: iconSize,
                          color: _showSubButtons ? Colors.grey : Colors.black,
                        ),
                        onPressed: _toggleSubButtons,
                      ),
                      IconButton(
                        key: _historyKey,
                        icon: Icon(Icons.access_time, size: iconSize),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                  child: Text(
                    'Sip smart, live strong.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // 子按鈕
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            bottom: _showSubButtons ? screenHeight * 0.2 : 100,
            left: _showSubButtons ? 0 : -100,
            right: _showSubButtons ? screenWidth * 0.25 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showSubButtons ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_showSubButtons,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      key: _editNoteKey,
                      icon: Icon(Icons.edit_note, size: iconSize),
                      onPressed: () {
                        setState(() => _showSubButtons = false);
                        Navigator.pushNamed(context, '/text');
                      },
                    ),
                    SizedBox(width: screenWidth * 0.1),
                  ],
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            bottom: _showSubButtons ? screenHeight * 0.12 : screenHeight * 0.1,
            left: _showSubButtons ? -screenWidth : -screenWidth,
            right: _showSubButtons ? 0 : screenWidth * 0.25,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showSubButtons ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_showSubButtons,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(width: screenWidth * 0.1),
                    IconButton(
                      key: _cameraAltKey,
                      icon: Icon(Icons.camera_alt, size: iconSize),
                      onPressed: () async {
                        setState(() => _showSubButtons = false);
                        final result = await Navigator.pushNamed(
                          context,
                          '/image',
                        );
                        if (result != null) {
                          await _handleImageResult(result as String);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
