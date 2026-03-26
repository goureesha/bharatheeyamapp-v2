import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/common.dart';

import '../services/subscription_service.dart';
import '../services/google_auth_service.dart';
import '../services/device_binding_service.dart';
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
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setState(() => _geoStatus = 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.');
        } else {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name'] as String;
          final autoTz = await getTimezoneForPlace(displayName, lat, lon);
          await LocationService.setLocation(placeName.trim(), lat, lon, autoTz);
          setState(() {
            _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
            _geoStatus = '📍 ${data[0]['display_name']} (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('ಡೀಫಾಲ್ಟ್ ಸ್ಥಳ: ${placeName.trim()}'),
              backgroundColor: Colors.green,
            ));
          }
        }
      }
    } catch (_) {
      setState(() => _geoStatus = 'ಸ್ಥಳ ಸಂಪರ್ಕ ದೋಷ. ನೇರವಾಗಿ ಅಕ್ಷಾಂಶ/ರೇಖಾಂಶ ನಮೂದಿಸಿ.');
    }
    setState(() => _geoLoading = false);
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

                    // Language selection
                    SectionTitle(AppLocale.l('language')),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<String>(
                      valueListenable: AppLocale.langNotifier,
                      builder: (context, currentLang, _) {
                        return Column(
                          children: [
                            RadioListTile<String>(
                              value: 'kn',
                              groupValue: currentLang,
                              title: Text('ಕನ್ನಡ (Kannada)', style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                              activeColor: kPurple2,
                              onChanged: (val) {
                                if (val != null) {
                                  AppLocale.setLang(val);
                                  setState(() {});
                                }
                              },
                            ),
                            RadioListTile<String>(
                              value: 'hi',
                              groupValue: currentLang,
                              title: Text('हिन्दी (Hindi)', style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                              activeColor: kPurple2,
                              onChanged: (val) {
                                if (val != null) {
                                  AppLocale.setLang(val);
                                  setState(() {});
                                }
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
                                ],
                              )),
                            ]),
                            const SizedBox(height: 12),
                            Text('Sheets, Docs, Calendar ಸಿಂಕ್ ಸಕ್ರಿಯವಾಗಿದೆ', style: TextStyle(fontSize: 13, color: Colors.green)),
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
                              label: Text('ಸಾಧನ ಬದಲಾಯಿಸಿ / Migrate Device', style: TextStyle(color: kPurple2, fontSize: 13)),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                                  backgroundColor: kCard,
                                  title: Text('ಸಾಧನ ಬದಲಾಯಿಸಿ?', style: TextStyle(color: kText)),
                                  content: Text('ಈ ಸಾಧನವನ್ನು ನಿಮ್ಮ ಪ್ರಾಥಮಿಕ ಸಾಧನವಾಗಿ ಹೊಂದಿಸಲಾಗುವುದು. ಬೇರೆ ಸಾಧನದಲ್ಲಿ ಈ ಖಾತೆ ಬ್ಲಾಕ್ ಆಗುತ್ತದೆ.', style: TextStyle(color: kText)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('ರದ್ದು', style: TextStyle(color: kMuted))),
                                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: kPurple2),
                                      child: Text('ಹೌದು, ಬದಲಾಯಿಸಿ')),
                                  ],
                                ));
                                if (confirm == true) {
                                  final ok = await DeviceBindingService.migrateDevice();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(ok ? 'ಸಾಧನ ಯಶಸ್ವಿಯಾಗಿ ಬದಲಾಯಿಸಲಾಗಿದೆ!' : 'ವಿಫಲವಾಗಿದೆ'),
                                      backgroundColor: ok ? Colors.green : Colors.red));
                                  }
                                }
                              },
                            ),
                          ] else ...[
                            Row(children: [
                              Icon(Icons.account_circle, color: kPurple2, size: 28),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Google ಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ Sheets, Docs ಮತ್ತು Calendar ಸಿಂಕ್ ಬಳಸಿ',
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
                    
                    // Purchase Premium
                    SectionTitle('ಪ್ರೀಮಿಯಂ ಚಂದಾದಾರಿಕೆ'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SubscriptionService.hasAdFree ? Colors.green.shade50 : kPurple1.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SubscriptionService.hasAdFree ? Colors.green.shade200 : kPurple2.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                           Row(
                             children: [
                               Icon(
                                 SubscriptionService.hasAdFree ? Icons.check_circle : Icons.star, 
                                 color: SubscriptionService.hasAdFree ? Colors.green.shade700 : kOrange,
                                 size: 28,
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Text(
                                   SubscriptionService.hasAdFree 
                                      ? 'ನೀವು ಪ್ರೀಮಿಯಂ ಸದಸ್ಯರು! (Ad-Free Active)' 
                                      : 'ಜಾಹೀರಾತು ಮುಕ್ತ ಅನುಭವ ಪಡೆಯಿರಿ',
                                   style: TextStyle(
                                     fontSize: SubscriptionService.hasAdFree ? 16 : 18, 
                                     fontWeight: FontWeight.bold,
                                     color: SubscriptionService.hasAdFree ? Colors.green.shade800 : kPurple1
                                   ),
                                 ),
                               ),
                             ],
                           ),
                           if (!SubscriptionService.hasAdFree) ...[
                             const SizedBox(height: 12),
                             Text(
                               'ವರ್ಷಕ್ಕೆ ಕೇವಲ ₹೭೦೦ ಪಾವತಿಸಿ ಮತ್ತು ಅಪ್ಲಿಕೇಶನ್ ಅನ್ನು ಯಾವುದೇ ಜಾಹೀರಾತುಗಳಿಲ್ಲದೆ ಬಳಸಿ.',
                               style: TextStyle(fontSize: 14, color: kText, height: 1.4),
                             ),
                             const SizedBox(height: 20),
                             ElevatedButton(
                               onPressed: () async {
                                 final success = await SubscriptionService.buyAdFreeSubscription();
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

}
