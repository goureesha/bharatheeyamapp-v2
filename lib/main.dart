import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/home_screen.dart';
import 'screens/support_screen.dart';
import 'widgets/common.dart';
import 'services/app_access_service.dart';
import 'services/trusted_time_service.dart';
import 'services/google_auth_service.dart';
import 'services/drive_backup_service.dart';
import 'core/transit_cache.dart';
import 'constants/places.dart';

import 'services/device_binding_service.dart';
import 'services/firebase_service.dart';
import 'services/offline_access_service.dart';
import 'services/network_service.dart';


import 'services/location_service.dart';
import 'services/tester_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sweph/sweph.dart' hide kIsWeb;
import 'core/ephemeris.dart';
import 'core/calculator.dart';
import 'services/timezone_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // NTP must init BEFORE AppAccessService so trusted time is available
  await TrustedTimeService.init();

  // Firebase must init BEFORE auth/binding/tester because sign-in triggers
  // TesterService.checkTesterStatus() which uses FirebaseFirestore.instance
  await FirebaseService.init();

  // Phase 1: FAST init — UI-critical only (theme, locale, location).
  // Auth + ephemeris run in parallel but we don't wait for ephemeris.
  initTimezones(); // Initialize IANA timezone database (sync, ~50ms)
  final ephFuture = _initEphemeris(); // Start but don't await
  await Future.wait([
    GoogleAuthService.signInSilently(),
    AppThemes.loadTheme(),
    ChartStyle.loadStyle(),
    VargaLagnaStyle.load(),
    SamshakaMode.load(),
    SingleLetterMode.load(),
    AppLocale.loadLang(),
    LocationService.init(),
  ]);

  // Phase 2: AppAccess (needs userEmail from sign-in)
  await AppAccessService.initialize();
  await OfflineAccessService.initialize();

  // Show the app IMMEDIATELY — no more blocking on binding/tester
  runApp(const BharatheeyamApp());

  // Phase 3: Heavy tasks AFTER first frame (no more black screen)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await ephFuture; // Ensure ephemeris is ready before sunrise calc
    loadWorldCities(); // Load 34K+ world cities in background
    await _initAuthAndBinding();
    TesterService.init();
    _deferredInit();
    // Preload 10 years of planet transit data in background
    TransitCache.preloadRange();
    // Check device-level block (installs collection) — runs AFTER trackInstall
    await DeviceBindingService.checkDeviceBlock();
    // Trigger UI rebuild if device is blocked
    if (DeviceBindingService.isDeviceBlocked) {
      deviceBindingNotifier.value = deviceBindingNotifier.value;
    }
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

/// Custom notifier that always fires, even when value is identical.
/// Standard ValueNotifier skips if old == new, which breaks the
/// sign-in → home screen transition (both values are `true`).
class _AlwaysNotify<T> extends ValueNotifier<T> {
  _AlwaysNotify(super.value);
  @override
  set value(T newValue) {
    if (super.value == newValue) {
      notifyListeners(); // fire even for same value
    } else {
      super.value = newValue; // fires automatically
    }
  }
}

/// Notifier for device binding status — triggers UI rebuild when binding changes
final ValueNotifier<bool> deviceBindingNotifier = _AlwaysNotify<bool>(true);

/// Whether the app version is too old and must be updated
bool _isVersionOutdated = false;
String _minimumVersionRequired = '';

/// Check device binding BEFORE the app renders.
/// Auth (signInSilently) already completed in Phase 1.
/// This ensures the correct screen is shown on the very first frame.
Future<void> _initAuthAndBinding() async {
  try {

    // Auth already done in Phase 1 — just do binding + trial sync
    if (GoogleAuthService.isSignedIn) {
      final bound = await DeviceBindingService.checkBinding();
      deviceBindingNotifier.value = bound;
      debugPrint('DeviceBinding: pre-render check result=$bound');
      // Sync trial start with Firestore (prevents trial reset on reinstall)
      await AppAccessService.syncTrialWithFirestore();
      // Restore offline day count from server (prevents reset on reinstall)
      await OfflineAccessService.restoreFromServer();
      // Auto-backup to Google Drive if due (every 12h, fire-and-forget)
      DriveBackupService.autoBackupIfDue();
    }
  } catch (e) {
    debugPrint('Auth/Binding init error: $e');
  }
}

/// Non-critical startup tasks that run AFTER the app is visible
Future<void> _deferredInit() async {
  // Firebase is already initialized in main() before the parallel block.
  if (GoogleAuthService.isSignedIn) {
    // (booking listener removed)
  }

  // Track every device install/launch
  DeviceBindingService.trackInstall();

  // Write sunrise data for the native Android home screen widget.
  _writeSunriseForWidget();

  // Check minimum version requirement from admin dashboard
  await _checkMinimumVersion();
  await AppAccessService.loadOfflineGraceDays();
}

/// Compare two version strings like "2.2.0" → returns true if current < minimum
bool _isVersionLessThan(String current, String minimum) {
  final c = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final m = minimum.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  // Pad to same length
  while (c.length < 3) c.add(0);
  while (m.length < 3) m.add(0);
  for (int i = 0; i < 3; i++) {
    if (c[i] < m[i]) return true;
    if (c[i] > m[i]) return false;
  }
  return false; // equal = not less
}

/// Read minimum_version from Firestore app_config/settings.
/// If current app version < minimum_version → block the app.
/// Safe: runs post-frame, has timeout, catches all errors.
Future<void> _checkMinimumVersion() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('settings')
        .get()
        .timeout(const Duration(seconds: 5));

    if (!doc.exists || doc.data() == null) return;

    final minVersion = doc.data()!['minimum_version'] as String?;
    if (minVersion == null || minVersion.isEmpty) return;

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version; // e.g. "2.2.0"

    debugPrint('VersionCheck: current=$currentVersion, minimum=$minVersion');

    if (_isVersionLessThan(currentVersion, minVersion)) {
      _isVersionOutdated = true;
      _minimumVersionRequired = minVersion;
      // Toggle notifier to force UI rebuild (ValueNotifier only notifies on change)
      final current = deviceBindingNotifier.value;
      deviceBindingNotifier.value = !current;
      await Future.delayed(const Duration(milliseconds: 50));
      deviceBindingNotifier.value = current;
      debugPrint('🚫 App version $currentVersion is below minimum $minVersion — blocking');
    }
  } catch (e) {
    debugPrint('VersionCheck: Failed to check minimum version: $e');
    // Silently fail — don't block if we can't reach Firestore
  }
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
    // Sunrise is always AM so no PM conversion needed, but guard against edge cases
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

class BharatheeyamApp extends StatefulWidget {
  const BharatheeyamApp({super.key});

  @override
  State<BharatheeyamApp> createState() => _BharatheeyamAppState();
}

class _BharatheeyamAppState extends State<BharatheeyamApp> with WidgetsBindingObserver {
  int _rebuildKey = 0; // Incremented only when access is actually revoked
  bool _webUnlocked = !kIsWeb; // Web starts locked, mobile starts unlocked

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppAccessService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-sync NTP clock on resume (updates offset if internet is now available)
      TrustedTimeService.syncWithNtp();
      // Sync offline usage when coming back online
      OfflineAccessService.syncToServer();
      OfflineAccessService.clearExpiredClaim();
      // Re-check access + device binding on resume.
      // If access has been revoked (offline too long, access expired, etc.)
      // redirect to the root gate screen.
      _verifyAccessOnResume();
    }
  }

  Future<void> _verifyAccessOnResume() async {

    // Always try to verify with the server, even during active offline claims.
    // This ensures admin revocations take effect even if the user claimed a day.
    final serverReached = await AppAccessService.checkAdminAccess();
    // Also check device-level block (installs collection)
    await DeviceBindingService.checkDeviceBlock();

    if (GoogleAuthService.isSignedIn) {
      final bound = await DeviceBindingService.checkBinding();
      deviceBindingNotifier.value = bound;
      AppAccessService.syncTrialWithFirestore();
    }

    // If the server was successfully reached and says no access,
    // the offline claim should NOT override an explicit server revocation.
    // Clear the claim and kick the user to the gate screen.
    if (serverReached &&
        !AppAccessService.adminAccess &&
        !AppAccessService.isActivated &&
        !AppAccessService.isTrialActive) {
      // Server confirmed: no access, no access, no trial.
      // If there's an active offline claim, invalidate it — server authority wins.
      if (OfflineAccessService.hasActiveClaim) {
        await OfflineAccessService.clearActiveClaim();
        debugPrint('🔒 Server revoked access — offline claim invalidated');
      }
    }

    // Force UI rebuild if access was revoked or user was blocked.
    // This kicks the user out of HomeScreen to SupportScreen/BlockedScreen.
    if (!AppAccessService.hasAccess ||
        AppAccessService.isBlocked ||
        DeviceBindingService.isDeviceBlocked) {
      // Increment rebuild key to force MaterialApp recreation with blocked/support screen
      if (mounted) setState(() => _rebuildKey++);
      debugPrint('🔒 Access revoked on resume — forcing UI rebuild');
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
              scaffoldMessengerKey: scaffoldMessengerKey,
              key: ValueKey('theme_${themeIndex}_bound_${isBound}_$_rebuildKey'),
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
                  brightness: (themeIndex == 1 || themeIndex == 5) ? Brightness.dark : Brightness.light,
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
              home: (kIsWeb && !_webUnlocked)
                  ? _WebPasswordScreen(onUnlocked: () => setState(() => _webUnlocked = true))
                  : _isVersionOutdated
                  ? const _ForceUpdateScreen()
                  : (AppAccessService.isBlocked || DeviceBindingService.isDeviceBlocked)
                  ? _BlockedScreen()
                  : !GoogleAuthService.isSignedIn && !kIsWeb
                  ? (AppAccessService.lastOnlineCheck == null
                    ? const _FirstTimeSignInScreen()
                    : const _OfflineVerifyScreen())
                  : !isBound
                    ? const _DeviceMismatchScreen()
                    : AppAccessService.hasAccess ? const HomeScreen() : const SupportScreen(),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// WEB PASSWORD GATE — shown on every web load/reload
// ============================================================

class _WebPasswordScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _WebPasswordScreen({required this.onUnlocked});

  @override
  State<_WebPasswordScreen> createState() => _WebPasswordScreenState();
}

class _WebPasswordScreenState extends State<_WebPasswordScreen> {
  final _pinCtrl = TextEditingController();
  bool _hasError = false;
  static const _correctPin = '1145';

  void _verify() {
    if (_pinCtrl.text.trim() == _correctPin) {
      widget.onUnlocked();
    } else {
      setState(() => _hasError = true);
      _pinCtrl.clear();
    }
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 48, color: kPurple2),
              const SizedBox(height: 16),
              Text(AppLocale.l('appName'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPurple2)),
              const SizedBox(height: 24),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  filled: true,
                  fillColor: kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _hasError ? Colors.red : kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPurple2, width: 2)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                ),
                onSubmitted: (_) => _verify(),
              ),
              if (_hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Incorrect PIN', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple2,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Enter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FORCE UPDATE SCREEN — shown when app version < minimum_version
// ============================================================

class _ForceUpdateScreen extends StatelessWidget {
  const _ForceUpdateScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/logo.png', width: 80, height: 80),
            const SizedBox(height: 16),
            Text(AppLocale.l('appName'), style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w900, color: kOrange, letterSpacing: 1.5)),
            const SizedBox(height: 32),
            Icon(Icons.system_update, color: kPurple2, size: 72),
            const SizedBox(height: 20),
            Text('ಅಪ್‌ಡೇಟ್ ಅಗತ್ಯವಿದೆ', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: kPurple2)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPurple2.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPurple2.withOpacity(0.3)),
              ),
              child: Column(children: [
                Text(
                  'ದಯವಿಟ್ಟು ಆಪ್ ಅನ್ನು ನವೀಕರಿಸಿ. ಕನಿಷ್ಠ ಆವೃತ್ತಿ: $_minimumVersionRequired',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: kText, height: 1.6),
                ),
              ]),
            ),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Play Store', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurple2, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                // Open Play Store listing
                const url = 'https://play.google.com/store/apps/details?id=com.bharatheeyam.app';
                try {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                } catch (_) {
                  // Fallback: copy URL
                  Clipboard.setData(const ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied')));
                  }
                }
              },
            )),
          ]),
        )),
      ),
    );
  }
}

// ============================================================
// BLOCKED SCREEN — shown when admin blocks a user
// ============================================================

class _BlockedScreen extends StatefulWidget {
  const _BlockedScreen();
  @override
  State<_BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<_BlockedScreen> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    final reason = AppAccessService.isBlocked
        ? AppAccessService.blockedReason
        : DeviceBindingService.deviceBlockedReason;
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/logo.png', width: 80, height: 80),
            const SizedBox(height: 16),
            Text(AppLocale.l('appName'), style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w900, color: kOrange, letterSpacing: 1.5)),
            const SizedBox(height: 32),
            Icon(Icons.block, color: Colors.red[400], size: 72),
            const SizedBox(height: 20),
            Text('Account Blocked', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.red[700])),
            const SizedBox(height: 8),
            Text('ಖಾತೆ ನಿರ್ಬಂಧಿಸಲಾಗಿದೆ', style: TextStyle(
              fontSize: 16, color: Colors.red[400])),
            const SizedBox(height: 24),
            if (reason.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, color: Colors.red[400], size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(reason, style: TextStyle(
                    fontSize: 14, color: kText, height: 1.5))),
                ]),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Your account has been blocked by the administrator. Please contact support for assistance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kMuted, height: 1.6),
            ),
            const SizedBox(height: 32),
            if (_checking)
              CircularProgressIndicator(color: kPurple2)
            else
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry / ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple2, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  setState(() => _checking = true);
                  try {
                    await AppAccessService.checkAdminAccess();
                    await DeviceBindingService.checkDeviceBlock();
                  } catch (_) {}
                  if (mounted) {
                    if (!AppAccessService.isBlocked && !DeviceBindingService.isDeviceBlocked) {
                      // Unblocked! Rebuild the app
                      deviceBindingNotifier.value = deviceBindingNotifier.value;
                    } else {
                      setState(() => _checking = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Account is still blocked'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              )),
            const SizedBox(height: 24),
            Divider(color: kBorder),
            const SizedBox(height: 12),
            Text('Contact Support', style: TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.phone, size: 14, color: kPurple2),
              const SizedBox(width: 4),
              Text('+91 8762629847', style: TextStyle(fontSize: 12, color: kText)),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.email, size: 14, color: kPurple2),
              const SizedBox(width: 4),
              Text('goureesh3690@gmail.com', style: TextStyle(fontSize: 12, color: kText)),
            ]),
          ]),
        )),
      ),
    );
  }
}

// ============================================================

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
          Text(AppLocale.l('activeOnOtherDevice'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 8),
          Text('Active on Another Device', style: TextStyle(fontSize: 16, color: kMuted)),
          const SizedBox(height: 24),
          Text(AppLocale.l('deviceMismatchMsg').replaceAll('{email}', GoogleAuthService.userEmail ?? ''),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kText, height: 1.6)),
          const SizedBox(height: 32),
          if (_migrating)
            CircularProgressIndicator(color: kPurple2)
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              label: Text(AppLocale.l('migrateDevice')),
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
                      SnackBar(content: Text(AppLocale.l('migrateFailed')), backgroundColor: Colors.red));
                  }
                }
              },
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              await GoogleAuthService.signOut();
              // Sign in with a different account
              final signedIn = await GoogleAuthService.signIn();
              if (signedIn) {
                // Re-check device binding for the new account
                final bound = await DeviceBindingService.checkBinding();
                deviceBindingNotifier.value = bound;
                if (bound) {
                  await AppAccessService.syncTrialWithFirestore();
                }
              }
              // If sign-in cancelled/failed, stay on mismatch screen
              // deviceBindingNotifier stays false → screen stays blocked
            },
            child: Text(AppLocale.l('signInDifferent'),
              style: TextStyle(color: kMuted, fontSize: 13)),
          ),
        ]),
      )),
    );
  }
}

/// Shown when user hasn't connected to internet in > 24 hours
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
          Text(AppLocale.l('internetRequired'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 8),
          Text('Internet Connection Required', style: TextStyle(fontSize: 16, color: kMuted)),
          const SizedBox(height: 24),
          Text(
            AppLocale.l('internetRequiredMsg'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kText, height: 1.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Please connect to the internet at least once every 24 hours to continue using the app.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: kMuted, height: 1.5),
          ),
          if (AppAccessService.lastOnlineCheck != null) ...[
            const SizedBox(height: 12),
            Builder(builder: (_) {
              final hoursSince = TrustedTimeService.now().difference(AppAccessService.lastOnlineCheck!).inHours;
              final graceDaysLeft = 10 - TrustedTimeService.now().difference(AppAccessService.lastOnlineCheck!).inDays;
              return Text(
                'Last verified: ${hoursSince}h ago  •  Grace: ${graceDaysLeft > 0 ? graceDaysLeft : 0} days left',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.orange[300], fontWeight: FontWeight.w600),
              );
            }),
          ],
          const SizedBox(height: 24),
          if (_checking)
            CircularProgressIndicator(color: kPurple2)
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(AppLocale.l('verifyNow')),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurple2,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: () async {
                setState(() => _checking = true);
                try {
                  await Future.wait([
                    AppAccessService.checkAdminAccess(),
                    AppAccessService.recordOnlineCheck(),
                  ]).timeout(const Duration(seconds: 5), onTimeout: () => []);
                } catch (_) {}
                if (mounted) {
                  if (!AppAccessService.needsInternetVerification) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => AppAccessService.hasAccess
                          ? const HomeScreen()
                          : const SupportScreen(),
                      ),
                      (_) => false,
                    );
                  } else {
                    setState(() => _checking = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocale.l('internetFailed')),
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

/// Smart gate: If online → show Google login. If offline → show offline day claim.
class _OfflineVerifyScreen extends StatefulWidget {
  const _OfflineVerifyScreen();
  @override
  State<_OfflineVerifyScreen> createState() => _OfflineVerifyScreenState();
}

class _OfflineVerifyScreenState extends State<_OfflineVerifyScreen> {
  bool _checking = true;
  bool _isOnline = false;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _checking = true);
    // Use actual connectivity check — not the cached 48h grace window
    _isOnline = await NetworkService.isActuallyOnline();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    // While checking connectivity, show loading
    if (_checking) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/logo.png', width: 80, height: 80),
          const SizedBox(height: 24),
          CircularProgressIndicator(color: kPurple2),
          const SizedBox(height: 16),
          Text('Checking connection...', style: TextStyle(color: kMuted)),
        ])),
      );
    }

    // If online, show the normal Gmail login screen
    if (_isOnline) {
      return const _GmailRequiredScreen();
    }


    // Returning user (has signed in before) — show offline access claim screen
    final daysLeft = OfflineAccessService.daysRemaining;
    final hasClaim = OfflineAccessService.hasActiveClaim;
    final hoursLeft = OfflineAccessService.claimHoursRemaining;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/logo.png', width: 80, height: 80),
            const SizedBox(height: 16),
            Text(AppLocale.l('appName'), style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w900, color: kOrange, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text('Vedic Astrology', style: TextStyle(fontSize: 13, color: kMuted)),
            const SizedBox(height: 32),

            // Status card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPurple2.withOpacity(0.08), kOrange.withOpacity(0.06)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPurple2.withOpacity(0.3)),
              ),
              child: Column(children: [
                Icon(Icons.wifi_off_rounded, color: Colors.orange[400], size: 56),
                const SizedBox(height: 16),
                Text(AppLocale.l('offlineMode'), style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
                const SizedBox(height: 4),
                Text('Offline Access', style: TextStyle(fontSize: 14, color: kMuted)),
                const SizedBox(height: 16),

                if (hasClaim) ...[
                  // Active claim — show remaining hours
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle, color: kGreen, size: 20),
                      const SizedBox(width: 8),
                      Text('${AppLocale.l('offlineActive')} — $hoursLeft ${AppLocale.l('hoursLeft')}',
                        style: TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    icon: const Icon(Icons.home),
                    label: Text(AppLocale.l('continueToApp'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple2, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      // Navigate directly to home — bypass auth gate
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (_) => false,
                      );
                    },
                  )),
                ] else if (daysLeft > 0) ...[
                  // Can claim offline day
                  Text(AppLocale.l('offlineClaimDesc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: kText, height: 1.6)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: kOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$daysLeft / ${OfflineAccessService.maxOfflineDays} ${AppLocale.l('daysLeft')}',
                      style: TextStyle(color: kOrange, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    icon: _claiming
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.offline_bolt),
                    label: Text(_claiming ? 'Claiming...' : AppLocale.l('claimOfflineDay'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _claiming ? null : () async {
                      setState(() => _claiming = true);
                      final ok = await OfflineAccessService.claimOfflineDay();
                      if (ok && mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (_) => false,
                        );
                      } else if (mounted) {
                        setState(() => _claiming = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocale.l('claimFailed')), backgroundColor: Colors.red),
                        );
                      }
                    },
                  )),
                ] else ...[
                  // No days left
                  Icon(Icons.block, color: Colors.red[400], size: 40),
                  const SizedBox(height: 12),
                  Text(AppLocale.l('offlineDaysExhausted'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: kText, height: 1.6)),
                  const SizedBox(height: 8),
                  Text('All 10 offline days have been used. Please connect to the internet or contact support.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: kMuted, height: 1.5)),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    icon: const Icon(Icons.support_agent),
                    label: Text(AppLocale.l('contactSupport'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400], foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                    },
                  )),
                ],

                const SizedBox(height: 20),
                // Retry connection button
                TextButton.icon(
                  icon: Icon(Icons.refresh, color: kPurple2, size: 18),
                  label: Text(AppLocale.l('retryConnection'), style: TextStyle(color: kPurple2, fontSize: 13)),
                  onPressed: () => _checkConnection(),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Divider(color: kBorder),
            const SizedBox(height: 12),
            Text('Need help? Contact support', style: TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.phone, size: 14, color: kPurple2),
              const SizedBox(width: 4),
              Text('+91 8762629847', style: TextStyle(fontSize: 12, color: kText)),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.email, size: 14, color: kPurple2),
              const SizedBox(width: 4),
              Text('goureesh3690@gmail.com', style: TextStyle(fontSize: 12, color: kText)),
            ]),
          ]),
        )),
      ),
    );
  }
}

/// First-time sign-in: instant UI, no internet check, no lag.
class _FirstTimeSignInScreen extends StatefulWidget {
  const _FirstTimeSignInScreen();
  @override
  State<_FirstTimeSignInScreen> createState() => _FirstTimeSignInScreenState();
}

class _FirstTimeSignInScreenState extends State<_FirstTimeSignInScreen> {
  bool _signingIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/logo.png', width: 80, height: 80),
            const SizedBox(height: 16),
            Text(AppLocale.l('appName'), style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w900, color: kOrange, letterSpacing: 1.5)),
            const SizedBox(height: 32),
            Icon(Icons.account_circle_rounded, color: kPurple2, size: 64),
            const SizedBox(height: 16),
            Text(AppLocale.l('gmailRequired'), style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
            const SizedBox(height: 8),
            Text('Sign in to get started',
              style: TextStyle(fontSize: 14, color: kMuted)),
            const SizedBox(height: 16),
            Text(AppLocale.l('gmailRequiredMsg'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kText, height: 1.6)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _signingIn
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login),
                label: Text(_signingIn ? 'Signing in...' : 'Sign in with Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple2, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _signingIn ? null : () async {
                  setState(() => _signingIn = true);
                  try {
                    final ok = await GoogleAuthService.signIn();
                    if (ok && mounted) {
                      // Binding check MUST complete — don't timeout
                      final bound = await DeviceBindingService.checkBinding();
                      // AppAccess check MUST complete before UI rebuild
                      // so hasAccess is correct (trial/access state resolved)
                      await AppAccessService.checkAdminAccess();
                      await AppAccessService.recordOnlineCheck();
                      // Now trigger UI rebuild with correct state
                      deviceBindingNotifier.value = bound;
                      // These can run in background
                      AppAccessService.syncTrialWithFirestore();
                    } else if (mounted) {
                      setState(() => _signingIn = false);
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _signingIn = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign-in failed. Please check your internet.'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
            Divider(color: kBorder),
            const SizedBox(height: 12),
            Text('Need help? Contact support', style: TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.phone, size: 14, color: kPurple2),
              const SizedBox(width: 4),
              Text('+91 8762629847', style: TextStyle(fontSize: 12, color: kText)),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.email, size: 14, color: kPurple2),
              const SizedBox(width: 4),
              Text('goureesh3690@gmail.com', style: TextStyle(fontSize: 12, color: kText)),
            ]),
          ]),
        )),
      ),
    );
  }
}

/// Shown when user has never signed in with Gmail (first-ever app open)
class _GmailRequiredScreen extends StatefulWidget {
  const _GmailRequiredScreen();
  @override
  State<_GmailRequiredScreen> createState() => _GmailRequiredScreenState();
}

class _GmailRequiredScreenState extends State<_GmailRequiredScreen> {
  bool _signingIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/logo.png', width: 90, height: 90),
            const SizedBox(height: 16),
            Text(AppLocale.l('appName'), style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900, color: kOrange,
              letterSpacing: 1.5,
            )),
            const SizedBox(height: 4),
            Text(AppLocale.l('vedicAstrology'), style: TextStyle(
              fontSize: 14, color: kMuted, letterSpacing: 0.5,
            )),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPurple2.withOpacity(0.08), kOrange.withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPurple2.withOpacity(0.3)),
              ),
              child: Column(children: [
                Icon(Icons.account_circle_rounded, color: kPurple2, size: 64),
                const SizedBox(height: 16),
                Text(AppLocale.l('gmailRequired'), style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
                const SizedBox(height: 8),
                Text('Gmail Login Required', style: TextStyle(
                  fontSize: 14, color: kMuted)),
                const SizedBox(height: 16),
                Text(AppLocale.l('gmailRequiredMsg'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: kText, height: 1.6)),
                const SizedBox(height: 8),
                Text('Sign in with your Google account to continue using the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: kMuted, height: 1.5)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _signingIn ? null : () async {
                      setState(() => _signingIn = true);
                      try {
                        final ok = await GoogleAuthService.signIn();
                        if (ok && mounted) {
                          // Binding check MUST complete — don't timeout
                          final bound = await DeviceBindingService.checkBinding();
                          // AppAccess check MUST complete before UI rebuild
                          await AppAccessService.checkAdminAccess();
                          await AppAccessService.recordOnlineCheck();
                          // Now trigger UI rebuild with correct state
                          deviceBindingNotifier.value = bound;
                          // Background tasks
                          AppAccessService.syncTrialWithFirestore();
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sign-in cancelled'), backgroundColor: Colors.orange),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sign-in error: \$e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                      if (mounted) setState(() => _signingIn = false);
                    },
                    icon: _signingIn
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.login),
                    label: Text(_signingIn ? 'Signing in...' : 'Sign in with Google',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple2,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        )),
      ),
    );
  }
}
