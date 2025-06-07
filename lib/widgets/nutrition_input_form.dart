import 'package:flutter/material.dart';
import '../model/nutrition_result.dart';

/// 可輸入營養數值(熱量、蛋白質、碳水、脂肪)及備註的表單
class NutritionInputForm extends StatefulWidget {
  /// 初始值
  final NutritionResult initial;
  /// 當任一營養數值改變時回傳最新 NutritionResult
  final ValueChanged<NutritionResult> onChanged;
  /// 當備註改變時回傳最新文字
  final ValueChanged<String> onCommentChanged;

  const NutritionInputForm({
    Key? key,
    required this.initial,
    required this.onChanged,
    required this.onCommentChanged,
  }) : super(key: key);

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
      _calController.text     = _data.calories.toString();
      _proteinController.text = _data.protein.toString();
      _carbsController.text   = _data.carbohydrate.toString();
      _fatsController.text    = _data.fat.toString();
      // 如需重設 comment，可同時更新 _commentController.text
    }
  }

  void _createControllers(NutritionResult data) {
    _calController     = TextEditingController(text: data.calories.toString());
    _proteinController = TextEditingController(text: data.protein.toString());
    _carbsController   = TextEditingController(text: data.carbohydrate.toString());
    _fatsController    = TextEditingController(text: data.fat.toString());
    _commentController = TextEditingController();
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
      calories: calories    ?? _data.calories,
      protein:  protein     ?? _data.protein,
      carbohydrate: carbohydrate ?? _data.carbohydrate,
      fat:       fat        ?? _data.fat,
    );
    widget.onChanged(_data);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Calories & Protein
        Expanded(
          child: Row(
            children: [
              _buildNumberField(
                label: 'Calories',
                controller: _calController,
                onChanged: (v) => _updateData(calories: int.tryParse(v) ?? 0),
              ),
              _buildNumberField(
                label: 'Protein',
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
                controller: _carbsController,
                onChanged: (v) => _updateData(carbohydrate: int.tryParse(v) ?? 0),
              ),
              _buildNumberField(
                label: 'Fats',
                controller: _fatsController,
                onChanged: (v) => _updateData(fat: int.tryParse(v) ?? 0),
              ),
            ],
          ),
        ),
        // 3. Comment (單行、按 Enter 完成、不可換行，並顯示字數/上限)
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.done,
              onChanged: widget.onCommentChanged,
              onSubmitted: (_) {
                widget.onCommentChanged(_commentController.text);
                FocusScope.of(context).unfocus();
              },
              maxLength: 50,
              buildCounter: (
                BuildContext context, {
                required int currentLength,
                required int? maxLength,
                required bool isFocused,
              }) {
                return Text('$currentLength/$maxLength');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
