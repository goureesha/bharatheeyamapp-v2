import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/paywall_screen.dart';
import 'widgets/common.dart';
import 'services/subscription_service.dart';
import 'services/google_auth_service.dart';
import 'services/install_checker.dart';
import 'services/device_binding_service.dart';
import 'services/festival_cache_service.dart';
import 'services/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sweph/sweph.dart';
import 'core/ephemeris.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Run the 3 critical startup tasks in PARALLEL (not sequentially)
  // These are needed before the first frame renders:
  //   1. Ephemeris engine (for calculations)
  //   2. Subscription status (to decide paywall vs home)
  //   3. Theme (to render with correct colors)
  await Future.wait([
    _initEphemeris(),
    SubscriptionService.initialize(),
    AppThemes.loadTheme(),
    ChartStyle.loadStyle(),
    AppLocale.loadLang(),
    LocationService.init(),
  ]);

  // Show the app immediately — don't block on network calls
  runApp(const BharatheeyamApp());

  // Defer non-critical checks to AFTER the first frame renders
  // This makes the app feel instant while these run in the background
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _deferredInit();
  });
}

/// Ephemeris init with error handling (non-blocking on failure)
Future<void> _initEphemeris() async {
  try {
    await Ephemeris.initSweph();
  } catch (e) {
    debugPrint("Failed to initialize Sweph: $e");
  }
}

/// Non-critical startup tasks that run AFTER the app is visible
Future<void> _deferredInit() async {
  // These don't affect initial screen rendering
  await InstallChecker.check();
  await GoogleAuthService.signInSilently();

  if (GoogleAuthService.isSignedIn) {
    DeviceBindingService.checkBinding(); // fire-and-forget, don't await
  }

  // Pre-load festival events lazily (non-blocking)
  FestivalCacheService.loadYear(DateTime.now().year);
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
          key: ValueKey('theme_$themeIndex'), // Forces full rebuild on theme change
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
          home: !InstallChecker.isFromPlayStore
            ? const _SideloadBlockedScreen()
            : !DeviceBindingService.isDeviceBound
              ? const _DeviceMismatchScreen()
              : SubscriptionService.hasAccess ? const HomeScreen() : const PaywallScreen(),
        );
      },
    );
  }
}

// ============================================================
// BLOCKED SCREENS
// ============================================================

/// Shown when app is sideloaded (not from Play Store)
class _SideloadBlockedScreen extends StatelessWidget {
  const _SideloadBlockedScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.block, size: 80, color: Colors.red[400]),
          const SizedBox(height: 24),
          Text('ಅನಧಿಕೃತ ಅನುಸ್ಥಾಪನೆ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 8),
          Text('Unauthorized Installation', style: TextStyle(fontSize: 16, color: kMuted)),
          const SizedBox(height: 24),
          Text('ಈ ಅಪ್ಲಿಕೇಶನ್ Google Play Store ನಿಂದ ಮಾತ್ರ ಡೌನ್‌ಲೋಡ್ ಮಾಡಬೇಕು.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: kText, height: 1.5)),
          const SizedBox(height: 8),
          Text('This app can only be used when downloaded from the Google Play Store.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kMuted, height: 1.5)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.shop, color: Colors.white),
            label: const Text('Play Store ಗೆ ಹೋಗಿ'),
            style: ElevatedButton.styleFrom(backgroundColor: kPurple2, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            onPressed: () {
              // Open Play Store listing
              // url_launcher can be used here if needed
            },
          ),
        ]),
      )),
    );
  }
}

/// Shown when user's Gmail is bound to a different device
class _DeviceMismatchScreen extends StatefulWidget {
  const _DeviceMismatchScreen();
  @override
  State<_DeviceMismatchScreen> createState() => _DeviceMismatchScreenState();
}

class _DeviceMismatchScreenState extends State<_DeviceMismatchScreen> {
  bool _migrating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.devices, size: 80, color: Colors.orange[400]),
          const SizedBox(height: 24),
          Text('ಬೇರೆ ಸಾಧನದಲ್ಲಿ ಸಕ್ರಿಯ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 8),
          Text('Active on Another Device', style: TextStyle(fontSize: 16, color: kMuted)),
          const SizedBox(height: 24),
          Text('ನಿಮ್ಮ Google ಖಾತೆ (${GoogleAuthService.userEmail ?? ''}) ಬೇರೆ ಸಾಧನದಲ್ಲಿ ಸಕ್ರಿಯವಾಗಿದೆ.\nಈ ಸಾಧನಕ್ಕೆ ಬದಲಾಯಿಸಲು "ಸಾಧನ ಬದಲಾಯಿಸಿ" ಒತ್ತಿ.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kText, height: 1.6)),
          const SizedBox(height: 32),
          if (_migrating)
            CircularProgressIndicator(color: kPurple2)
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              label: const Text('ಸಾಧನ ಬದಲಾಯಿಸಿ / Migrate Device'),
              style: ElevatedButton.styleFrom(backgroundColor: kPurple2, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              onPressed: () async {
                setState(() => _migrating = true);
                final ok = await DeviceBindingService.migrateDevice();
                if (ok && mounted) {
                  // Restart the app to the home screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => SubscriptionService.hasAccess ? const HomeScreen() : const PaywallScreen()),
                    (_) => false,
                  );
                } else {
                  setState(() => _migrating = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ Google ಸೈನ್ ಇನ್ ಮಾಡಿ.'), backgroundColor: Colors.red));
                  }
                }
              },
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              await GoogleAuthService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => SubscriptionService.hasAccess ? const HomeScreen() : const PaywallScreen()),
                  (_) => false,
                );
              }
            },
            child: Text('ಬೇರೆ ಖಾತೆಯಿಂದ ಲಾಗಿನ್ / Sign in with different account',
              style: TextStyle(color: kMuted, fontSize: 13)),
          ),
        ]),
      )),
    );
  }
}
