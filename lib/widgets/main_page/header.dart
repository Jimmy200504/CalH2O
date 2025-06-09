import 'package:flutter/material.dart';
import '../../pages/setting_page.dart';

class MainHeader extends StatelessWidget {
  final double iconSize;
  final double titleSize;
  final VoidCallback onTutorialPressed;

  const MainHeader({
    super.key,
    required this.iconSize,
    required this.titleSize,
    required this.onTutorialPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: MediaQuery.of(context).size.height * 0.015,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.settings, size: iconSize),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingPage()));
            },
          ),
          Text(
            'CalH2O',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          IconButton(
            icon: Icon(Icons.info, size: iconSize),
            onPressed: onTutorialPressed,
          ),
        ],
      ),
    );
  }
}
