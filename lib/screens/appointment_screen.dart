import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common.dart';
import '../services/appointment_service.dart';
import '../services/google_auth_service.dart';
import '../services/client_service.dart';
import 'client_detail_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = true;
  late TabController _tabCtrl;
  String _clientSearch = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await AppointmentService.loadAll();
    await ClientService.loadAll();
    if (mounted) setState(() => _isLoading = false);
  }

  List<Appointment> _getEventsForDay(DateTime day) {
    return AppointmentService.getAppointmentsForDate(day)
        .where((a) => a.status == 'booked' && a.clientName.trim().isNotEmpty)
        .toList();
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
          IconButton(
            icon: Icon(Icons.share, color: kTeal),
            tooltip: 'ಕ್ಯಾಲೆಂಡರ್ ಹಂಚಿಕೊಳ್ಳಿ',
            onPressed: () => _showShareConfigDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: kTeal,
          labelColor: kTeal,
          unselectedLabelColor: kMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today, size: 18), text: 'ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್'),
            Tab(icon: Icon(Icons.people, size: 18), text: 'ಗ್ರಾಹಕರು'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !GoogleAuthService.isSignedIn
              ? _buildSignInPrompt()
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // Tab 1: Appointments (calendar + list) — all scrollable
                    SingleChildScrollView(
                      child: Column(
                        children: [
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
                                          decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
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
                          if (dayAppointments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Column(
                                children: [
                                  Icon(Icons.event_available, size: 60, color: kMuted.withOpacity(0.3)),
                                  const SizedBox(height: 12),
                                  Text('ಯಾವುದೇ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ಇಲ್ಲ', style: TextStyle(color: kMuted, fontSize: 15)),
                                ],
                              ),
                            )
                          else
                            ...dayAppointments.map((a) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildAppointmentCard(a),
                            )),
                          const SizedBox(height: 80), // space for FAB
                        ],
                      ),
                    ),
                    // Tab 2: Clients
                    _buildClientsTab(),
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

  // ─── Clients Tab ─────────────────────────────────────────

  Widget _buildClientsTab() {
    final allClients = ClientService.searchClients(_clientSearch);

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            onChanged: (v) => setState(() => _clientSearch = v),
            decoration: InputDecoration(
              hintText: 'ಹೆಸರು, ಫೋನ್ ಅಥವಾ ID ಹುಡುಕಿ...',
              prefixIcon: Icon(Icons.search, color: kMuted),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              fillColor: kCard,
              filled: true,
            ),
            style: TextStyle(color: kText),
          ),
        ),

        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.people, color: kTeal, size: 18),
              const SizedBox(width: 6),
              Text('${allClients.length} \u0c97\u0ccd\u0cb0\u0cbe\u0cb9\u0c95\u0cb0\u0cc1', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Client list
        Expanded(
          child: allClients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_off, size: 60, color: kMuted.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      Text(_clientSearch.isEmpty ? '\u0c97\u0ccd\u0cb0\u0cbe\u0cb9\u0c95\u0cb0\u0cc1 \u0c87\u0cb2\u0ccd\u0cb2' : '\u0caf\u0cbe\u0cb5\u0cc1\u0ca6\u0cc7 \u0cab\u0cb2\u0cbf\u0ca4\u0cbe\u0c82\u0cb6 \u0c87\u0cb2\u0ccd\u0cb2', style: TextStyle(color: kMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: allClients.length,
                  itemBuilder: (_, i) => _buildClientCard(allClients[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildClientCard(Client client) {
    final members = ClientService.getMembersForClient(client.clientId);
    final phone = client.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final visits = AppointmentService.appointments.where((a) =>
      a.clientId == client.clientId ||
      a.clientPhone.replaceAll(RegExp(r'[^0-9]'), '') == phone
    ).length;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
      ).then((_) => _loadData()),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: kBorder),
        ),
        color: kCard,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kPurple2.withOpacity(0.15),
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: kPurple2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(client.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kText))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(client.clientId, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTeal)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: kMuted),
                        const SizedBox(width: 4),
                        Text(client.phone, style: TextStyle(fontSize: 12, color: kMuted)),
                        const SizedBox(width: 12),
                        Icon(Icons.event, size: 12, color: kMuted),
                        const SizedBox(width: 4),
                        Text('$visits \u0cad\u0cc7\u0c9f\u0cbf', style: TextStyle(fontSize: 12, color: kMuted)),
                        const SizedBox(width: 12),
                        Icon(Icons.people, size: 12, color: kMuted),
                        const SizedBox(width: 4),
                        Text('${members.length} \u0cb8\u0ca6\u0cb8\u0ccd\u0caf', style: TextStyle(fontSize: 12, color: kMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: kMuted),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAppointmentCard(Appointment appt) {
    final isCompleted = appt.status == 'completed';
    final isCancelled = appt.status == 'cancelled';
    final statusColor = isCompleted ? Colors.green : (isCancelled ? Colors.red : kTeal);
    final statusIcon = isCompleted ? Icons.check_circle : (isCancelled ? Icons.cancel : Icons.schedule);
    final statusText = isCompleted ? '\u0cae\u0cc1\u0c97\u0cbf\u0ca6\u0cbf\u0ca6\u0cc6' : (isCancelled ? '\u0cb0\u0ca6\u0ccd\u0ca6\u0cbe\u0c97\u0cbf\u0ca6\u0cc6' : '\u0cac\u0cc1\u0c95\u0ccd \u0c86\u0c97\u0cbf\u0ca6\u0cc6');

    // Check if returning client
    Client? client;
    int visitCount = 0;
    if (appt.clientId.isNotEmpty) {
      client = ClientService.getClientById(appt.clientId);
    } else if (appt.clientPhone.isNotEmpty) {
      client = ClientService.getClientByPhone(appt.clientPhone);
    }
    if (client != null) {
      final phone = client.phone.replaceAll(RegExp(r'[^0-9]'), '');
      visitCount = AppointmentService.appointments.where((a) =>
        a.clientId == client!.clientId ||
        a.clientPhone.replaceAll(RegExp(r'[^0-9]'), '') == phone
      ).length;
    }

    // Navigate to ClientDetailScreen — auto-create client if needed
    void openClient() async {
      Client? c = client;
      if (c == null && appt.clientName.isNotEmpty) {
        // Auto-create client record
        c = await ClientService.getOrCreateClient(
          name: appt.clientName,
          phone: appt.clientPhone,
        );
        if (c != null && mounted) {
          setState(() {}); // refresh to show new clientId
        }
      }
      if (c != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClientDetailScreen(client: c!)),
        ).then((_) => _loadData());
      }
    }

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
            // Header: Client name + status + return visit badge
            Row(
              children: [
                GestureDetector(
                  onTap: openClient,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: statusColor.withOpacity(0.12),
                    child: Text(
                      appt.clientName.isNotEmpty ? appt.clientName[0].toUpperCase() : '?',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: openClient,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appt.clientName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kTeal,
                          decoration: TextDecoration.underline,
                          decorationColor: kTeal,
                        )),
                        Row(
                          children: [
                            if (appt.clientPhone.isNotEmpty)
                              Text(appt.clientPhone, style: TextStyle(color: kMuted, fontSize: 13)),
                            if (appt.clientId.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: kTeal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(appt.clientId, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTeal)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Return visit badge
                if (visitCount > 1)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: kOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.repeat, size: 12, color: kOrange),
                      const SizedBox(width: 2),
                      Text('${visitCount}\u0ca8\u0cc7 \u0cad\u0cc7\u0c9f\u0cbf', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kOrange)),
                    ]),
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

  // ─── Share Config Dialog ────────────────────────────────────

  void _showShareConfigDialog() {
    DateTime fromDate = DateTime.now().add(const Duration(days: 1));
    DateTime toDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay fromTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay toTime = const TimeOfDay(hour: 17, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
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
                  Text('\u0c95\u0ccd\u0caf\u0cbe\u0cb2\u0cc6\u0c82\u0ca1\u0cb0\u0ccd \u0cb9\u0c82\u0c9a\u0cbf\u0c95\u0cca\u0cb3\u0ccd\u0cb3\u0cbf', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kText)),
                  const SizedBox(height: 6),
                  Text('\u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0cb8\u0cae\u0caf \u0c86\u0caf\u0ccd\u0c95\u0cc6 \u0cae\u0cbe\u0ca1\u0cbf', style: TextStyle(color: kMuted, fontSize: 13)),
                  const SizedBox(height: 20),

                  // FROM DATE
                  _configTile(
                    icon: Icons.calendar_today,
                    label: '\u0caa\u0ccd\u0cb0\u0cbe\u0cb0\u0c82\u0cad \u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95',
                    value: _formatDate(fromDate),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx, initialDate: fromDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setSheetState(() => fromDate = d);
                    },
                  ),
                  const SizedBox(height: 10),

                  // TO DATE
                  _configTile(
                    icon: Icons.event,
                    label: '\u0c85\u0c82\u0ca4\u0ccd\u0caf \u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95',
                    value: _formatDate(toDate),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx, initialDate: toDate,
                        firstDate: fromDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setSheetState(() => toDate = d);
                    },
                  ),
                  const SizedBox(height: 10),

                  // FROM TIME
                  _configTile(
                    icon: Icons.access_time,
                    label: '\u0caa\u0ccd\u0cb0\u0cbe\u0cb0\u0c82\u0cad \u0cb8\u0cae\u0caf',
                    value: fromTime.format(ctx),
                    onTap: () async {
                      final t = await showTimePicker(context: ctx, initialTime: fromTime);
                      if (t != null) setSheetState(() => fromTime = t);
                    },
                  ),
                  const SizedBox(height: 10),

                  // TO TIME
                  _configTile(
                    icon: Icons.access_time_filled,
                    label: '\u0c85\u0c82\u0ca4\u0ccd\u0caf \u0cb8\u0cae\u0caf',
                    value: toTime.format(ctx),
                    onTap: () async {
                      final t = await showTimePicker(context: ctx, initialTime: toTime);
                      if (t != null) setSheetState(() => toTime = t);
                    },
                  ),

                  const SizedBox(height: 24),

                  // SHARE VIA WHATSAPP
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('WhatsApp \u0ca8\u0cb2\u0ccd\u0cb2\u0cbf \u0cb9\u0c82\u0c9a\u0cbf\u0c95\u0cca\u0cb3\u0ccd\u0cb3\u0cbf', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final message = AppointmentService.customCalendarMessage(
                          fromDate: fromDate, toDate: toDate,
                          fromHour: fromTime.hour, fromMinute: fromTime.minute,
                          toHour: toTime.hour, toMinute: toTime.minute,
                        );
                        final encoded = Uri.encodeComponent(message);
                        launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // CREATE BOOKING LINK FOR CLIENTS
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.link, color: kTeal),
                      label: Text('ಬುಕಿಂಗ್ ಲಿಂಕ್ ಹಂಚಿಕೊಳ್ಳಿ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kTeal)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kTeal),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final bookingUrl = AppointmentService.generateBookingPageUrl(
                          fromDate: fromDate, toDate: toDate,
                          fromHour: fromTime.hour, fromMinute: fromTime.minute,
                          toHour: toTime.hour, toMinute: toTime.minute,
                        );
                        final msg = '\u0ca8\u0cae\u0cb8\u0ccd\u0c95\u0cbe\u0cb0,\n\n'
                            '\u0c85\u0caa\u0cbe\u0caf\u0cbf\u0c82\u0c9f\u0ccd\u200c\u0cae\u0cc6\u0c82\u0c9f\u0ccd \u0cac\u0cc1\u0c95\u0ccd \u0cae\u0cbe\u0ca1\u0cb2\u0cc1 \u0c88 \u0cb2\u0cbf\u0c82\u0c95\u0ccd \u0ca4\u0cc6\u0cb0\u0cc6\u0caf\u0cbf\u0cb0\u0cbf:\n'
                            '$bookingUrl\n\n'
                            '- \u0cad\u0cbe\u0cb0\u0ca4\u0cc0\u0caf\u0cae\u0ccd \u2728';
                        final encoded = Uri.encodeComponent(msg);
                        launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
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

  Widget _configTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kTeal.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: kTeal, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: kMuted, fontSize: 13))),
            Text(value, style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(width: 6),
            Icon(Icons.edit, color: kMuted, size: 16),
          ],
        ),
      ),
    );
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
