import 'package:flutter/material.dart';
import '../widgets/common.dart';

class PlanetDetailSheet extends StatelessWidget {
  final String pName;
  final Map<String, dynamic> detail;

  const PlanetDetailSheet({super.key, required this.pName, required this.detail});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('ಗ್ರಹದ ಸಂಪೂರ್ಣ ವಿವರ — $pName',
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: kPurple2)),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _section('📌 ಮೂಲ ವಿವರ', [
                    ['ಸ್ಫುಟ',  detail['degFmt']],
                    ['ಗತಿ',   detail['gati']],
                    ['ಅಸ್ತ',  detail['isAsta'] == true ? 'ಹೌದು' : (detail['isAsta'] == false ? 'ಇಲ್ಲ' : 'ಅನ್ವಯಿಸುವುದಿಲ್ಲ')],
                  ]),
                  const SizedBox(height: 8),
                  _section('📊 ವರ್ಗಗಳು', [
                    ['ರಾಶಿ',      detail['d1']],
                    ['ಹೋರಾ',     detail['d2']],
                    ['ದ್ರೇಕ್ಕಾಣ', detail['d3']],
                    ['ನವಾಂಶ',    detail['d9']],
                    ['ದ್ವಾದಶಾಂಶ',detail['d12']],
                    ['ತ್ರಿಂಶಾಂಶ',detail['d30']],
                  ]),
                  const SizedBox(height: 8),
                  _section('🧩 ಉಪ-ವಿಭಾಗಗಳು', [
                    ['ರಾಶಿ ದ್ರೇಕ್ಕಾಣ', detail['subDrekD1']],
                    ['ನವಾಂಶ ದ್ರೇಕ್ಕಾಣ', detail['subDrekD9']],
                    ['ದ್ವಾದಶಾಂಶ ದ್ರೇಕ್ಕಾಣ', detail['subDrekD12']],
                    ['ನವ-ನವಾಂಶ', detail['d9OfD9']],
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<List<String>> rows) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(title, style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF2B6CB0))),
          ),
          ...rows.map((r) => Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: kBorder))),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Text(r[0], style: TextStyle(
                fontWeight: FontWeight.w700, color: const Color(0xFF4A5568))),
              const Spacer(),
              Text(r[1], style: TextStyle(fontWeight: FontWeight.w700)),
            ]),
          )),
        ],
      ),
    );
  }
}
