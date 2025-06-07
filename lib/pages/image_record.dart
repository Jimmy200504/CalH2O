import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../services/image_picker.dart';
import '../services/get_nutrition_from_photo.dart';
import '../services/image_upload_service.dart';
import '../model/nutrition_result.dart';
import '../widgets/upload_bar.dart';

class ImageRecordPage extends StatefulWidget {
  const ImageRecordPage({super.key});

  @override
  _ImageRecordPageState createState() => _ImageRecordPageState();
}

class _ImageRecordPageState extends State<ImageRecordPage> {
  File? _localImage;
  NutritionResult? _nutritionResult;
  bool _loadingNutrition = false;

  // 目標值（記得定義好）
  final int _proteinTarget = 50;
  final int _carbsTarget   = 250;
  final int _fatsTarget    = 65;
  final int _caloriesTarget = 2000;

  Future<void> _pickImage() async {
    final file = await ImagePickerService.pickAndSaveImage();
    if (file != null) {
      setState(() {
        _localImage = file;
        _nutritionResult = null;
      });
      await _analyzeNutrition(file);
    }
  }

  Future<void> _analyzeNutrition(File file) async {
    setState(() => _loadingNutrition = true);
    try {
      final bytes = await file.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final nutrition = await getNutritionFromPhoto(base64Image);
      // Save results to Firestore
      await ImageUploadService.saveNutritionResult(
        // imageUrl: imageUrl,
        time: null,
        base64Image: base64Image,
        comment: '',
        nutritionResult: nutrition,
      );
      setState(() => _nutritionResult = nutrition);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('獲取營養資訊失敗：${e.toString()}')),
      );
    } finally {
      setState(() => _loadingNutrition = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final protein  = _nutritionResult?.protein     ?? 0;
    final carbs    = _nutritionResult?.carbohydrate ?? 0;
    final fats     = _nutritionResult?.fat         ?? 0;
    final calories = _nutritionResult?.calories    ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('圖片上傳'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
      padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 6:3:1
            // 上半部：圖片／按鈕區域，佔 flex: 2
            Flexible(
              flex: 6,
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.8,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _localImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_localImage!, fit: BoxFit.cover),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image, size: 64, color: Colors.grey),
                                ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('選擇圖片'),
                        onPressed: _loadingNutrition ? null : _pickImage,
                      ),
                    ),
                  ),
                  if (_loadingNutrition)
                    Flexible(
                      flex: 1,
                      child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),

            // 下半部：營養進度，佔 flex: 3
            Flexible(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    NutrientBar(
                      label: 'Protein',
                      value: (protein / _proteinTarget).clamp(0.0, 1.0),
                      leftText: '${protein}g / $_proteinTarget g',
                    ),
                    NutrientBar(
                      label: 'Carbs',
                      value: (carbs / _carbsTarget).clamp(0.0, 1.0),
                      leftText: '${carbs}g / $_carbsTarget g',
                    ),
                    NutrientBar(
                      label: 'Fats',
                      value: (fats / _fatsTarget).clamp(0.0, 1.0),
                      leftText: '${fats}g / $_fatsTarget g',
                    ),
                    NutrientBar(
                      label: 'Calories',
                      value: (calories / _caloriesTarget).clamp(0.0, 1.0),
                      leftText: '$calories cal / $_caloriesTarget cal',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
