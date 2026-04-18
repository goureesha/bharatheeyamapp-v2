import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/paywall_screen.dart';
import 'widgets/common.dart';
import 'services/subscription_service.dart';
import 'services/trusted_time_service.dart';
import 'services/google_auth_service.dart';
import 'services/firebase_service.dart';

import 'services/festival_cache_service.dart';
import 'services/location_service.dart';
import 'services/tester_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sweph/sweph.dart';
import 'core/ephemeris.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // NTP must init BEFORE SubscriptionService so trusted time is available
  await TrustedTimeService.init();

  // Firebase must init BEFORE auth/binding/tester because sign-in triggers
  // TesterService.checkTesterStatus() which uses FirebaseFirestore.instance
  await FirebaseService.init();

  // Run ALL critical startup tasks in PARALLEL (not sequentially)
  await Future.wait([
    _initEphemeris(),
    SubscriptionService.initialize(),
    AppThemes.loadTheme(),
    ChartStyle.loadStyle(),
    AppLocale.loadLang(),
    LocationService.init(),
    TesterService.init(),
    _initAuth(),
  ]);

  // Now show the app
  runApp(const BharatheeyamApp());

  // Defer non-critical tasks to AFTER the first frame
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

/// Sign in silently (no device binding check).
Future<void> _initAuth() async {
  try {
    await GoogleAuthService.signInSilently();
  } catch (e) {
    debugPrint('Auth init error: $e');
  }
}

/// Non-critical startup tasks that run AFTER the app is visible
Future<void> _deferredInit() async {
  // Start the appointment listener now that auth is complete.
  if (GoogleAuthService.isSignedIn) {
    FirebaseService.listenForAppointments();
  }

  // Pre-load festival events lazily (non-blocking)
  FestivalCacheService.loadYear(DateTime.now().year);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BharatheeyamApp extends StatefulWidget {
  const BharatheeyamApp({super.key});

  @override
  State<BharatheeyamApp> createState() => _BharatheeyamAppState();
}

class _BharatheeyamAppState extends State<BharatheeyamApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SubscriptionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-sync NTP clock on resume (updates offset if internet is now available)
      TrustedTimeService.syncWithNtp();
      // Re-verify subscription when app comes back to foreground
      SubscriptionService.checkOnReconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppThemes.themeNotifier,
      builder: (context, themeIndex, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          key: ValueKey('theme_$themeIndex'),
          title: 'ಪ್ರಶ್ನ',
          debugShowCheckedModeBanner: false,
          locale: const Locale('en', 'IN'),
          supportedLocales: const [
            Locale('en', 'IN'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final data = MediaQuery.of(context);
            final shortestSide = data.size.shortestSide;
            
            double scale = 1.0;
            if (shortestSide >= 800) {
              scale = 1.4;
            } else if (shortestSide >= 600) {
              scale = 1.2;
            }

            // Combine OS text scaling with our screen-size based scaling
            final finalScale = data.textScaler.scale(scale);

            return MediaQuery(
              data: data.copyWith(
                textScaler: TextScaler.linear(finalScale),
              ),
              child: child!,
            );
          },
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
          home: SubscriptionService.needsInternetVerification
              ? const _InternetRequiredScreen()
              : SubscriptionService.hasAccess ? const HomeScreen() : const PaywallScreen(),
        );
      },
    );
  }
}

// ============================================================
// BLOCKED SCREENS
// ============================================================

/// Shown when subscription needs internet verification (offline > 2 days)
class _InternetRequiredScreen extends StatefulWidget {
  const _InternetRequiredScreen();
  @override
  State<_InternetRequiredScreen> createState() => _InternetRequiredScreenState();
}

class _InternetRequiredScreenState extends State<_InternetRequiredScreen> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, size: 80, color: Colors.orange[400]),
          const SizedBox(height: 24),
          Text('ಇಂಟರ್ನೆಟ್ ಅಗತ್ಯವಿದೆ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 8),
          Text('Internet Connection Required', style: TextStyle(fontSize: 16, color: kMuted)),
          const SizedBox(height: 24),
          Text(
            'ನಿಮ್ಮ ಚಂದಾದಾರಿಕೆ ಸ್ಥಿತಿಯನ್ನು ಪರಿಶೀಲಿಸಲು ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಅಗತ್ಯವಿದೆ.\nPlay Store ನೊಂದಿಗೆ ಪರಿಶೀಲಿಸಲು ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕಿಸಿ ಮತ್ತು ಕೆಳಗಿನ ಬಟನ್ ಒತ್ತಿ.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kText, height: 1.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Please connect to the internet to verify your subscription status with Google Play.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: kMuted, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(children: [
              Text(SubscriptionService.statusText,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kText)),
              const SizedBox(height: 4),
              Text(SubscriptionService.graceStatusText,
                style: TextStyle(fontSize: 12, color: kMuted)),
            ]),
          ),
          const SizedBox(height: 24),
          if (_checking)
            CircularProgressIndicator(color: kPurple2)
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('ಪರಿಶೀಲಿಸಿ / Verify Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurple2,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: () async {
                setState(() => _checking = true);
                await SubscriptionService.reVerify();
                if (mounted) {
                  if (SubscriptionService.hasAccess) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false,
                    );
                  } else if (!SubscriptionService.needsInternetVerification) {
                    // Verified but no subscription — show paywall
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      (_) => false,
                    );
                  } else {
                    setState(() => _checking = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
        ]),
      )),
    );
  }
}
