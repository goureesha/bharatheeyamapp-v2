import 'package:flutter/material.dart';
import '../widgets/common.dart';


class MantraSangrahaScreen extends StatelessWidget {
  const MantraSangrahaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಮಂತ್ರ ಸಂಗ್ರಹ / Mantra Sangraha',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Center(
                    child: Column(children: [
                      Icon(Icons.menu_book_rounded, size: 64, color: kTeal),
                      const SizedBox(height: 12),
                      Text('ಮಂತ್ರ ಸಂಗ್ರಹ', style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900, color: kPurple2)),
                      const SizedBox(height: 4),
                      Text('Sacred Mantra Collection', style: TextStyle(
                        fontSize: 13, color: kMuted)),
                      const SizedBox(height: 24),
                    ]),
                  ),

                  // Coming soon sections
                  _mantraSection(
                    icon: Icons.self_improvement,
                    title: 'ನವಗ್ರಹ ಮಂತ್ರ',
                    subtitle: 'Navagraha Mantras',
                    description: 'ಒಂಬತ್ತು ಗ್ರಹಗಳ ಮಂತ್ರಗಳು ಮತ್ತು ಸ್ತೋತ್ರಗಳು',
                  ),
                  _mantraSection(
                    icon: Icons.temple_hindu,
                    title: 'ಗಣಪತಿ ಮಂತ್ರ',
                    subtitle: 'Ganapati Mantras',
                    description: 'ಶ್ರೀ ಗಣೇಶನ ಮಂತ್ರಗಳು ಮತ್ತು ಸ್ತೋತ್ರಗಳು',
                  ),
                  _mantraSection(
                    icon: Icons.brightness_7,
                    title: 'ಸೂರ್ಯ ಮಂತ್ರ',
                    subtitle: 'Surya Mantras',
                    description: 'ಆದಿತ್ಯ ಹೃದಯ ಮತ್ತು ಸೂರ್ಯ ನಮಸ್ಕಾರ ಮಂತ್ರಗಳು',
                  ),
                  _mantraSection(
                    icon: Icons.nightlight_round,
                    title: 'ಚಂದ್ರ ಮಂತ್ರ',
                    subtitle: 'Chandra Mantras',
                    description: 'ಚಂದ್ರ ದೇವರ ಮಂತ್ರಗಳು ಮತ್ತು ಸ್ತೋತ್ರಗಳು',
                  ),
                  _mantraSection(
                    icon: Icons.spa,
                    title: 'ಶಾಂತಿ ಮಂತ್ರ',
                    subtitle: 'Shanti Mantras',
                    description: 'ಶಾಂತಿ ಮತ್ತು ಧ್ಯಾನ ಮಂತ್ರಗಳು',
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kTeal.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Icon(Icons.update, color: kTeal, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        'ಹೊಸ ಮಂತ್ರಗಳು ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿವೆ!\nNew mantras coming soon!',
                        style: TextStyle(fontSize: 13, color: kText, height: 1.4),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _mantraSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kOrange, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
                  Text(subtitle, style: TextStyle(
                    fontSize: 11, color: kMuted)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(
                    fontSize: 12, color: kText, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.lock_outline, color: kMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
