import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../services/client_service.dart';
import '../services/appointment_service.dart';
import '../services/storage_service.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../constants/places.dart';
import '../services/location_service.dart';
import 'dashboard_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  List<FamilyMember> _members = [];
  List<Appointment> _history = [];
  bool _loading = true;
  bool _familyMode = false;
  Set<int> _selectedMembers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _members = ClientService.getMembersForClient(widget.client.clientId);
    // Find all appointments for this client
    final phone = widget.client.phone.replaceAll(RegExp(r'[^0-9]'), '');
    _history = AppointmentService.appointments.where((a) {
      return a.clientId == widget.client.clientId ||
             a.clientPhone.replaceAll(RegExp(r'[^0-9]'), '') == phone;
    }).toList()..sort((a, b) => b.date.compareTo(a.date)); // newest first

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(widget.client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kBg,
        foregroundColor: kText,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientHeader(),
                  _buildHistorySection(),
                  _buildModeToggle(),
                  _buildMembersList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_familyMode && _selectedMembers.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'generate_family',
              onPressed: () => _generateKundali(familyMode: true),
              backgroundColor: kTeal,
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text('ರಚಿಸಿ (${_selectedMembers.length})', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            )
          else if (!_familyMode && _members.isNotEmpty)
            const SizedBox.shrink(),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_member',
            onPressed: _showAddMemberDialog,
            backgroundColor: kPurple2,
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildClientHeader() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: kPurple2.withOpacity(0.2),
                radius: 28,
                child: Text(
                  widget.client.name.isNotEmpty ? widget.client.name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPurple2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.client.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kTeal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(widget.client.clientId, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTeal)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: kMuted),
                onPressed: _showEditClientDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.phone, widget.client.phone),
          if (widget.client.email.isNotEmpty) _infoRow(Icons.email, widget.client.email),
          if (widget.client.address.isNotEmpty) _infoRow(Icons.location_on, widget.client.address),
          _infoRow(Icons.calendar_today, 'ಗ್ರಾಹಕರ ದಿನಾಂಕ: ${widget.client.createdAt}'),
          if (_history.isNotEmpty)
            _infoRow(Icons.repeat, '${_history.length} ಭೇಟಿಗಳು | ಕೊನೆ: ${_history.first.dateStr}'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: kText))),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('📅 ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ಇತಿಹಾಸ'),
          ..._history.take(5).map((a) => Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kBg, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: a.status == 'completed' ? kGreen.withOpacity(0.15) : kTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    a.status == 'completed' ? Icons.check_circle : Icons.schedule,
                    size: 18,
                    color: a.status == 'completed' ? kGreen : kTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${a.dateStr} | ${a.timeRange}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                      if (a.notes.isNotEmpty)
                        Text(a.notes, style: TextStyle(fontSize: 12, color: kMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(a.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(a.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(a.status))),
                ),
              ],
            ),
          )),
          if (_history.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('+ ${_history.length - 5} ಹೆಚ್ಚಿನ ಭೇಟಿಗಳು', style: TextStyle(fontSize: 12, color: kMuted)),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return kGreen;
      case 'cancelled': return Colors.red;
      default: return kTeal;
    }
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('👥 ಕುಟುಂಬ ಸದಸ್ಯರು', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPurple2)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: kCard, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modeChip('ಒಬ್ಬರು', !_familyMode, () => setState(() { _familyMode = false; _selectedMembers.clear(); })),
                _modeChip('ಕುಟುಂಬ', _familyMode, () => setState(() => _familyMode = true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800,
          color: selected ? Colors.white : kMuted,
        )),
      ),
    );
  }

  Widget _buildMembersList() {
    if (_members.isEmpty) {
      return AppCard(
        child: Center(
          child: Column(
            children: [
              Icon(Icons.person_add, size: 48, color: kMuted),
              const SizedBox(height: 8),
              Text('ಇನ್ನೂ ಸದಸ್ಯರಿಲ್ಲ. ➕ ಬಟನ್ ಒತ್ತಿ ಸೇರಿಸಿ.', style: TextStyle(color: kMuted, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _members.asMap().entries.map((entry) {
        final i = entry.key;
        final m = entry.value;
        final isSelected = _selectedMembers.contains(i);

        return GestureDetector(
          onTap: () {
            if (_familyMode) {
              setState(() {
                if (isSelected) _selectedMembers.remove(i);
                else _selectedMembers.add(i);
              });
            } else {
              _generateKundaliForMember(m);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? kTeal.withOpacity(0.1) : kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? kTeal : kBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (_familyMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected ? kTeal : kMuted,
                    ),
                  ),
                CircleAvatar(
                  backgroundColor: _relationColor(m.relation).withOpacity(0.15),
                  radius: 22,
                  child: Text(
                    m.memberName.isNotEmpty ? m.memberName[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.w900, color: _relationColor(m.relation)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(m.memberName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kText))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _relationColor(m.relation).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(m.relation, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _relationColor(m.relation))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${m.dob} | ${m.birthTime} | ${m.birthPlace}', style: TextStyle(fontSize: 12, color: kMuted)),
                    ],
                  ),
                ),
                if (!_familyMode)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kTeal.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.auto_awesome, color: kTeal, size: 20),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _relationColor(String relation) {
    switch (relation) {
      case 'Self': return kTeal;
      case 'Wife': case 'Husband': return kPurple2;
      case 'Son': case 'Daughter': return kOrange;
      case 'Father': case 'Mother': return kGreen;
      default: return kPurple1;
    }
  }

  // ─── Kundali Generation ──────────────────────────────────

  Future<void> _generateKundaliForMember(FamilyMember m) async {
    final dob = m.dobDate;
    if (dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ಜನ್ಮ ದಿನಾಂಕ ಸರಿಯಾಗಿಲ್ಲ')));
      return;
    }
    _showLoading();

    try {
      final localHour = m.hour + m.minute / 60.0;
      final result = await AstroCalculator.calculate(
        year: dob.year, month: dob.month, day: dob.day,
        hourUtcOffset: LocationService.tzOffset,
        hour24: localHour,
        lat: m.lat, lon: m.lon,
        ayanamsaMode: 'lahiri',
        trueNode: true,
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // dismiss loading safely

      if (result != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) {
            return DashboardScreen(
              result: result,
              name: m.memberName,
              place: m.birthPlace,
              dob: dob,
              hour: m.hour12,
              minute: m.minute,
              ampm: m.ampm,
              lat: m.lat,
              lon: m.lon,
              extraInfo: {'clientId': m.clientId},
              initialNotes: m.notes,
              onSave: (notes, aroodhas, janmaIdx, {bool isNew = true}) {
              // Save notes back to member
              final updated = FamilyMember(
                clientId: m.clientId,
                memberName: m.memberName,
                relation: m.relation,
                dob: m.dob,
                birthTime: m.birthTime,
                birthPlace: m.birthPlace,
                lat: m.lat, lon: m.lon,
                notes: notes,
              );
              ClientService.updateFamilyMember(updated);
              // Also save locally
              StorageService.save(Profile(
                name: m.memberName,
                date: m.dob,
                hour: m.hour12, minute: m.minute, ampm: m.ampm,
                lat: m.lat, lon: m.lon,
                place: m.birthPlace,
                notes: notes,
                aroodhas: aroodhas,
                janmaNakshatraIdx: janmaIdx,
                clientId: m.clientId,
              ));
            },
           );
          },
        )).then((_) {
          _loadData(); // refresh after returning
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ದೋಷ: $e')));
      }
    }
  }

  Future<void> _generateKundali({required bool familyMode}) async {
    if (!familyMode || _selectedMembers.isEmpty) return;

    final selected = _selectedMembers.map((i) => _members[i]).toList();
    // Generate for the first member, then user can switch
    _generateKundaliForMember(selected.first);
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  // ─── Add Member Dialog ──────────────────────────────────

  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final placeCtrl = TextEditingController(text: 'Yellapur');
    final latCtrl = TextEditingController(text: '14.9800');
    final lonCtrl = TextEditingController(text: '74.7300');
    DateTime dob = DateTime(1990, 1, 1);
    int hour = 12, minute = 0;
    String ampm = 'PM';
    String relation = 'Self';

    final relations = ['Self', 'Wife', 'Husband', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('➕ ಸದಸ್ಯ ಸೇರಿಸಿ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple2)),
                const SizedBox(height: 16),

                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'ಹೆಸರು', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),

                // Relation
                DropdownButtonFormField<String>(
                  value: relation,
                  decoration: const InputDecoration(labelText: 'ಸಂಬಂಧ', prefixIcon: Icon(Icons.family_restroom)),
                  items: relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setS(() => relation = v!),
                ),
                const SizedBox(height: 12),

                // DOB
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dob,
                      firstDate: DateTime(1800),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setS(() => dob = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: kCard, border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today, color: kMuted),
                      const SizedBox(width: 10),
                      Text('ದಿನಾಂಕ: ${dob.day.toString().padLeft(2, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.year}',
                        style: TextStyle(color: kText)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Time
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay(hour: ampm == 'PM' && hour != 12 ? hour + 12 : (ampm == 'AM' && hour == 12 ? 0 : hour), minute: minute),
                    );
                    if (picked != null) {
                      setS(() {
                        ampm = picked.hour >= 12 ? 'PM' : 'AM';
                        hour = picked.hour % 12 == 0 ? 12 : picked.hour % 12;
                        minute = picked.minute;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: kCard, border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.access_time, color: kMuted),
                      const SizedBox(width: 10),
                      Text('ಸಮಯ: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm',
                        style: TextStyle(color: kText)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Place with offline autocomplete
                Autocomplete<String>(
                  optionsBuilder: (v) {
                    if (v.text.isEmpty) return offlinePlaces.keys.take(10);
                    final q = v.text.toLowerCase();
                    return offlinePlaces.keys.where((n) => n.toLowerCase().contains(q));
                  },
                  fieldViewBuilder: (context, textCtrl, focusNode, onSubmit) {
                    return TextField(
                      controller: textCtrl,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'ಜನ್ಮ ಸ್ಥಳ', prefixIcon: Icon(Icons.location_on)),
                    );
                  },
                  onSelected: (selection) {
                    if (offlinePlaces.containsKey(selection)) {
                      final coords = offlinePlaces[selection]!;
                      setS(() {
                        placeCtrl.text = selection;
                        latCtrl.text = coords[0].toStringAsFixed(4);
                        lonCtrl.text = coords[1].toStringAsFixed(4);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Lat/Lon
                Row(children: [
                  Expanded(child: TextField(
                    controller: latCtrl,
                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'ಅಕ್ಷಾಂಶ'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: lonCtrl,
                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'ರೇಖಾಂಶ'),
                  )),
                ]),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('ಸೇರಿಸಿ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);

                      final member = FamilyMember(
                        clientId: widget.client.clientId,
                        memberName: nameCtrl.text.trim(),
                        relation: relation,
                        dob: '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
                        birthTime: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm',
                        birthPlace: placeCtrl.text,
                        lat: double.tryParse(latCtrl.text) ?? 14.98,
                        lon: double.tryParse(lonCtrl.text) ?? 74.73,
                      );

                      final ok = await ClientService.addFamilyMember(member);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'ಸದಸ್ಯ ಸೇರಿಸಲಾಗಿದೆ!' : 'ದೋಷ ಸಂಭವಿಸಿದೆ')));
                        _loadData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Edit Client Dialog ──────────────────────────────────

  void _showEditClientDialog() {
    final nameCtrl = TextEditingController(text: widget.client.name);
    final phoneCtrl = TextEditingController(text: widget.client.phone);
    final emailCtrl = TextEditingController(text: widget.client.email);
    final addressCtrl = TextEditingController(text: widget.client.address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✏️ ಗ್ರಾಹಕ ವಿವರ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple2)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ಹೆಸರು')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'ಫೋನ್'), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'ಇಮೇಲ್')),
            const SizedBox(height: 10),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'ವಿಳಾಸ')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final updated = Client(
                    clientId: widget.client.clientId,
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    createdAt: widget.client.createdAt,
                  );
                  await ClientService.updateClient(updated);
                  if (mounted) setState(() {});
                },
                style: ElevatedButton.styleFrom(backgroundColor: kTeal, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('ನವೀಕರಿಸಿ', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
