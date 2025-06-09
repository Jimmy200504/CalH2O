import 'package:calh2o/widgets/button_or_other_modifications/continue_button.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'goal_selection_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  int _height = 0;
  int _weight = 0;
  String _activityLevel = 'active'; // 預設值
  final List<String> _activityOptions = [
    'sedentary',
    'light',
    'active',
    'very active',
    'extra active',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(""),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white, // 👈 整個背景白色
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/animation/normal/frame_0.png', height: 120),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Fill up your personal information',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  color: Colors.white, // 👈 Card 背景白色
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Height',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: _inputDecoration('Height (cm)'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your height'
                                : null,
                            onSaved: (value) => _height = int.parse(value!),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Weight(kg)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: _inputDecoration('Weight (kg)'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your weight'
                                : null,
                            onSaved: (value) => _weight = int.parse(value!),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Activity Level',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _activityLevel,
                            decoration: _inputDecoration(''), // 👈 背景白色
                            dropdownColor: Colors.white, // 👈 Dropdown 也白色
                            items: _activityOptions.map((String level) {
                              return DropdownMenuItem<String>(
                                value: level,
                                child: Text(level),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _activityLevel = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ContinueButton(
                              text: 'Continue',
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();

                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setInt('height', _height);
                                  await prefs.setInt('weight', _weight);
                                  await prefs.setString(
                                    'activityLevel',
                                    _activityLevel,
                                  );
                                  final account = prefs.getString('account');

                                  if (account != null) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(account)
                                        .set({
                                      'height': _height,
                                      'weight': _weight,
                                      'activityLevel': _activityLevel,
                                    }, SetOptions(merge: true));
                                  }
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GoalSelectionPage(),
                                    ),
                                  );
                                }
                              },
                              width: double.infinity,
                              height: 56,
                            ),

                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white, // 👈 輸入框背景白色
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
