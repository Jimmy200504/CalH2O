import 'package:flutter/material.dart';
import 'nutrition_card.dart';

class NutritionSection extends StatelessWidget {
  final double proteinProgress;
  final double carbsProgress;
  final double fatsProgress;
  final int protein;
  final int carbs;
  final int fats;
  final int proteinTarget;
  final int carbsTarget;
  final int fatsTarget;
  final double cardSpacing;
  final double horizontalPadding;

  const NutritionSection({
    super.key,
    required this.proteinProgress,
    required this.carbsProgress,
    required this.fatsProgress,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatsTarget,
    required this.cardSpacing,
    required this.horizontalPadding,
  });

  String _getLabel(int current, int target, String unit) {
    if (current >= target) {
      return 'Completed';
    }
    return '${target - current}$unit Left';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: NutritionCard(
              label: 'Protein',
              value: proteinProgress,
              left: _getLabel(protein, proteinTarget, 'g'),
              icon: Icons.fitness_center,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
          Expanded(
            child: NutritionCard(
              label: 'Carbs',
              value: carbsProgress,
              left: _getLabel(carbs, carbsTarget, 'g'),
              icon: Icons.rice_bowl,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
          Expanded(
            child: NutritionCard(
              label: 'Fats',
              value: fatsProgress,
              left: _getLabel(fats, fatsTarget, 'g'),
              icon: Icons.emoji_food_beverage,
            ),
          ),
        ],
      ),
    );
  }
}
