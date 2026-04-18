import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/common.dart';

import '../services/subscription_service.dart';
import '../services/trusted_time_service.dart';
import '../services/backup_service.dart';
import '../services/google_auth_service.dart';

import '../main.dart';
import '../services/tester_service.dart';
import '../services/local_export_service.dart';
import '../services/drive_backup_service.dart';

import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import '../services/location_service.dart';
import '../constants/places.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tzCtrl = TextEditingController();
  bool _geoLoading = false;
  String _geoStatus = '';

  @override
  void initState() {
    super.initState();
    _tzCtrl.text = '${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}';
  }

  Future<void> _performGeocode(String placeName) async {
    if (placeName.trim().isEmpty) return;
    setState(() { _geoLoading = true; _geoStatus = ''; });
    try {
      final q = Uri.encodeComponent(placeName.trim());
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setState(() => _geoStatus = 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.');
        } else if (data.length == 1) {
          // Only one result — auto-select
          await _applyGeoResult(data[0], placeName.trim());
        } else {
          // Multiple results — show selection dialog
          if (!mounted) return;
          final selected = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: kCard,
              title: Text('ಸ್ಥಳ ಆಯ್ಕೆಮಾಡಿ / Select Location',
                  style: TextStyle(color: kText, fontWeight: FontWeight.w900, fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: data.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: kBorder),
                  itemBuilder: (ctx, i) {
                    final item = data[i];
                    final displayName = item['display_name'] as String;
                    final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0;
                    final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0;
                    final type = item['type'] as String? ?? '';
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Icon(Icons.location_on, color: kPurple2, size: 20),
                      title: Text(
                        displayName,
                        style: TextStyle(fontSize: 13, color: kText),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}° • $type',
                        style: TextStyle(fontSize: 11, color: kMuted),
                      ),
                      onTap: () => Navigator.pop(ctx, item),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('ರದ್ದು / Cancel', style: TextStyle(color: kMuted)),
                ),
              ],
            ),
          );
          if (selected != null && mounted) {
            await _applyGeoResult(selected, placeName.trim());
          }
        }
      }
    } catch (_) {
      setState(() => _geoStatus = 'ಸ್ಥಳ ಸಂಪರ್ಕ ದೋಷ. ನೇರವಾಗಿ ಅಕ್ಷಾಂಶ/ರೇಖಾಂಶ ನಮೂದಿಸಿ.');
    }
    setState(() => _geoLoading = false);
  }

  /// Apply a selected geocode result
  Future<void> _applyGeoResult(Map<String, dynamic> result, String placeName) async {
    final lat = double.parse(result['lat'].toString());
    final lon = double.parse(result['lon'].toString());
    final displayName = result['display_name'] as String;
    final autoTz = await getTimezoneForPlace(displayName, lat, lon);
    await LocationService.setLocation(placeName, lat, lon, autoTz);
    if (mounted) {
      setState(() {
        _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
        _geoStatus = '📍 $displayName (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ಡೀಫಾಲ್ಟ್ ಸ್ಥಳ: $placeName'),
        backgroundColor: Colors.green,
      ));
    }
  }

  @override
  void dispose() {
    _tzCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themes = ['ಸ್ಟ್ಯಾಂಡರ್ಡ್ ಲೈಟ್', 'ಡಾರ್ಕ್ ಮೋಡ್', 'ಸ್ವರ್ಣ', 'ಸಾಗರ', 'ಹಸಿರು'];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಸೆಟ್ಟಿಂಗ್ಸ್ / Settings',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ResponsiveCenter(child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme selection
                    SectionTitle('ಥೀಮ್ ಸೆಟ್ಟಿಂಗ್ಸ್'),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<int>(
                      valueListenable: AppThemes.themeNotifier,
                      builder: (context, currentTheme, _) {
                        return Column(
                          children: List.generate(themes.length, (i) {
                            return RadioListTile<int>(
                              value: i,
                              groupValue: currentTheme,
                              title: Text(themes[i], style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                              activeColor: kPurple2,
                              onChanged: (val) {
                                if (val != null) {
                                  AppThemes.setTheme(val);
                                }
                              },
                            );
                          }),
                        );
                      }
                    ),
                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),

                    // Chart Style selection
                    SectionTitle('ಕುಂಡಲಿ ಶೈಲಿ / Chart Style'),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<String>(
                      valueListenable: ChartStyle.styleNotifier,
                      builder: (context, currentStyle, _) {
                        return Column(
                          children: [
                            RadioListTile<String>(
                              value: 'south',
                              groupValue: currentStyle,
                              title: Row(children: [
                                Text('ದಕ್ಷಿಣ ಭಾರತ ', style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                                Text('(South Indian)', style: TextStyle(color: kMuted, fontSize: 12)),
                              ]),
                              subtitle: Text('4×4 ಗ್ರಿಡ್ - ರಾಶಿ ಸ್ಥಿರ, ಗ್ರಹಗಳು ಚಲಿಸುವವು', style: TextStyle(fontSize: 11, color: kMuted)),
                              activeColor: kPurple2,
                              onChanged: (val) {
                                if (val != null) ChartStyle.setStyle(val);
                              },
                            ),
                            RadioListTile<String>(
                              value: 'north',
                              groupValue: currentStyle,
                              title: Row(children: [
                                Text('ಉತ್ತರ ಭಾರತ ', style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                                Text('(North Indian)', style: TextStyle(color: kMuted, fontSize: 12)),
                              ]),
                              subtitle: Text('ವಜ್ರ (Diamond) - ಭಾವ ಸ್ಥಿರ, ರಾಶಿಗಳು ಚಲಿಸುವವು', style: TextStyle(fontSize: 11, color: kMuted)),
                              activeColor: kPurple2,
                              onChanged: (val) {
                                if (val != null) ChartStyle.setStyle(val);
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),

                    // Default Location
                    SectionTitle('ಡೀಫಾಲ್ಟ್ ಸ್ಥಳ / Default Location'),
                    const SizedBox(height: 6),
                    Text('ಪಂಚಾಂಗ ಮತ್ತು ವೈದಿಕ ಗಡಿಯಾರ ಲೆಕ್ಕಾಚಾರಕ್ಕೆ ಬಳಸಲಾಗುತ್ತದೆ',
                      style: TextStyle(fontSize: 12, color: kMuted)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kBorder.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBorder.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.location_on, color: kPurple2, size: 22),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(LocationService.place, style: TextStyle(fontWeight: FontWeight.bold, color: kText, fontSize: 14)),
                            Text('${LocationService.lat.toStringAsFixed(2)}°N, ${LocationService.lon.toStringAsFixed(2)}°E | TZ: ${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}',
                              style: TextStyle(fontSize: 12, color: kMuted)),
                          ],
                        )),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return offlinePlaces.keys.take(15);
                        }
                        final query = textEditingValue.text.toLowerCase();
                        return offlinePlaces.keys.where(
                            (name) => name.toLowerCase().contains(query));
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'ಸ್ಥಳ ಹುಡುಕಿ / Search Location',
                            prefixIcon: Icon(Icons.search, color: kMuted),
                            suffixIcon: _geoLoading
                                ? Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPurple2)))
                                : IconButton(
                                    icon: Icon(Icons.travel_explore, color: kTeal),
                                    onPressed: () {
                                      _performGeocode(controller.text);
                                    },
                                    tooltip: 'ಆನ್‌ಲೈನ್ ಹುಡುಕಿ / Online Search',
                                  ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: TextStyle(color: kText),
                          onSubmitted: (_) {
                            _performGeocode(controller.text);
                          },
                        );
                      },
                      onSelected: (String selection) async {
                        if (offlinePlaces.containsKey(selection)) {
                          final coords = offlinePlaces[selection]!;
                          final autoTz = await getTimezoneForPlace(selection, coords[0], coords[1]);
                          _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                          await LocationService.setLocation(selection, coords[0], coords[1], autoTz);
                          if (mounted) {
                            setState(() {
                              _geoStatus = '';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('ಡೀಫಾಲ್ಟ್ ಸ್ಥಳ: $selection'),
                              backgroundColor: Colors.green,
                            ));
                          }
                        }
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            color: kCard,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 64),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(Icons.location_on, size: 18, color: kPurple2),
                                    title: Text(option, style: TextStyle(fontSize: 13, color: kText)),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_geoStatus.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(_geoStatus, style: TextStyle(fontSize: 12, color: _geoStatus.contains('ದೋಷ') || _geoStatus.contains('ಇಲ್ಲ') ? Colors.redAccent : Colors.green)),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tzCtrl,
                      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      style: TextStyle(color: kText),
                      decoration: InputDecoration(
                        labelText: 'Time Zone (UTC Offset, e.g. 5.5)',
                        prefixIcon: Icon(Icons.language, color: kMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (val) async {
                        final tz = double.tryParse(val) ?? 5.5;
                        await LocationService.setLocation(LocationService.place, LocationService.lat, LocationService.lon, tz);
                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Time Zone updated to: $tz'),
                            backgroundColor: Colors.green,
                          ));
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),

                    // Google Account
                    SectionTitle(AppLocale.l('googleAccount')),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GoogleAuthService.isSignedIn ? Colors.green.withOpacity(0.08) : kBorder.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GoogleAuthService.isSignedIn ? Colors.green.withOpacity(0.3) : kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (GoogleAuthService.isSignedIn) ...[
                            Row(children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 28),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(GoogleAuthService.userName ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: kText)),
                                  Text(GoogleAuthService.userEmail ?? '', style: TextStyle(fontSize: 12, color: kMuted)),
                                  const SizedBox(height: 6),
                                  ValueListenableBuilder<String>(
                                    valueListenable: TesterService.statusMessage,
                                    builder: (context, msg, _) => Text(
                                      'Beta Status: $msg',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: msg.contains('Verified') ? Colors.green : Colors.red),
                                    ),
                                  ),
                                ],
                              )),
                            ]),
                            const SizedBox(height: 12),
                            Text('Google ಸಿಂಕ್ ಸಕ್ರಿಯವಾಗಿದೆ', style: TextStyle(fontSize: 13, color: Colors.green)),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () async {
                                await GoogleAuthService.signOut();
                                if (mounted) setState(() {});
                              },
                              child: Text('Sign Out', style: TextStyle(color: kMuted)),
                            ),
                            const SizedBox(height: 8),

                          ] else ...[
                            Row(children: [
                              Icon(Icons.account_circle, color: kPurple2, size: 28),
                              const SizedBox(width: 12),
                              Expanded(child: Text('ಕ್ಲೌಡ್ ಬ್ಯಾಕಪ್‌ಗಾಗಿ Google ಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ',
                                style: TextStyle(fontSize: 14, color: kText))),
                            ]),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final ok = await GoogleAuthService.signIn();
                                if (mounted) {
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(ok ? 'Google Sign In ಯಶಸ್ವಿ!' : 'Sign In ವಿಫಲ'),
                                  ));
                                }
                              },
                              icon: Icon(Icons.login),
                              label: Text('Google Sign In'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPurple2,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),




                    // Backup & Restore
                    SectionTitle('ಡೇಟಾ ಬ್ಯಾಕಪ್ ಮತ್ತು ಮರುಸ್ಥಾಪನೆ (Data Backup & Restore)'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBorder.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('ನಿಮ್ಮ ಎಲ್ಲಾ ನಿಯತಕಾಲಿಕ ಡೇಟಾವನ್ನು (ಗ್ರಾಹಕರು, ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್\u200cಗಳು) ಬ್ಯಾಕಪ್ ಮಾಡಿ ಮತ್ತು ಹೊಸ ಸಾಧನಕ್ಕೆ ಮರುಸ್ಥಾಪಿಸಿ.',
                              style: TextStyle(fontSize: 13, color: kMuted)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final ok = await BackupService.exportData();
                                    if (mounted && ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('ಬ್ಯಾಕಪ್ ಫೈಲ್ ಅನ್ನು ಉಳಿಸಲು ಅಪ್ಲಿಕೇಶನ್ ಆಯ್ಕೆಮಾಡಿ.'))
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('ಬ್ಯಾಕಪ್ ರಫ್ತು ಮಾಡಿ\n(Export)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kTeal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final err = await BackupService.importData();
                                    if (mounted) {
                                      if (err == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('ಡೇಟಾ ಯಶಸ್ವಿಯಾಗಿ ಮರುಸ್ಥಾಪನೆಯಾಗಿದೆ!'), backgroundColor: Colors.green)
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(err), backgroundColor: Colors.red)
                                        );
                                      }
                                    }
                                  },
                                  icon: Icon(Icons.file_download, color: kPurple2),
                                  label: Text('ಬ್ಯಾಕಪ್ ಆಮದು ಮಾಡಿ\n(Import)', style: TextStyle(color: kText)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: kBorder),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('ಮಾನವ ಓದಬಲ್ಲ ಸ್ಪ್ರೆಡ್‌ಶೀಟ್‌ಗಳು (Human-readable Spreadsheets & Notes):',
                              style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final ok = await LocalExportService.exportReadableData();
                              if (mounted) {
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('ಸ್ಪ್ರೆಡ್‌ಶೀಟ್ ಮತ್ತು ಟಿಪ್ಪಣಿಗಳನ್ನು ರಫ್ತು ಮಾಡಲಾಗಿದೆ!'), backgroundColor: Colors.green)
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('ರಫ್ತು ವಿಫಲವಾಗಿದೆ (Export failed).'), backgroundColor: Colors.red)
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.table_view),
                            label: const Text('ಸ್ಪ್ರೆಡ್‌ಶೀಟ್ ಮತ್ತು ಟಿಪ್ಪಣಿಗಳನ್ನು ರಫ್ತು ಮಾಡಿ\n(Export Spreadsheets & Notes)', textAlign: TextAlign.center),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPurple2,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),

                    // Google Drive Backup
                    SectionTitle('Google Drive ಬ್ಯಾಕಪ್ (Cloud Backup)'),
                    const SizedBox(height: 12),
                    _buildDriveBackupSection(),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),
                    
                    // Purchase Premium
                    SectionTitle('ಪ್ರೀಮಿಯಂ ಚಂದಾದಾರಿಕೆ'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SubscriptionService.hasSubscription ? Colors.green.shade50 : kPurple1.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SubscriptionService.hasSubscription ? Colors.green.shade200 : kPurple2.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                           Row(
                             children: [
                               Icon(
                                 SubscriptionService.hasSubscription ? Icons.check_circle : Icons.star, 
                                 color: SubscriptionService.hasSubscription ? Colors.green.shade700 : kOrange,
                                 size: 28,
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Text(
                                   SubscriptionService.hasSubscription 
                                      ? 'ನೀವು ಪ್ರೀಮಿಯಂ ಸದಸ್ಯರು! (Premium Active)' 
                                      : 'ಪ್ರೀಮಿಯಂ ಲಭ್ಯತೆ ಪಡೆಯಿರಿ',
                                   style: TextStyle(
                                     fontSize: SubscriptionService.hasSubscription ? 16 : 18, 
                                     fontWeight: FontWeight.bold,
                                     color: SubscriptionService.hasSubscription ? Colors.green.shade800 : kPurple1
                                   ),
                                 ),
                               ),
                             ],
                           ),
                           // ── Subscription Status Info ──
                           const SizedBox(height: 12),
                           Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: kBorder.withOpacity(0.12),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(children: [
                                   Icon(Icons.verified_user, size: 16,
                                     color: SubscriptionService.hasSubscription ? Colors.green : kMuted),
                                   const SizedBox(width: 8),
                                   Expanded(child: Text(
                                     SubscriptionService.statusText,
                                     style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText),
                                   )),
                                 ]),
                                 if (SubscriptionService.hasSubscription && SubscriptionService.subscriptionDaysRemaining > 0) ...[
                                   const SizedBox(height: 8),
                                   ClipRRect(
                                     borderRadius: BorderRadius.circular(4),
                                     child: LinearProgressIndicator(
                                       value: SubscriptionService.subscriptionDaysRemaining / 365,
                                       backgroundColor: kBorder.withOpacity(0.3),
                                       color: SubscriptionService.subscriptionDaysRemaining > 30 ? Colors.green : Colors.orange,
                                       minHeight: 6,
                                     ),
                                   ),
                                   const SizedBox(height: 4),
                                   Text('${SubscriptionService.subscriptionDaysRemaining} / 365 ದಿನ ಬಾಕಿ',
                                     style: TextStyle(fontSize: 11, color: kMuted)),
                                 ],
                                 const SizedBox(height: 10),
                                 Row(children: [
                                   Icon(
                                     SubscriptionService.isGracePeriodActive ? Icons.shield : Icons.shield_outlined,
                                     size: 16,
                                     color: SubscriptionService.isGracePeriodActive ? Colors.orange : kMuted,
                                   ),
                                   const SizedBox(width: 8),
                                   Expanded(child: Text(
                                     SubscriptionService.graceStatusText,
                                     style: TextStyle(
                                       fontSize: 12,
                                       color: SubscriptionService.isGracePeriodActive ? Colors.orange.shade800 : kMuted,
                                       fontWeight: SubscriptionService.isGracePeriodActive ? FontWeight.w700 : FontWeight.normal,
                                     ),
                                   )),
                                 ]),
                                 if (SubscriptionService.isGracePeriodActive) ...[
                                   const SizedBox(height: 6),
                                   ClipRRect(
                                     borderRadius: BorderRadius.circular(4),
                                     child: LinearProgressIndicator(
                                       value: SubscriptionService.gracePeriodRemainingHours / 48,
                                       backgroundColor: kBorder.withOpacity(0.3),
                                       color: Colors.orange,
                                       minHeight: 4,
                                     ),
                                   ),
                                 ],
                               ],
                             ),
                           ),
                           if (!SubscriptionService.hasSubscription) ...[
                             const SizedBox(height: 12),
                             Text(
                               'ವರ್ಷಕ್ಕೆ ಕೇವಲ ₹೭೦೦ ಪಾವತಿಸಿ ಮತ್ತು ಎಲ್ಲಾ ಕುಂಡಲಿ ಹಾಗೂ ಪಂಚಾಂಗ ವೈಶಿಷ್ಟ್ಯಗಳನ್ನು ಬಳಸಿ.',
                               style: TextStyle(fontSize: 14, color: kText, height: 1.4),
                             ),
                             const SizedBox(height: 20),
                             ElevatedButton(
                               onPressed: () async {
                                 final success = await SubscriptionService.buySubscription();
                                 if (!success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('ಚಂದಾದಾರಿಕೆ ಪ್ರಕ್ರಿಯೆ ವಿಫಲವಾಗಿದೆ ಅಥವಾ ನೀವು ವೆಬ್ ಬಳಸುತ್ತಿದ್ದೀರಿ.'))
                                    );
                                 }
                               },
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: kOrange,
                                 foregroundColor: Colors.white,
                                 padding: const EdgeInsets.symmetric(vertical: 14),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                               ),
                               child: const Text('₹700 / ವರ್ಷಕ್ಕೆ ಚಂದಾದಾರರಾಗಿ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                             ),
                             const SizedBox(height: 12),
                             TextButton(
                               onPressed: () async {
                                  await SubscriptionService.restorePurchases();
                                  if (mounted) {
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('ಹಿಂದಿನ ಖರೀದಿಗಳನ್ನು ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ.'))
                                    );
                                  }
                               },
                               child: Text('ಹಿಂದಿನ ಖರೀದಿಯನ್ನು ಮರುಸ್ಥಾಪಿಸಿ (Restore)', style: TextStyle(color: kPurple2, fontWeight: FontWeight.w600)),
                             )
                           ]
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),

                    // Clock / NTP Status
                    SectionTitle('ಸಮಯ ಪರಿಶೀಲನೆ / Clock Verification'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TrustedTimeService.isClockTampered
                            ? Colors.red.withOpacity(0.08)
                            : TrustedTimeService.hasTrustedTime
                                ? Colors.green.withOpacity(0.08)
                                : kBorder.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TrustedTimeService.isClockTampered
                              ? Colors.red.withOpacity(0.3)
                              : TrustedTimeService.hasTrustedTime
                                  ? Colors.green.withOpacity(0.3)
                                  : kBorder.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(
                              TrustedTimeService.isClockTampered
                                  ? Icons.warning_amber_rounded
                                  : TrustedTimeService.hasTrustedTime
                                      ? Icons.access_time_filled
                                      : Icons.access_time,
                              color: TrustedTimeService.isClockTampered
                                  ? Colors.red
                                  : TrustedTimeService.hasTrustedTime
                                      ? Colors.green
                                      : kMuted,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(
                              TrustedTimeService.statusText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: TrustedTimeService.isClockTampered ? Colors.red : kText,
                              ),
                            )),
                          ]),
                          if (TrustedTimeService.isClockTampered) ...[
                            const SizedBox(height: 8),
                            Text(
                              'ನಿಮ್ಮ ಫೋನ್ ಗಡಿಯಾರ ಬದಲಾಗಿದೆ. ಸರಿಯಾದ ಸಮಯಕ್ಕೆ ಹೊಂದಿಸಿ.',
                              style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                            ),
                            Text(
                              'Your phone clock appears modified. Set to automatic time.',
                              style: TextStyle(fontSize: 11, color: kMuted),
                            ),
                          ],
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            icon: Icon(Icons.sync, size: 18, color: kPurple2),
                            label: Text('NTP ಮರುಸಿಂಕ್ / Re-sync Clock', style: TextStyle(color: kPurple2, fontSize: 13)),
                            onPressed: () async {
                              final ok = await TrustedTimeService.syncWithNtp();
                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? 'NTP ಸಿಂಕ್ ಯಶಸ್ವಿ!' : 'NTP ಸಿಂಕ್ ವಿಫಲ — ಇಂಟರ್ನೆಟ್ ಪರಿಶೀಲಿಸಿ'),
                                  backgroundColor: ok ? Colors.green : Colors.red,
                                ));
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),

                    // About Us
                    ListTile(
                      leading: Icon(Icons.info_outline, color: kPurple2),
                      title: Text('ನಮ್ಮ ಬಗ್ಗೆ / About Us',
                          style: TextStyle(color: kText, fontSize: 14)),
                      trailing: Icon(Icons.chevron_right, color: kMuted),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    // Privacy Policy
                    ListTile(
                      leading: Icon(Icons.shield_outlined, color: kPurple2),
                      title: Text('ಗೌಪ್ಯತಾ ನೀತಿ / Privacy Policy',
                          style: TextStyle(color: kText, fontSize: 14)),
                      trailing: Icon(Icons.chevron_right, color: kMuted),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      ),
                    ),
                  ],
                ),
              )),
            ),
          ),

        ],
      ),
    );
  }

  // Old Online Search dialog removed in favor of inline Geocode search

  Widget _buildDriveBackupSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBorder.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: const Color(0xFF4285F4), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ನಿಮ್ಮ ಡೇಟಾವನ್ನು Google Drive ನಲ್ಲಿ ಸುರಕ್ಷಿತವಾಗಿ ಬ್ಯಾಕಪ್ ಮಾಡಿ.\nYour data is stored securely in your own Google Drive.',
                  style: TextStyle(fontSize: 12, color: kMuted, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Last backup info
          FutureBuilder<Map<String, String>?>(
            future: GoogleAuthService.isSignedIn
                ? DriveBackupService.getBackupInfo()
                : Future.value(null),
            builder: (context, snapshot) {
              if (!GoogleAuthService.isSignedIn) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Google Drive ಬ್ಯಾಕಪ್ ಬಳಸಲು ದಯವಿಟ್ಟು ಮೊದಲು ಸೈನ್ ಇನ್ ಮಾಡಿ.',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kMuted)),
                      const SizedBox(width: 8),
                      Text('ಬ್ಯಾಕಪ್ ಮಾಹಿತಿ ಪಡೆಯಲಾಗುತ್ತಿದೆ...', style: TextStyle(fontSize: 12, color: kMuted)),
                    ],
                  ),
                );
              }

              final info = snapshot.data;
              if (info != null) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ಕೊನೆಯ ಬ್ಯಾಕಪ್: ${info['lastBackup']}  (${info['size']})',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ಇನ್ನೂ ಯಾವುದೇ ಬ್ಯಾಕಪ್ ಇಲ್ಲ (No backup yet)',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          // Backup & Restore buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: GoogleAuthService.isSignedIn ? () async {
                    // Show loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('☁️ Google Drive ಗೆ ಬ್ಯಾಕಪ್ ಮಾಡಲಾಗುತ್ತಿದೆ...'), duration: Duration(seconds: 2)),
                    );
                    final result = await DriveBackupService.uploadBackup();
                    if (mounted) {
                      if (result == 'success') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Google Drive ಗೆ ಬ್ಯಾಕಪ್ ಯಶಸ್ವಿ!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {}); // Refresh backup info
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result), backgroundColor: Colors.red),
                        );
                      }
                    }
                  } : null,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Drive ಗೆ\nಬ್ಯಾಕಪ್', textAlign: TextAlign.center),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: GoogleAuthService.isSignedIn ? () async {
                    // Confirm before restore
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: kCard,
                        title: Text('Drive ಬ್ಯಾಕಪ್ ಮರುಸ್ಥಾಪನೆ', style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
                        content: Text(
                          'Google Drive ನಿಂದ ಡೇಟಾ ಮರುಸ್ಥಾಪಿಸುವುದರಿಂದ ಪ್ರಸ್ತುತ ಡೇಟಾ ಬದಲಾಗುತ್ತದೆ.\n\n'
                          'ಮುಂದುವರಿಸಬೇಕೇ?\n\n'
                          '(Restoring will overwrite current data. Continue?)',
                          style: TextStyle(color: kMuted, height: 1.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('ಬೇಡ', style: TextStyle(color: kMuted)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('ಮರುಸ್ಥಾಪಿಸಿ', style: TextStyle(color: const Color(0xFF4285F4), fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('☁️ Google Drive ನಿಂದ ಮರುಸ್ಥಾಪಿಸಲಾಗುತ್ತಿದೆ...'), duration: Duration(seconds: 2)),
                      );
                    }
                    final err = await DriveBackupService.downloadAndRestore();
                    if (mounted) {
                      if (err == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Google Drive ನಿಂದ ಡೇಟಾ ಯಶಸ್ವಿಯಾಗಿ ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err), backgroundColor: Colors.red),
                        );
                      }
                    }
                  } : null,
                  icon: Icon(Icons.cloud_download, color: GoogleAuthService.isSignedIn ? const Color(0xFF4285F4) : Colors.grey),
                  label: Text('Drive ನಿಂದ\nಮರುಸ್ಥಾಪಿಸಿ', textAlign: TextAlign.center, style: TextStyle(color: kText)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: GoogleAuthService.isSignedIn ? const Color(0xFF4285F4) : Colors.grey.shade300),
                    disabledForegroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

