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
  int _calories = 0;
  int _protein = 0;
  int _carbs = 0;
  int _fats = 0;
  int _water = 0;

  int _caloriesTarget = 2000;
  int _proteinTarget = 50;
  int _carbsTarget = 250;
  int _fatsTarget = 65;
  int _waterTarget = 2000;

  double _caloriesProgress = 0.0;
  double _proteinProgress = 0.0;
  double _carbsProgress = 0.0;
  double _fatsProgress = 0.0;
  double _waterProgress = 0.0;

  bool _showSubButtons = false;
  bool _isProcessing = false;

  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();
  final GlobalKey _comboKey = GlobalKey();
  final GlobalKey _editNoteKey = GlobalKey();
  final GlobalKey _cameraAltKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadTargets();
    _setupNutritionListener();
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
    final int caloriesTarget = (data['calories'] as num).toInt();
    final int waterTarget = (data['water'] as num).toInt();
    final int proteinTarget = (data['proteinTarget'] as num).toInt();
    final int carbsTarget = (data['carbsTarget'] as num).toInt();
    final int fatsTarget = (data['fatsTarget'] as num).toInt();

    // 4. 把它們存到 State 裡
    setState(() {
      _caloriesTarget = caloriesTarget;
      _waterTarget = waterTarget;
      _proteinTarget = proteinTarget;
      _carbsTarget = carbsTarget;
      _fatsTarget = fatsTarget;
    });
  }

  void _setupNutritionListener() async {
    // Get user account
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    // Get today's start and end timestamps
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Listen to Firestore for real-time updates
    FirebaseFirestore.instance
        .collection('users')
        .doc(account)
        .collection('nutrition_records')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .listen((snapshot) {
          // Reset values
          setState(() {
            _calories = 0;
            _protein = 0;
            _carbs = 0;
            _fats = 0;
          });

          // Sum up all nutrition values
          for (var doc in snapshot.docs) {
            final data = doc.data();
            setState(() {
              _calories += (data['calories'] as num).toInt();
              _protein += (data['protein'] as num).toInt();
              _carbs += (data['carbohydrate'] as num).toInt();
              _fats += (data['fat'] as num).toInt();
            });
          }

          // Update progress values
          setState(() {
            _caloriesProgress = (_calories / _caloriesTarget).clamp(0.0, 1.0);
            _proteinProgress = (_protein / _proteinTarget).clamp(0.0, 1.0);
            _carbsProgress = (_carbs / _carbsTarget).clamp(0.0, 1.0);
            _fatsProgress = (_fats / _fatsTarget).clamp(0.0, 1.0);
          });
        });
  }

  String _getLabel(int current, int target, String unit) {
    if (current >= target) {
      return 'Completed';
    }
    return '${target - current}$unit Left';
  }

  void _incrementCalories() {
    setState(() {
      if (_calories >= _caloriesTarget) return;

      _calories += 200;
      _caloriesProgress = (_calories / _caloriesTarget).clamp(0.0, 1.0);

      // Update nutrition values proportionally
      _protein += 10; // 10g protein per increment
      _carbs += 25; // 25g carbs per increment
      _fats += 7; // 7g fats per increment
    });
  }

  // void _updateNutrition(NutritionResult nutrition) {
  //   setState(() {
  //     _calories += nutrition.calories.round();
  //     _protein += nutrition.protein.round();
  //     _carbs += nutrition.carbohydrate.round();
  //     _fats += nutrition.fat.round();

  //     // Update progress values
  //     _caloriesProgress = (_calories / _caloriesTarget).clamp(0.0, 1.0);
  //   });
  // }

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.settings, size: 40),
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
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info, size: 40),
                        onPressed: _showTutorial,
                      ),
                    ],
                  ),
                ),
                MainProgressBar(
                  color: Colors.orange,
                  label: _getLabel(
                    _calories,
                    _caloriesTarget,
                    ' kcal Calories',
                  ),
                  value: _caloriesProgress,
                  onIncrement: _incrementCalories,
                  additionalInfo: 'Total Calories: $_calories kcal',
                ),
                MainProgressBar(
                  color: Colors.blue,
                  label: _getLabel(_water, _waterTarget, ' ml Water'),
                  value: _waterProgress,
                  onIncrement: _incrementWater,
                  additionalInfo: 'Total Water: $_water ml',
                ),
                // SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      NutritionCard(
                        label: 'Protein',
                        value: _protein / _proteinTarget,
                        left: _getLabel(_protein, _proteinTarget, 'g'),
                        icon: Icons.fitness_center,
                      ),
                      NutritionCard(
                        label: 'Carbs',
                        value: _carbs / _carbsTarget,
                        left: _getLabel(_carbs, _carbsTarget, 'g'),
                        icon: Icons.rice_bowl,
                      ),
                      NutritionCard(
                        label: 'Fats',
                        value: _fats / _fatsTarget,
                        left: _getLabel(_fats, _fatsTarget, 'g'),
                        icon: Icons.emoji_food_beverage,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isProcessing)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: LoadingOverlay(),
                      ),
                    Container(
                      key: _comboKey,
                      margin: const EdgeInsets.only(top: 16, right: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        //
                        'combo',
                        style: TextStyle(fontSize: 20, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [const FrameAnimationWidget(size: 200)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        key: _addKey,
                        icon: Icon(
                          Icons.lunch_dining,
                          size: 40,
                          color: _showSubButtons ? Colors.grey : Colors.black,
                        ),
                        onPressed: _toggleSubButtons,
                      ),
                      IconButton(
                        key: _historyKey,
                        icon: const Icon(Icons.access_time, size: 40),
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
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Sip smart, live strong.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // 子按鈕
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            bottom: _showSubButtons ? 150 : 100,
            left: _showSubButtons ? 0 : -100,
            right: _showSubButtons ? 100 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showSubButtons ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_showSubButtons,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 文字輸入按鈕（上方）
                    IconButton(
                      key: _editNoteKey,
                      icon: const Icon(Icons.edit_note, size: 40),
                      onPressed: () {
                        Navigator.pushNamed(context, '/text');
                        _toggleSubButtons();
                      },
                    ),
                    const SizedBox(width: 40), // 佔位，保持對齊
                  ],
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            bottom: _showSubButtons ? 90 : 80,
            left: _showSubButtons ? -400 : -400,
            right: _showSubButtons ? 0 : 100,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showSubButtons ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_showSubButtons,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 40), // 佔位，保持對齊
                    // 圖片輸入按鈕（右方）
                    IconButton(
                      key: _cameraAltKey,
                      icon: const Icon(Icons.camera_alt, size: 40),
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/image',
                        );
                        if (result != null) {
                          await _handleImageResult(result as String);
                        }
                        _toggleSubButtons();
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
