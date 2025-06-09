import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/main_page/main_progress_bar.dart';
import '../widgets/main_page/nutrition_card.dart';
import '../widgets/main_page/loading_overlay.dart';
import '../widgets/animation.dart';
import '../services/cloud_function_fetch/get_nutrition_from_photo.dart';
import '../model/nutrition_draft.dart';
import '../main.dart';
import '../services/water_upload_service.dart';
import '../pages/setting_page.dart';
import '../widgets/main_page/speech_bubble.dart';
import '../widgets/main_page/tutorial_manager.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double _waterProgress = 0.0;
  bool _isProcessing = false;

  int _calories = 0;
  int _protein = 0;
  int _carbs = 0;
  int _fats = 0;
  int _initialWater = 0;
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

  bool _showSubButtons = false;

  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();
  final GlobalKey _comboKey = GlobalKey();
  final GlobalKey _editNoteKey = GlobalKey();
  final GlobalKey _cameraAltKey = GlobalKey();
  final GlobalKey _petKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 一次性抓 OR 初始化
    WaterUploadService.fetchOrInitTodayWater().then((ml) {
      setState(() {
        _water = ml;
        _initialWater = ml;
        _waterProgress = (_water / _waterTarget).clamp(0.0, 1.0);
      });
    });
    _loadTargets();
    _setupNutritionListener();
  }

  Future<void> _loadTargets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final account = prefs.getString('account');
      if (account == null) return;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(account)
              .get();
      final data = doc.data();
      if (data == null) return;

      // 把目標撈回來
      final newCalTarget = _safeGetInt(data, 'calories', 2000);
      final newWaterTarget = _safeGetInt(data, 'water', 2000);
      final newProTarget = _safeGetInt(data, 'proteinTarget', 50);
      final newCarbTarget = _safeGetInt(data, 'carbsTarget', 250);
      final newFatTarget = _safeGetInt(data, 'fatsTarget', 65);

      setState(() {
        _caloriesTarget = newCalTarget;
        _waterTarget = newWaterTarget;
        _proteinTarget = newProTarget;
        _carbsTarget = newCarbTarget;
        _fatsTarget = newFatTarget;

        // **重算進度**：載入完新目標後，馬上把目前數值除以目標，算出 ProgressBar
        _caloriesProgress = (_calories / _caloriesTarget).clamp(0.0, 1.0);
        _waterProgress = (_water / _waterTarget).clamp(0.0, 1.0);
        _proteinProgress = (_protein / _proteinTarget).clamp(0.0, 1.0);
        _carbsProgress = (_carbs / _carbsTarget).clamp(0.0, 1.0);
        _fatsProgress = (_fats / _fatsTarget).clamp(0.0, 1.0);
      });
    } catch (e) {
      print('Error loading targets: $e');
      // 可保留原本的預設值，也要重算一次進度
      setState(() {
        _caloriesTarget = 2000;
        _waterTarget = 2000;
        _proteinTarget = 50;
        _carbsTarget = 250;
        _fatsTarget = 65;
        _caloriesProgress = (_calories / _caloriesTarget).clamp(0.0, 1.0);
        _waterProgress = (_water / _waterTarget).clamp(0.0, 1.0);
        _proteinProgress = (_protein / _proteinTarget).clamp(0.0, 1.0);
        _carbsProgress = (_carbs / _carbsTarget).clamp(0.0, 1.0);
        _fatsProgress = (_fats / _fatsTarget).clamp(0.0, 1.0);
      });
    }
  }

  int _safeGetInt(Map<String, dynamic> data, String key, int defaultValue) {
    try {
      final value = data[key];
      if (value == null) return defaultValue;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  void _setupNutritionListener() async {
    // Get user account
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    //     final doc =
    //         await FirebaseFirestore.instance.collection('users').doc(account).get();
    //     final data = doc.data();
    //     if (data == null) return;

    //     final int caloriesTarget = (data['calories'] as num).toInt();
    //     final int waterTarget = (data['water'] as num).toInt();
    //     final int proteinTarget = (data['proteinTarget'] as num).toInt();
    //     final int carbsTarget = (data['carbsTarget'] as num).toInt();
    //     final int fatsTarget = (data['fatsTarget'] as num).toInt();

    //     setState(() {
    //       _caloriesTarget = caloriesTarget;
    //       _waterTarget = waterTarget;
    //       _proteinTarget = proteinTarget;
    //       _carbsTarget = carbsTarget;
    //       _fatsTarget = fatsTarget;
    //     });
    //   }

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

  /// 計算並上傳這段期間的水量差
  void _uploadDelta() {
    final delta = _water - _initialWater;
    if (delta != 0) {
      WaterUploadService.saveTodayWaterIntake(delta);
      _initialWater = _water; // 重置基準
    }
  }

  /// 導航到命名路由 [routeName]，回來後自動呼 _uploadDelta
  Future<void> _navigateNamed(String routeName) async {
    _uploadDelta();
    await Navigator.of(context).pushNamed(routeName);
    _uploadDelta();
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

  Future<void> _incrementWater() async {
    const intake = 250;
    setState(() {
      _water += intake;
      _waterProgress = (_water / _waterTarget).clamp(0.0, 1.0);
    });
  }

  Future<void> _decrementWater() async {
    const intake = 250;
    setState(() {
      _water = max(0, _water - intake);
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
              _navigateNamed('/text');
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

  void _showTutorial() {
    TutorialManager.showTutorial(
      context: context,
      addKey: _addKey,
      historyKey: _historyKey,
      comboKey: _comboKey,
      editNoteKey: _editNoteKey,
      cameraAltKey: _cameraAltKey,
      petKey: _petKey,
      onTutorialStart: () => setState(() => _showSubButtons = true),
      onTutorialFinish: () => setState(() => _showSubButtons = false),
    );
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
                        icon: const Icon(Icons.info, size: 40),
                        onPressed: _showTutorial,
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
                        icon: Icon(Icons.settings, size: 40),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                MainProgressBar(
                  color: Colors.orange,
                  label:
                      'Calories $_calories kcal (${_getLabel(_calories, _caloriesTarget, ' kcal')})',
                  value: _caloriesProgress,
                  onIncrement: _incrementCalories,
                ),
                WaveProgressBar(
                  label:
                      'Water $_water ml (${_getLabel(_water, _waterTarget, ' ml')})',
                  value: _waterProgress,
                  onIncrement: _incrementWater,
                  onDecrement: _decrementWater,
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

                SizedBox(height: 8),
                Flexible(
                  fit: FlexFit.loose,
                  child: Stack(
                    children: [
                      // 先放彈幕
                      const SpeechBubble(),

                      // 再放動畫
                      Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          key: _petKey,
                          child: const FrameAnimationWidget(size: 200),
                        ),
                      ),
                    ],
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
                          _navigateNamed('/history');
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
