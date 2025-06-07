import 'package:flutter/material.dart';

/// 名字和日期時間列
/// 允許使用者輸入名字並回傳給父元件，
/// 也可選擇日期與時間
class NameDateRow extends StatefulWidget {
  /// 初始顯示的名字
  final String initialName;
  /// 當使用者輸入/提交名字時回傳
  final ValueChanged<String> onNameChanged;

  const NameDateRow({
    Key? key,
    required this.initialName,
    required this.onNameChanged,
  }) : super(key: key);

  @override
  _NameDateRowState createState() => _NameDateRowState();
}

class _NameDateRowState extends State<NameDateRow> {
  late TextEditingController _nameController;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    // 用父元件傳入的 initialName 初始化
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void didUpdateWidget(covariant NameDateRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當父元件給的 initialName 改變時，同步更新 text
    if (widget.initialName != oldWidget.initialName) {
      _nameController.text = widget.initialName;
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
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左：相機 icon
          Expanded(
            flex: 1,
            child: Center(
              child: Icon(
                Icons.camera_alt,
                size: 50,
                color: Colors.grey[700],
              ),
            ),
          ),
          // 右：名字 + 日期 + 時間
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 名字輸入框
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '名字',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (text) {
                    widget.onNameChanged(text);
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 8),
                // 日期＋時間按鈕
                Row(
                  children: [
                    Flexible(
                      child: TextButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 20),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                          ),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TextButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 20),
                        label: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:'
                          '${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
}
