import 'package:flutter/material.dart';
import '../widgets/main_progress_bar.dart';
import '../widgets/nutrition_card.dart';
import 'upload_img.dart';  


class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
              label: '729 Calories Left',
              value: 0.7,
            ),
            SizedBox(height: 16),
            MainProgressBar(
              color: Colors.blue,
              label: '2500 ml Water Left',
              value: 0.3,
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  NutritionCard(
                    label: 'Protein',
                    value: 0.8,
                    left: '15g Left',
                    icon: Icons.fitness_center,
                  ),
                  NutritionCard(
                    label: 'Carbs',
                    value: 0.6,
                    left: '62g Left',
                    icon: Icons.rice_bowl,
                  ),
                  NutritionCard(
                    label: 'Fats',
                    value: 0.4,
                    left: '3g Left',
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
                  IconButton( //跳到 upload page
                    icon: const Icon(Icons.note_alt, size: 40),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UploadPage()),
                      );
                    },
                  ),
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
