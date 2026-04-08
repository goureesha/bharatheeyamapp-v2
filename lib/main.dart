import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/paywall_screen.dart';
import 'widgets/common.dart';
import 'services/subscription_service.dart';
import 'services/trusted_time_service.dart';
import 'services/google_auth_service.dart';
import 'services/install_checker.dart';
import 'services/device_binding_service.dart';
import 'services/firebase_service.dart';
import 'services/cloud_sync_service.dart';
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

  // Run ALL critical startup tasks in PARALLEL (not sequentially)
  // Including silent sign-in + device binding check — these MUST complete
  // before the first frame so we can show the correct screen
  await Future.wait([
    _initEphemeris(),
    SubscriptionService.initialize(),
    AppThemes.loadTheme(),
    ChartStyle.loadStyle(),
    AppLocale.loadLang(),
    LocationService.init(),
    TesterService.init(),
    InstallChecker.check(),
    _initAuthAndBinding(), // ← Sign in + device binding check BEFORE first frame
  ]);

  // Now show the app — binding state is already resolved
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

/// Notifier for device binding status — triggers UI rebuild when binding changes
final ValueNotifier<bool> deviceBindingNotifier = ValueNotifier<bool>(true);

/// Sign in silently and check device binding BEFORE the app renders.
/// This ensures the correct screen is shown on the very first frame.
Future<void> _initAuthAndBinding() async {
  try {
    await GoogleAuthService.signInSilently();
    if (GoogleAuthService.isSignedIn) {
      final bound = await DeviceBindingService.checkBinding();
      deviceBindingNotifier.value = bound;
      debugPrint('DeviceBinding: pre-render check result=$bound');
    }
  } catch (e) {
    debugPrint('Auth/Binding init error: $e');
    // If it fails, keep deviceBindingNotifier as true (fail-open for auth errors)
    // The binding service itself is fail-closed for Firestore errors
  }
}

/// Non-critical startup tasks that run AFTER the app is visible
Future<void> _deferredInit() async {
  // Start Firebase appointment listener + cloud sync
  if (GoogleAuthService.isSignedIn) {
    FirebaseService.init();
    // Auto-sync app data to cloud (once per day)
    CloudSyncService.autoSyncIfNeeded();
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
      // Re-check device binding on resume (catches if user migrated from another device)
      if (GoogleAuthService.isSignedIn) {
        DeviceBindingService.checkBinding().then((bound) {
          deviceBindingNotifier.value = bound;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppThemes.themeNotifier,
      builder: (context, themeIndex, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: deviceBindingNotifier,
          builder: (context, isBound, child) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              key: ValueKey('theme_${themeIndex}_bound_$isBound'),
              title: 'ಭಾರತೀಯಮ್',
              debugShowCheckedModeBanner: false,
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
              home: !InstallChecker.isFromPlayStore
                ? const _SideloadBlockedScreen()
                : !isBound
                  ? const _DeviceMismatchScreen()
                  : SubscriptionService.needsInternetVerification
                    ? const _InternetRequiredScreen()
                    : SubscriptionService.hasAccess ? const HomeScreen() : const PaywallScreen(),
            );
          },
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
                  // Update the notifier → triggers full app rebuild via ValueListenableBuilder
                  deviceBindingNotifier.value = true;
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
              // After sign-out, no email = binding is N/A → use notifier to rebuild
              deviceBindingNotifier.value = true;
            },
            child: Text('ಬೇರೆ ಖಾತೆಯಿಂದ ಲಾಗಿನ್ / Sign in with different account',
              style: TextStyle(color: kMuted, fontSize: 13)),
          ),
        ]),
      )),
    );
  }
}

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
