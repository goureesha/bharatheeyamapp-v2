import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'widgets/common.dart';
import 'services/google_auth_service.dart';
import 'services/firebase_service.dart';
import 'services/user_session_service.dart';

import 'services/festival_cache_service.dart';
import 'services/location_service.dart';
import 'services/tester_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sweph/sweph.dart' hide kIsWeb;
import 'core/ephemeris.dart';
import 'core/calculator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Firebase must init BEFORE auth (sign-in needs Firestore for appointments)
  await FirebaseService.init();

  // Run ALL critical startup tasks in PARALLEL
  await Future.wait([
    _initEphemeris(),
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

/// Sign in silently for appointment sync (mobile only).
Future<void> _initAuth() async {
  if (kIsWeb) return; // Web uses password auth, not Google
  try {
    await GoogleAuthService.signInSilently();
  } catch (e) {
    debugPrint('Auth init error: $e');
  }
}

/// Non-critical startup tasks that run AFTER the app is visible
Future<void> _deferredInit() async {
  // Start the appointment listener if signed in
  if (GoogleAuthService.isSignedIn) {
    FirebaseService.listenForAppointments();
  }

  // Pre-load festival events lazily (non-blocking)
  FestivalCacheService.loadYear(DateTime.now().year);

  // Write sunrise data for the native Android home screen widget.
  _writeSunriseForWidget();
}

/// Calculate today's sunrise and save to SharedPreferences for native widget
Future<void> _writeSunriseForWidget() async {
  try {
    final now = DateTime.now();
    final result = await AstroCalculator.calculate(
      year: now.year, month: now.month, day: now.day,
      hourUtcOffset: LocationService.tzOffset,
      hour24: now.hour + now.minute / 60.0,
      lat: LocationService.lat, lon: LocationService.lon,
      ayanamsaMode: 'lahiri', trueNode: true,
    );
    if (result == null) return;

    // Parse sunrise time from panchanga string (format: "06:23 AM")
    final srParts = result.panchang.sunrise.split(':');
    final srHour = double.tryParse(srParts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 6;
    final srMin = double.tryParse(srParts.length > 1 ? srParts[1].replaceAll(RegExp(r'[^0-9]'), '') : '0') ?? 0;
    final isPM = result.panchang.sunrise.toUpperCase().contains('PM');
    double sunriseH24 = srHour + srMin / 60.0;
    if (isPM && srHour != 12) sunriseH24 += 12;
    if (!isPM && srHour == 12) sunriseH24 = srMin / 60.0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sunrise_hour24', sunriseH24);
    debugPrint('Widget sunrise_hour24 written: $sunriseH24');
  } catch (e) {
    debugPrint('Widget sunrise write failed: $e');
  }
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
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
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // No-op for now, lifecycle tasks can be added here
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppThemes.themeNotifier,
      builder: (context, themeIndex, child) {
        return MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          navigatorKey: navigatorKey,
          key: ValueKey('theme_$themeIndex'),
          title: AppLocale.l('appName'),
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
              hintStyle: TextStyle(color: kMuted),
            ),
            dropdownMenuTheme: DropdownMenuThemeData(
              textStyle: TextStyle(color: kText),
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
          home: kIsWeb
              ? const _WebPasswordGate()
              : GoogleAuthService.isSignedIn
                  ? const _AuthGate()
                  : const _LoginScreen(),
        );
      },
    );
  }
}

/// Gate that checks blocked status after login
class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checking = true;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final allowed = await UserSessionService.registerAndCheck();
    if (mounted) {
      setState(() {
        _blocked = !allowed;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: kPurple2),
            const SizedBox(height: 16),
            Text('Verifying access...', style: TextStyle(color: kMuted)),
          ]),
        ),
      );
    }
    if (_blocked) return const _BlockedScreen();
    return const HomeScreen();
  }
}

/// Web password gate — simple password screen for web platform
class _WebPasswordGate extends StatefulWidget {
  const _WebPasswordGate();
  @override
  State<_WebPasswordGate> createState() => _WebPasswordGateState();
}

class _WebPasswordGateState extends State<_WebPasswordGate> {
  final _controller = TextEditingController();
  String? _error;
  bool _obscure = true;

  void _submit() {
    if (_controller.text.trim() == '1122133') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      setState(() { _error = 'Incorrect password'; });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 64, color: kPurple2),
                const SizedBox(height: 16),
                Text('ಭಾರತೀಯಂ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kPurple2)),
                const SizedBox(height: 8),
                Text('Bharatheeyam Jyothishya', style: TextStyle(fontSize: 14, color: kMuted)),
                const SizedBox(height: 32),
                Text('Enter password to continue', style: TextStyle(fontSize: 14, color: kText)),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  obscureText: _obscure,
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(color: kText),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: kMuted),
                    filled: true,
                    fillColor: kBorder.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kPurple2, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: kMuted),
                      onPressed: () => setState(() { _obscure = !_obscure; }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.lock_open, color: Colors.white),
                    label: const Text('Enter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple2,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Login screen shown when user is not signed in (mobile only)
class _LoginScreen extends StatefulWidget {
  const _LoginScreen();
  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final success = await GoogleAuthService.signIn();
      if (success && mounted) {
        // Register device and check block
        final allowed = await UserSessionService.registerAndCheck();
        if (mounted) {
          if (!allowed) {
            setState(() { _loading = false; _error = 'Account blocked. Contact admin.'; });
            return;
          }
          // Start appointment listener
          FirebaseService.listenForAppointments();
          // Restart app to home
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          );
        }
      } else {
        if (mounted) setState(() { _loading = false; _error = 'Sign-in cancelled.'; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 64, color: kPurple2),
              const SizedBox(height: 16),
              Text('ಭಾರತೀಯಂ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kPurple2)),
              const SizedBox(height: 8),
              Text('Bharatheeyam Jyothishya', style: TextStyle(fontSize: 14, color: kMuted)),
              const SizedBox(height: 32),
              Text('Sign in with Google to continue', style: TextStyle(fontSize: 14, color: kText)),
              const SizedBox(height: 20),
              if (_loading)
                CircularProgressIndicator(color: kPurple2)
              else
                ElevatedButton.icon(
                  onPressed: _signIn,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Sign in with Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple2,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Blocked screen shown when admin has blocked the user
class _BlockedScreen extends StatelessWidget {
  const _BlockedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Account Blocked', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.red)),
              const SizedBox(height: 12),
              Text(
                'Your account has been blocked by the administrator.\nPlease contact support for assistance.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: kMuted),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await GoogleAuthService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const _LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                child: Text('Sign Out', style: TextStyle(color: kPurple2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
