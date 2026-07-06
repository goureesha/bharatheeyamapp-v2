import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/common.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import '../services/location_service.dart';

class PanchangaSearchScreen extends StatefulWidget {
  const PanchangaSearchScreen({super.key});

  @override
  State<PanchangaSearchScreen> createState() => _PanchangaSearchScreenState();
}

class _PanchangaSearchScreenState extends State<PanchangaSearchScreen> {
  // Chandra Masa names (same order as calculator.dart)
  static const _chandraMasaNames = [
    'ವೈಶಾಖ','ಜ್ಯೇಷ್ಠ','ಆಷಾಢ','ಶ್ರಾವಣ','ಭಾದ್ರಪದ','ಆಶ್ವಿನ',
    'ಕಾರ್ತಿಕ','ಮಾರ್ಗಶಿರ','ಪುಷ್ಯ','ಮಾಘ','ಫಾಲ್ಗುಣ','ಚೈತ್ರ',
  ];

  // Soura Masa names (same order as calculator.dart)
  static const _souraMasaNames = [
    'ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕಾಟಕ','ಸಿಂಹ','ಕನ್ಯಾ',
    'ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ',
  ];

  // Tithi options (index 0-29 maps to knTithi)
  // We show separate Shukla/Krishna sections
  static const _shuklaBaseTithis = [
    'ಪಾಡ್ಯಮಿ', 'ದ್ವಿತೀಯ', 'ತೃತೀಯ', 'ಚತುರ್ಥಿ', 'ಪಂಚಮಿ',
    'ಷಷ್ಠಿ', 'ಸಪ್ತಮಿ', 'ಅಷ್ಟಮಿ', 'ನವಮಿ', 'ದಶಮಿ',
    'ಏಕಾದಶಿ', 'ದ್ವಾದಶಿ', 'ತ್ರಯೋದಶಿ', 'ಚತುರ್ದಶಿ', 'ಹುಣ್ಣಿಮೆ',
  ];
  static const _krishnaBaseTithis = [
    'ಪಾಡ್ಯಮಿ', 'ದ್ವಿತೀಯ', 'ತೃತೀಯ', 'ಚತುರ್ಥಿ', 'ಪಂಚಮಿ',
    'ಷಷ್ಠಿ', 'ಸಪ್ತಮಿ', 'ಅಷ್ಟಮಿ', 'ನವಮಿ', 'ದಶಮಿ',
    'ಏಕಾದಶಿ', 'ದ್ವಾದಶಿ', 'ತ್ರಯೋದಶಿ', 'ಚತುರ್ದಶಿ', 'ಅಮಾವಾಸ್ಯೆ',
  ];

  // Filter state
  int? _selectedChandraMasa; // index into _chandraMasaNames, null = any
  int? _selectedSouraMasa;   // index into _souraMasaNames, null = any
  int? _selectedPaksha;      // 0 = Shukla, 1 = Krishna, null = any
  int? _selectedTithiInPaksha; // 0-14 within the selected paksha
  TimeOfDay _fromTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 18, minute: 0);

  // Results
  List<_SearchResult> _results = [];
  bool _isSearching = false;
  int _scanProgress = 0;
  int _scanTotal = 0;
  bool _hasSearched = false;

  /// Compute the absolute tithi index (0-29) from paksha + tithi selection
  int? get _absoluteTithiIndex {
    if (_selectedPaksha == null || _selectedTithiInPaksha == null) return null;
    if (_selectedPaksha == 0) return _selectedTithiInPaksha!;       // Shukla 0-14
    return 15 + _selectedTithiInPaksha!;                            // Krishna 15-29
  }

  Future<void> _search() async {
    // At least one filter must be set
    if (_selectedChandraMasa == null && _selectedSouraMasa == null && _absoluteTithiIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.l('selectFilter')), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _results = [];
      _hasSearched = true;
    });

    final lat = LocationService.lat;
    final lon = LocationService.lon;
    final tz = LocationService.tzOffset;
    final now = DateTime.now();
    final totalDays = 365;

    setState(() => _scanTotal = totalDays);

    final List<_SearchResult> found = [];
    final fromH24 = _fromTime.hour + _fromTime.minute / 60.0;
    final toH24 = _toTime.hour + _toTime.minute / 60.0;
    final midH24 = (fromH24 + toH24) / 2.0;
    bool enteredMasa = false; // track if we've entered the selected masa

    for (int i = 0; i < totalDays; i++) {
      if (!mounted) break;

      final date = now.add(Duration(days: i));

      // Yield to UI every 10 days to keep it responsive
      if (i % 10 == 0) {
        setState(() => _scanProgress = i);
        await Future.delayed(Duration.zero);
      }

      try {
        // Step 1: Calculate at NOON to find if tithi/masa matches this day
        final noonResult = await AstroCalculator.calculate(
          year: date.year, month: date.month, day: date.day,
          hourUtcOffset: tz, hour24: 12.0,
          lat: lat, lon: lon,
          ayanamsaMode: 'lahiri', trueNode: true,
        );
        if (noonResult == null) continue;

        final noonP = noonResult.panchang;

        // Hard filter: Chandra Masa
        bool masaMatch = true;
        if (_selectedChandraMasa != null) {
          if (noonP.chandraMasaRaw != _chandraMasaNames[_selectedChandraMasa!]) {
            masaMatch = false;
          }
        }
        if (_selectedSouraMasa != null) {
          if (noonP.souraMasa != _souraMasaNames[_selectedSouraMasa!]) {
            masaMatch = false;
          }
        }

        // Smart early exit: if we already found results inside the masa
        // and now we've left it, stop scanning
        if (!masaMatch) {
          if (enteredMasa && found.isNotEmpty) break;
          continue;
        }
        enteredMasa = true;

        // Hard filter: Tithi must match at noon
        if (_absoluteTithiIndex != null) {
          if (noonP.tithiIndex != _absoluteTithiIndex) continue;
        }

        // Step 2: Only re-calc at user time if it differs from noon
        PanchangData p = noonP;
        bool tithiNotAvailable = false;
        if ((midH24 - 12.0).abs() > 0.5) {
          final timeResult = await AstroCalculator.calculate(
            year: date.year, month: date.month, day: date.day,
            hourUtcOffset: tz, hour24: midH24,
            lat: lat, lon: lon,
            ayanamsaMode: 'lahiri', trueNode: true,
          );
          if (timeResult != null) p = timeResult.panchang;
          tithiNotAvailable = (_absoluteTithiIndex != null && p.tithiIndex != _absoluteTithiIndex);
        }

        found.add(_SearchResult(
          date: date,
          vara: p.vara,
          tithi: p.tithi,
          tithiEndTime: p.tithiEndTime,
          tithiEndsNextDay: p.tithiEndsNextDay,
          nakshatra: p.nakshatra,
          nakEndTime: p.nakEndTime,
          nakEndsNextDay: p.nakEndsNextDay,
          karana: p.karana,
          karanaEndTime: p.karanaEndTime,
          karanaEndsNextDay: p.karanaEndsNextDay,
          yoga: p.yoga,
          yogaEndTime: p.yogaEndTime,
          yogaEndsNextDay: p.yogaEndsNextDay,
          chandraMasa: p.chandraMasa,
          souraMasa: p.souraMasa,
          sunrise: p.sunrise,
          sunset: p.sunset,
          tithiNotAvailable: tithiNotAvailable,
        ));
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _results = found;
        _isSearching = false;
        _scanProgress = _scanTotal;
      });
    }
  }

  Future<void> _pickTime(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : _toTime,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('${AppLocale.l('panchangaSearch')} / Panchanga Search',
          style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxWidth: 600,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // ── FILTER CARD ──
                AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppLocale.l('filterTitle'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                  const SizedBox(height: 4),
                  Text('Select criteria to search', style: TextStyle(fontSize: 12, color: kMuted)),
                  const SizedBox(height: 16),

                  // Chandra Masa
                  _buildDropdown(
                    label: AppLocale.l('chandraMasaLabel'),
                    value: _selectedChandraMasa,
                    items: _chandraMasaNames,
                    onChanged: (v) => setState(() => _selectedChandraMasa = v),
                    allowNull: true,
                  ),
                  const SizedBox(height: 12),

                  // Soura Masa
                  _buildDropdown(
                    label: AppLocale.l('souraMasaLabel'),
                    value: _selectedSouraMasa,
                    items: _souraMasaNames,
                    onChanged: (v) => setState(() => _selectedSouraMasa = v),
                    allowNull: true,
                  ),
                  const SizedBox(height: 12),

                  // Paksha
                  _buildDropdown(
                    label: AppLocale.l('pakshaLabel'),
                    value: _selectedPaksha,
                    items: const ['ಶುಕ್ಲ ಪಕ್ಷ', 'ಕೃಷ್ಣ ಪಕ್ಷ'],
                    onChanged: (v) => setState(() {
                      _selectedPaksha = v;
                      _selectedTithiInPaksha = null; // reset tithi on paksha change
                    }),
                    allowNull: true,
                  ),
                  const SizedBox(height: 12),

                  // Tithi (depends on paksha)
                  if (_selectedPaksha != null) ...[
                    _buildDropdown(
                      label: AppLocale.l('tithiLabel'),
                      value: _selectedTithiInPaksha,
                      items: _selectedPaksha == 0 ? _shuklaBaseTithis : _krishnaBaseTithis,
                      onChanged: (v) => setState(() => _selectedTithiInPaksha = v),
                      allowNull: true,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Time Range
                  Row(children: [
                    Expanded(child: _buildTimeButton(AppLocale.l('fromDate'), _fromTime, () => _pickTime(true))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeButton(AppLocale.l('toDate'), _toTime, () => _pickTime(false))),
                  ]),
                  const SizedBox(height: 6),
                  Text('Scanning 1 year from today', style: TextStyle(fontSize: 11, color: kMuted)),
                  const SizedBox(height: 16),

                  // Search Button
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    icon: _isSearching
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search, size: 20),
                    label: Text(_isSearching
                      ? '${AppLocale.l('scanning')} $_scanProgress/$_scanTotal'
                      : AppLocale.l('searchBtn'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple2, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSearching ? null : _search,
                  )),
                ])),

                // ── PROGRESS ──
                if (_isSearching) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _scanTotal > 0 ? _scanProgress / _scanTotal : 0,
                    backgroundColor: kBorder,
                    valueColor: AlwaysStoppedAnimation(kPurple2),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],

                // ── RESULTS ──
                if (_hasSearched && !_isSearching) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    Icon(_results.isNotEmpty ? Icons.check_circle : Icons.info_outline,
                      color: _results.isNotEmpty ? kGreen : kMuted, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _results.isNotEmpty
                        ? '${_results.length} ${AppLocale.l('resultsFound')}'
                        : AppLocale.l('noResults'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: _results.isNotEmpty ? kGreen : kMuted),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ..._results.map((r) => _buildResultCard(r)),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int? value,
    required List<String> items,
    required ValueChanged<int?> onChanged,
    bool allowNull = false,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
          color: kCard, border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            isExpanded: true,
            value: value,
            dropdownColor: kCard,
            style: TextStyle(color: kText, fontSize: 14),
            icon: Icon(Icons.arrow_drop_down, color: kMuted),
            items: [
              if (allowNull)
                DropdownMenuItem<int?>(value: null, child: Text('— ${AppLocale.l('anyOption')} —', style: TextStyle(color: kMuted))),
              ...items.asMap().entries.map((e) =>
                DropdownMenuItem<int?>(value: e.key, child: Text(trAll(e.value)))),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  Widget _buildTimeButton(String label, TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kCard, border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.access_time, size: 14, color: kPurple2),
            const SizedBox(width: 6),
            Text(_formatTime(time), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildResultCard(_SearchResult r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Date header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kPurple2.withOpacity(0.1), kOrange.withOpacity(0.06)]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.calendar_month, color: kPurple2, size: 20),
            const SizedBox(width: 8),
            Text(_formatDate(r.date), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kText)),
            const Spacer(),
            Text(trAll(r.vara), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kOrange)),
          ]),
        ),
        const SizedBox(height: 10),

        // Masa info
        Row(children: [
          _infoChip(AppLocale.l('chandraMasaLabel'), trAll(r.chandraMasa), kPurple2),
          const SizedBox(width: 8),
          _infoChip(AppLocale.l('souraMasaLabel'), trAll(r.souraMasa), kGreen),
        ]),
        const SizedBox(height: 10),

        // Tithi not available warning
        if (r.tithiNotAvailable) ...[    
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                AppLocale.l('tithiNotAvail'),
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
              )),
            ]),
          ),
          const SizedBox(height: 10),
        ],

        // Panchanga details table
        _detailRow(AppLocale.l('tithiLabel'), r.tithi, r.tithiEndTime, r.tithiEndsNextDay),
        _detailRow(AppLocale.l('nakshatraLabel'), r.nakshatra, r.nakEndTime, r.nakEndsNextDay),
        _detailRow(AppLocale.l('yogaLabel'), r.yoga, r.yogaEndTime, r.yogaEndsNextDay),
        _detailRow(AppLocale.l('karanaLabel'), r.karana, r.karanaEndTime, r.karanaEndsNextDay),

        const SizedBox(height: 6),
        // Sunrise/Sunset
        Row(children: [
          Icon(Icons.wb_sunny, size: 14, color: kOrange),
          const SizedBox(width: 4),
          Text('${r.sunrise}', style: TextStyle(fontSize: 11, color: kMuted)),
          const SizedBox(width: 16),
          Icon(Icons.nightlight, size: 14, color: kPurple2),
          const SizedBox(width: 4),
          Text('${r.sunset}', style: TextStyle(fontSize: 11, color: kMuted)),
        ]),
      ])),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ]),
    ));
  }

  Widget _detailRow(String label, String value, String endTime, bool nextDay) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted))),
        Expanded(child: Text(trAll(value), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText))),
        if (endTime.isNotEmpty) ...[
          Text(endTime, style: TextStyle(fontSize: 11, color: kPurple2, fontWeight: FontWeight.w600)),
          if (nextDay) Text(' (+1)', style: TextStyle(fontSize: 9, color: kOrange, fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }
}

class _SearchResult {
  final DateTime date;
  final String vara, tithi, tithiEndTime, nakshatra, nakEndTime;
  final String karana, karanaEndTime, yoga, yogaEndTime;
  final bool tithiEndsNextDay, nakEndsNextDay, karanaEndsNextDay, yogaEndsNextDay;
  final String chandraMasa, souraMasa, sunrise, sunset;
  final bool tithiNotAvailable;

  _SearchResult({
    required this.date, required this.vara,
    required this.tithi, required this.tithiEndTime, required this.tithiEndsNextDay,
    required this.nakshatra, required this.nakEndTime, required this.nakEndsNextDay,
    required this.karana, required this.karanaEndTime, required this.karanaEndsNextDay,
    required this.yoga, required this.yogaEndTime, required this.yogaEndsNextDay,
    required this.chandraMasa, required this.souraMasa,
    required this.sunrise, required this.sunset,
    this.tithiNotAvailable = false,
  });
}
