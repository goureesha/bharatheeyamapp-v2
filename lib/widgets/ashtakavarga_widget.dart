import 'package:flutter/material.dart';
import '../constants/strings.dart';
import 'common.dart';
import 'kundali_chart.dart';

class AshtakavargaWidget extends StatelessWidget {
  final List<int> savBindus;
  final Map<String, List<int>> bavBindus;

  const AshtakavargaWidget({super.key, required this.savBindus, required this.bavBindus});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SectionTitle('ಸರ್ವಾಷ್ಟಕವರ್ಗ (SAV)', color: kOrange),
          _SavGrid(savBindus: savBindus),
          SectionTitle('📝 ಬಿನ್ನಾಷ್ಟಕವರ್ಗ (BAV)', color: const Color(0xFF2B6CB0)),
          _BavTable(savBindus: savBindus, bavBindus: bavBindus),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SavGrid extends StatelessWidget {
  final List<int> savBindus;
  const _SavGrid({required this.savBindus});

  static const List<int?> _grid = [
    11, 0, 1, 2, 10, null, null, 3, 9, null, null, 4, 8, 7, 6, 5,
  ];

  @override
  Widget build(BuildContext context) {
    bool centerDone = false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(3),
          child: GridView.count(
            crossAxisCount: 4,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            children: _grid.map((idx) {
              if (idx == null) {
                if (!centerDone) {
                  centerDone = true;
                  return _centerBox(savBindus.fold(0, (a, b) => a + b));
                }
                return const SizedBox.shrink();
              }
              return _rashiBox(idx, savBindus[idx]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _rashiBox(int idx, int bindu) {
    return Container(
      margin: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E0), width: 1.0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3, top: 2),
            child: Text(knRashi[idx],
              style: const TextStyle(fontSize: 11, color: Color(0xFF2F855A), fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: Center(
              child: Text(bindu.toString(),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFDD6B20))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerBox(int total) {
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EC),
        border: Border.all(color: const Color(0xFFDD6B20), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('ಒಟ್ಟು', style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFDD6B20),
          letterSpacing: 1.2)),
        Text(total.toString(), style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFE53E3E))),
      ]),
    );
  }
}

class _BavTable extends StatelessWidget {
  final List<int> savBindus;
  final Map<String, List<int>> bavBindus;
  static const _planets = ['ರವಿ','ಚಂದ್ರ','ಕುಜ','ಬುಧ','ಗುರು','ಶುಕ್ರ','ಶನಿ'];
  static const _short   = ['ರ','ಚಂ','ಕು','ಬು','ಗು','ಶು','ಶ'];

  const _BavTable({required this.savBindus, required this.bavBindus});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AppCard(
          padding: EdgeInsets.zero,
          child: DataTable(
            columnSpacing: 10,
            horizontalMargin: 10,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFEDF2F7)),
            columns: [
              DataColumn(label: Text('ರಾಶಿ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
              ..._short.map((s) => DataColumn(label: Text(s, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)))),
              DataColumn(label: Text('ಒಟ್ಟು', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
            ],
            rows: List.generate(12, (i) {
              return DataRow(cells: [
                DataCell(Text(knRashi[i], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                ..._planets.map((p) {
                  final v = bavBindus[p]?[i] ?? 0;
                  return DataCell(Text(v.toString(), style: TextStyle(fontSize: 11)));
                }),
                DataCell(Text(savBindus[i].toString(),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: const Color(0xFFE53E3E)))),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
