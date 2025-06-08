import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/main_page/main_progress_bar.dart';
import '../widgets/main_page/nutrition_card.dart';
import '../widgets/main_page/loading_overlay.dart';
import '../widgets/animation.dart';
import '../services/cloud_function_fetch/get_nutrition_from_photo.dart';
import '../services/image_upload_service.dart';

import '../pages/setting_page.dart';
import '../pages/history_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double _caloriesProgress = 0.0;
  double _waterProgress = 0.0;
  bool _isProcessing = false;

  // Nutrition variables
  int _water = 0;
  int _calories = 0;
  int _protein = 0;
  int _carbs = 0;
  int _fats = 0;

  // Nutrition targets
  final int _waterTarget = 2500; // 2500ml water target
  final int _caloriesTarget = 2000; // 2000kcal calories target
  final int _proteinTarget = 50; // 50g protein target
  final int _carbsTarget = 250; // 250g carbs target
  final int _fatsTarget = 65; // 65g fats target

  bool _showSubButtons = false;

  @override
  void initState() {
    super.initState();
    _setupNutritionListener();
  }

  void _setupNutritionListener() {
    // Get today's start and end timestamps
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Listen to Firestore for real-time updates
    FirebaseFirestore.instance
        .collection('nutrition_records')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
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
            setState(() {
              _calories += (doc['calories'] as num).toInt();
              _protein += (doc['protein'] as num).toInt();
              _carbs += (doc['carbohydrate'] as num).toInt();
              _fats += (doc['fat'] as num).toInt();
            });
          }

          // Update progress values
          setState(() {
            _caloriesProgress = (_calories / _caloriesTarget).clamp(0.0, 1.0);
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

      // 上傳到資料庫
      await ImageUploadService.saveNutritionResult(
        base64Image: result,
        comment: '',
        nutritionResult: nutritionResult,
      );
    } catch (e) {
      debugPrint('Error processing image: $e');
      // 可以在這裡添加錯誤提示
    } finally {
      setState(() => _isProcessing = false);
    }
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
                      Icon(Icons.info, size: 40),
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
                        //跳到 upload page
                        icon: Icon(
                          Icons.lunch_dining,
                          size: 40,
                          color: _showSubButtons ? Colors.grey : Colors.black,
                        ),
                        onPressed: _toggleSubButtons,
                      ),
                      IconButton(
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
