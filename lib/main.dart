import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/paywall_screen.dart';
import 'widgets/common.dart';
import 'services/subscription_service.dart';
import 'services/google_auth_service.dart';
import 'package:sweph/sweph.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Sweph.init(epheAssets: []);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  
  // Setup Google Play Billing bindings right away
  await SubscriptionService.initialize();

  // Load saved theme before starting the app
  await AppThemes.loadTheme();

  // Try to restore Google sign-in silently
  await GoogleAuthService.signInSilently();

  runApp(const BharatheeyamApp());
}

class BharatheeyamApp extends StatefulWidget {
  const BharatheeyamApp({super.key});

  @override
  State<BharatheeyamApp> createState() => _BharatheeyamAppState();
}

class _BharatheeyamAppState extends State<BharatheeyamApp> {
  @override
  void dispose() {
    SubscriptionService.dispose();
    super.dispose();
  }

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
            canvasColor: kCard,
            dialogBackgroundColor: kCard,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kPurple2,
              brightness: themeIndex == 1 ? Brightness.dark : Brightness.light,
              primary: kPurple2,
              secondary: kOrange,
              surface: kCard,
            ),
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: kText,
              displayColor: kText,
            ).copyWith(
              bodyMedium: TextStyle(color: kText, fontSize: 14),
              bodyLarge: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            listTileTheme: ListTileThemeData(
              textColor: kText,
              iconColor: kPurple2,
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: kPurple2,
              selectionColor: kPurple2.withOpacity(0.3),
              selectionHandleColor: kPurple2,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: kBg,
              headerBackgroundColor: kPurple2,
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                if (states.contains(WidgetState.disabled)) return kMuted;
                return kText;
              }),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return kText;
              }),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: kBg,
              dialBackgroundColor: kCard,
              dialTextColor: kText,
              hourMinuteTextColor: kText,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w800),
              iconTheme: IconThemeData(color: kText),
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
          home: SubscriptionService.hasAccess ? const HomeScreen() : const PaywallScreen(),
        );
      },
    );
  }
}
