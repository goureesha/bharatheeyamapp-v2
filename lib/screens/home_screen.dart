import 'package:flutter/material.dart';
import '../widgets/common.dart';

import '../services/google_auth_service.dart';
import '../services/calendar_service.dart';
import 'input_screen.dart';
import 'panchanga_screen.dart';
import 'taranukoola_screen.dart';
import 'muhurta_screen.dart';
import 'match_making_tab.dart';
import 'mantra_sangraha_screen.dart';
import 'planets_screen.dart';
import 'settings_screen.dart';
import 'vedic_clock_screen.dart';
import 'appointment_screen.dart';
import 'ashtamangala_screen.dart';
import 'library_screen.dart';
import '../services/tester_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _Section(AppLocale.l('kundali'), 'Kundali', Icons.auto_awesome, kOrange, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InputScreen()));
      }),
      _Section(AppLocale.l('panchanga'), 'Panchanga', Icons.calendar_month, kPurple2, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PanchangaScreen()));
      }),
      _Section(AppLocale.l('taranukoola'), 'Taranukoola', Icons.stars_rounded, kGreen, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TaranukoolaScreen()));
      }),
      _Section('ಮುಹೂರ್ತ', 'Muhurta', Icons.access_time_filled, const Color(0xFF8E44AD), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MuhurtaScreen()));
      }),
      _Section(AppLocale.l('matchMaking'), 'Match Making', Icons.favorite, const Color(0xFFE53E3E), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchMakingScreen()));
      }),
      _Section(AppLocale.l('planets'), 'Planets', Icons.blur_circular, const Color(0xFFc0392b), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanetsScreen()));
      }),
      _Section(AppLocale.isHindi ? 'मंत्र संग्रह' : 'ಮಂತ್ರ ಸಂಗ್ರಹ', 'Mantra Sangraha', Icons.menu_book_rounded, kTeal, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MantraSangrahaScreen()));
      }),
      _Section(AppLocale.l('vedicClock'), 'Vedic Clock', Icons.watch_later_rounded, const Color(0xFF5B2C6F), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VedicClockScreen()));
      }),
      _Section(AppLocale.l('appointment'), 'Appointments', Icons.event_note, kTeal, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentScreen()));
      }),
      _Section(AppLocale.isHindi ? 'अष्टमंगल' : 'ಅಷ್ಟಮಂಗಲ', 'Ashtamangala', Icons.auto_fix_high, const Color(0xFFE67E22), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AshtamangalaScreen()));
      }),
      _Section(AppLocale.l('settings'), 'Settings', Icons.settings, kMuted, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      }),
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxWidth: 700,
            child: Builder(builder: (context) {
              final tablet = isTablet(context);
              return Column(
                children: [
                  // Scrollable Logo Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(children: [
                      Image.asset('assets/images/logo.png',
                        width: tablet ? 110 : 80,
                        height: tablet ? 110 : 80),
                      const SizedBox(height: 10),
                      Text(AppLocale.l('appName'), style: TextStyle(
                        fontSize: tablet ? 32 : 26,
                        fontWeight: FontWeight.w900,
                        color: kOrange,
                        letterSpacing: 1.5,
                      )),
                      const SizedBox(height: 4),
                      Text('Vedic Astrology', style: TextStyle(
                        fontSize: tablet ? 15 : 13,
                        color: kMuted, letterSpacing: 0.5,
                      )),
                    ]),
                  ),


                  // Sections Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: TesterService.isTesterNotifier,
                      builder: (context, isTester, _) {
                        final currentSections = List<_Section>.from(sections);
                        if (isTester) {
                          currentSections.add(
                            _Section('ಗ್ರಂಥಾಲಯ', 'Books & Kosha', Icons.library_books, Colors.brown, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen()));
                            }),
                          );
                        }

                        return GridView.count(
                          crossAxisCount: tablet ? 3 : 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: tablet ? 1.1 : 1.15,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: currentSections.map((s) => _buildCard(s)).toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showAppointmentDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    int durationMinutes = 60;
    final clientNameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: kCard,
          title: Text('ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ರಚಿಸಿ', style: TextStyle(color: kText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clientNameCtrl,
                decoration: InputDecoration(
                  labelText: 'ಗ್ರಾಹಕರ ಹೆಸರು',
                  labelStyle: TextStyle(color: kMuted),
                  isDense: true,
                ),
                style: TextStyle(color: kText),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.calendar_today, color: kPurple2),
                title: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: TextStyle(color: kText)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setDialogState(() => selectedDate = d);
                },
              ),
              ListTile(
                leading: Icon(Icons.access_time, color: kPurple2),
                title: Text(selectedTime.format(ctx), style: TextStyle(color: kText)),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (t != null) setDialogState(() => selectedTime = t);
                },
              ),
              ListTile(
                leading: Icon(Icons.timer, color: kPurple2),
                title: Text('$durationMinutes ನಿಮಿಷ', style: TextStyle(color: kText)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: Icon(Icons.remove, color: kMuted), onPressed: () {
                    if (durationMinutes > 15) setDialogState(() => durationMinutes -= 15);
                  }),
                  IconButton(icon: Icon(Icons.add, color: kMuted), onPressed: () {
                    setDialogState(() => durationMinutes += 15);
                  }),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ರದ್ದು', style: TextStyle(color: kMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final startTime = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  selectedTime.hour, selectedTime.minute,
                );
                final ok = await CalendarService.createAppointment(
                  title: clientNameCtrl.text.isNotEmpty ? clientNameCtrl.text : 'ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್',
                  start: startTime,
                  end: startTime.add(Duration(minutes: durationMinutes)),
                  description: 'ಜಾತಕ ವಿಶ್ಲೇಷಣೆ',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Calendar ಗೆ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ಸೇರಿಸಲಾಗಿದೆ!' : 'ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ವಿಫಲ'),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: Colors.white),
              child: Text('ರಚಿಸಿ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(_Section s) {
    return GestureDetector(
      onTap: s.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: s.color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: s.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(s.icon, color: s.color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(s.label, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: kText,
            )),
            const SizedBox(height: 2),
            Text(s.subtitle, style: TextStyle(
              fontSize: 11, color: kMuted,
            )),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Section(this.label, this.subtitle, this.icon, this.color, this.onTap);
}

// Wrapper for MatchMakingTab to make it a full screen
class MatchMakingScreen extends StatelessWidget {
  const MatchMakingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಹೊಂದಾಣಿಕೆ / Match Making',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: const MatchMakingTab(),
    );
  }
}
