import 'package:flutter/material.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';
import '../core/match_making.dart';

class MatchMakingTab extends StatefulWidget {
  const MatchMakingTab({super.key});

  @override
  State<MatchMakingTab> createState() => _MatchMakingTabState();
}

class _MatchMakingTabState extends State<MatchMakingTab> {
  int? _bNak;
  int? _bRashi;
  int? _gNak;
  int? _gRashi;

  Map<String, dynamic>? _result;

  static const Map<int, List<int>> _rashiNakMap = {
    0: [0, 1, 2],       // Mesha: Ashwini, Bharani, Krittika
    1: [2, 3, 4],       // Vrishabha: Krittika, Rohini, Mrigashira
    2: [4, 5, 6],       // Mithuna: Mrigashira, Ardra, Punarvasu
    3: [6, 7, 8],       // Karka: Punarvasu, Pushya, Ashlesha
    4: [9, 10, 11],     // Simha: Magha, Purva Phalguni, Uttara Phalguni
    5: [11, 12, 13],    // Kanya: Uttara Phalguni, Hasta, Chitra
    6: [13, 14, 15],    // Tula: Chitra, Swati, Vishakha
    7: [15, 16, 17],    // Vrischika: Vishakha, Anuradha, Jyeshtha
    8: [18, 19, 20],    // Dhanu: Mula, Purva Ashadha, Uttara Ashadha
    9: [20, 21, 22],    // Makara: Uttara Ashadha, Shravana, Dhanishta
    10: [22, 23, 24],   // Kumbha: Dhanishta, Shatabhisha, Purva Bhadrapada
    11: [24, 25, 26],   // Meena: Purva Bhadrapada, Uttara Bhadrapada, Revati
  };

  void _calculateMatch() {
    if (_bNak == null || _bRashi == null || _gNak == null || _gRashi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ದಯವಿಟ್ಟು ವಧು ಮತ್ತು ವರರ ಎಲ್ಲಾ ವಿವರಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ')),
      );
      return;
    }

    setState(() {
      _result = MatchMakingLogic.calculateCompatibility(_bRashi!, _bNak!, _gRashi!, _gNak!);
    });
  }

  Widget _buildDropdown(String label, int? value, List<String> allItems, List<int> allowedIndices, ValueChanged<int?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: kCard,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              hint: Text('ಆಯ್ಕೆಮಾಡಿ', style: TextStyle(fontSize: 14)),
              value: (allowedIndices.contains(value)) ? value : null,
              items: allowedIndices.map((i) => DropdownMenuItem<int>(
                value: i,
                child: Text(allItems[i], style: TextStyle(fontSize: 14)),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultTable() {
    if (_result == null) return const SizedBox.shrink();

    final total = _result!['total'] as double;
    
    // Verdict logic
    String verdict;
    Color verdictColor;
    if (total <= 18) {
      verdict = 'ಹೊಂದಾಣಿಕೆ ಉತ್ತಮವಾಗಿಲ್ಲ';
      verdictColor = Colors.red.shade700;
    } else if (total <= 25) {
      verdict = 'ಹೊಂದಾಣಿಕೆ ಮಧ್ಯಮವಾಗಿದೆ';
      verdictColor = Colors.orange.shade700;
    } else {
      verdict = 'ಹೊಂದಾಣಿಕೆ ತುಂಬಾ ಉತ್ತಮವಾಗಿದೆ';
      verdictColor = Colors.green.shade700;
    }

    TableRow row(String name, double pts, int max) {
      return TableRow(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(name, style: TextStyle(fontWeight: FontWeight.w600))),
          Padding(padding: const EdgeInsets.all(12), child: Text(pts.toStringAsFixed(1), textAlign: TextAlign.center)),
          Padding(padding: const EdgeInsets.all(12), child: Text(max.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
        ],
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ಅಷ್ಟಕೂಟ ಗುಣ ಮಿಲನ ಫಲಿತಾಂಶ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPurple1), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
               0: FlexColumnWidth(2),
               1: FlexColumnWidth(1),
               2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                children: const [
                  Padding(padding: EdgeInsets.all(12), child: Text('ಕೂಟ', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(12), child: Text('ಪಡೆದ\nಗುಣ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(12), child: Text('ಗರಿಷ್ಠ\nಗುಣ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              row('೧. ವರ್ಣ', _result!['varna'], 1),
              row('೨. ವಶ್ಯ', _result!['vashya'], 2),
              row('೩. ತಾರಾ', _result!['tara'], 3),
              row('೪. ಯೋನಿ', _result!['yoni'], 4),
              row('೫. ಗ್ರಹ ಮೈತ್ರಿ', _result!['graha'], 5),
              row('೬. ಗಣ', _result!['gana'], 6),
              row('೭. ಭಕ್ಕೂಟ (ರಾಶಿ)', _result!['bhakoot'], 7),
              row('೮. ನಾಡಿ', _result!['nadi'], 8),
              TableRow(
                decoration: BoxDecoration(color: kPurple1.withOpacity(0.05)),
                children: [
                  Padding(padding: EdgeInsets.all(12), child: Text('ಒಟ್ಟು ಗುಣ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Padding(padding: const EdgeInsets.all(12), child: Text(total.toStringAsFixed(1), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPurple1))),
                  Padding(padding: EdgeInsets.all(12), child: Text('36', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
             padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
             decoration: BoxDecoration(
               color: verdictColor.withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: verdictColor.withOpacity(0.3)),
             ),
             child: Column(
               children: [
                 Text('ಫಲಿತಾಂಶ:', style: TextStyle(fontSize: 14, color: verdictColor, fontWeight: FontWeight.w600)),
                 const SizedBox(height: 4),
                 Text(
                   verdict, 
                   textAlign: TextAlign.center,
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: verdictColor)
                 ),
               ],
             ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('ವಧುವಿನ ವಿವರಗಳು', color: kOrange),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdown('ರಾಶಿ', _bRashi, knRashi, List.generate(12, (i) => i), (v) {
                       setState(() { _bRashi = v; if (v != null && !_rashiNakMap[v]!.contains(_bNak)) _bNak = null; });
                    })),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdown('ನಕ್ಷತ್ರ', _bNak, knNak, _bRashi != null ? _rashiNakMap[_bRashi]! : List.generate(27, (i) => i), (v) => setState(() => _bNak = v))),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(),
                const SizedBox(height: 8),
                SectionTitle('ವರನ ವಿವರಗಳು', color: kTeal),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdown('ರಾಶಿ', _gRashi, knRashi, List.generate(12, (i) => i), (v) {
                       setState(() { _gRashi = v; if (v != null && !_rashiNakMap[v]!.contains(_gNak)) _gNak = null; });
                    })),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdown('ನಕ್ಷತ್ರ', _gNak, knNak, _gRashi != null ? _rashiNakMap[_gRashi]! : List.generate(27, (i) => i), (v) => setState(() => _gNak = v))),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculateMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple1,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('ಹೊಂದಾಣಿಕೆ ಪರೀಕ್ಷಿಸಿ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          _buildResultTable(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
