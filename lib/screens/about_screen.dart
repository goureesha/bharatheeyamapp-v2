import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common.dart';
import '../core/events.dart';
import '../core/calculator.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _githubUrl = 'https://github.com/goureesha/bharatheeyamapp';
  static const _seUrl = 'https://www.astro.com/swisseph/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ನಮ್ಮ ಬಗ್ಗೆ / About',
            style: TextStyle(
                color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ─── App Identity ──────────────────────────────────────────
            Center(
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80, height: 80, fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text('ಭಾರತೀಯಮ್',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: kPurple2)),
                Text('Bharatheeyam — Vedic Astrology',
                    style: TextStyle(fontSize: 14, color: kMuted)),
                Text('Version 1.0.1  •  Open Source (AGPL-3.0)',
                    style: TextStyle(fontSize: 12, color: kMuted)),
              ]),
            ),

            const SizedBox(height: 24),

            // ─── Calculation Engine ────────────────────────────────────
            _sectionHeader('ಲೆಕ್ಕಾಚಾರ ಎಂಜಿನ್ / Calculation Engine'),
            _calcCard(
              icon: Icons.precision_manufacturing_outlined,
              title: 'Swiss Ephemeris (sweph)',
              body:
                  'All planetary positions are calculated using the Swiss Ephemeris — '
                  'the world\'s most accurate astronomical positional engine, '
                  'developed by Astrodienst AG (Zürich, Switzerland). '
                  'It is accurate to sub-arcsecond precision and covers dates from '
                  '5400 BCE to 5400 CE.\n\n'
                  'The engine takes: birth date, time (in UTC), latitude, and longitude '
                  'as input and computes precise sidereal planetary longitudes.',
            ),

            const SizedBox(height: 20),

            // ─── Ayanamsa ────────────────────────────────────────────
            _sectionHeader('ಅಯನಾಂಶ / Ayanamsa'),
            _calcCard(
              icon: Icons.rotate_right,
              title: 'Tropical → Sidereal Conversion',
              body:
                  'The Swiss Ephemeris returns tropical (Western) longitudes. '
                  'Vedic astrology uses the sidereal zodiac. '
                  'The difference between tropical and sidereal is called Ayanamsa.\n\n'
                  '• Lahiri (Chitrapaksha) — Official Indian government standard. '
                  'Most widely used in India.\n'
                  '• KP (Krishnamurti Paddhati) — A slightly different Ayanamsa '
                  'used in KP astrology system.\n'
                  '• Raman — Developed by B.V. Raman, another popular choice.\n\n'
                  'Sidereal Longitude = Tropical Longitude − Ayanamsa',
            ),

            const SizedBox(height: 20),

            // ─── Kundali (Birth Chart) ─────────────────────────────────
            _sectionHeader('ಕುಂಡಲಿ / Birth Chart'),
            _calcCard(
              icon: Icons.circle_outlined,
              title: 'Graha Sphutas & House Cusps',
              body:
                  'After computing sidereal longitudes, the app places each planet '
                  '(Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Rahu, Ketu, '
                  'Mandi, and Gulika) into its Rashi (sign) and Nakshatra (lunar mansion).\n\n'
                  '📐 House Cusps: Calculated using the Whole Sign house system — '
                  'each house spans exactly one zodiac sign starting from the Lagna (Ascendant).\n\n'
                  '🌙 Rahu & Ketu (Lunar Nodes): The app supports both True Node '
                  '(actual astronomical position) and Mean Node (average position). '
                  'Rahu and Ketu are always 180° apart.\n\n'
                  '⚡ Mandi & Gulika: Calculated from the day\'s sunrise/sunset times '
                  'and the weekday lord sequence using the classical Parashari method.',
            ),

            const SizedBox(height: 20),

            // ─── Panchanga ─────────────────────────────────────────────
            _sectionHeader('ಪಂಚಾಂಗ / Panchanga'),
            _calcCard(
              icon: Icons.calendar_today_outlined,
              title: 'Five Limbs of the Hindu Calendar',
              body:
                  'The Panchanga has five elements, each calculated from the '
                  'Sun and Moon\'s positions:\n\n'
                  '1. ವಾರ (Vara) — Day of the week determined by the lord of the '
                  'hour at sunrise. Each day has a ruling planet.\n\n'
                  '2. ತಿಥಿ (Tithi) — Lunar day. Calculated as the angular distance '
                  'between Sun and Moon divided by 12°. Each 12° = 1 Tithi. '
                  'There are 30 Tithis in a lunar month.\n\n'
                  '3. ನಕ್ಷತ್ರ (Nakshatra) — Lunar mansion. The ecliptic is divided '
                  'into 27 equal segments of 13°20\' each. The Moon\'s position '
                  'determines the current Nakshatra.\n\n'
                  '4. ಯೋಗ (Yoga) — Calculated by adding the sidereal longitudes '
                  'of Sun + Moon, then dividing by 13°20\'. There are 27 Yogas.\n\n'
                  '5. ಕರಣ (Karana) — Half a Tithi (6°). There are 11 types of '
                  'Karanas — 4 fixed and 7 repeating.\n\n'
                  '☀️ Sunrise & Sunset are calculated using the Swiss Ephemeris '
                  'rise/set algorithm for the exact birth coordinates.',
            ),

            const SizedBox(height: 20),

            // ─── Panchanga Events Reference ──────────────────────────────
            _sectionHeader('ಪಂಚಾಂಗ ಹಬ್ಬಗಳ ಆಧಾರ / Panchanga Events Reference'),
            ..._buildEventReference(),

            const SizedBox(height: 20),

            // ─── Dasha ─────────────────────────────────────────────────
            _sectionHeader('ವಿಂಶೋತ್ತರಿ ದಶ / Vimshottari Dasha'),
            _calcCard(
              icon: Icons.timeline_outlined,
              title: 'Planetary Period System',
              body:
                  'Vimshottari Dasha is a 120-year planetary period system based '
                  'on the Moon\'s Nakshatra at birth.\n\n'
                  '🔑 Start Point: The balance of the Dasha at birth is calculated '
                  'from how far the Moon has traversed its birth Nakshatra.\n\n'
                  'Balance = (1 − nakshatra_traversed_fraction) × lord\'s_total_years\n\n'
                  'Dasha Lords and their periods (total 120 years):\n'
                  'Ketu 7 • Venus 20 • Sun 6 • Moon 10 • Mars 7 • Rahu 18 • '
                  'Jupiter 16 • Saturn 19 • Mercury 17\n\n'
                  '📊 Antardasha (sub-periods) are calculated by proportional '
                  'subdivision: each Mahadasha is split into 9 Antardashas '
                  'in the same lord sequence, proportional to period lengths.',
            ),

            const SizedBox(height: 20),

            // ─── Shadbala ──────────────────────────────────────────────
            _sectionHeader('ಷಡ್ಬಲ / Shadbala'),
            _calcCard(
              icon: Icons.bar_chart,
              title: '6-Fold Planetary Strength',
              body:
                  'Shadbala measures the total strength of each planet in 6 categories, '
                  'expressed in Rupas and Shashtiamshas:\n\n'
                  '1. Sthana Bala (ಸ್ಥಾನ ಬಲ) — Positional strength: Uccha (exaltation), '
                  'Saptavargaja (divisional chart placement), Ojayugmarashyamsha, '
                  'Kendradi, and Drekkana strengths.\n\n'
                  '2. Dig Bala (ದಿಗ್ ಬಲ) — Directional strength. Each planet is '
                  'strongest in a specific house quadrant.\n\n'
                  '3. Kala Bala (ಕಾಲ ಬಲ) — Temporal strength: Natonnata (day/night), '
                  'Paksha (lunar fortnight), Tribhaga, Abda, Masa, Vara, Hora, '
                  'Ayana, and Yuddha (planetary war).\n\n'
                  '4. Chesta Bala (ಚೇಷ್ಟ ಬಲ) — Motional strength based on '
                  'retrograde/direct motion and speed.\n\n'
                  '5. Naisargika Bala (ನೈಸರ್ಗಿಕ ಬಲ) — Natural/inherent strength: '
                  'Fixed order: Saturn < Mars < Mercury < Jupiter < Venus < Moon < Sun.\n\n'
                  '6. Drik Bala (ದೃಕ್ ಬಲ) — Aspectual strength from other planets.\n\n'
                  'Minimum required Rupas benchmarks are used to evaluate '
                  'whether each planet meets its strength threshold.',
            ),

            const SizedBox(height: 20),

            // ─── Divisional Charts ─────────────────────────────────────
            _sectionHeader('ವರ್ಗ ಚಕ್ರಗಳು / Divisional Charts'),
            _calcCard(
              icon: Icons.grid_on_outlined,
              title: 'D-1, D-9, D-12 Subdivisions',
              body:
                  'Each planet\'s sign is subdivided into smaller equal segments:\n\n'
                  '• D-1 (Rashi/Lagna chart) — Full 30° of each sign. The primary chart.\n\n'
                  '• D-9 (Navamsha) — Each sign is divided into 9 equal parts of 3°20\'. '
                  'The Navamsha describes the inner nature of the planet and is crucial '
                  'for assessing marriage and dharma.\n\n'
                  '• D-12 (Dwadashamsha) — Each sign is divided into 12 equal parts of '
                  '2°30\'. Used to assess parents and ancestral karma.\n\n'
                  '• D9 of D9 — The Navamsha within the Navamsha, giving a deeper '
                  'sub-divisional reading.',
            ),

            const SizedBox(height: 20),

            // ─── Arudha ──────────────────────────────────────────────
            _sectionHeader('ಆರೂಢ ಲಗ್ನ / Arudha Lagna'),
            _calcCard(
              icon: Icons.account_balance_outlined,
              title: 'Maya & Manifestation',
              body:
                  'The Arudha Lagna represents how the world perceives you — '
                  'the image or Maya you project.\n\n'
                  '📐 Calculation:\n'
                  '1. Count houses from Lagna to its lord.\n'
                  '2. Count the same number of houses from the lord.\n'
                  '3. The resulting house is the Arudha Lagna.\n\n'
                  'Exception: If the result falls in the 1st or 7th house from '
                  'Lagna, move it 10 houses forward (classical Parashari rule).\n\n'
                  'The app calculates Arudhas for all 12 Bhavas (A1–A12) '
                  'using this same method applied to each house lord.',
            ),

            const SizedBox(height: 20),

            // ─── Taranukula ───────────────────────────────────────────
            _sectionHeader('ತಾರಾನುಕೂಲ / Taranukula'),
            _calcCard(
              icon: Icons.star_half_outlined,
              title: 'Star Compatibility from Birth Nakshatra',
              body:
                  'Taranukula evaluates the 27 Nakshatras relative to the '
                  'Janma (birth) Nakshatra using a 9-fold cycle:\n\n'
                  '1. Janma (Birth) — The Nakshatra itself.\n'
                  '2. Sampat (Wealth)\n'
                  '3. Vipat (Danger/Loss)\n'
                  '4. Kshema (Well-being)\n'
                  '5. Pratyak (Obstacle)\n'
                  '6. Sadhana (Achievement)\n'
                  '7. Naidhana (Death/End)\n'
                  '8. Mitra (Friend)\n'
                  '9. Parama Mitra (Best Friend)\n\n'
                  'The cycle repeats every 9 Nakshatras. '
                  'Beneficial: Sampat, Kshema, Sadhana, Mitra, Parama Mitra.\n'
                  'Inauspicious: Vipat, Pratyak, Naidhana.',
            ),

            const SizedBox(height: 20),

            // ─── Melapaka ─────────────────────────────────────────────
            _sectionHeader('ಮೇಳಾಪಕ / Melapaka (Compatibility)'),
            _calcCard(
              icon: Icons.favorite_outline,
              title: '36-Point Marriage Compatibility',
              body:
                  'Melapaka assesses marriage compatibility by comparing '
                  'the Rashi and Nakshatra of two people across 8 Kootas:\n\n'
                  '1. Varna (1 pt) — Spiritual compatibility by caste category.\n'
                  '2. Vashya (2 pt) — Control/dominance relationship between signs.\n'
                  '3. Tara (3 pt) — Star compatibility using the Taranukula cycle.\n'
                  '4. Yoni (4 pt) — Sexual/physical compatibility by animal symbols.\n'
                  '5. Graha Maitri (5 pt) — Friendship between Moon sign lords.\n'
                  '6. Gana (6 pt) — Nature: Deva (divine), Manushya (human), '
                  'Rakshasa (demon).\n'
                  '7. Rashi (7 pt) — Sign compatibility (Bhakuta): '
                  'positive/negative relationships between Rashis.\n'
                  '8. Nadi (8 pt) — Energy channel: Vata, Pitta, Kapha. '
                  'Same Nadi = 0 points (Nadi Dosha).\n\n'
                  'Maximum = 36 points. Score ≥ 18 is considered compatible.',
            ),

            const SizedBox(height: 20),

            // ─── Special Points ───────────────────────────────────────
            _sectionHeader('ಉಪಗ್ರಹಗಳು / Upagrahas & Special Points'),
            _calcCard(
              icon: Icons.workspaces_outline,
              title: 'Mandi, Gulika & 16 Sphutas',
              body:
                  '🔴 Mandi & Gulika: Calculated from sunrise/sunset times and '
                  'the hora (planetary hour) sequence for the day. '
                  'Mandi is the son of Saturn and is considered inauspicious.\n\n'
                  '⭐ Advanced Sphutas (16 points) include:\n'
                  '• Bhava Lagna, Hora Lagna, Ghati Lagna — time-based Lagnas.\n'
                  '• Pushkara Navamsha & Bhaga — auspicious sub-divisions.\n'
                  '• Shree Lagna, Indu Lagna, Pranapada — derived special ascendants.\n'
                  '• Varnada Lagna — used for Varna calculation in Jaimini.\n'
                  '• Yogi, Avayogi, Duplicate Yogi — fortune/misfortune points '
                  'calculated from Sun + Moon longitude + 93°20\'.',
            ),

            const SizedBox(height: 24),
            Divider(color: kBorder),
            const SizedBox(height: 16),

            // ─── Swiss Ephemeris Attribution ───────────────────────────
            _sectionHeader('Swiss Ephemeris — License & Attribution'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This app uses the Swiss Ephemeris by Astrodienst AG, '
                      'Zürich, Switzerland.\n'
                      'Copyright © 1997–2024 Astrodienst AG. '
                      'Swiss Ephemeris is a trademark of Astrodienst AG.\n\n'
                      'Distributed under dual license:\n'
                      '• AGPL v3 (free, open source) — applies here since this app is open source.\n'
                      '• Commercial license — for proprietary/closed-source use.',
                      style: TextStyle(fontSize: 12, color: kText, height: 1.6),
                    ),
                    const SizedBox(height: 10),
                    _linkRow(Icons.open_in_new, 'Swiss Ephemeris Documentation', _seUrl),
                  ]),
            ),

            const SizedBox(height: 16),

            // ─── Open Source Libraries ─────────────────────────────────
            _sectionHeader('Open Source Libraries'),
            const SizedBox(height: 8),
            _libRow('sweph', 'Swiss Ephemeris Dart bindings', 'AGPL v3'),
            _libRow('pdf + printing', 'PDF generation & download', 'Apache 2.0'),
            _libRow('google_mobile_ads', 'AdMob ads', 'Apache 2.0'),
            _libRow('google_sign_in', 'Google authentication', 'BSD'),
            _libRow('in_app_purchase', 'Subscription management', 'BSD'),
            _libRow('share_plus', 'CSV sharing', 'BSD'),

            const SizedBox(height: 24),
            Divider(color: kBorder),
            const SizedBox(height: 16),

            // ─── Source Code (prominent at bottom) ────────────────────


            _sectionHeader('ಅಪ್ ಬಗ್ಗೆ / About the App'),
            _bodyCard(
              'ಭಾರತೀಯಮ್ ಒಂದು ಮುಕ್ತ-ಮೂಲ ವೈದಿಕ ಜ್ಯೋತಿಷ್ಯ ಅಪ್ಲಿಕೇಶನ್ — '
              'ಜನ್ಮಕುಂಡಲಿ, ದಶ, ಪಂಚಾಂಗ, ಷಡ್ಬಲ, ಆರೂಢ, ತಾರಾನುಕೂಲ ಮತ್ತು ಮೇಳಾಪಕ '
              'ಲೆಕ್ಕಾಚಾರಗಳನ್ನು ನಿಖರವಾದ Swiss Ephemeris ಬಳಸಿ ಒದಗಿಸುತ್ತದೆ.\n\n'
              'Bharatheeyam is a free, open-source Vedic Astrology app providing '
              'precise Kundali calculations, Dasha periods, Panchanga, Shadbala, '
              'Arudha Lagna, Taranukula, and Melapaka — all powered by the '
              'globally trusted Swiss Ephemeris engine.',
            ),

            const SizedBox(height: 20),

            _sectionHeader('📂 Source Code'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _launch(_githubUrl),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPurple2, kPurple2.withOpacity(0.6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.code, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('View Source Code',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          Text('github.com/goureesha/bharatheeyamapp',
                              style: TextStyle(
                                  color:
                                      Colors.white.withOpacity(0.8),
                                  fontSize: 12)),
                        ]),
                  ),
                  const Icon(Icons.open_in_new,
                      color: Colors.white, size: 20),
                ]),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                '© 2026 Bharatheeyam  •  AGPL-3.0  •  Built with ❤️ in Karnataka',
                style: TextStyle(fontSize: 11, color: kMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static Widget _sectionHeader(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w900, color: kPurple2)));

  static Widget _bodyCard(String text) => Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder)),
      child: Text(text,
          style: TextStyle(fontSize: 13, color: kText, height: 1.6)));

  static Widget _calcCard(
      {required IconData icon,
      required String title,
      required String body}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: kPurple2, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: kText))),
          ]),
          const SizedBox(height: 10),
          Text(body, style: TextStyle(fontSize: 12.5, color: kText, height: 1.65)),
        ]),
      );

  static Widget _linkRow(IconData icon, String label, String url) =>
      GestureDetector(
        onTap: () => _launch(url),
        child: Row(children: [
          Icon(icon, color: kPurple2, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: kPurple2,
                  fontSize: 12,
                  decoration: TextDecoration.underline)),
        ]),
      );

  static Widget _libRow(String name, String desc, String license) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kBorder)),
        child: Row(children: [
          Expanded(
              flex: 3,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: kText)),
                    Text(desc, style: TextStyle(fontSize: 11, color: kMuted)),
                  ])),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: kPurple2.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4)),
            child: Text(license,
                style: TextStyle(
                    fontSize: 10,
                    color: kPurple2,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static List<Widget> _buildEventReference() {
    // Build all events by creating dummy PanchangData for each month/tithi
    final months = [
      {'name': 'ಚೈತ್ರ', 'tithis': [0, 2, 5, 8, 14, 27]},
      {'name': 'ವೈಶಾಖ', 'tithis': [2, 6, 10, 13, 14]},
      {'name': 'ಜ್ಯೇಷ್ಠ', 'tithis': [10, 14, 27]},
      {'name': 'ಆಷಾಢ', 'tithis': [1, 10, 14, 29]},
      {'name': 'ಶ್ರಾವಣ', 'tithis': [4, 9, 14, 17, 22]},
      {'name': 'ಭಾದ್ರಪದ', 'tithis': [2, 3, 4, 13, 14, 29]},
      {'name': 'ಆಶ್ವಿನ', 'tithis': [0, 4, 6, 7, 8, 9, 28, 29]},
      {'name': 'ಕಾರ್ತಿಕ', 'tithis': [0, 1, 11, 14, 27]},
      {'name': 'ಮಾರ್ಗಶಿರ', 'tithis': [5, 10, 14, 22, 25]},
      {'name': 'ಪುಷ್ಯ', 'tithis': [10, 14, 18, 29]},
      {'name': 'ಮಾಘ', 'tithis': [4, 6, 10, 28]},
      {'name': 'ಫಾಲ್ಗುಣ', 'tithis': [3, 10, 14]},
    ];

    final widgets = <Widget>[];

    for (final m in months) {
      final monthName = m['name'] as String;
      final tithis = m['tithis'] as List<int>;
      final monthEvents = <AstroEvent>[];

      for (final t in tithis) {
        // Create minimal list to extract events
        final events = _getEventsForMasaTithi(monthName, t);
        monthEvents.addAll(events);
      }

      if (monthEvents.isEmpty) continue;

      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text('📅 $monthName ಮಾಸ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kPurple2)),
      ));

      for (final e in monthEvents) {
        widgets.add(Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kText)),
              const SizedBox(height: 4),
              Text(e.description, style: TextStyle(fontSize: 12, color: kMuted)),
              if (e.shloka.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPurple2.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kPurple2.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ಆಧಾರ ಶ್ಲೋಕ:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPurple2)),
                      const SizedBox(height: 2),
                      Text(e.shloka.replaceAll('\\n', '\n'),
                        style: TextStyle(fontStyle: FontStyle.italic, color: kPurple2, fontSize: 12)),
                    ],
                  ),
                ),
              ],
              if (e.meaning.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ನಿಯಮ:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber[800])),
                      const SizedBox(height: 2),
                      Text(e.meaning, style: TextStyle(fontSize: 12, color: kText)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('ಆಕರ: ', style: TextStyle(fontSize: 10, color: kMuted)),
                  Flexible(child: Text(e.source, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kPurple2))),
                ],
              ),
            ],
          ),
        ));
      }
    }

    return widgets;
  }

  /// Extract events for a given masa and tithi index
  static List<AstroEvent> _getEventsForMasaTithi(String masa, int tIdx) {
    // Create a minimal PanchangData to pass to EventCalculator
    final dummy = PanchangData(
      vara: '', tithi: '', nakshatra: '', yoga: '', karana: '',
      chandraRashi: '', udayadiGhati: '', gataGhati: '', paramaGhati: '',
      shesha: '', dashaBalance: '', dashaLord: '',
      nakshatraIndex: 0, nakPercent: 0, sunrise: '', sunset: '',
      tithiIndex: tIdx, chandraMasaRaw: masa, chandraMasa: masa,
    );
    return EventCalculator.getEventsForPanchang(dummy);
  }
}
