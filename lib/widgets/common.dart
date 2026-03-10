import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ─────────────────────────────────────────────
// Shared app-wide decorators / constants
// ─────────────────────────────────────────────

class AppThemes {
  static final ValueNotifier<int> themeNotifier = ValueNotifier(0);

  static const List<Map<String, Color>> palettes = [
    { // Standard Light
      'purple1': Color(0xFF8E2DE2),
      'purple2': Color(0xFF4A00E0),
      'bg': Color(0xFFFFFDF7),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF2D3748),
      'border': Color(0xFFE2E8F0),
      'muted': Color(0xFF718096),
    },
    { // Dark Night
      'purple1': Color(0xFF9F7AEA),
      'purple2': Color(0xFF805AD5),
      'bg': Color(0xFF1A202C),
      'card': Color(0xFF2D3748),
      'text': Color(0xFFF7FAFC),
      'border': Color(0xFF4A5568),
      'muted': Color(0xFFA0AEC0),
    },
    { // Golden Sepia
      'purple1': Color(0xFFDD6B20),
      'purple2': Color(0xFFC05621),
      'bg': Color(0xFFFFFBEB),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF451A03),
      'border': Color(0xFFFCD34D),
      'muted': Color(0xFF92400E),
    },
    { // Royal Ocean
      'purple1': Color(0xFF2563EB),
      'purple2': Color(0xFF1D4ED8),
      'bg': Color(0xFFF0F9FF),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF0F172A),
      'border': Color(0xFFBAE6FD),
      'muted': Color(0xFF475569),
    },
    { // Emerald Forest
      'purple1': Color(0xFF059669),
      'purple2': Color(0xFF047857),
      'bg': Color(0xFFF0FDF4),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF064E3B),
      'border': Color(0xFFBBF7D0),
      'muted': Color(0xFF166534),
    }
  ];

  static void setTheme(int i) {
    if (i < 0 || i >= palettes.length) return;
    final p = palettes[i];
    kPurple1 = p['purple1']!;
    kPurple2 = p['purple2']!;
    kBg = p['bg']!;
    kCard = p['card']!;
    kText = p['text']!;
    kBorder = p['border']!;
    kMuted = p['muted']!;
    themeNotifier.value = i;
    // Persist theme choice
    SharedPreferences.getInstance().then((prefs) => prefs.setInt('app_theme', i));
  }

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('app_theme') ?? 0;
    setTheme(idx);
  }
}

Color kPurple1 = AppThemes.palettes[0]['purple1']!;
Color kPurple2 = AppThemes.palettes[0]['purple2']!;
Color kOrange  = const Color(0xFFDD6B20);
Color kOrange2 = const Color(0xFFC05621);
Color kTeal    = const Color(0xFF319795);
Color kGreen   = const Color(0xFF047857);
Color kBg      = AppThemes.palettes[0]['bg']!;
Color kCard    = AppThemes.palettes[0]['card']!;
Color kBorder  = AppThemes.palettes[0]['border']!;
Color kText    = AppThemes.palettes[0]['text']!;
Color kMuted   = AppThemes.palettes[0]['muted']!;

// ─────────────────────────────────────────────
// Header widget (purple gradient banner)
// ─────────────────────────────────────────────
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPurple1, kPurple2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPurple2.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
        border: const Border(bottom: BorderSide(color: Color(0xFFF6D365), width: 4)),
      ),
      child: Center(
        child: Text(
          'ಭಾರತೀಯಮ್',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card wrapper
// ─────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;
  SectionTitle(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color ?? kPurple2,
        ),
      ),
    );
  }
}
