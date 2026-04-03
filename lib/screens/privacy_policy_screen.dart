import 'package:flutter/material.dart';
import '../widgets/common.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಗೌಪ್ಯತಾ ನೀತಿ / Privacy Policy',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header('ಭಾರತೀಯಮ್ - ಗೌಪ್ಯತಾ ನೀತಿ'),
            _meta('ಕೊನೆಯ ನವೀಕರಣ: ಮಾರ್ಚ್ 2026'),
            const SizedBox(height: 16),

            // ─── Kannada Section ─────────────────────────────────────
            _section('1. ಪರಿಚಯ'),
            _body(
              'ಭಾರತೀಯಮ್ ಅಪ್ಲಿಕೇಶನ್‌ಗೆ ಸ್ವಾಗತ. ನಿಮ್ಮ ಗೌಪ್ಯತೆ ನಮಗೆ ಮುಖ್ಯ. '
              'ಈ ನೀತಿಯು ನಾವು ಯಾವ ಮಾಹಿತಿಯನ್ನು ಸಂಗ್ರಹಿಸುತ್ತೇವೆ, '
              'ಅದನ್ನು ಹೇಗೆ ಬಳಸುತ್ತೇವೆ ಮತ್ತು ಹೇಗೆ ರಕ್ಷಿಸುತ್ತೇವೆ ಎಂದು ವಿವರಿಸುತ್ತದೆ.',
            ),
            const SizedBox(height: 12),

            _section('2. ಸಂಗ್ರಹಿಸುವ ಮಾಹಿತಿ'),
            _body('ಅಪ್ ಈ ಕೆಳಗಿನ ಮಾಹಿತಿಯನ್ನು ಮಾತ್ರ ಸಂಗ್ರಹಿಸುತ್ತದೆ:'),
            _bullet('ಜಾತಕ ದತ್ತಾಂಶ: ಹೆಸರು, ಜನ್ಮ ದಿನಾಂಕ, ಸಮಯ ಮತ್ತು ಸ್ಥಳ — ಇವು ನಿಮ್ಮ ಸಾಧನದಲ್ಲೇ ಸಂಗ್ರಹವಾಗುತ್ತವೆ.'),
            _bullet('Google ಖಾತೆ ಮಾಹಿತಿ: ನೀವು Google ಸೈನ್ ಇನ್ ಮಾಡಿದರೆ, ನಿಮ್ಮ ಹೆಸರು ಮತ್ತು ಇಮೇಲ್ ಮಾತ್ರ ಬಳಕೆಯಾಗುತ್ತದೆ.'),
            _bullet('ಜ್ಯೋತಿಷ್ಯ ಫಲಿತಾಂಶಗಳು: ಸ್ಥಳೀಯ ಸಂಗ್ರಹ ಮಾಡಲ್ಪಡುತ್ತವೆ. Google ಸಿಂಕ್ ಆಯ್ಕೆಮಾಡಿದರೆ ನಿಮ್ಮ ಕ್ಲೌಡ್ ಬ್ಯಾಕಪ್‌ಗೆ ಮಾತ್ರ ಹೋಗುತ್ತದೆ.'),
            const SizedBox(height: 12),

            _section('3. ಮಾಹಿತಿ ಬಳಕೆ'),
            _body('ನಿಮ್ಮ ಮಾಹಿತಿ ಹೇಗೆ ಬಳಸಲಾಗುತ್ತದೆ:'),
            _bullet('ಜಾತಕ ಲೆಕ್ಕಾಚಾರ ಮತ್ತು ಪ್ರದರ್ಶನಕ್ಕೆ'),
            _bullet('ಐಚ್ಛಿಕ ಡೇಟಾ ಬ್ಯಾಕಪ್ ಸಿಂಕ್‌ಗೆ'),
            _bullet('ಅಪ್ ಕಾರ್ಯಕ್ಷಮತೆ ಸುಧಾರಿಸಲು'),
            const SizedBox(height: 12),

            _section('4. ಮಾಹಿತಿ ಹಂಚಿಕೆ'),
            _body('ನಾವು ನಿಮ್ಮ ಯಾವುದೇ ವ್ಯಕ್ತಿಗತ ಮಾಹಿತಿಯನ್ನು ತೃತೀಯ ಪಕ್ಷಕ್ಕೆ ಮಾರಾಟ ಮಾಡುವುದಿಲ್ಲ ಅಥವಾ ಹಂಚಿಕೊಳ್ಳುವುದಿಲ್ಲ.'),
            const SizedBox(height: 12),

            _section('5. Google ಸೇವೆಗಳು'),
            _body(
              'ಆಯ್ಕೆ ಮಾಡಿದರೆ, ಅಪ್ ಇವುಗಳನ್ನು ಬಳಸಬಹುದು: Google Sign-In ಮತ್ತು ಕ್ಲೌಡ್ ಬ್ಯಾಕಪ್. '
              'ಈ ಸೇವೆಗಳಿಗೆ Google ನ ಗೌಪ್ಯತಾ ನೀತಿ ಅನ್ವಯಿಸುತ್ತದೆ: '
              'https://policies.google.com/privacy',
            ),
            const SizedBox(height: 12),



            _section('7. ಡೇಟಾ ಸುರಕ್ಷತೆ'),
            _body(
              'ಎಲ್ಲಾ ಜಾತಕ ದತ್ತಾಂಶ ನಿಮ್ಮ ಸಾಧನದಲ್ಲೇ ಸ್ಥಳೀಯವಾಗಿ ಸಂಗ್ರಹವಾಗುತ್ತದೆ. '
              'ನಾವು ಯಾವುದೇ ಕೇಂದ್ರ ಸರ್ವರ್‌ನಲ್ಲಿ ನಿಮ್ಮ ದತ್ತಾಂಶ ಸಂಗ್ರಹಿಸುವುದಿಲ್ಲ.',
            ),
            const SizedBox(height: 12),

            _section('8. ನಿಮ್ಮ ಹಕ್ಕುಗಳು'),
            _bullet('ಅಪ್ ಅನ್ನು ಅನ್ಇನ್ಸ್ಟಾಲ್ ಮಾಡುವ ಮೂಲಕ ನಿಮ್ಮ ಎಲ್ಲಾ ಸ್ಥಳೀಯ ದತ್ತಾಂಶ ಅಳಿಸಬಹುದು.'),
            _bullet('Settings ನಲ್ಲಿ Google Sign Out ಮೂಲಕ Google ಸಂಪರ್ಕ ಕಡಿದುಕೊಳ್ಳಬಹುದು.'),
            const SizedBox(height: 24),

            // ─── Divider ──────────────────────────────────────────────
            Divider(color: kBorder, thickness: 1),
            const SizedBox(height: 16),

            // ─── English Section ──────────────────────────────────────
            _header('Privacy Policy — English'),
            _meta('Last Updated: March 2026'),
            const SizedBox(height: 16),

            _section('1. Introduction'),
            _body(
              'Welcome to Bharatheeyam — a Vedic Astrology (Kundali) application. '
              'This Privacy Policy explains how we collect, use, and protect your information.',
            ),
            const SizedBox(height: 12),

            _section('2. Information We Collect'),
            _bullet('Kundali Data: Name, date of birth, time, and place — stored LOCALLY on your device only.'),
            _bullet('Google Account: If you use Google Sign-In, only your name and email are accessed.'),
            _bullet('Astrological Results: Stored locally. If Google Sync is enabled, data goes only to your private Cloud Backup.'),
            const SizedBox(height: 12),

            _section('3. How We Use Information'),
            _bullet('To calculate and display astrological charts'),
            _bullet('Optional data backup sync'),
            _bullet('To improve app performance'),
            const SizedBox(height: 12),

            _section('4. Data Sharing'),
            _body('We do NOT sell or share your personal information with any third party.'),
            const SizedBox(height: 12),

            _section('5. Google Services'),
            _body(
              'If enabled, the app uses Google Sign-In and cloud backup. '
              'Google\'s Privacy Policy applies: https://policies.google.com/privacy',
            ),
            const SizedBox(height: 12),



            _section('7. Data Security'),
            _body(
              'All Kundali data is stored locally on your device. '
              'We do NOT store any of your data on a central server.',
            ),
            const SizedBox(height: 12),

            _section('8. Your Rights'),
            _bullet('Uninstall the app to delete all local data.'),
            _bullet('Use Settings → Sign Out to disconnect your Google account.'),
            const SizedBox(height: 12),

            _section('9. Children\'s Privacy'),
            _body('This app is not directed to children under 13. We do not knowingly collect data from children.'),
            const SizedBox(height: 12),

            _section('10. Contact Us'),
            _body('For privacy questions, contact us at: bharatheeyam@app.com'),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _header(String text) => Text(text,
      style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w900, color: kPurple2));

  static Widget _meta(String text) => Text(text,
      style: TextStyle(fontSize: 12, color: kMuted));

  static Widget _section(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: kPurple2)));

  static Widget _body(String text) => Text(text,
      style: TextStyle(fontSize: 13, color: kText, height: 1.5));

  static Widget _bullet(String text) => Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('• ', style: TextStyle(color: kPurple2, fontWeight: FontWeight.bold)),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: kText, height: 1.5))),
      ]));
}
