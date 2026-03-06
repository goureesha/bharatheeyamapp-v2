import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/strings.dart';
import 'input_screen.dart';
import 'match_making_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InputScreen(),
    const MatchMakingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF4A00E0), // kPurple2
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'ಕುಂಡಲಿ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'ಹೊಂದಾಣಿಕೆ',
          ),
        ],
      ),
    );
  }
}
