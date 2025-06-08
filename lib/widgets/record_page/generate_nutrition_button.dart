import 'package:flutter/material.dart';
import 'package:calh2o/services/cloud_function_fetch/message_sent.dart';
import 'package:calh2o/model/nutrition_result.dart';

class GenerateNutritionButton extends StatefulWidget {
  final NutritionResult nutritionResult;
  final Function(NutritionResult) onNutritionGenerated;

  const GenerateNutritionButton({
    super.key,
    required this.nutritionResult,
    required this.onNutritionGenerated,
  });

  @override
  State<GenerateNutritionButton> createState() =>
      _GenerateNutritionButtonState();
}

class _GenerateNutritionButtonState extends State<GenerateNutritionButton> {
  bool _isGeneratingNutrition = false;

  Future<void> _generateNutrition() async {
    if (widget.nutritionResult.imageName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先輸入Name')));
      return;
    }

    setState(() => _isGeneratingNutrition = true);
    try {
      final result = await messageSent(
        widget.nutritionResult.imageName,
        NutritionResult(
          foods: [],
          imageName: '',
          calories: 0,
          carbohydrate: 0,
          protein: 0,
          fat: 0,
        ),
        [],
      );

      widget.onNutritionGenerated(
        widget.nutritionResult.copyWith(
          calories: result.nutrition.calories,
          carbohydrate: result.nutrition.carbohydrate,
          protein: result.nutrition.protein,
          fat: result.nutrition.fat,
        ),
      );
    } finally {
      setState(() => _isGeneratingNutrition = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: _isGeneratingNutrition ? null : _generateNutrition,
          icon:
              _isGeneratingNutrition
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.orange[900]!,
                      ),
                    ),
                  )
                  : const Icon(Icons.auto_awesome),
          label: Text(
            _isGeneratingNutrition ? 'Generating...' : 'Generate Nutrition',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[100],
            foregroundColor: Colors.orange[900],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
      ),
    );
  }
}
