import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../services/ad_service.dart';
import 'input_screen.dart';
import 'panchanga_screen.dart';
import 'taranukoola_screen.dart';
import 'match_making_tab.dart';
import 'mantra_sangraha_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _Section('ಕುಂಡಲಿ', 'Kundali', Icons.auto_awesome, kOrange, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InputScreen()));
      }),
      _Section('ಪಂಚಾಂಗ', 'Panchanga', Icons.calendar_month, kPurple2, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PanchangaScreen()));
      }),
      _Section('ತಾರಾನುಕೂಲ', 'Taranukoola', Icons.stars_rounded, kGreen, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TaranukoolaScreen()));
      }),
      _Section('ಹೊಂದಾಣಿಕೆ', 'Match Making', Icons.favorite, const Color(0xFFE53E3E), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchMakingScreen()));
      }),
      _Section('ಮಂತ್ರ ಸಂಗ್ರಹ', 'Mantra Sangraha', Icons.menu_book_rounded, kTeal, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MantraSangrahaScreen()));
      }),
      _Section('ಸೆಟ್ಟಿಂಗ್ಸ್', 'Settings', Icons.settings, kMuted, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      }),
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Logo Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(children: [
                Image.asset('assets/images/logo.png', width: 80, height: 80),
                const SizedBox(height: 10),
                Text('ಭಾರತೀಯಮ್', style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: kOrange,
                  letterSpacing: 1.5,
                )),
                const SizedBox(height: 4),
                Text('Vedic Astrology', style: TextStyle(
                  fontSize: 13, color: kMuted, letterSpacing: 0.5,
                )),
              ]),
            ),

            // Sections Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: sections.map((s) => _buildCard(s)).toList(),
                ),
              ),
            ),

            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(_Section s) {
    return GestureDetector(
      onTap: s.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: s.color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: s.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(s.icon, color: s.color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(s.label, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: kText,
            )),
            const SizedBox(height: 2),
            Text(s.subtitle, style: TextStyle(
              fontSize: 11, color: kMuted,
            )),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Section(this.label, this.subtitle, this.icon, this.color, this.onTap);
}

// Wrapper for MatchMakingTab to make it a full screen
class MatchMakingScreen extends StatelessWidget {
  const MatchMakingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಹೊಂದಾಣಿಕೆ / Match Making',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: Column(
        children: [
          const Expanded(child: MatchMakingTab()),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
