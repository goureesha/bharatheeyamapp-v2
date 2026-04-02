import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/planet_detail_sheet.dart';
import '../core/calculator.dart';
import '../core/yoga_calculator.dart';

class YogaResultsScreen extends StatefulWidget {
  final KundaliResult result;
  final String name;

  const YogaResultsScreen({super.key, required this.result, required this.name});

  @override
  State<YogaResultsScreen> createState() => _YogaResultsScreenState();
}

class _YogaResultsScreenState extends State<YogaResultsScreen> {
  int _selectedVarga = 1; // 1 = D1, 9 = D9, 12 = D12
  late List<KundaliYoga> _yogas;

  @override
  void initState() {
    super.initState();
    _yogas = YogaCalculator.scanYogas(widget.result);
  }

  void _showPlanetDetail(String planetName) {
    if (planetName == 'ಲಗ್ನ') return;
    final info = widget.result.planets[planetName];
    if (info == null) return;
    final sun = widget.result.planets['ರವಿ'];
    final detail = AstroCalculator.getPlanetDetail(
      planetName, info.longitude, info.speed, sun?.longitude ?? 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanetDetailSheet(pName: planetName, detail: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text('${widget.name} - ಯೋಗಗಳು', style: TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: kBg,
        elevation: 0,
        iconTheme: IconThemeData(color: kText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Varga Chart Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _buildTab(1, 'D1 Rashi'),
                      _buildTab(9, 'D9 Navamsha'),
                      _buildTab(12, 'D12 Dvadashamsha'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Active Chart
                // Use a key to force chart rebuild when varga changes so shortnames reset cleanly
                SizedBox(
                  width: double.infinity,
                  child: KundaliChart(
                     key: ValueKey(_selectedVarga),
                     result: widget.result,
                     varga: _selectedVarga,
                     isBhava: false,
                     showSphutas: false,
                     centerLabel: _selectedVarga == 1 ? 'ರಾಶಿ\n(Rashi)' : _selectedVarga == 9 ? 'ನವಾಂಶ\n(D9)' : 'ದ್ವಾದಶಾಂಶ\n(D12)',
                     onPlanetTap: _showPlanetDetail,
                  ),
                ),
                const SizedBox(height: 24),

                // Yogas Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ಫಲಿತ ಯೋಗಗಳು (Results)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: kPurple2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: kPurple1.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('${_yogas.length} Found', style: TextStyle(color: kPurple1, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Yogas List
                if (_yogas.isEmpty)
                   Padding(
                     padding: const EdgeInsets.all(32),
                     child: Text('ನಮೂದಿಸಿದ ಜಾತಕದಲ್ಲಿ ಪ್ರಸ್ತುತ ಬೆಂಬಲಿತ ಯೋಗಗಳು ಕಂಡುಬಂದಿಲ್ಲ.', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
                   )
                else
                   ListView.separated(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: _yogas.length,
                     separatorBuilder: (_,__) => const SizedBox(height: 12),
                     itemBuilder: (ctx, i) => _buildYogaCard(_yogas[i]),
                   ),
                   
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int vargaValue, String label) {
    bool isSel = _selectedVarga == vargaValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedVarga = vargaValue),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSel ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? kPurple2 : kMuted)),
        ),
      ),
    );
  }

  Widget _buildYogaCard(KundaliYoga yoga) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: yoga.isAuspicious ? const Color(0xFFF0FFF4) : const Color(0xFFFFF5F5),
        border: Border.all(color: yoga.isAuspicious ? const Color(0xFFC6F6D5) : const Color(0xFFFED7D7)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Expanded(child: Text(yoga.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: yoga.isAuspicious ? const Color(0xFF276749) : const Color(0xFFC53030)))),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                    color: yoga.isAuspicious ? const Color(0xFFC6F6D5) : const Color(0xFFFED7D7),
                    borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(yoga.isAuspicious ? 'ಶುಭ (Auspicious)' : 'ದೋಷ (Dosha)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: yoga.isAuspicious ? const Color(0xFF22543D) : const Color(0xFF9B2C2C))),
               )
             ]
          ),
          const SizedBox(height: 8),
          Row(
            children: [
               Icon(Icons.rule, size: 14, color: kMuted),
               const SizedBox(width: 4),
               Expanded(child: Text(yoga.rule, style: TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w500))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ಫಲ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kText)),
              const SizedBox(width: 6),
              Expanded(child: Text(yoga.effect, style: TextStyle(fontSize: 13, color: kText, height: 1.4))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
               ...yoga.contributingPlanets.map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Text(p, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPurple2)),
               )),
               Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(16)),
                  child: Text(yoga.chartReference, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTeal)),
               )
            ],
          )
        ],
      )
    );
  }
}
