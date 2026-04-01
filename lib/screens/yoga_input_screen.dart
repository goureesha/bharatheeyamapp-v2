import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import '../services/location_service.dart';
import '../constants/places.dart';
import 'yoga_results_screen.dart';

class YogaInputScreen extends StatefulWidget {
  const YogaInputScreen({super.key});

  @override
  State<YogaInputScreen> createState() => _YogaInputScreenState();
}

class _YogaInputScreenState extends State<YogaInputScreen> {
  final _nameCtrl = TextEditingController();
  late final TextEditingController _placeCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;

  DateTime _dob = DateTime.now();
  int _hour = DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12;
  int _minute = DateTime.now().minute;
  String _ampm = DateTime.now().hour < 12 ? 'AM' : 'PM';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _placeCtrl = TextEditingController(text: LocationService.place);
    _latCtrl = TextEditingController(text: LocationService.lat.toStringAsFixed(4));
    _lonCtrl = TextEditingController(text: LocationService.lon.toStringAsFixed(4));
  }

  void _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: kPurple2, onPrimary: Colors.white, surface: kBg, onSurface: kText),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dob = d);
  }

  void _pickTime() async {
    int initH = _hour;
    if (_ampm == 'PM' && initH != 12) initH += 12;
    if (_ampm == 'AM' && initH == 12) initH = 0;
    
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initH, minute: _minute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: kPurple2, onPrimary: Colors.white, surface: kBg, onSurface: kText),
        ),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() {
        _hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
        _minute = t.minute;
        _ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
      });
    }
  }

  Future<void> _calculateYogas() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final lat = double.tryParse(_latCtrl.text) ?? 14.98;
      final lon = double.tryParse(_lonCtrl.text) ?? 74.73;

      int h24 = _hour + (_ampm == 'PM' && _hour != 12 ? 12 : 0);
      if (_ampm == 'AM' && _hour == 12) h24 = 0;
      final localHour = h24 + _minute / 60.0;

      final result = await AstroCalculator.calculate(
        year: _dob.year, month: _dob.month, day: _dob.day,
        hourUtcOffset: LocationService.tzOffset,
        hour24: localHour,
        lat: lat, lon: lon,
        ayanamsaMode: 'lahiri',
        trueNode: true,
      );

      if (result != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => YogaResultsScreen(
            result: result,
            name: _nameCtrl.text.trim().isEmpty ? 'Unknown' : _nameCtrl.text.trim(),
          ),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text('ಯೋಗ ಶೋಧಕ (Yoga Scanner)', style: TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: kBg,
        elevation: 0,
        iconTheme: IconThemeData(color: kText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('ಜನನ ವಿವರಗಳು (Birth Details)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kPurple2)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: 'ಹೆಸರು (Name)', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.calendar_today, color: kMuted),
                      const SizedBox(width: 10),
                      Text('ದಿನಾಂಕ: ${_dob.day.toString().padLeft(2,'0')}-${_dob.month.toString().padLeft(2,'0')}-${_dob.year}', style: TextStyle(color: kText)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.access_time, color: kMuted),
                      const SizedBox(width: 10),
                      Text('ಸಮಯ: ${_hour.toString().padLeft(2,'0')}:${_minute.toString().padLeft(2,'0')} $_ampm', style: TextStyle(color: kText)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _placeCtrl,
                  decoration: InputDecoration(labelText: 'ಸ್ಥಳ (Place)', prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _calculateYogas,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple2,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ಯೋಗಗಳನ್ನು ಹುಡುಕಿ (Find Yogas)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
