import 'package:flutter/material.dart';
import '../../model/nutrition_result.dart';

/// 可輸入營養數值(熱量、蛋白質、碳水、脂肪)及備註的表單
class NutritionInputForm extends StatefulWidget {
  /// 初始值
  final NutritionResult initial;

  /// 初始備註
  final String? initialComment;

  /// 當任一營養數值改變時回傳最新 NutritionResult
  final ValueChanged<NutritionResult> onChanged;

  /// 當備註改變時回傳最新文字
  final ValueChanged<String> onCommentChanged;

  const NutritionInputForm({
    super.key,
    required this.initial,
    this.initialComment,
    required this.onChanged,
    required this.onCommentChanged,
  });

  @override
  _NutritionInputFormState createState() => _NutritionInputFormState();
}

class _NutritionInputFormState extends State<NutritionInputForm> {
  late NutritionResult _data;
  late TextEditingController _calController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatsController;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _data = widget.initial;
    _createControllers(_data);
  }

  @override
  void didUpdateWidget(NutritionInputForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != oldWidget.initial) {
      _data = widget.initial;
      // 同步更新輸入欄位文字
      _calController.text = _data.calories.toString();
      _proteinController.text = _data.protein.toString();
      _carbsController.text = _data.carbohydrate.toString();
      _fatsController.text = _data.fat.toString();
    }
    if (widget.initialComment != oldWidget.initialComment) {
      _commentController.text = widget.initialComment ?? '';
    }
  }

  void _createControllers(NutritionResult data) {
    _calController = TextEditingController(text: data.calories.toString());
    _proteinController = TextEditingController(text: data.protein.toString());
    _carbsController = TextEditingController(
      text: data.carbohydrate.toString(),
    );
    _fatsController = TextEditingController(text: data.fat.toString());
    _commentController = TextEditingController(
      text: widget.initialComment ?? '',
    );
  }

  @override
  void dispose() {
    _calController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _updateData({int? calories, int? protein, int? carbohydrate, int? fat}) {
    _data = NutritionResult(
      foods: _data.foods,
      imageName: _data.imageName,
      calories: calories ?? _data.calories,
      protein: protein ?? _data.protein,
      carbohydrate: carbohydrate ?? _data.carbohydrate,
      fat: fat ?? _data.fat,
    );
    widget.onChanged(_data);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Calories & Protein
          Expanded(
            child: Row(
              children: [
                _buildNumberField(
                  label: 'Calories',
                  icon: Icons.local_fire_department,
                  controller: _calController,
                  onChanged: (v) => _updateData(calories: int.tryParse(v) ?? 0),
                ),
                _buildNumberField(
                  label: 'Protein',
                  icon: Icons.fitness_center,
                  controller: _proteinController,
                  onChanged: (v) => _updateData(protein: int.tryParse(v) ?? 0),
                ),
              ],
            ),
          ),
          // 2. Carbs & Fats
          Expanded(
            child: Row(
              children: [
                _buildNumberField(
                  label: 'Carbs',
                  icon: Icons.grain,
                  controller: _carbsController,
                  onChanged:
                      (v) => _updateData(carbohydrate: int.tryParse(v) ?? 0),
                ),
                _buildNumberField(
                  label: 'Fats',
                  icon: Icons.water_drop,
                  controller: _fatsController,
                  onChanged: (v) => _updateData(fat: int.tryParse(v) ?? 0),
                ),
              ],
            ),
          ),
          // 3. Comment
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[100]!),
                ),
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: 'Comment',
                    labelStyle: TextStyle(color: Colors.orange[700]),
                    prefixIcon: Icon(Icons.comment, color: Colors.orange[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  minLines: 4,
                  textInputAction: TextInputAction.newline,
                  onChanged: widget.onCommentChanged,
                  maxLength: 100,
                  buildCounter: (
                    BuildContext context, {
                    required int currentLength,
                    required int? maxLength,
                    required bool isFocused,
                  }) {
                    return Text(
                      '$currentLength/$maxLength',
                      style: TextStyle(color: Colors.orange[700], fontSize: 12),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[100]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.orange[700]),
              prefixIcon: Icon(icon, color: Colors.orange[400], size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 15),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
