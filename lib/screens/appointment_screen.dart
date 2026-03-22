import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common.dart';
import '../services/appointment_service.dart';
import '../services/google_auth_service.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await AppointmentService.loadAll();
    if (mounted) setState(() => _isLoading = false);
  }

  List<Appointment> _getEventsForDay(DateTime day) {
    return AppointmentService.getAppointmentsForDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final dayAppointments = _getEventsForDay(_selectedDate);
    final apptByDate = AppointmentService.getAppointmentsByDate();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್‌ಗಳು', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kBg,
        foregroundColor: kText,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Share available slots for selected day
          IconButton(
            icon: Icon(Icons.share, color: kTeal),
            tooltip: 'ಲಭ್ಯ ಸ್ಲಾಟ್ ಹಂಚಿಕೊಳ್ಳಿ',
            onPressed: () => _shareAvailableSlots(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !GoogleAuthService.isSignedIn
              ? _buildSignInPrompt()
              : Column(
                  children: [
                    // Calendar
                    AppCard(
                      child: TableCalendar(
                        firstDay: DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (d) => isSameDay(d, _selectedDate),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDate = selected;
                            _focusedDay = focused;
                          });
                        },
                        onPageChanged: (focused) {
                          _focusedDay = focused;
                        },
                        eventLoader: (day) => _getEventsForDay(day),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (_, date, events) {
                            if (events.isEmpty) return null;
                            return Positioned(
                              bottom: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  events.length > 3 ? 3 : events.length,
                                  (_) => Container(
                                    width: 6, height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(color: kTeal, shape: BoxShape.circle),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        headerStyle: HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                          titleTextStyle: TextStyle(color: kPurple2, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: kPurple2.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: kTeal,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(color: kText, fontWeight: FontWeight.bold),
                          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          defaultTextStyle: TextStyle(color: kText),
                          weekendTextStyle: TextStyle(color: Colors.redAccent),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: kText, fontWeight: FontWeight.bold),
                          weekendStyle: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Selected date header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.event_note, color: kTeal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(_selectedDate),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText),
                          ),
                          const Spacer(),
                          Text(
                            '${dayAppointments.length} ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್',
                            style: TextStyle(fontSize: 13, color: kMuted),
                          ),
                        ],
                      ),
                    ),

                    // Appointments list
                    Expanded(
                      child: dayAppointments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_available, size: 60, color: kMuted.withOpacity(0.3)),
                                  const SizedBox(height: 12),
                                  Text('ಯಾವುದೇ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ಇಲ್ಲ', style: TextStyle(color: kMuted, fontSize: 15)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: dayAppointments.length,
                              itemBuilder: (_, i) => _buildAppointmentCard(dayAppointments[i]),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: GoogleAuthService.isSignedIn
          ? FloatingActionButton.extended(
              onPressed: () => _showAddAppointmentDialog(),
              backgroundColor: kTeal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('ಹೊಸ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login, size: 60, color: kMuted),
            const SizedBox(height: 16),
            Text('Google ಸೈನ್ ಇನ್ ಅಗತ್ಯವಿದೆ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
            const SizedBox(height: 8),
            Text('ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ನಿರ್ವಹಣೆಗಾಗಿ Settings ನಲ್ಲಿ Google ಸೈನ್ ಇನ್ ಮಾಡಿ.',
              textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appt) {
    final isCompleted = appt.status == 'completed';
    final isCancelled = appt.status == 'cancelled';
    final statusColor = isCompleted ? Colors.green : (isCancelled ? Colors.red : kTeal);
    final statusIcon = isCompleted ? Icons.check_circle : (isCancelled ? Icons.cancel : Icons.schedule);
    final statusText = isCompleted ? 'ಮುಗಿದಿದೆ' : (isCancelled ? 'ರದ್ದಾಗಿದೆ' : 'ಬುಕ್ ಆಗಿದೆ');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      color: kCard,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Client name + status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Text(
                    appt.clientName.isNotEmpty ? appt.clientName[0].toUpperCase() : '?',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.clientName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kText)),
                      if (appt.clientPhone.isNotEmpty)
                        Text(appt.clientPhone, style: TextStyle(color: kMuted, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Time
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: kTeal),
                const SizedBox(width: 6),
                Text(appt.timeRange, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kText)),
              ],
            ),

            if (appt.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(appt.notes, style: TextStyle(color: kMuted, fontSize: 13)),
            ],

            const SizedBox(height: 12),

            // Action buttons
            if (!isCancelled)
              Row(
                children: [
                  // WhatsApp confirmation
                  _actionBtn(Icons.message, 'ಸಂದೇಶ', Colors.green, () => _sendWhatsApp(appt, isReminder: false)),
                  const SizedBox(width: 8),
                  // WhatsApp reminder
                  _actionBtn(Icons.notifications_active, 'ಜ್ಞಾಪನೆ', kOrange, () => _sendWhatsApp(appt, isReminder: true)),
                  const Spacer(),
                  if (!isCompleted) ...[
                    // Mark completed
                    _actionBtn(Icons.check, 'ಮುಗಿದಿದೆ', Colors.green, () async {
                      final ok = await AppointmentService.updateStatus(appt, 'completed');
                      if (ok && mounted) setState(() {});
                    }),
                    const SizedBox(width: 8),
                    // Cancel
                    _actionBtn(Icons.close, 'ರದ್ದು', Colors.red, () async {
                      final ok = await AppointmentService.updateStatus(appt, 'cancelled');
                      if (ok && mounted) setState(() {});
                    }),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────

  void _showAddAppointmentDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime apptDate = _selectedDate;
    String? selectedSlot;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final availableSlots = AppointmentService.getAvailableSlotsForDate(apptDate);

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kMuted.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Text('ಹೊಸ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kText)),
                  const SizedBox(height: 20),

                  // Client Name
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ಗ್ರಾಹಕರ ಹೆಸರು *',
                      prefixIcon: Icon(Icons.person, color: kTeal),
                    ),
                    style: TextStyle(color: kText),
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'ಫೋನ್ ಸಂಖ್ಯೆ',
                      prefixIcon: Icon(Icons.phone, color: kTeal),
                    ),
                    style: TextStyle(color: kText),
                  ),
                  const SizedBox(height: 12),

                  // Date picker
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: kTeal),
                    title: Text(_formatDate(apptDate), style: TextStyle(color: kText, fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.edit, color: kMuted, size: 18),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: apptDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) {
                        setSheetState(() {
                          apptDate = d;
                          selectedSlot = null;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Available time slots
                  Text('ಲಭ್ಯ ಸಮಯ:', style: TextStyle(fontWeight: FontWeight.bold, color: kText)),
                  const SizedBox(height: 8),
                  if (availableSlots.isEmpty)
                    Text('ಈ ದಿನ ಯಾವುದೇ ಸ್ಲಾಟ್ ಲಭ್ಯವಿಲ್ಲ', style: TextStyle(color: kMuted))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableSlots.map((slot) {
                        final isSelected = selectedSlot == slot;
                        return ChoiceChip(
                          label: Text(_formatTimeSlot(slot), style: TextStyle(
                            color: isSelected ? Colors.white : kText,
                            fontWeight: FontWeight.bold, fontSize: 13,
                          )),
                          selected: isSelected,
                          selectedColor: kTeal,
                          backgroundColor: kBg,
                          onSelected: (_) => setSheetState(() => selectedSlot = slot),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'ಟಿಪ್ಪಣಿಗಳು (ಐಚ್ಛಿಕ)',
                      prefixIcon: Icon(Icons.note, color: kTeal),
                    ),
                    style: TextStyle(color: kText),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ಬುಕ್ ಮಾಡಿ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: selectedSlot == null || nameCtrl.text.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(ctx);

                              // Calculate end time
                              final slotParts = selectedSlot!.split(':');
                              final startHour = int.parse(slotParts[0]);
                              final startMin = int.parse(slotParts[1]);
                              // Find slot duration from available slots
                              final daySlots = AppointmentService.availableSlots;
                              final daySlot = daySlots.firstWhere(
                                (s) => s.dayOfWeek == apptDate.weekday,
                                orElse: () => AvailableSlot(dayOfWeek: 1, startTime: '09:00', endTime: '17:00', slotMinutes: 60),
                              );
                              final endTotal = startHour * 60 + startMin + daySlot.slotMinutes;
                              final endTime = '${(endTotal ~/ 60).toString().padLeft(2, '0')}:${(endTotal % 60).toString().padLeft(2, '0')}';

                              setState(() => _isLoading = true);
                              final ok = await AppointmentService.addAppointment(
                                date: apptDate,
                                startTime: selectedSlot!,
                                endTime: endTime,
                                clientName: nameCtrl.text,
                                clientPhone: phoneCtrl.text,
                                notes: notesCtrl.text,
                              );

                              if (mounted) {
                                setState(() => _isLoading = false);
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('✅ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ಬುಕ್ ಆಗಿದೆ!'), backgroundColor: Colors.green),
                                  );
                                  // Ask to send WhatsApp confirmation
                                  _promptWhatsApp(phoneCtrl.text, AppointmentService.confirmationMessage(
                                    Appointment(
                                      id: '', date: apptDate, startTime: selectedSlot!,
                                      endTime: endTime, clientName: nameCtrl.text,
                                      clientPhone: phoneCtrl.text, status: 'booked',
                                      notes: notesCtrl.text, createdAt: '',
                                    ),
                                  ));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('❌ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ವಿಫಲ'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── WhatsApp ───────────────────────────────────────────

  void _sendWhatsApp(Appointment appt, {required bool isReminder}) {
    final message = isReminder
        ? AppointmentService.reminderMessage(appt)
        : AppointmentService.confirmationMessage(appt);
    _promptWhatsApp(appt.clientPhone, message);
  }

  void _promptWhatsApp(String phone, String message) {
    // Clean phone number
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isNotEmpty && !cleanPhone.startsWith('+')) {
      cleanPhone = '+91$cleanPhone'; // Default India country code
    }

    final encoded = Uri.encodeComponent(message);
    final url = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$encoded'
        : 'https://wa.me/?text=$encoded';

    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _shareAvailableSlots() {
    final message = AppointmentService.availableSlotsMessage(_selectedDate);
    final encoded = Uri.encodeComponent(message);
    launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
  }

  void _shareCalendar({required int days}) {
    final message = AppointmentService.weeklyCalendarMessage(days: days);
    final encoded = Uri.encodeComponent(message);
    launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
  }

  // ─── Helpers ───────────────────────────────────────────

  String _formatDate(DateTime d) {
    const months = ['ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್', 'ಜುಲೈ', 'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್'];
    const days = ['ಸೋಮ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರವಿ'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  String _formatTimeSlot(String time) {
    final parts = time.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final amPm = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:$m $amPm';
  }
}
