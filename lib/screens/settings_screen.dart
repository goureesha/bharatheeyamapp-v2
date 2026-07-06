import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/common.dart';

import '../services/subscription_service.dart';
import '../services/trusted_time_service.dart';
import '../services/backup_service.dart';
import '../services/google_auth_service.dart';
import '../services/device_binding_service.dart';
import '../main.dart';
import '../services/tester_service.dart';
import '../services/local_export_service.dart';
import '../services/drive_backup_service.dart';
import 'support_screen.dart';

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
          setState(() => _geoStatus = AppLocale.l('placeNotFoundDash'));
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
              title: Text('${AppLocale.l('selectLocation')} / Select Location',
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
                  child: Text('${AppLocale.l('cancel')} / Cancel', style: TextStyle(color: kMuted)),
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
      setState(() => _geoStatus = AppLocale.l('placeError'));
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
        content: Text('${AppLocale.l('defaultLocationSet')}: $placeName'),
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
    final themes = [AppLocale.l('themeLight'), AppLocale.l('themeDark'), AppLocale.l('themeGold'), AppLocale.l('themeOcean'), AppLocale.l('themeGreen')];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('${AppLocale.l('settings')} / Settings',
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
                    SectionTitle(AppLocale.l('themeSettings')),
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
                    SectionTitle('${AppLocale.l('chartStyle')} / Chart Style'),
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
                                Text('${AppLocale.l('southIndian')} ', style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                                Text('(South Indian)', style: TextStyle(color: kMuted, fontSize: 12)),
                              ]),
                              subtitle: Text(AppLocale.l('southDesc'), style: TextStyle(fontSize: 11, color: kMuted)),
                              activeColor: kPurple2,
                              onChanged: (val) {
                                if (val != null) ChartStyle.setStyle(val);
                              },
                            ),
                            RadioListTile<String>(
                              value: 'north',
                              groupValue: currentStyle,
                              title: Row(children: [
                                Text('${AppLocale.l('northIndian')} ', style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                                Text('(North Indian)', style: TextStyle(color: kMuted, fontSize: 12)),
                              ]),
                              subtitle: Text(AppLocale.l('northDesc'), style: TextStyle(fontSize: 11, color: kMuted)),
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

                    // Samshaka Kundali toggle
                    SectionTitle('${AppLocale.l('samshakaTitle')} / Samshaka Kundali'),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<bool>(
                      valueListenable: SamshakaMode.notifier,
                      builder: (context, isActive, _) {
                        return SwitchListTile(
                          value: isActive,
                          onChanged: (val) => SamshakaMode.toggle(val),
                          activeColor: kPurple2,
                          title: Text(AppLocale.l('samshakaLabel'), style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                          subtitle: Text(
                            AppLocale.l('samshakaDesc'),
                            style: TextStyle(fontSize: 11, color: kMuted),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),

                    // Language selection
                    SectionTitle(AppLocale.l('language')),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<String>(
                      valueListenable: AppLocale.langNotifier,
                      builder: (context, currentLang, _) {
                        final langs = [
                          {'code': 'kn', 'label': 'ಕನ್ನಡ', 'sub': 'Kannada'},
                          {'code': 'hi', 'label': 'हिन्दी', 'sub': 'Hindi'},
                          {'code': 'ta', 'label': 'தமிழ்', 'sub': 'Tamil'},
                          {'code': 'te', 'label': 'తెలుగు', 'sub': 'Telugu'},
                          {'code': 'ml', 'label': 'മലയാളം', 'sub': 'Malayalam'},
                        ];
                        return Column(
                          children: langs.map((l) => RadioListTile<String>(
                            value: l['code']!,
                            groupValue: currentLang,
                            title: Row(children: [
                              Text(l['label']!, style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                              const SizedBox(width: 8),
                              Text('(${l['sub']!})', style: TextStyle(color: kMuted, fontSize: 12)),
                            ]),
                            activeColor: kPurple2,
                            onChanged: (val) {
                              if (val != null) {
                                AppLocale.setLang(val);
                                setState(() {});
                              }
                            },
                          )).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),

                    // Default Location
                    SectionTitle(AppLocale.l('defaultLocation')),
                    const SizedBox(height: 6),
                    Text(AppLocale.l('locationHint'),
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
                            labelText: '${AppLocale.l('searchLocation')} / Search Location',
                            prefixIcon: Icon(Icons.search, color: kMuted),
                            suffixIcon: _geoLoading
                                ? Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPurple2)))
                                : IconButton(
                                    icon: Icon(Icons.travel_explore, color: kTeal),
                                    onPressed: () {
                                      _performGeocode(controller.text);
                                    },
                                    tooltip: '${AppLocale.l('onlineSearch')} / Online Search',
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
                              content: Text('${AppLocale.l('defaultLocationSet')}: $selection'),
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
                      Text(_geoStatus, style: TextStyle(fontSize: 12, color: _geoStatus.contains(AppLocale.l('errorLabel')) || _geoStatus.contains(AppLocale.l('placeNotFoundDash')) ? Colors.redAccent : Colors.green)),
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
                                          color: msg.contains('Verified') ? Colors.green
                                              : msg.contains('rules') || msg.contains('Auth') ? Colors.orange
                                              : msg.contains('Offline') || msg.contains('cached') ? Colors.grey
                                              : Colors.red),
                                    ),
                                  ),
                                  Text(
                                    'Firebase Auth: ${GoogleAuthService.isFirebaseAuthActive ? "Active ✅" : "Inactive ❌"}',
                                    style: TextStyle(fontSize: 10, color: GoogleAuthService.isFirebaseAuthActive ? Colors.green : Colors.red),
                                  ),
                                  if (SubscriptionService.manualPremium)
                                    Text(
                                      'Beta Access: Active ✅${SubscriptionService.manualPremiumExpiry != null ? " (${SubscriptionService.manualPremiumExpiry!.day}/${SubscriptionService.manualPremiumExpiry!.month}/${SubscriptionService.manualPremiumExpiry!.year})" : ""}',
                                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              )),
                            ]),
                            const SizedBox(height: 12),
                            Text(AppLocale.l('googleSyncActive'), style: TextStyle(fontSize: 13, color: Colors.green)),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () async {
                                await GoogleAuthService.signOut();
                                if (mounted) setState(() {});
                              },
                              child: Text('Sign Out', style: TextStyle(color: kMuted)),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              icon: Icon(Icons.swap_horiz, color: kPurple2, size: 18),
                              label: Text('${AppLocale.l('migrateDevice')} / Migrate Device', style: TextStyle(color: kPurple2, fontSize: 13)),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                                  backgroundColor: kCard,
                                  title: Text(AppLocale.l('migrateConfirm'), style: TextStyle(color: kText)),
                                  content: Text(AppLocale.l('migrateMsg'), style: TextStyle(color: kText)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocale.l('cancel'), style: TextStyle(color: kMuted))),
                                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: kPurple2),
                                      child: Text(AppLocale.l('yesChange'))),
                                  ],
                                ));
                                if (confirm == true) {
                                  final ok = await DeviceBindingService.migrateDevice();
                                  if (ok) {
                                    deviceBindingNotifier.value = true;
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(ok ? AppLocale.l('migrateSuccess') : AppLocale.l('failed')),
                                      backgroundColor: ok ? Colors.green : Colors.red));
                                  }
                                }
                              },
                            ),
                          ] else ...[
                            Row(children: [
                              Icon(Icons.account_circle, color: kPurple2, size: 28),
                              const SizedBox(width: 12),
                              Expanded(child: Text(AppLocale.l('signInForCloud'),
                                style: TextStyle(fontSize: 14, color: kText))),
                            ]),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final ok = await GoogleAuthService.signIn();
                                if (ok) {
                                  // Check device binding after sign-in
                                  final bound = await DeviceBindingService.checkBinding();
                                  deviceBindingNotifier.value = bound;
                                }
                                if (mounted) {
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(ok ? AppLocale.l('signInSuccess') : AppLocale.l('signInFailed')),
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

                    // Device Binding Info
                    SectionTitle('ಸಾಧನ ಬೈಂಡಿಂಗ್ / Device Binding'),
                    const SizedBox(height: 12),
                    FutureBuilder<String>(
                      future: DeviceBindingService.getDeviceId(),
                      builder: (context, snapshot) {
                        final devId = snapshot.data ?? 'Loading...';
                        final email = GoogleAuthService.userEmail ?? 'Not signed in';
                        final isBound = DeviceBindingService.isDeviceBound;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kBorder.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isBound ? Colors.green.withOpacity(0.3) : kBorder.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(isBound ? Icons.link : Icons.link_off,
                                  size: 20, color: isBound ? Colors.green : Colors.orange),
                                const SizedBox(width: 8),
                                Text(isBound ? 'Device Bound ✅' : 'Not Bound ⚠️',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                                    color: isBound ? Colors.green : Colors.orange)),
                              ]),
                              const SizedBox(height: 12),
                              _bindingInfoRow(Icons.smartphone, 'Device ID', devId),
                              const SizedBox(height: 8),
                              _bindingInfoRow(Icons.email_outlined, 'Gmail', email),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),



                    // Backup & Restore
                    SectionTitle('${AppLocale.l('backupRestore')} (Data Backup & Restore)'),
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
                          Text(AppLocale.l('backupDesc'),
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
                                        const SnackBar(content: Text('Backup saved to Downloads folder.'), backgroundColor: Colors.green)
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: Text('${AppLocale.l('exportBackup')}\n(Export)'),
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
                                          SnackBar(content: Text(AppLocale.l('restoreSuccess')), backgroundColor: Colors.green)
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(err), backgroundColor: Colors.red)
                                        );
                                      }
                                    }
                                  },
                                  icon: Icon(Icons.file_download, color: kPurple2),
                                  label: Text('${AppLocale.l('importBackup')}\n(Import)', style: TextStyle(color: kText)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: kBorder),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('${AppLocale.l('humanReadable')} (Human-readable Spreadsheets & Notes):',
                              style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final ok = await LocalExportService.exportReadableData();
                              if (mounted) {
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Spreadsheet & Notes exported!'), backgroundColor: Colors.green)
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Export failed.'), backgroundColor: Colors.red)
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.table_view),
                            label: Text('${AppLocale.l('exportSpreadsheet')}\n(Export Spreadsheets & Notes)', textAlign: TextAlign.center),
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
                    SectionTitle('${AppLocale.l('cloudBackup')} (Cloud Backup)'),
                    const SizedBox(height: 12),
                    _buildDriveBackupSection(),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),
                    
                    // App Status
                    SectionTitle('${AppLocale.l('appStatus')} / App Status'),
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
                                 (SubscriptionService.hasSubscription || SubscriptionService.manualPremium) ? Icons.check_circle
                                   : SubscriptionService.isTrialActive ? Icons.hourglass_bottom
                                   : Icons.info_outline, 
                                 color: (SubscriptionService.hasSubscription || SubscriptionService.manualPremium) ? Colors.green.shade700
                                   : SubscriptionService.isTrialActive ? kOrange
                                   : kMuted,
                                 size: 28,
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Text(
                                   (SubscriptionService.hasSubscription || SubscriptionService.manualPremium)
                                      ? AppLocale.l('premiumActive')
                                      : SubscriptionService.isTrialActive
                                        ? AppLocale.l('trialActive').replaceAll('{h}', '${SubscriptionService.trialMinutesRemaining}')
                                        : AppLocale.l('trialExpired'),
                                   style: TextStyle(
                                     fontSize: 16, 
                                     fontWeight: FontWeight.bold,
                                     color: (SubscriptionService.hasSubscription || SubscriptionService.manualPremium) ? Colors.green.shade800
                                       : SubscriptionService.isTrialActive ? kOrange
                                       : kMuted
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
                                 if (SubscriptionService.manualPremium && SubscriptionService.manualPremiumExpiry != null) ...[
                                   const SizedBox(height: 10),
                                   Builder(builder: (_) {
                                     final expiry = SubscriptionService.manualPremiumExpiry!;
                                     final now = DateTime.now();
                                     final totalDays = 365;
                                     final remaining = expiry.difference(now).inDays;
                                     final fraction = (remaining / totalDays).clamp(0.0, 1.0);
                                     final expiryStr = '${expiry.day}/${expiry.month}/${expiry.year}';
                                     return Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         ClipRRect(
                                           borderRadius: BorderRadius.circular(4),
                                           child: LinearProgressIndicator(
                                             value: fraction,
                                             backgroundColor: kBorder.withOpacity(0.3),
                                             color: remaining > 30 ? Colors.green : Colors.orange,
                                             minHeight: 6,
                                           ),
                                         ),
                                         const SizedBox(height: 6),
                                         Row(
                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                           children: [
                                             Text('$remaining days remaining',
                                               style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                                 color: remaining > 30 ? Colors.green : Colors.orange)),
                                             Text('Expires: $expiryStr',
                                               style: TextStyle(fontSize: 11, color: kMuted)),
                                           ],
                                         ),
                                       ],
                                     );
                                   }),
                                 ],
                               ],
                             ),
                           ),
                           if (!SubscriptionService.hasSubscription && !SubscriptionService.manualPremium) ...[
                             const SizedBox(height: 12),
                             OutlinedButton.icon(
                               onPressed: () {
                                 Navigator.push(context, MaterialPageRoute(
                                   builder: (_) => const SupportScreen()));
                               },
                               icon: Icon(Icons.support_agent, color: kPurple2),
                               label: Text('Contact Support',
                                 style: TextStyle(color: kPurple2, fontSize: 14, fontWeight: FontWeight.w700)),
                               style: OutlinedButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(vertical: 12),
                                 side: BorderSide(color: kPurple2),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                               ),
                             ),
                           ]
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: kBorder),
                    const SizedBox(height: 24),

                    // Clock / NTP Status
                    SectionTitle('${AppLocale.l('clockVerification')} / Clock Verification'),
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
                              AppLocale.l('clockTampered'),
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
                            label: Text(AppLocale.l('ntpResync'), style: TextStyle(color: kPurple2, fontSize: 13)),
                            onPressed: () async {
                              final ok = await TrustedTimeService.syncWithNtp();
                              if (mounted) {
                                setState(() {});
                                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? AppLocale.l('ntpSyncSuccess') : AppLocale.l('ntpSyncFailed')),
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
                      title: Text(AppLocale.l('aboutUsLink'),
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
                      title: Text(AppLocale.l('privacyLink'),
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
                  AppLocale.l('driveBackupDesc'),
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
                          AppLocale.l('signInForBackup'),
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
                      Text(AppLocale.l('fetchingBackup'), style: TextStyle(fontSize: 12, color: kMuted)),
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
                          '${AppLocale.l('lastBackup')}: ${info['lastBackup']}  (${info['size']})',
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
                          '${AppLocale.l('noBackupYet')} (No backup yet)',
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
                      SnackBar(content: Text(AppLocale.l('backingUpDrive')), duration: Duration(seconds: 2)),
                    );
                    final result = await DriveBackupService.uploadBackup();
                    if (mounted) {
                      if (result == 'success') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocale.l('driveBackupSuccess')),
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
                  label: Text(AppLocale.l('backupToDrive'), textAlign: TextAlign.center),
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
                        title: Text(AppLocale.l('driveRestoreTitle'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
                        content: Text(
                          AppLocale.l('driveRestoreWarn') + '\n\n'
                          '${AppLocale.l('continueQ')}\n\n'
                          '(Restoring will overwrite current data. Continue?)',
                          style: TextStyle(color: kMuted, height: 1.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(AppLocale.l('no'), style: TextStyle(color: kMuted)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(AppLocale.l('restore'), style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocale.l('restoringDrive')), duration: Duration(seconds: 2)),
                      );
                    }
                    final err = await DriveBackupService.downloadAndRestore();
                    if (mounted) {
                      if (err == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocale.l('driveRestoreSuccess')),
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
                  label: Text(AppLocale.l('restoreFromDrive'), textAlign: TextAlign.center, style: TextStyle(color: kText)),
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

  Widget _bindingInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: kMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
        Expanded(
          child: SelectableText(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

