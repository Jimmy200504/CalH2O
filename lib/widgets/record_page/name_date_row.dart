import 'package:flutter/material.dart';
import 'dart:convert';
import '../../pages/record_page/image_record.dart';

/// 名字和日期時間列
/// 允許使用者輸入名字並回傳給父元件，
/// 也可選擇日期與時間
class NameDateRow extends StatefulWidget {
  /// 初始顯示的名字
  final String initialName;

  /// 當使用者輸入/提交名字時回傳
  final ValueChanged<String> onNameChanged;

  /// 當使用者選擇日期時回傳
  final ValueChanged<DateTime> onDateChanged;

  /// 當使用者選擇時間時回傳
  final ValueChanged<TimeOfDay> onTimeChanged;

  /// 當使用者拍照時回傳
  final ValueChanged<String>? onImageCaptured;

  /// 初始顯示的圖片
  final String? initialImage;

  /// 初始日期時間
  final DateTime? initialDateTime;

  const NameDateRow({
    super.key,
    required this.initialName,
    required this.onNameChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onImageCaptured,
    this.initialImage,
    this.initialDateTime,
  });

  @override
  _NameDateRowState createState() => _NameDateRowState();
}

class _NameDateRowState extends State<NameDateRow> {
  late TextEditingController _nameController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _capturedImageBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _capturedImageBase64 = widget.initialImage;

    // 設置初始時間
    if (widget.initialDateTime != null) {
      _selectedDate = widget.initialDateTime!;
      _selectedTime = TimeOfDay.fromDateTime(widget.initialDateTime!);
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void didUpdateWidget(covariant NameDateRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialName != oldWidget.initialName) {
      _nameController.text = widget.initialName;
    }
    if (widget.initialImage != oldWidget.initialImage) {
      _capturedImageBase64 = widget.initialImage;
    }
    if (widget.initialDateTime != oldWidget.initialDateTime &&
        widget.initialDateTime != null) {
      _selectedDate = widget.initialDateTime!;
      _selectedTime = TimeOfDay.fromDateTime(widget.initialDateTime!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData().copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xFFFFB74D),
            onPrimary: Colors.black,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          dialogBackgroundColor: Colors.white,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      widget.onDateChanged(picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData().copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xFFFFB74D),
            onPrimary: Colors.black,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          dialogBackgroundColor: Colors.white,
          timePickerTheme: TimePickerThemeData(
            dayPeriodColor: Color(0xFFFFB74D).withOpacity(0.5),     // AM/PM按鈕背景顏色
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      widget.onTimeChanged(picked);
    }
  }

  Future<void> _openCamera() async {
    if (widget.onImageCaptured == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImageRecordPage()),
    );

    if (result != null && result is String) {
      setState(() {
        _capturedImageBase64 = result;
      });
      widget.onImageCaptured!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左側圖片區塊，固定寬高
          SizedBox(
            width: 120,
            height: 120,
            child: GestureDetector(
              onTap: _openCamera,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    _capturedImageBase64 != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildImageFromBase64(_capturedImageBase64!),
                        )
                        : Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 70,
                            color: Colors.grey[700],
                          ),
                        ),
                    if (_capturedImageBase64 != null)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // 右側表單區塊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: const TextStyle(color: Colors.black), // label 文字改黑
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black), // 黑色邊框
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(color: Colors.black), // 文字改黑
                  textInputAction: TextInputAction.done,
                  onSubmitted: (text) {
                    widget.onNameChanged(text);
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: TextButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 20, color:Colors.black),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                            style: const TextStyle(color: Colors.black), // 文字黑
                          ),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TextButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 20, color: Colors.black),
                        label: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.black), // 文字黑
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(String base64String) {
    try {
      if (base64String.isEmpty) {
        return const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
        );
      }

      // Remove data URL prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains('base64,')) {
        cleanBase64 = base64String.split('base64,')[1];
      }

      // Check if the string is valid base64
      if (!cleanBase64.contains(RegExp(r'^[a-zA-Z0-9+/=]+$'))) {
        return const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 50),
        );
      }

      // Add padding if needed
      String paddedBase64 = cleanBase64;
      while (paddedBase64.length % 4 != 0) {
        paddedBase64 += '=';
      }

      // Try to decode the base64 string
      final bytes = base64Decode(paddedBase64);
      if (bytes.isEmpty) {
        return const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 50),
        );
      }

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 50),
          );
        },
      );
    } catch (e) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.red, size: 50),
      );
    }
  }
}
