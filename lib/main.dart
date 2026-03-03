import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/input_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BharatheeyamApp());
}

class BharatheeyamApp extends StatelessWidget {
  const BharatheeyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ಭಾರತೀಯಮ್',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(context),
      home: const InputScreen(),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFFFDF7),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4A00E0),
        brightness: Brightness.light,
        primary: const Color(0xFF4A00E0),
        secondary: const Color(0xFFDD6B20),
        surface: const Color(0xFFFFFFFF),
      ),
      textTheme: Theme.of(context).textTheme.copyWith(
        bodyMedium: TextStyle(
          color: const Color(0xFF2D3748),
          fontSize: 14,
        ),
        bodyLarge: TextStyle(
          color: const Color(0xFF2D3748),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: const Color(0xFF718096)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDD6B20),
          foregroundColor: Colors.white,
          textStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 4,
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: const Color(0xFF047857),
        unselectedLabelColor: const Color(0xFF718096),
        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorColor: const Color(0xFF047857),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }
}
