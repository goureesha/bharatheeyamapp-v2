import 'package:flutter/material.dart';
import 'common.dart';

class ShadbalaWidget extends StatelessWidget {
  final Map<String, Map<String, double>> shadbala;

  const ShadbalaWidget({super.key, required this.shadbala});

  @override
  Widget build(BuildContext context) {
    if (shadbala.isEmpty) {
      return const Center(child: Text('ಷಡ್ಬಲ ಡೇಟಾ ಲಭ್ಯವಿಲ್ಲ (Shadbala Data Not Available)'));
    }

    final pKeysEng = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'];
    final pKeysKn = ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kOrange.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ಷಡ್ಬಲ (Shadbala - Six-fold Strength)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kOrange2),
                ),
                SizedBox(height: 6),
                Text(
                  'ಗ್ರಹಗಳ ೬ ಬಗೆಯ ಬಲಗಳನ್ನು ರೂಪಗಳಲ್ಲಿ (Rupas) ನೀಡಲಾಗಿದೆ. 1 ರೂಪ = 60 ಷಷ್ಟ್ಯಾಂಶ (Shashtiamsas). ಒಟ್ಟು ಬಲವು ಗ್ರಹದ ನೈಜ ಶಕ್ತಿಯನ್ನು ಸೂಚಿಸುತ್ತದೆ.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: kText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(kPurple1.withOpacity(0.1)),
                  columnSpacing: 20,
                  horizontalMargin: 16,
                  columns: const [
                    DataColumn(label: Text('ಗ್ರಹ\nPlanet', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ಸ್ಥಾನ\nSthana', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ದಿಕ್\nDik', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ಕಾಲ\nKala', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ಚೇಷ್ಟಾ\nCheshta', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ನೈಸರ್ಗಿಕ\nNaisargika', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ದೃಕ್\nDrik', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ಒಟ್ಟು\nTotal', style: TextStyle(fontWeight: FontWeight.w900, color: kPurple2))),
                  ],
                  rows: List.generate(pKeysEng.length, (i) {
                    final eKey = pKeysEng[i];
                    final kKey = pKeysKn[i];
                    final data = shadbala[eKey] ?? {};

                    return DataRow(
                      cells: [
                        DataCell(Text(kKey, style: const TextStyle(fontWeight: FontWeight.bold, color: kPurple2))),
                        DataCell(Text((data['Sthana'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Dik'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Kala'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Cheshta'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Naisargika'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Drik'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Total'] ?? 0.0).toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900))),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
