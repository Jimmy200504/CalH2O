import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'goal_selection_page.dart'; // 下一頁可自行切換為 main_page.dart

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  String _height = '';
  String _weight = '';

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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/minion.png', height: 120),
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
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Enter your height'
                                        : null,
                            onSaved: (value) => _height = value!,
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
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Enter your weight'
                                        : null,
                            onSaved: (value) => _weight = value!,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();

                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString('height', _height);
                                  await prefs.setString('weight', _weight);

                                  // 👉 下一頁可以是 GoalSelectionPage 或 MainPage
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const GoalSelectionPage(),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Continue',
                                style: TextStyle(fontSize: 18),
                              ),
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
      hintText: hintText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
