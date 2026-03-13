import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _githubUrl =
      'https://github.com/goureesha/bharatheeyamapp';

  static const _seUrl =
      'https://www.astro.com/swisseph/swephprg.htm';

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
            // ─── App identity ────────────────────────────────────────
            Center(
              child: Column(children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: kPurple2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.stars_rounded,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 12),
                Text('ಭಾರತೀಯಮ್',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: kPurple2)),
                const SizedBox(height: 4),
                Text('Bharatheeyam — Vedic Astrology',
                    style: TextStyle(fontSize: 14, color: kMuted)),
                Text('Version 1.0.1',
                    style: TextStyle(fontSize: 12, color: kMuted)),
              ]),
            ),

            const SizedBox(height: 24),

            // ─── Description ─────────────────────────────────────────
            _card(
              column: true,
              children: [
                _sectionTitle('ಅಪ್ ಬಗ್ಗೆ'),
                const SizedBox(height: 8),
                Text(
                  'ಭಾರತೀಯಮ್ ಒಂದು ಮುಕ್ತ-ಮೂಲ ವೈದಿಕ ಜ್ಯೋತಿಷ್ಯ ಅಪ್ಲಿಕೇಶನ್. '
                  'ಜನ್ಮಕುಂಡಲಿ, ದಶ, ಪಂಚಾಂಗ, ಷಡ್ಬಲ ಮತ್ತು ಮೇಳಾಪಕ ಲೆಕ್ಕಾಚಾರಗಳನ್ನು '
                  'ನಿಖರವಾದ Swiss Ephemeris ಮೂಲಕ ಒದಗಿಸುತ್ತದೆ.',
                  style: TextStyle(fontSize: 13, color: kText, height: 1.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'This is a free, open-source Vedic Astrology app for Kundali / '
                  'Jataka calculations including Dasha, Panchanga, Shadbala, '
                  'and Mela calculations powered by the Swiss Ephemeris.',
                  style: TextStyle(fontSize: 13, color: kText, height: 1.6),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ─── Source code ─────────────────────────────────────────
            _card(
              children: [
                Icon(Icons.code, color: kPurple2, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Source Code',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: kText,
                                fontSize: 14)),
                        Text('github.com/goureesha/bharatheeyamapp',
                            style: TextStyle(
                                color: kPurple2, fontSize: 12)),
                      ]),
                ),
                IconButton(
                  icon: Icon(Icons.open_in_new, color: kPurple2),
                  onPressed: () => _launch(_githubUrl),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── Swiss Ephemeris License ──────────────────────────────
            _sectionTitle('Swiss Ephemeris — Open Source License'),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This application uses the Swiss Ephemeris, '
                    'a precision ephemeris developed by Astrodienst AG, Zürich, Switzerland.',
                    style: TextStyle(
                        fontSize: 12, color: kText, height: 1.6),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Swiss Ephemeris is distributed under the following dual license:',
                    style: TextStyle(
                        fontSize: 12, color: kText, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _licPoint('1.',
                      'GNU Affero General Public License (AGPL v3): '
                      'Free to use as long as the software using it is also '
                      'released as open source under AGPL. '
                      'Since Bharatheeyam is open source on GitHub, this license applies.'),
                  _licPoint('2.',
                      'Commercial License: Available from Astrodienst AG '
                      'for proprietary/closed-source use.'),
                  const SizedBox(height: 10),
                  Text(
                    'Copyright © 1997–2024 Astrodienst AG, Switzerland.\n'
                    'Swiss Ephemeris is a trademark of Astrodienst AG.',
                    style: TextStyle(
                        fontSize: 11, color: kMuted, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _launch(_seUrl),
                    child: Text(
                      'Swiss Ephemeris Documentation →',
                      style: TextStyle(
                          color: kPurple2,
                          fontSize: 12,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Open Source Libraries ────────────────────────────────
            _sectionTitle('Open Source Libraries Used'),
            const SizedBox(height: 8),
            _libRow('sweph', 'Swiss Ephemeris Dart bindings', 'AGPL v3'),
            _libRow('pdf / printing', 'PDF generation', 'Apache 2.0'),
            _libRow('google_mobile_ads', 'AdMob ads', 'Apache 2.0'),
            _libRow('google_sign_in', 'Google authentication', 'BSD'),
            _libRow('googleapis', 'Sheets, Docs, Calendar', 'BSD'),
            _libRow('in_app_purchase', 'Subscription management', 'BSD'),
            _libRow('share_plus', 'CSV sharing', 'BSD'),

            const SizedBox(height: 24),

            // ─── License notice ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPurple2.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPurple2.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.balance, color: kPurple2, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bharatheeyam is released under the GNU Affero General Public License v3 (AGPL-3.0). '
                    'You are free to use, study, modify, and distribute it under the same terms.',
                    style: TextStyle(
                        fontSize: 11, color: kText, height: 1.5),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 32),

            Center(
              child: Text(
                '© 2026 Bharatheeyam. Built with ❤️ in Karnataka, India.',
                style: TextStyle(fontSize: 11, color: kMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static Widget _sectionTitle(String t) => Text(t,
      style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, color: kPurple2));

  static Widget _card(
      {required List<Widget> children, bool column = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: column
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children)
          : Row(children: children),
    );
  }

  static Widget _licPoint(String num, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$num ', style: TextStyle(color: kPurple2, fontWeight: FontWeight.bold, fontSize: 12)),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: kText, height: 1.5))),
      ]));

  static Widget _libRow(String name, String desc, String license) => Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kBorder)),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12, color: kText)),
              Text(desc, style: TextStyle(fontSize: 11, color: kMuted)),
            ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: kPurple2.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4)),
            child: Text(license,
                style: TextStyle(
                    fontSize: 10,
                    color: kPurple2,
                    fontWeight: FontWeight.w600))),
      ]));

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
