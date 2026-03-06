import 'package:flutter/material.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';
import '../core/match_making.dart';

class MatchMakingScreen extends StatefulWidget {
  const MatchMakingScreen({super.key});

  @override
  State<MatchMakingScreen> createState() => _MatchMakingScreenState();
}

class _MatchMakingScreenState extends State<MatchMakingScreen> {
  int? _bNak;
  int? _bRashi;
  int? _gNak;
  int? _gRashi;

  Map<String, dynamic>? _result;

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

  Widget _buildDropdown(String label, int? value, List<String> items, ValueChanged<int?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              hint: const Text('ಆಯ್ಕೆಮಾಡಿ', style: TextStyle(fontSize: 14)),
              value: value,
              items: List.generate(items.length, (i) => DropdownMenuItem<int>(
                value: i,
                child: Text(items[i], style: const TextStyle(fontSize: 14)),
              )),
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
          Padding(padding: const EdgeInsets.all(12), child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
          Padding(padding: const EdgeInsets.all(12), child: Text(pts.toStringAsFixed(1), textAlign: TextAlign.center)),
          Padding(padding: const EdgeInsets.all(12), child: Text(max.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))),
        ],
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ಅಷ್ಟಕೂಟ ಗುಣ ಮಿಲನ ಫಲಿತಾಂಶ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPurple1), textAlign: TextAlign.center),
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
                  const Padding(padding: EdgeInsets.all(12), child: Text('ಒಟ್ಟು ಗುಣ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Padding(padding: const EdgeInsets.all(12), child: Text(total.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPurple1))),
                  const Padding(padding: EdgeInsets.all(12), child: Text('36', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey))),
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
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle('ವಧುವಿನ ವಿವರಗಳು (Bride)', color: kOrange),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildDropdown('ರಾಶಿ', _bRashi, knRashi, (v) => setState(() => _bRashi = v))),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDropdown('ನಕ್ಷತ್ರ', _bNak, knNak, (v) => setState(() => _bNak = v))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 8),
                          const SectionTitle('ವರನ ವಿವರಗಳು (Groom)', color: kTeal),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildDropdown('ರಾಶಿ', _gRashi, knRashi, (v) => setState(() => _gRashi = v))),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDropdown('ನಕ್ಷತ್ರ', _gNak, knNak, (v) => setState(() => _gNak = v))),
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
                              child: const Text('ಹೊಂದಾಣಿಕೆ ಪರೀಕ್ಷಿಸಿ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildResultTable(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
