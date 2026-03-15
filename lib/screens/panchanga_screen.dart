import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../services/ad_service.dart';

class PanchangaScreen extends StatefulWidget {
  const PanchangaScreen({super.key});

  @override
  State<PanchangaScreen> createState() => _PanchangaScreenState();
}

class _PanchangaScreenState extends State<PanchangaScreen> {
  DateTime _selectedDate = DateTime.now();
  PanchangData? _panchang;
  bool _loading = false;

  // Default location: Yellapur
  final double _lat = 14.98;
  final double _lon = 74.73;
  final String _place = 'Yellapur';

  @override
  void initState() {
    super.initState();
    _calcPanchang(_selectedDate);
  }

  Future<void> _calcPanchang(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _loading = true;
    });

    try {
      // Calculate for sunrise time (approx 6:00 AM local)
      final result = await AstroCalculator.calculate(
        year: date.year, month: date.month, day: date.day,
        hourUtcOffset: 5.5,
        hour24: 6.0, // sunrise approx
        lat: _lat, lon: _lon,
        ayanamsaMode: 'lahiri',
        trueNode: true,
      );

      if (result != null && mounted) {
        setState(() {
          _panchang = result.panchang;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.day.toString().padLeft(2,'0')}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.year}';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಪಂಚಾಂಗ / Panchanga',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Calendar Card
                  AppCard(
                    child: Column(children: [
                      Row(children: [
                        Icon(Icons.calendar_month, color: kPurple2, size: 20),
                        const SizedBox(width: 8),
                        Text('ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ', style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _calcPanchang(DateTime.now()),
                          icon: Icon(Icons.today, size: 16),
                          label: Text('ಇಂದು', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CalendarDatePicker(
                          initialDate: _selectedDate,
                          firstDate: DateTime(1800),
                          lastDate: DateTime(2100),
                          onDateChanged: (date) => _calcPanchang(date),
                        ),
                      ),
                    ]),
                  ),

                  // Date & Place info
                  AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _kv('ಸ್ಥಳ', _place),
                    _kv('ದಿನಾಂಕ', dateStr),
                    _kv('ಸಮಯ', 'ಸೂರ್ಯೋದಯ'),
                  ])),

                  // Loading or Panchanga data
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: kPurple2),
                    )
                  else if (_panchang != null)
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        _tableRow(['ಸಂವತ್ಸರ', _panchang!.samvatsara]),
                        _tableRow(['ವಾರ', _panchang!.vara]),
                        _tableRow(['ತಿಥಿ', _panchang!.tithi]),
                        _tableRow(['ಚಂದ್ರ ನಕ್ಷತ್ರ', _panchang!.nakshatra]),
                        _tableRow(['ಯೋಗ', _panchang!.yoga]),
                        _tableRow(['ಕರಣ', _panchang!.karana]),
                        _tableRow(['ಚಂದ್ರ ರಾಶಿ', _panchang!.chandraRashi]),
                        _tableRow(['ಚಂದ್ರ ಮಾಸ', _panchang!.chandraMasa]),
                        _tableRow(['ಸೂರ್ಯ ನಕ್ಷತ್ರ', '${_panchang!.suryaNakshatra} - ಪಾದ ${_panchang!.suryaPada}']),
                        _tableRow(['ಸೌರ ಮಾಸ', _panchang!.souraMasa]),
                        _tableRow(['ಸೌರ ಮಾಸ ಗತ ದಿನ', _panchang!.souraMasaGataDina]),
                        _tableRow(['ಸೂರ್ಯೋದಯ', _panchang!.sunrise]),
                        _tableRow(['ಸೂರ್ಯಾಸ್ತ', _panchang!.sunset]),
                        _tableRow(['ಉದಯಾದಿ ಘಟಿ', _panchang!.udayadiGhati]),
                        _tableRow(['ಗತ ಘಟಿ', _panchang!.gataGhati]),
                        _tableRow(['ಪರಮ ಘಟಿ', _panchang!.paramaGhati]),
                        _tableRow(['ಶೇಷ ಘಟಿ', _panchang!.shesha]),
                        _tableRow(['ವಿಷ ಪ್ರಘಟಿ', _panchang!.vishaPraghati]),
                        _tableRow(['ಅಮೃತ ಪ್ರಘಟಿ', _panchang!.amrutaPraghati]),
                      ]),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text('$k: ', style: TextStyle(fontWeight: FontWeight.w800, color: kPurple2)),
        Expanded(child: Text(v, style: TextStyle(color: kText))),
      ]),
    );
  }

  Widget _tableRow(List<String> cols) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(e.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: e.key == 0 ? FontWeight.w700 : FontWeight.normal,
                color: kText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )).toList(),
      ),
    );
  }
}
