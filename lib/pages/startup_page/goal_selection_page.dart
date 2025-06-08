import 'package:calh2o/pages/main_page.dart';
import 'package:calh2o/services/cloud_function_fetch/dailyNeeds.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoalSelectionPage extends StatefulWidget {
  const GoalSelectionPage({super.key});

  @override
  State<GoalSelectionPage> createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends State<GoalSelectionPage> {
  final List<String> _goals = [
    'Maintain weight',
    'Drink more water',
    'Lose weight',
    'Gain weight',
  ];
  String _selectedGoal = 'Maintain weight';

  Future<void> _saveGoalAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goal', _selectedGoal);

    final account = prefs.getString('account');

    if (account != null && account.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(account).set({
          'goal': _selectedGoal,
        }, SetOptions(merge: true));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('儲存goal失敗:$e')));
        return;
      }

      late String userId, gender, birthday, activityLevel;
      late int height, weight;
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(account)
                .get();
        final data = doc.data()!;
        userId = account;
        gender = data['gender'] as String;
        birthday = data['birthday'] as String;
        activityLevel = data['activityLevel'] as String;
        height = (data['height'] as num).toInt();
        weight = (data['weight'] as num).toInt();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('讀取 Profile 失敗: $e')));
        return;
      }
      debugPrint('Checking');
      DailyNeedsResult dailyNeeds;
      try {
        // debugPrint('Before try');
        // debugPrint(gender);
        // debugPrint(birthday);
        // debugPrint(height.toString());
        // debugPrint(weight.toString());
        // debugPrint(activityLevel);
        // debugPrint(_selectedGoal.toLowerCase());
        dailyNeeds = await getDailyNeeds(
          userId: userId,
          gender: gender,
          birthday: birthday,
          height: height,
          weight: weight,
          activityLevel: activityLevel,
          goal: _selectedGoal.toLowerCase(), // 確保符合 API 要求
        );
        debugPrint('After try');
      } catch (e) {
        debugPrint("Failed");
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('取得每日需求失敗: $e')));
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/minion.png', height: 120),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'What do you want to improve ?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Target',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedGoal,
                      items:
                          _goals.map((String goal) {
                            return DropdownMenuItem<String>(
                              value: goal,
                              child: Text(goal),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGoal = value!;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveGoalAndStart,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Let’s Start",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
