import 'package:flutter/material.dart';

class NameDateRow extends StatefulWidget {
  const NameDateRow({Key? key}) : super(key: key);

  @override
  _NameDateRowState createState() => _NameDateRowState();
}

class _NameDateRowState extends State<NameDateRow> {
  // 1. 控制器：用來讀取 TextField 輸入文字
  final TextEditingController _nameController = TextEditingController();

  // 2. 分別記錄使用者選的日期／時間
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // 3. 跳出日期選擇器
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // 4. 跳出時間選擇器
  Future<void> _pickTime() async {
    TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child:Row(
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
                  onSubmitted: (text) {
                    // 使用者按 Enter 後，你可以在這裡取得 _nameController.text
                    // 例如：print('使用者輸入名字：$text');
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
