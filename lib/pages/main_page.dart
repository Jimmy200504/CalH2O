import 'package:flutter/material.dart';
import '../widgets/main_progress_bar.dart';
import '../widgets/nutrition_card.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double _caloriesProgress = 0.0;
  double _waterProgress = 0.0;

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

  void _incrementWater() {
    setState(() {
      if (_water >= _waterTarget) return;

      _water += 250;
      _waterProgress = (_water / _waterTarget).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.settings, size: 40),
                  Text(
                    'H2OCal',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Icon(Icons.info_outline, size: 40),
                ],
              ),
            ),
            MainProgressBar(
              color: Colors.orange,
              label: _getLabel(_calories, _caloriesTarget, ' kcal Calories'),
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
            Align(
              alignment: Alignment.centerRight,
              child: Container(
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
            ),
            SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Container(
                  width: 160,
                  height: 180,
                  color: Colors.amber,
                  child: Center(
                    child: Text(
                      'minion',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                  Icon(Icons.note_alt, size: 40),
                  Icon(Icons.access_time, size: 40),
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
    );
  }
}
