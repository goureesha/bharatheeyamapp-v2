import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/input_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BharatheeyamApp());
}

import 'widgets/common.dart';

class BharatheeyamApp extends StatelessWidget {
  const BharatheeyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppThemes.themeNotifier,
      builder: (context, themeIndex, child) {
        return MaterialApp(
          title: 'ಭಾರತೀಯಮ್',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: kBg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kPurple2,
              brightness: themeIndex == 1 ? Brightness.dark : Brightness.light,
              primary: kPurple2,
              secondary: kOrange,
              surface: kCard,
            ),
            textTheme: Theme.of(context).textTheme.copyWith(
              bodyMedium: TextStyle(color: kText, fontSize: 14),
              bodyLarge: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: kCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPurple2, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              labelStyle: TextStyle(color: kMuted),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
              ),
            ),
            tabBarTheme: TabBarTheme(
              labelColor: kGreen,
              unselectedLabelColor: kMuted,
              labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              indicatorColor: kGreen,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
          home: const InputScreen(),
        );
      },
    );
  }
}
