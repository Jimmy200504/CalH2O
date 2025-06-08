import 'package:calh2o/pages/main_page.dart';
import 'package:calh2o/services/cloud_function_fetch/dailyNeeds.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // controllers
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // dropdown state
  String _gender = 'Men';
  String _activityLevel = 'sedentary';
  String _goal = 'maintain weight';

  // options
  final List<String> _genders = ['Men', 'Women', 'Other'];
  final List<String> _activities = [
    'sedentary',
    'light',
    'active',
    'very active',
    'extra active',
  ];
  final List<String> _goals = [
    'maintain weight',
    'drink more water',
    'lose weight',
    'gain weight',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(account)
              .get();
      if (!doc.exists) return;
      final data = doc.data()!;
      setState(() {
        _gender = data['gender'] as String? ?? _gender;
        _birthdayController.text = data['birthday'] as String? ?? '';
        _heightController.text = (data['height'] ?? 0).toString();
        _weightController.text = (data['weight'] ?? 0).toString();
        _activityLevel = data['activityLevel'] as String? ?? _activityLevel;
        _goal = (data['goal'] as String? ?? _goal).toLowerCase();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('讀取資料失敗：$e')));
    }
  }

  @override
  void dispose() {
    _birthdayController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    DateTime initial;
    try {
      initial = DateTime.parse(_birthdayController.text);
    } catch (_) {
      initial = now;
    }
    final dt = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (dt != null) {
      _birthdayController.text =
          '${dt.year.toString().padLeft(4, '0')}'
          '${dt.month.toString().padLeft(2, '0')}'
          '${dt.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString('account');
    if (account == null) return;

    // 1) update basic fields
    try {
      await FirebaseFirestore.instance.collection('users').doc(account).update({
        'gender': _gender,
        'birthday': _birthdayController.text,
        'height': int.tryParse(_heightController.text) ?? 0,
        'weight': int.tryParse(_weightController.text) ?? 0,
        'activityLevel': _activityLevel,
        'goal': _goal,
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新資料失敗：$e')));
      return;
    }

    // 2) fetch full profile
    late String gender, birthday, activityLevel;
    late int height, weight;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(account)
              .get();
      final data = doc.data()!;
      gender = data['gender'] as String;
      birthday = data['birthday'] as String;
      activityLevel = data['activityLevel'] as String;
      height = (data['height'] as num).toInt();
      weight = (data['weight'] as num).toInt();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('讀取 Profile 失敗：$e')));
      return;
    }

    // 3) call cloud function to get daily needs
    DailyNeedsResult dailyNeeds;
    try {
      dailyNeeds = await getDailyNeeds(
        userId: account,
        gender: gender,
        birthday: birthday,
        height: height,
        weight: weight,
        activityLevel: activityLevel,
        goal: _goal,
      );
      // you may want to store dailyNeeds in prefs or Firestore here
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('取得每日需求失敗：$e')));
      return;
    }

    // 4) navigate to MainPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', false);
                    await prefs.remove('account');
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (r) => false,
                    );
                  },
                  tooltip: 'Log out',
                ),
              ],
            ),

            _buildDropdown(
              label: 'Gender',
              value: _gender,
              items: _genders,
              onChanged: (v) => setState(() => _gender = v!),
            ),
            const SizedBox(height: 12),
            _buildDateField(
              label: 'Birthday (YYYYMMDD)',
              controller: _birthdayController,
              onIconPressed: _pickBirthday,
            ),
            const SizedBox(height: 12),
            _buildNumberField(
              label: 'Height (cm)',
              controller: _heightController,
            ),
            const SizedBox(height: 12),
            _buildNumberField(
              label: 'Weight (kg)',
              controller: _weightController,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Activity Level',
              value: _activityLevel,
              items: _activities,
              onChanged: (v) => setState(() => _activityLevel = v!),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Goal',
              value: _goal,
              items: _goals,
              onChanged: (v) => setState(() => _goal = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveUserData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save Changes', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items:
              items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onIconPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'YYYYMMDD',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: onIconPressed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }
}
