# Graph Report - lib  (2026-06-06)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 1579 nodes · 1972 edges · 60 communities (57 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f0d30865`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]

## God Nodes (most connected - your core abstractions)
1. `KundaliResult` - 9 edges
2. `_BharatheeyamAppState` - 4 edges
3. `_DashboardScreenState` - 4 edges
4. `_PlanetsScreenState` - 4 edges
5. `SectionTitle` - 4 edges
6. `PanchangData` - 3 edges
7. `BharatheeyamApp` - 3 edges
8. `_AshtamangalaScreenState` - 3 edges
9. `_ClientDetailScreenState` - 3 edges
10. `_InputScreenState` - 3 edges

## Surprising Connections (you probably didn't know these)
- `ashtamangala_screen.dart` --references--> `PanchangData`  [EXTRACTED]
  None → core/calculator.dart  _Bridges community 6 → community 2_
- `ashtamangala_screen.dart` --references--> `KundaliResult`  [EXTRACTED]
  None → core/calculator.dart  _Bridges community 32 → community 2_
- `prashna_dashboard_screen.dart` --references--> `KundaliResult`  [EXTRACTED]
  None → core/calculator.dart  _Bridges community 32 → community 15_
- `appointment_screen.dart` --references--> `DateTime`  [EXTRACTED]
  None → None  _Bridges community 11 → community 4_
- `ashtamangala_screen.dart` --references--> `DateTime`  [EXTRACTED]
  None → None  _Bridges community 11 → community 2_

## Import Cycles
- None detected.

## Communities (60 total, 3 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.02
Nodes (111): bool get, abhijitApplied, abhijitTime, abhijitTimeWindow, allowedLagnas, allowedNakshatras, allowedTithis, allowedVaras (+103 more)

### Community 1 - "Community 1"
Cohesion: 0.02
Nodes (92): advSphutas, agniVasa, amPm, amrutaPraghati, antardashas, AstroCalculator, ayana, bhavas (+84 more)

### Community 2 - "Community 2"
Cohesion: 0.03
Nodes (79): ashtamangala_screen.dart, _ampm, _ashtaItems, _asmNumber, _bhutaNames, _bhutaNature, _bodyParts, build (+71 more)

### Community 3 - "Community 3"
Cohesion: 0.03
Nodes (76): package:flutter/gestures.dart, _addSavedProfile, ampm, _aroodhas, _bhavaPlanet, build, _buildAroodhaTab, _buildAshtakaTab (+68 more)

### Community 4 - "Community 4"
Cohesion: 0.03
Nodes (72): appointment_screen.dart, _actionBtn, build, _buildClientsTab, _buildDayCell, _buildMonthPlanner, _buildSignInPrompt, _clientSearch (+64 more)

### Community 5 - "Community 5"
Cohesion: 0.04
Nodes (50): ../core/muhurta_rules.dart, MuhurtaEvent, _janmaNakshatraIdx, _AscSample, _balaChipRow, build, _buildBala, _buildEventRulesCard (+42 more)

### Community 6 - "Community 6"
Cohesion: 0.04
Nodes (47): PanchangData, package:table_calendar/table_calendar.dart, build, _buildChougadiyaCard, _buildHoraCard, _buildKalaCard, _buildMuhurtaCard, _buildSpecialMuhurtaCard (+39 more)

### Community 7 - "Community 7"
Cohesion: 0.04
Nodes (47): alignment, all, blackGold, borderColor1, borderInset, borderWidth1, buildPageBorder, chartBorder (+39 more)

### Community 8 - "Community 8"
Cohesion: 0.05
Nodes (43): ../core/calculator.dart, dart:typed_data, package:pdf/pdf.dart, package:pdf/widgets.dart, package:printing/printing.dart, package:screenshot/screenshot.dart, file, fontBytes (+35 more)

### Community 9 - "Community 9"
Cohesion: 0.05
Nodes (43): addClient, addFamilyMember, address, ampm, birthPlace, birthTime, clearCache, Client (+35 more)

### Community 10 - "Community 10"
Cohesion: 0.05
Nodes (41): _ampm, _ayanamsa, build, _buildHistorySheet, _buildInputCard, _buildProfileListSheet, _checkNetwork, createState (+33 more)

### Community 11 - "Community 11"
Cohesion: 0.05
Nodes (38): ayanamsaKP, ayanamsaLahiri, ayanamsaRaman, calcAll, _deg, Ephemeris, findMoonriseSetForDate, findSunriseSetForDate (+30 more)

### Community 12 - "Community 12"
Cohesion: 0.05
Nodes (37): AshtakaVarga, computeAll, computeBAV, _jupiterBav, _marsBav, _mercuryBav, _moonBav, planets (+29 more)

### Community 13 - "Community 13"
Cohesion: 0.05
Nodes (39): EdgeInsets?, Widget, AppLocale, AppThemes, build, ChartStyle, child, color (+31 more)

### Community 14 - "Community 14"
Cohesion: 0.05
Nodes (36): calculator.dart, _d12Rashi, _d3Rashi, _d9Rashi, drekkanaPhala, drekkanaRashi, _drekPhala, _dvadamshaPhalaFor (+28 more)

### Community 15 - "Community 15"
Cohesion: 0.06
Nodes (35): ../core/graha_phala.dart, prashna_dashboard_screen.dart, ampm, _bhavaChip, _bhavaPlanet, build, _buildBhavaControls, _buildGrahaPhalas (+27 more)

### Community 16 - "Community 16"
Cohesion: 0.07
Nodes (29): PlanetInfo, bhavaFromPlanet, build, _buildOuterLabels, _buildRashiBoxes, _centerBox, centerLabel, degInRashi (+21 more)

### Community 17 - "Community 17"
Cohesion: 0.07
Nodes (29): dart:async, double get, anuVighati, build, createState, _currentGhati, _d2r, dispose (+21 more)

### Community 18 - "Community 18"
Cohesion: 0.07
Nodes (28): FixedExtentScrollController, _ampm, _ampmCtrl, _ayanamsa, build, _buildWheel, createState, dispose (+20 more)

### Community 19 - "Community 19"
Cohesion: 0.07
Nodes (26): Client, build, _buildClientHeader, _buildHistorySection, _buildMembersList, _buildModeToggle, client, createState (+18 more)

### Community 20 - "Community 20"
Cohesion: 0.07
Nodes (26): appDashaLords, appNak, appPlanetNames, appPlanetOrder, appRashi, appSphutas16Order, appTithi, appTitle (+18 more)

### Community 21 - "Community 21"
Cohesion: 0.09
Nodes (23): core/ephemeris.dart, GlobalKey, BharatheeyamApp, _BharatheeyamAppState, build, createState, _deferredInit, didChangeAppLifecycleState (+15 more)

### Community 22 - "Community 22"
Cohesion: 0.08
Nodes (23): add, ampm, clearAll, date, _entries, fromJson, HistoryEntry, hour (+15 more)

### Community 23 - "Community 23"
Cohesion: 0.08
Nodes (23): _amshaDegree, _aroodhaChip, aroodhas, bhavaFromPlanet, build, _buildHouseWidgets, centerLabel, houseRashi (+15 more)

### Community 24 - "Community 24"
Cohesion: 0.09
Nodes (21): ../core/transit_calculator.dart, build, _buildAstaList, _buildTransits, _buildVakriList, _changeYear, createState, _formatDate (+13 more)

### Community 25 - "Community 25"
Cohesion: 0.09
Nodes (21): ampm, aroodhas, clientId, date, delete, fromJson, groupMembers, hour (+13 more)

### Community 26 - "Community 26"
Cohesion: 0.10
Nodes (20): package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart, package:google_sign_in/google_sign_in.dart, package:googleapis_auth/googleapis_auth.dart, _currentUser, ensureCalendarScope, ensureDriveScope, getAuthenticatedClient, getAuthHeaders (+12 more)

### Community 27 - "Community 27"
Cohesion: 0.10
Nodes (20): _getEventsForDay, allEvents, _cache, _cachePrefix, _cacheVersion, clear, _computeAndSave, _isLoaded (+12 more)

### Community 28 - "Community 28"
Cohesion: 0.10
Nodes (20): _amshaDegree, aroodhas, bhavaFromPlanet, build, _centerBox, centerLabel, ChipType, _grid (+12 more)

### Community 29 - "Community 29"
Cohesion: 0.10
Nodes (19): AmaraKoshaEntry, author, Book, category, Chapter, chapters, fromJson, id (+11 more)

### Community 30 - "Community 30"
Cohesion: 0.10
Nodes (19): package:googleapis/calendar/v3.dart, _appIdKey, _appSourceKey, _calendarApi, _calendarId, _calendarName, createAppointment, deleteEvent (+11 more)

### Community 31 - "Community 31"
Cohesion: 0.12
Nodes (18): ../constants/strings.dart, DashaEntry, List, north_indian_chart.dart, MatchMakingScreen, StatelessWidget, AppCard, AppHeader (+10 more)

### Community 32 - "Community 32"
Cohesion: 0.11
Nodes (18): ../core/ashtakavarga.dart, KundaliResult, _avData, _barColor, _binduColor, build, _buildAVKundaliChart, _buildBarChart (+10 more)

### Community 33 - "Community 33"
Cohesion: 0.12
Nodes (14): backup_service_stub.dart, client_service.dart, package:flutter/foundation.dart, BackupService, exportData, importData, validKeys, DocsService (+6 more)

### Community 34 - "Community 34"
Cohesion: 0.12
Nodes (16): package:uuid/uuid.dart, _cacheLocalBinding, checkBinding, _clearLocalBinding, _deviceId, _deviceIdKey, _ensureFirebase, _firestoreCollection (+8 more)

### Community 35 - "Community 35"
Cohesion: 0.13
Nodes (14): google_auth_service.dart, package:shared_preferences/shared_preferences.dart, downloadAndRestore, _driveApi, _fileName, _findBackupFileId, getBackupInfo, _mimeType (+6 more)

### Community 36 - "Community 36"
Cohesion: 0.12
Nodes (15): package:google_mobile_ads/google_mobile_ads.dart, AdService, _bannerAd, bannerAdUnitId, build, createState, dispose, initialize (+7 more)

### Community 37 - "Community 37"
Cohesion: 0.13
Nodes (15): about_screen.dart, ../core/events.dart, package:url_launcher/url_launcher.dart, _bodyCard, build, _buildEventReference, _calcCard, _getEventsForMasaTithi (+7 more)

### Community 38 - "Community 38"
Cohesion: 0.13
Nodes (14): Color, IconData, _buildCard, color, icon, label, onTap, _Section (+6 more)

### Community 39 - "Community 39"
Cohesion: 0.17
Nodes (11): dart:io, export_service_mobile.dart, package:file_picker/file_picker.dart, package:path_provider/path_provider.dart, package:share_plus/share_plus.dart, exportJsonFile, pickJsonFile, shareCSV (+3 more)

### Community 40 - "Community 40"
Cohesion: 0.23
Nodes (14): BannerAdWidget, client_detail_screen.dart, input_screen.dart, match_making_tab.dart, panchanga_screen.dart, prashna_input_screen.dart, _ClientDetailScreenState, _InputScreenState (+6 more)

### Community 41 - "Community 41"
Cohesion: 0.14
Nodes (13): ../constants/places.dart, _applyGeoResult, createState, dispose, _geoLoading, _geoStatus, initState, _performGeocode (+5 more)

### Community 42 - "Community 42"
Cohesion: 0.17
Nodes (11): dart:convert, dart:html, exportJsonFile, pickJsonFile, blob, bytes, _downloadFile, exportJsonFile (+3 more)

### Community 43 - "Community 43"
Cohesion: 0.20
Nodes (9): common.dart, Map, package:flutter/material.dart, build, detail, pName, _section, build (+1 more)

### Community 44 - "Community 44"
Cohesion: 0.18
Nodes (10): location_service.dart, init, _lat, _lon, _place, setLocation, _tzOffset, static double (+2 more)

### Community 45 - "Community 45"
Cohesion: 0.18
Nodes (10): AdService, bannerAdUnitId, BannerAdWidget, build, initialize, interstitialAdUnitId, rewardedInterstitialAdUnitId, showInterstitialAd (+2 more)

### Community 46 - "Community 46"
Cohesion: 0.18
Nodes (10): checkTesterStatus, _clearStatus, init, isTester, isTesterNotifier, onSignOut, statusMessage, _testerCacheKey (+2 more)

### Community 47 - "Community 47"
Cohesion: 0.20
Nodes (9): AstroEvent, description, EventCalculator, getEventsForPanchang, meaning, name, shloka, source (+1 more)

### Community 48 - "Community 48"
Cohesion: 0.25
Nodes (7): ../config/secrets.dart, ../main.dart, package:cloud_firestore/cloud_firestore.dart, package:firebase_core/firebase_core.dart, init, _initialized, listenForAppointments

### Community 49 - "Community 49"
Cohesion: 0.25
Nodes (7): getTimezoneForPlace, karnatakaPlaces, _knownTimezones, lowerName, offlinePlaces, otherPlaces, package:http/http.dart

### Community 50 - "Community 50"
Cohesion: 0.25
Nodes (8): MaterialPageRoute, _buildAppointmentCard, _buildClientCard, _generateKundaliForMember, build, _calculate, _calculate, build

### Community 51 - "Community 51"
Cohesion: 0.25
Nodes (7): package:package_info_plus/package_info_plus.dart, check, _checked, isFromPlayStore, _isFromStore, static bool, static bool get

### Community 52 - "Community 52"
Cohesion: 0.25
Nodes (8): privacy_policy_screen.dart, _body, build, _bullet, _header, _meta, _section, ../widgets/common.dart

### Community 53 - "Community 53"
Cohesion: 0.29
Nodes (6): main, srHour, srMin, srMinBug, srParts, sunriseStr

### Community 54 - "Community 54"
Cohesion: 0.33
Nodes (6): dashboard_screen.dart, planets_screen.dart, _AshtamangalaScreenState, _DashboardScreenState, _PlanetsScreenState, SingleTickerProviderStateMixin

### Community 55 - "Community 55"
Cohesion: 0.50
Nodes (4): CustomPainter, _GhatiClockPainter, _CornerPainter, _NorthIndianPainter

### Community 56 - "Community 56"
Cohesion: 0.50
Nodes (3): exportJsonFile, exportMultipleFiles, pickJsonFile

## Knowledge Gaps
- **1324 isolated node(s):** `karnatakaPlaces`, `otherPlaces`, `offlinePlaces`, `_knownTimezones`, `lowerName` (+1319 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `KundaliResult` connect `Community 32` to `Community 1`, `Community 2`, `Community 3`, `Community 5`, `Community 15`, `Community 16`, `Community 23`, `Community 28`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `AstroEvent` connect `Community 47` to `Community 6`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Why does `PanchangData` connect `Community 6` to `Community 1`, `Community 2`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `karnatakaPlaces`, `otherPlaces`, `offlinePlaces` to the rest of the system?**
  _1324 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.017857142857142856 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.021505376344086023 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.02531645569620253 - nodes in this community are weakly interconnected._