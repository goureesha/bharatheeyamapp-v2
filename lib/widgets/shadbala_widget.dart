import 'package:flutter/material.dart';
import 'common.dart';

class ShadbalaWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> shadbala;

  const ShadbalaWidget({super.key, required this.shadbala});

  @override
  Widget build(BuildContext context) {
    if (shadbala.isEmpty) {
      return Center(child: Text(AppLocale.l('shadbalNoData') + ' (Shadbala Data Not Available)'));
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocale.l('shadbala')} (Shadbala - Six-fold Strength)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kOrange2),
                ),
                SizedBox(height: 6),
                Text(
                  AppLocale.l('shadbalDesc'),
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
                  columnSpacing: 16,
                  horizontalMargin: 12,
                  columns: [
                    DataColumn(label: Text(AppLocale.l('graha'), style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocale.l('sthana'), style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocale.l('dik'), style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocale.l('kaala'), style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocale.l('cheshta'), style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocale.l('naisargika'), style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocale.l('drik'), style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocale.l('ottu'), style: TextStyle(fontWeight: FontWeight.w900, color: kPurple2))),
                    DataColumn(label: Text(AppLocale.l('arhate'), style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocale.l('phalitamsha'), style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(pKeysEng.length, (i) {
                    final eKey = pKeysEng[i];
                    final kKey = pKeysKn[i];
                    final data = shadbala[eKey] ?? {};
                    
                    final isStrong = data['IsStrong'] ?? false;
                    final totalVal = data['Total'] ?? 0.0;
                    final reqVal = data['Required'] ?? 0.0;

                    return DataRow(
                      cells: [
                        DataCell(Text(tr(kKey), style: TextStyle(fontWeight: FontWeight.bold, color: kPurple2))),
                        DataCell(Text((data['Sthana'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Dik'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Kala'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Cheshta'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Naisargika'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text((data['Drik'] ?? 0.0).toStringAsFixed(2))),
                        DataCell(Text(totalVal.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.w900))),
                        DataCell(Text(reqVal.toStringAsFixed(1), style: TextStyle(color: kMuted))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isStrong ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isStrong ? AppLocale.l('balashali') : AppLocale.l('durbala'),
                              style: TextStyle(
                                color: isStrong ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
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
