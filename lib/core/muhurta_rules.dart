// Muhurta Rules Engine — based on Muhurta Chintamani

// ============================================================
// MUHURTA RULES ENGINE
// Based on Muhurta Chintamani by Daivagya Acharya Ram
// ============================================================

/// Event categories for Muhurta selection
enum MuhurtaEvent {
  vivaha,        // ವಿವಾಹ — Marriage
  upanayana,     // ಉಪನಯನ — Thread Ceremony
  grihaPrevesha, // ಗೃಹಪ್ರವೇಶ — House Warming
  devaPratishtha,// ದೇವ ಪ್ರತಿಷ್ಠಾ — Deity Installation
  aksharabhyasa, // ಅಕ್ಷರಾಭ್ಯಾಸ — Starting Education
  yatra,         // ಯಾತ್ರಾ — Travel
  vyapara,       // ವ್ಯಾಪಾರ — Business Start
  annaprashana,  // ಅನ್ನಪ್ರಾಶನ — First Feeding
  namakarana,    // ನಾಮಕರಣ — Naming Ceremony
  seemanta,      // ಸೀಮಂತ — Prenatal Rite
  chowla,        // ಚೌಲ — Tonsure
  vastuShilanyas,// ವಾಸ್ತು ಶಿಲಾನ್ಯಾಸ — Foundation Laying
  aushadha,      // ಔಷಧ — Medical Treatment
  krishi,        // ಕೃಷಿ — Agriculture
  vahanaKraya,   // ವಾಹನ ಖರೀದಿ — Vehicle Purchase
  aasthiKraya,   // ಆಸ್ತಿ ಖರೀದಿ — Property Purchase
  swarnaKraya,   // ಆಭರಣ ಖರೀದಿ — Gold Purchase
  udyoga,        // ಉದ್ಯೋಗ — Job Joining / Office
  karnavedha,    // ಕರ್ಣವೇಧ — Ear Piercing
}

/// Kannada names and English subtitles for each event
class MuhurtaEventInfo {
  final String kannadaName;
  final String englishName;
  final bool defaultTwoPerson; // Auto-switch to 2-person mode

  const MuhurtaEventInfo(this.kannadaName, this.englishName, {this.defaultTwoPerson = false});
}

const Map<MuhurtaEvent, MuhurtaEventInfo> muhurtaEventNames = {
  MuhurtaEvent.vivaha:         MuhurtaEventInfo('ವಿವಾಹ', 'Marriage', defaultTwoPerson: true),
  MuhurtaEvent.upanayana:      MuhurtaEventInfo('ಉಪನಯನ', 'Thread Ceremony'),
  MuhurtaEvent.grihaPrevesha:  MuhurtaEventInfo('ಗೃಹಪ್ರವೇಶ', 'House Warming'),
  MuhurtaEvent.devaPratishtha: MuhurtaEventInfo('ದೇವ ಪ್ರತಿಷ್ಠಾ', 'Deity Installation'),
  MuhurtaEvent.aksharabhyasa:  MuhurtaEventInfo('ಅಕ್ಷರಾಭ್ಯಾಸ', 'Education Start'),
  MuhurtaEvent.yatra:          MuhurtaEventInfo('ಯಾತ್ರಾ', 'Travel'),
  MuhurtaEvent.vyapara:        MuhurtaEventInfo('ವ್ಯಾಪಾರ ಆರಂಭ', 'Business Start'),
  MuhurtaEvent.annaprashana:   MuhurtaEventInfo('ಅನ್ನಪ್ರಾಶನ', 'First Feeding'),
  MuhurtaEvent.namakarana:     MuhurtaEventInfo('ನಾಮಕರಣ', 'Naming Ceremony'),
  MuhurtaEvent.seemanta:       MuhurtaEventInfo('ಸೀಮಂತ', 'Prenatal Rite'),
  MuhurtaEvent.chowla:         MuhurtaEventInfo('ಚೌಲ / ಮುಂಡನ', 'Tonsure'),
  MuhurtaEvent.vastuShilanyas: MuhurtaEventInfo('ವಾಸ್ತು ಶಿಲಾನ್ಯಾಸ', 'Foundation Laying'),
  MuhurtaEvent.aushadha:       MuhurtaEventInfo('ಔಷಧ ಸೇವನೆ', 'Medical Treatment'),
  MuhurtaEvent.krishi:         MuhurtaEventInfo('ಕೃಷಿ', 'Agriculture'),
  MuhurtaEvent.vahanaKraya:    MuhurtaEventInfo('ವಾಹನ ಖರೀದಿ', 'Vehicle Purchase'),
  MuhurtaEvent.aasthiKraya:    MuhurtaEventInfo('ಆಸ್ತಿ ಖರೀದಿ', 'Property Purchase'),
  MuhurtaEvent.swarnaKraya:    MuhurtaEventInfo('ಆಭರಣ ಖರೀದಿ', 'Gold Purchase'),
  MuhurtaEvent.udyoga:         MuhurtaEventInfo('ಉದ್ಯೋಗ ಸೇರ್ಪಡೆ', 'Job/Office Joining'),
  MuhurtaEvent.karnavedha:     MuhurtaEventInfo('ಕರ್ಣವೇಧ', 'Ear Piercing'),
};

/// Which shuddhi checks are required for the event
enum ShuddhiType { lagna, saptama, ashtama, dashama, chandraSaptama }

/// Rules for each muhurta event type
class MuhurtaEventRules {
  /// Allowed tithi indices (0-29). Null = all allowed.
  final List<int>? allowedTithis;
  /// Allowed nakshatra indices (0-26). Null = all allowed.
  final List<int>? allowedNakshatras;
  /// Allowed vara indices (0=Sun, 1=Mon, ..., 6=Sat). Null = all allowed.
  final List<int>? allowedVaras;
  /// Avoid Vishti (Bhadra) karana
  final bool avoidVishti;
  /// Only Shukla Paksha (tithiIndex 0-14)
  final bool requireShukla;
  /// Requires Uttarayana (Sun in Makara to Mithuna, i.e., indices 9, 10, 11, 0, 1, 2)
  final bool requireUttarayana;
  /// Allowed lagna rashi indices (0-11). Null = not checked in Phase 1.
  final List<int>? allowedLagnas;
  /// Which shuddhi checks this event requires
  final Set<ShuddhiType> requiredShuddhis;

  /// Shastra shloka for this event
  final String? shloka;
  /// Shastra reference source
  final String? shastraRef;

  const MuhurtaEventRules({
    this.allowedTithis,
    this.allowedNakshatras,
    this.allowedVaras,
    this.avoidVishti = true,
    this.requireShukla = false,
    this.requireUttarayana = false,
    this.allowedLagnas,
    this.requiredShuddhis = const {ShuddhiType.lagna}, // default: at least lagna
    this.shloka,
    this.shastraRef,
  });
}

/// Mapping of event types to their Panchanga rules
const Map<MuhurtaEvent, MuhurtaEventRules> muhurtaRules = {
  // ── ವಿವಾಹ (Marriage) ──
  // Per MC: Needs ALL checks. Saptama forbids ALL planets.
  MuhurtaEvent.vivaha: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [3, 4, 9, 11, 12, 14, 16, 18, 20, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: null, // Removed static limits, rely purely on Shuddhi
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.saptama, ShuddhiType.ashtama, ShuddhiType.chandraSaptama},
    shloka: '''೧. ನಕ್ಷತ್ರ ನಿಯಮ:
ರೋಹಿಣೀಮೃಗಶೀರ್ಷಂ ಚ ಉತ್ತರಾತ್ರಯಮೇವ ಚ ।
ರೇವತೀ ಹಸ್ತಮೂಲಂ ಚ ಸ್ವಾತೀ ಮಾಘಮನುರಾಧಕಾಃ ॥
ಏತೇ ವಿವಾಹೇ ಶುಭದಾಃ ತಾರಾಃ ಪ್ರೋಕ್ತಾ ಮನೀಷಿಭಿಃ ।

೨. ಸಪ್ತಮ ಶುದ್ಧಿ ಮತ್ತು ಲಗ್ನ:
ಲಗ್ನಂ ಶುಭಗ್ರಹೈರ್ದೃಷ್ಟಂ ಸಪ್ತಮಂ ಗ್ರಹವರ್ಜಿತಮ್ ।
ಅಷ್ಟಮಂ ಶುಕ್ರವರ್ಜಂ ಚ ವಿವಾಹೇ ಶುಭದಾಯಕಮ್ ॥

೩. ಗುರು-ಚಂದ್ರ ಬಲ:
ಗುರುಬಲಂ ವಧೂವರಯೋಃ ಚಂದ್ರಬಲಂ ತಥೈವ ಚ ।
ವಿವಾಹೇ ಸರ್ವದಾ ಗ್ರಾಹ್ಯಂ ಸರ್ವಸಂಪತ್ಪ್ರದಾಯಕಮ್ ॥''',
    shastraRef: 'ಮುಹೂರ್ತ ಚಿಂತಾಮಣಿ (ವಿವಾಹ ಪ್ರಕರಣ)',
  ),

  // ── ಉಪನಯನ (Thread Ceremony) ──
  MuhurtaEvent.upanayana: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 9, 10, 11, 16, 17, 19],
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 14, 16, 20, 21, 22, 23, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireUttarayana: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama},
    shloka: '''೧. ನಕ್ಷತ್ರ ನಿಯಮ:
ಆಶ್ಲೇಷಾ ಮೂಲ ಕೃತ್ತಿಕಾ ವರ್ಜಯಿತ್ವಾಖಿಲಾನಿ ಚ ।
ಉಪನಯನೇ ಶುಭದಾನಿ ನಕ್ಷತ್ರಾಣಿ ಭವಂತಿ ಹಿ ॥

೨. ತಿಥಿ ನಿಯಮ:
ದ್ವಿತೀಯಾ ತೃತೀಯಾ ಚ ಪಂಚಮೀ ಷಷ್ಠೀ ತಥೈವ ಚ ।
ದಶಮೀ ಚೈಕಾದಶೀ ದ್ವಾದಶೀ ಶುಭದಾಃ ಸ್ಮೃತಾಃ ॥

೩. ಗುರು ಬಲ:
ಗುರುಬಲಂ ವಟೋಃ ಕಾರ್ಯೇ ಬ್ರಾಹ್ಮಣಾನಾಂ ವಿಶೇಷತಃ ।
ಶುಭಗ್ರಹೈರ್ನಿರೀಕ್ಷಿತೇ ಲಗ್ನೇ ಚೈವೋಪನಯನಮ್ ॥''',
    shastraRef: 'ಮುಹೂರ್ತ ಚಿಂತಾಮಣಿ (ಸಂಸ್ಕಾರ ಪ್ರಕರಣ)',
  ),

  // ── ಗೃಹಪ್ರವೇಶ (House Warming) ──
  // Only event that explicitly mandates Sthira (Fixed) rashis: Vrishabha, Simha, Vrischika, Kumbha
  MuhurtaEvent.grihaPrevesha: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [3, 4, 11, 13, 16, 20, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireUttarayana: true,
    requireShukla: true,
    allowedLagnas: [1, 4, 7, 10], // Sthira rashis
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama, ShuddhiType.chandraSaptama},
    shloka: '''೧. ನಕ್ಷತ್ರ ನಿಯಮ:
ರೋಹಿಣೀ ಮೃಗಶೀರ್ಷಂ ಚ ಉತ್ತರಾತ್ರಯಮೇವ ಚ ।
ಪುಷ್ಯೋ ಧನಿಷ್ಠಾ ಶತತಾರಾ ನಕ್ಷತ್ರಾಣಿ ಶುಭಾನಿ ಚ ॥

೨. ಲಗ್ನ ನಿಯಮ:
ಸ್ಥಿರ ಲಗ್ನಂ ಗೃಹಪ್ರವೇಶೇ ಶ್ರೇಷ್ಠಂ ಭವತಿ ಸರ್ವದಾ ।
ದ್ವಿಸ್ವಭಾವೇ ಮಧ್ಯಮಂ ಸ್ಯಾಚ್ಚರ ಲಗ್ನಂ ವಿವರ್ಜಯೇತ್ ॥

೩. ಕಾಲ ನಿಯಮ:
ದಿವಾ ಭಾಗೇ ಗೃಹಪ್ರವೇಶಃ ಸರ್ವದಾ ಶುಭದಾಯಕಃ ।
ರಾತ್ರೌ ಚ ವಿವರ್ಜಯೇತ್ ಪ್ರವೇಶಂ ನೂತನಮಂದಿರೇ ॥''',
    shastraRef: 'ಮುಹೂರ್ತ ಚಿಂತಾಮಣಿ (ವಾಸ್ತು ಪ್ರಕರಣ)',
  ),

  // ── ದೇವ ಪ್ರತಿಷ್ಠಾ (Deity Installation) ──
  MuhurtaEvent.devaPratishtha: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 7, 9, 10, 11, 12, 13],
    allowedNakshatras: [3, 4, 11, 12, 13, 14, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireUttarayana: true,
    requireShukla: true,
    allowedLagnas: [1, 4, 7, 10], // Sthira
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama},
    shloka: '''೧. ಅಯನ-ಮಾಸ ನಿಯಮ:
ಉತ್ತರಾಯಣೇ ವಸಂತೇ ವಾ ಜೇಷ್ಠೇ ವಾ ಫಾಲ್ಗುನೇ ತಥಾ ।
ದೇವತಾನಾಂ ಪ್ರತಿಷ್ಠಾ ಚ ಕಾರ್ಯಾ ಸರ್ವಾರ್ಥ ಸಿದ್ಧಯೇ ॥

೨. ನಕ್ಷತ್ರ-ತಿಥಿ ನಿಯಮ:
ರೋಹಿಣೀ ಶ್ರವಣೋ ಹಸ್ತಃ ಪುಷ್ಯೋತ್ತರ-ತ್ರಯಂ ತಥಾ ।
ರೇವತೀ ಚ ಅಶ್ವಿನೀ ಮೃಗೋ ದೇವ-ಪ್ರತಿಷ್ಠನೇ ಶುಭಮ್ ॥
ದ್ವಿತೀಯಾ ಪಂಚಮೀ ಷಷ್ಠೀ ಸಪ್ತಮೀ ದಶಮೀ ತಥಾ ।
ಏಕಾದಶೀ ತ್ರಯೋದಶೀ ಶುಕ್ಲಪಕ್ಷೇ ಪ್ರಶಸ್ಯತೇ ॥

೩. ಲಗ್ನ ಶುದ್ಧಿ:
ಸ್ಥಿರಲಗ್ನೇ ಶುಭೇ ತಾರೇ ಶುಭಗ್ರಹ ನಿರೀಕ್ಷಿತೇ ।
ಅಷ್ಟಮೇ ಪಾಪ ವರ್ಜೇ ಚ ದೇವತಾನಾಂ ಪ್ರತಿಷ್ಠನಮ್ ॥''',
    shastraRef: 'ಮುಹೂರ್ತ ಚಿಂತಾಮಣಿ (ದೇವ-ಪ್ರತಿಷ್ಠಾ ಪ್ರಕರಣ)',
  ),

  // ── ಅಕ್ಷರಾಭ್ಯಾಸ (Starting Education) ──
  MuhurtaEvent.aksharabhyasa: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 9, 10],
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 14, 20, 21, 22, 25, 26],
    allowedVaras: [3, 4],
    avoidVishti: true,
    requireUttarayana: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna},
    shloka: 'ಅಶ್ವಿನೀ ಪುಷ್ಯ ಹಸ್ತೇಷು ಚಿತ್ರಾ ಸ್ವಾತೀ ಪುನರ್ವಸು ।\nಶ್ರವಣೇ ಧನಿಷ್ಠಾಯಾಂ ಚ ಅಕ್ಷರಾರಂಭ ಶುಭದಾಯಕಃ ॥',
    shastraRef: 'ಮುಹೂರ್ತ ಚಿಂತಾಮಣಿ (ವಿದ್ಯಾರಂಭ ಪ್ರಕರಣ)',
  ),

  // ── ಯಾತ್ರಾ (Travel) ──
  MuhurtaEvent.yatra: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 4, 7, 12, 16, 21, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama, ShuddhiType.chandraSaptama},
    shloka: 'ಅಶ್ವಿನಿ ಪುಷ್ಯ ಹಸ್ತೇಷು ಚಿತ್ರಾ ಸ್ವಾತೀ ಪುನರ್ವಸು ।\nಮೃಗಶಿರೋ ರೇವತೀ ಚ ಯಾತ್ರಾಯಾಂ ಶುಭದಾಯಕಾಃ ॥',
    shastraRef: 'ಮುಹೂರ್ತ ಪಾರಿಜಾತ (ಯಾತ್ರಾ ಪ್ರಕರಣ)',
  ),

  // ── ವ್ಯಾಪಾರ (Business Start) ──
  MuhurtaEvent.vyapara: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 12],
    allowedNakshatras: [0, 3, 6, 7, 11, 12, 13, 14, 16, 21, 22, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.saptama},
    shloka: 'ಅಶ್ವಿನಿ ಪುಷ್ಯ ಹಸ್ತೇಷು ರೇವತೀ ಚಿತ್ರಕೇ ತಥಾ ।\nವ್ಯಾಪಾರಾರಂಭ ಕಾರ್ಯಾಣಿ ಶುಭದಾನಿ ನ ಸಂಶಯಃ ॥',
    shastraRef: 'ವಾಸ್ತು ರತ್ನಾಕರ',
  ),

  // ── ಅನ್ನಪ್ರಾಶನ (First Feeding) ──
  // Per MC: Requires Dashama Shuddhi (10th house empty)
  MuhurtaEvent.annaprashana: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 14, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.dashama},
    shloka: '''೧. ನಕ್ಷತ್ರ ನಿಯಮ:
ಪುಷ್ಯೇ ಪುನರ್ವಸೌ ಹಸ್ತೇ ರೇವತ್ಯಾಂ ಶ್ರವಣೇ ತಥಾ ।
ಅನ್ನಪ್ರಾಶನ ಕರ್ಮಾಣಿ ಕುರ್ಯಾತ್ ಸಂಪತ್ಕರಾಣಿ ಹಿ ॥

೨. ದಶಮ ಶುದ್ಧಿ:
ದಶಮಂ ಗ್ರಹವರ್ಜಿತಂ ಲಗ್ನಂ ಶುಭದೃಷ್ಟಿ ಸಮನ್ವಿತಮ್ ।
ಅನ್ನಪ್ರಾಶನ ಕಾಲೇ ತು ಸರ್ವರೋಗ ವಿನಾಶನಮ್ ॥''',
    shastraRef: 'ಮುಹೂರ್ತ ಚಿಂತಾಮಣಿ (ಅನ್ನಪ್ರಾಶನ ಪ್ರಕರಣ)',
  ),

  // ── ನಾಮಕರಣ (Naming Ceremony) ──
  MuhurtaEvent.namakarana: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 14, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama},
    shloka: '''೧. ಮಾಸ-ದಿನ ನಿಯಮ:
ಏಕಾದಶೇ ತಥಾಹ್ನಿ ಸ್ಯಾತ್ ದ್ವಾದಶೇ ನಾಮಕರ್ಮ ಚ ।
ರಿಕ್ತಾ-ಅಮಾವಾಸ್ಯಾ-ಪರ್ವ-ದಿನೇ ನಾಮಕರ್ಮ ವಿವರ್ಜಯೇತ್ ॥

೨. ತಿಥಿ-ನಕ್ಷತ್ರ:
ಅಶ್ವಿನೀ-ರೋಹಿಣೀ-ಪುಷ್ಯ-ಹಸ್ತ-ರೇವತಿಭಿಃ ಶುಭಮ್ ।
ಲಗ್ನೇ ಶುಭಗ್ರಹೈರ್ದೃಷ್ಟೇ ಅಷ್ಟಮೇ ಪಾಪ-ವರ್ಜಿತೇ ॥

೩. ಸಾರ್ವತ್ರಿಕ ಶುದ್ಧಿ:
ಗುರು-ಶುಕ್ರ-ಬುಧೈರ್ದೃಷ್ಟೇ ಕೇಂದ್ರ-ತ್ರಿಕೋಣ ಸಂಸ್ಥಿತೇ ।
ನಾಮಕರಣಂ ಶಿಶೂನಾಂ ಚ ಆಯುರ್ವೃದ್ಧಿಕರಂ ಭವೇತ್ ॥''',
    shastraRef: 'ಮುಹೂರ್ತ ಚಿಂತಾಮಣಿ (ನಾಮಕರಣ ಪ್ರಕರಣ)',
  ),

  // ── ಸೀಮಂತ (Prenatal Rite) ──
  MuhurtaEvent.seemanta: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [3, 4, 11, 13, 16, 20, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama},
    shloka: '''೧. ಮಾಸ-ಪಕ್ಷ ನಿಯಮ:
ಷಷ್ಠೇ ವಾ ಅಷ್ಟಮೇ ಮಾಸಿ ಶುಕ್ಲಪಕ್ಷೇ ಶುಭಾವಹೇ ।
ಪುಂಸವನ-ಸೀಮಂತಕರ್ಮ ಗರ್ಭ-ರಕ್ಷಾಕರಂ ಭವೇತ್ ॥

೨. ನಕ್ಷತ್ರ-ಲಗ್ನ:
ಪುಷ್ಯ-ಶ್ರವಣ-ರೋಹಿಣೀ-ಉತ್ತರ-ಹಸ್ತ-ರೇವತೀ ।
ಲಗ್ನೇ ಕೇಂದ್ರೇ ಶುಭೈರ್ದೃಷ್ಟೇ ಅಷ್ಟಮೇ ಪಾಪ ವರ್ಜಿತೇ ॥

೩. ಗುರು-ಚಂದ್ರ ಬಲ:
ಗುರು-ಚಂದ್ರ-ಬಲಂ ದೃಷ್ಟ್ವಾ ಗರ್ಭಿಣ್ಯಾಃ ಪ್ರೀತಿ-ವರ್ಧನಮ್ ।
ಮಂಗಳೇವಾಸರೇ ಚೈವ ವರ್ಜಯೇತ್ ಸರ್ವಕರ್ಮಸು ॥''',
    shastraRef: 'ಸಂಸ್ಕಾರ ಭಾಸ್ಕರ / ಮುಹೂರ್ತ ದರ್ಪಣ',
  ),

  // ── ಚೌಲ (Tonsure) ──
  MuhurtaEvent.chowla: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 4, 6, 7, 12, 13, 14, 21, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireUttarayana: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama, ShuddhiType.chandraSaptama},
    shloka: '''೧. ಅಯನ-ಮಾಸ ನಿಯಮ:
ಉತ್ತರಾಯಣೇ ಶುಭದಂ ಪ್ರೋಕ್ತಂ ಚೈತ್ರ ವೈಶಾಖ-ಜೇಷ್ಠಕೇ ।
ಸೋಮ-ಬುಧ-ಗುರು-ಶುಕ್ರೇ ಚ ಚೌಲಕರ್ಮ ಪ್ರಶಸ್ಯತೇ ॥

೨. ನಕ್ಷತ್ರ-ಮತ್ತು ತಿಥಿ:
ಪುನರ್ವಸು-ಪುಷ್ಯ-ಶ್ರವಣೇ ಅಶ್ವಿನೀ ಹಸ್ತ ರೇವತೀ ।
ರಿಕ್ತಾ-ಚತುರ್ದಶೀ-ಅಮಾವಾಸ್ಯಾಂ ಚೈವ ವಿವರ್ಜಯೇತ್ ॥

೩. ಲಗ್ನ ಶುದ್ಧಿ:
ಲಗ್ನ ಶುದ್ಧೇ ಅಷ್ಟಮ ಶುದ್ಧೇ ಚೌಲಕರ್ಮ ಭವೇತ್ ಶುಭಮ್ ।
ಕೇಂದ್ರೇ ದೃಷ್ಟೇ ಶುಭೈರ್ಗೃಹೈರ್-ಬಾಲಾಯುರ್-ವೃದ್ಧಿದಾಯಕಮ್ ॥''',
    shastraRef: 'ಮುಹೂರ್ತ ಮಾರ್ಥಾಂಡ (ಚೌಲ ಪ್ರಕರಣ)',
  ),

  // ── ವಾಸ್ತು ಶಿಲಾನ್ಯಾಸ (Foundation Laying) ──
  MuhurtaEvent.vastuShilanyas: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 14, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireUttarayana: true,
    requireShukla: true,
    allowedLagnas: [1, 4, 7, 10], // Sthira
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama},
    shloka: '''೧. ಮಾಸ ನಿಯಮ:
ವೈಶಾಖೇ ಫಾಲ್ಗುಣೇ ಚೈತ್ರೇ ಶ್ರಾವಣೇ ಮಾರ್ಗಶೀರ್ಷಕೇ ।
ಶುಕ್ಲಪಕ್ಷೇ ಶುಭಂ ಪ್ರೋಕ್ತಂ ವಾಸ್ತು-ಶಿಲಾನ್ಯಾಸ ಕರ್ಮಣಿ ॥

೨. ನಕ್ಷತ್ರ ಮತ್ತು ವಾರ:
ರೋಹಿಣೀ ಮೃಗಶೀರ್ಷಂ ಚ ಉತ್ತರಾತ್ರಯ-ರೇವತೀ ।
ಸೋಮ-ಬುಧ-ಗುರು-ಶುಕ್ರೇ ಚ ವಾಸ್ತುಪೂಜಾ ಸಿದ್ಧಿದಾ ॥

೩. ಲಗ್ನ ಶುದ್ಧಿ:
ಸ್ಥಿರಲಗ್ನೇ ಶುಭೇ ದೃಷ್ಟೇ ಅಷ್ಟಮೇ ಪಾಪ ವರ್ಜಿತೇ ।
ಕೇಂದ್ರ-ತ್ರಿಕೋಣೇ ಶುಭೈರ್ಯುಕ್ತೇ ಗೃಹಂ ಭವತಿ ಶಾಶ್ವತಮ್ ॥''',
    shastraRef: 'ವಾಸ್ತು ರತ್ನಾಕರ / ವಾಸ್ತು ಮಂಡಲ',
  ),

  // ── ಔಷಧ (Medical Treatment) ──
  MuhurtaEvent.aushadha: MuhurtaEventRules(
    allowedTithis: [0, 1, 2, 4, 5, 6, 9, 10, 11, 12, 14, 15, 16, 17, 19, 20, 21, 24, 25, 26, 29],
    allowedNakshatras: [0, 3, 4, 7, 12, 16, 21, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama},
    shloka: '''೧. ನಕ್ಷತ್ರ ನಿಯಮ:
ಅಶ್ವಿನೀ ಹಸ್ತ ಪುಷ್ಯೇ ಚ ಪುನರ್ವಸು ಶ್ರವಣೇ ತಥಾ ।
ರೋಗಾಣಾಂ ಭೇಷಜಂ ದದ್ಯಾತ್ ಶೀಘ್ರಮಾರೋಗ್ಯಕಾರಕಮ್ ॥

೨. ವಾರ-ತಿಥಿ ನಿಯಮ:
ರವಿ-ಸೋಮ-ಗುರು-ಶುಕ್ರೇ ಚ ರಿಕ್ತಾ-ಪರ್ವ-ವಿವರ್ಜಿತೇ ।
ಉಗ್ರ-ಕ್ರೂರ ನಕ್ಷತ್ರಾಣಿ ರೋಗ-ನಾಶನಾಯ ಯಥಾ ॥

೩. ಲಗ್ನ ಶುದ್ಧಿ:
ಲಗ್ನೇ ಪಾಪ-ಗ್ರಹೇ ದೃಷ್ಟೇ ಷಷ್ಠೇ-ಅಷ್ಟಮೇ ವಿವರ್ಜಯೇತ್ ।
ಔಷಧ-ಸೇವನಂ ಭಕ್ತ್ಯಾ ಸರ್ವವ್ಯಾಧಿ ವಿನಾಶನಮ್ ॥''',
    shastraRef: 'ಮುಹೂರ್ತ ಪಾರಿಜಾತ',
  ),

  // ── ಕೃಷಿ (Agriculture) ──
  MuhurtaEvent.krishi: MuhurtaEventRules(
    allowedTithis: [0, 1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [3, 4, 11, 12, 13, 14, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna},
    shloka: '''೧. ನಕ್ಷತ್ರ-ತಿಥಿ ನಿಯಮ:
ರೋಹಿಣೀಮೃಗಶೀರ್ಷಂ ಚ ಉತ್ತರಾತ್ರಯಮೇವ ಚ ।
ಪುಷ್ಯ-ಹಸ್ತ-ರೇವತೀ ಶುಭಾಃ ಕೃಷಿಕರ್ಮಣಿ ಸರ್ವದಾ ॥

೨. ವಾರ-ಪಕ್ಷ:
ಸೋಮ-ಬುಧ-ಗುರು-ಶುಕ್ರೇ ಶುಕ್ಲ-ಪಕ್ಷೇ ಶುಭಾವಹೇ ।
ರಿಕ್ತಾಮಾವಾಸ್ಯಾಂ ಹಿತ್ವಾ ಬೀಜ-ವಾಪನಮಾಚರೇತ್ ॥

೩. ಲಗ್ನ ಶುದ್ಧಿ:
ಲಗ್ನೇ ಕೇಂದ್ರೇ ಶುಭೇ ದೃಷ್ಟೇ ಪೃಥ್ವೀ ಸಸ್ಯಪ್ರದಾಯಿನೀ ।
ಅಷ್ಟಮೇ ಶುದ್ಧಿ-ಯುಕ್ತೇ ತು ವ್ಯವಸಾಯಃ ಫಲಪ್ರದಃ ॥''',
    shastraRef: 'ಕೃಷಿ ಪರಾಶರ',
  ),

  // ── ವಾಹನ ಖರೀದಿ (Vehicle Purchase) ──
  MuhurtaEvent.vahanaKraya: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 4, 6, 12, 13, 14, 21, 22, 26], // Chara & Mridu
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama},
    shloka: '''೧. ನಕ್ಷತ್ರ ನಿಯಮ:
ಅಶ್ವಿನೀ ಹಸ್ತ ಪುಷ್ಯೇ ಚ ಪುನರ್ವಸು ಶ್ರವಣೇ ತಥಾ ।
ಚರ-ಕ್ಷಿಪ್ರ-ನಕ್ಷತ್ರೇಷು ವಾಹನಕ್ರಯಮಾಚರೇತ್ ॥

೨. ವಾರ ಮತ್ತು ತಿಥಿ:
ಬುಧ-ಗುರು-ಶುಕ್ರ-ವಾರೇಷು ಶುಕ್ಲಪಕ್ಷೇ ಶುಭಾವಹೇ ।
ರಿಕ್ತಾ-ಅಮಾವಾಸ್ಯಾ-ಹೀನಾನಿ ದಿನಾನಿ ಶುಭದಾನಿ ಚ ॥

೩. ಲಗ್ನ ಶುದ್ಧಿ:
ಲಗ್ನೇ ಚತುರ್ಥೇ ಶುದ್ಧೇ ವಾ ಪಾಪ-ದೃಷ್ಟಿ ವಿವರ್ಜಿತೇ ।
ವಾಹನಂ ಸುಖದಂ ನಿತ್ಯಂ ಅಪಮೃತ್ಯು ವಿನಾಶನಮ್ ॥''',
    shastraRef: 'ಮುಹೂರ್ತ ದೀಪಿಕಾ',
  ),

  // ── ಆಸ್ತಿ ಖರೀದಿ (Property Purchase) ──
  MuhurtaEvent.aasthiKraya: MuhurtaEventRules(
    allowedTithis: [1, 4, 9, 10, 11],
    allowedNakshatras: [3, 4, 11, 13, 16, 20, 25, 26], // Sthira & Mridu
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama},
    shloka: '''೧. ನಕ್ಷತ್ರ ನಿಯಮ:
ರೋಹಿಣೀ ಮೃಗಶೀರ್ಷಂ ಚ ಉತ್ತರಾತ್ರಯಮೇವ ಚ ।
ಸ್ಥಿರ-ನಕ್ಷತ್ರ-ಯೋಗೇಷು ಭೂಮಿ-ಕ್ರಯ-ವಿಕ್ರಯಃ ಶುಭಃ ॥

೨. ವಾರ-ತಿಥಿ-ಲಗ್ನ:
ಗುರು-ಶುಕ್ರ-ಬುಧ-ವಾರೇ ಶುಕ್ಲಪಕ್ಷೇ ವಿಶೇಷತಃ ।
ಸ್ಥಿರ ಲಗ್ನೇ ಶುಭೇ ದೃಷ್ಟೇ ಸಂಪದ್-ವೃದ್ಧಿಕರಂ ಭವೇತ್ ॥

೩. ಅಷ್ಟಮ-ಶುದ್ಧಿ:
ಲಗ್ನಾತ್ ಅಷ್ಟಮ ಭಾವೇ ತು ಪಾಪ-ಗ್ರಹ ವಿವರ್ಜಿತೇ ।
ಆಸ್ತಿ-ಭೂಮಿ-ಕ್ರಯೇ ನಿತ್ಯಂ ಶಾಶ್ವತಂ ಸುಖದಾಯಕಮ್ ॥''',
    shastraRef: 'ವಾಸ್ತು ಚಿಂತಾಮಣಿ',
  ),

  // ── ಆಭರಣ ಖರೀದಿ (Gold Purchase) ──
  MuhurtaEvent.swarnaKraya: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 16, 21, 22, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna},
    shloka: '''೧. ನಕ್ಷತ್ರ ಮತ್ತು ವಾರ:
ಪುಷ್ಯ-ಹಸ್ತ-ರೇವತ್ಯಾಂ ಚ ಪುನರ್ವಸು ಶ್ರವಣೇ ತಥಾ ।
ಗುರುಪೂಷ್ಯ-ಯೋಗ-ಕಾಲೇ ತು ಸ್ವರ್ಣ-ಕ್ರಯ-ಮಹೋತ್ಸವಃ ॥

೨. ತಿಥಿ ನಿಯಮ:
ಪಕ್ಷೇ ಶುಕ್ಲೇ ತಥಾ ಕೃಷ್ಣೇ ರಿಕ್ತಾ-ಪರ್ವ ವಿವರ್ಜಿತೇ ।
ಏಕಾದಶೀ ಪೂರ್ಣಿಮಾ ಚ ಸ್ವರ್ಣ ಖರೀದಿಗೆ ಸಿದ್ಧಿದಾ ॥

೩. ಲಗ್ನ-ಧನ ಶುದ್ಧಿ:
ಲಗ್ನ-ವ್ಯಯ-ಧನ-ಭಾವೇ ಪಾಪದೃಷ್ಟಿ ವಿವರ್ಜಿತೇ ।
ಮಹಾಲಕ್ಷ್ಮೀ-ಕೃಪಾಯುಕ್ತಂ ಸ್ವರ್ಣ-ಮಂಗಳ-ಕಾರಕಮ್ ॥''',
    shastraRef: 'ಮಹಾಲಕ್ಷ್ಮೀ ತಂತ್ರ / ಮುಹೂರ್ತ ದರ್ಪಣ',
  ),

  // ── ಉದ್ಯೋಗ (Job Joining / Office) ──
  MuhurtaEvent.udyoga: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 9, 10, 11],
    allowedNakshatras: [3, 4, 7, 11, 13, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.dashama},
    shloka: '''೧. ನಕ್ಷತ್ರ-ತಿಥಿ ನಿಯಮ:
ಅಶ್ವಿನೀ ಪುಷ್ಯ ಹಸ್ತೇಷು ರೋಹಿಣೀ ಮೃಗಶೀರ್ಷಕೇ ।
ರಿಕ್ತಾಮಾವಾಸ್ಯಾಂ ಹಿತ್ವಾ ಉದ್ಯೋಗ-ಪದ-ಸಿದ್ಧಿದಃ ॥

೨. ವಾರ ನಿಯಮ:
ಸೋಮ-ಬುಧ-ಗುರು-ಶುಕ್ರೇ ಚ ಭಾನುವಾರೇ ವಿಶೇಷತಃ ।
ರಾಜ-ದರ್ಶನ-ಕಾರ್ಯೇಷು ಉದ್ಯೋಗ-ಗ್ರಹಣೇ ಶುಭಮ್ ॥

೩. ದಶಮ-ಲಗ್ನ-ಶುದ್ಧಿ:
ದಶಮೇ ಪಾಪ-ರಹಿತೇ ಲಗ್ನೇ ಶುಭ-ನಿರೀಕ್ಷಿತೇ ।
ಉದ್ಯೋಗ-ಸ್ಥೈರ್ಯ-ಲಾಭಾಯ ಸರ್ವ-ಕಾರ್ಯ-ಜಯಪ್ರದಮ್ ॥''',
    shastraRef: 'ಕರ್ಮ-ಪ್ರಕಾಶಿಕಾ',
  ),

  // ── ಕರ್ಣವೇಧ (Ear Piercing) ──
  MuhurtaEvent.karnavedha: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 4, 6, 7, 12, 13, 21, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: null,
    requiredShuddhis: {ShuddhiType.lagna, ShuddhiType.ashtama},
    shloka: '''೧. ನಕ್ಷತ್ರ ನಿಯಮ:
ಮೃಗಶಿರೋ-ಪುನರ್ವಸು-ಪುಷ್ಯೇ ಹಸ್ತೇ ಚೈವೋತ್ತರಾತ್ರಯೇ ।
ರೇವತ್ಯಾಂ ಶ್ರವಣೇ ವಾಪಿ ಕರ್ಣವೇಧಃ ಶುಭಾವಹಃ ॥

೨. ಮಾಸ-ತಿಥಿ ನಿಯಮ:
ಷಷ್ಠೇ ವಾ ಸಪ್ತಮೇ ಮಾಸಿ ರಿಕ್ತಾ-ಅಮಾವಾಸ್ಯಾ ವರ್ಜಿತೇ ।
ಶುಕ್ಲಪಕ್ಷೇ ದ್ವಿತೀಯಾಯಾಂ ತೃತೀಯಾಯಾಂ ಶುಭಂ ಭವೇತ್ ॥

೩. ಲಗ್ನ-ಅಷ್ಟಮ ಶುದ್ಧಿ:
ಲಗ್ನೇ ಕೇಂದ್ರೇ ಶುಭೈರ್ದೃಷ್ಟೇ ಅಷ್ಟಮೇ ಪಾಪ ವರ್ಜಿತೇ ।
ಕರ್ಣ-ರೋಗ-ವಿನಾಶಾಯ ಆಯುರ್-ವೃದ್ಧಿಕರಂ ಭವೇತ್ ॥''',
    shastraRef: 'ಮುಹೂರ್ತ ಚಿಂತಾಮಣಿ (ಸಂಸ್ಕಾರ ಪ್ರಕರಣ)',
  ),
};


// ============================================================
// SIDDHA YOGA — Tithi + Vara auspicious combinations
// ============================================================
// Key: vara index (0=Sun..6=Sat), Value: list of shubha tithi indices (0-based)
const Map<int, List<int>> siddhaYogaTable = {
  0: [0, 3, 5, 6, 10],    // Sunday: Pratipada(0), Chaturthi(3), Shashthi(5), Saptami(6), Ekadashi(10)
  1: [1, 6, 11],           // Monday: Dwitiya(1), Saptami(6), Dwadashi(11)
  2: [2, 7, 12],           // Tuesday: Tritiya(2), Ashtami(7), Trayodashi(12)
  3: [4, 9, 14],           // Wednesday: Panchami(4), Dashami(9), Purnima/Amavasya(14)
  4: [5, 10, 0],           // Thursday: Shashthi(5), Ekadashi(10), Pratipada(0)
  5: [1, 6, 11],           // Friday: Dwitiya(1), Saptami(6), Dwadashi(11)
  6: [2, 7, 12],           // Saturday: Tritiya(2), Ashtami(7), Trayodashi(12)
};

// ============================================================
// AMRITA SIDDHI YOGA — Vara + Nakshatra most powerful combos
// ============================================================
const Map<int, List<int>> amritaSiddhiTable = {
  0: [12, 7, 0],           // Sunday: Hasta(12), Pushya(7), Ashwini(0)
  1: [4, 3, 21],           // Monday: Mrigashira(4), Rohini(3), Shravana(21)
  2: [0, 11, 2],           // Tuesday: Ashwini(0), U.Phalguni(11), Krittika(2)
  3: [16, 26, 3],          // Wednesday: Anuradha(16), Revati(26), Rohini(3)
  4: [6, 7, 0, 26],        // Thursday: Punarvasu(6), Pushya(7), Ashwini(0), Revati(26)
  5: [26, 16, 21],         // Friday: Revati(26), Anuradha(16), Shravana(21)
  6: [3, 14, 21],          // Saturday: Rohini(3), Swati(14), Shravana(21)
};

// ============================================================
// DAGDHA YOGA — Vara + Nakshatra ALWAYS BAD (cannot be cancelled)
// ============================================================
const Map<int, List<int>> dagdhaYogaTable = {
  0: [1, 2],               // Sunday: Bharani(1), Krittika(2)
  1: [13, 15],             // Monday: Chitra(13), Vishakha(15)
  2: [11, 20],             // Tuesday: U.Phalguni(11), U.Ashadha(20)
  3: [22, 23],             // Wednesday: Dhanishtha(22), Shatabhisha(23)
  4: [4, 5],               // Thursday: Mrigashira(4), Ardra(5)
  5: [17, 18],             // Friday: Jyeshtha(17), Moola(18)
  6: [26, 0],              // Saturday: Revati(26), Ashwini(0)
};

// ============================================================
// BLOCKED YOGAS (Panchanga Yoga — always avoid)
// ============================================================
// Vishkumbha(0), Atiganda(6), Shoola(9), Ganda(10), Vyaghata(13),
// Vajra(14), Vyatipata(17), Parigha(19), Vaidhriti(26)
const List<int> blockedYogaIndices = [0, 6, 9, 10, 13, 14, 17, 19, 26];


// ============================================================
// TARA BALA
// ============================================================
/// Returns tara index (0-8) and whether it's good
class TaraResult {
  final int taraIndex; // 0-8
  final String taraName;
  final bool isGood;
  TaraResult(this.taraIndex, this.taraName, this.isGood);
}

const List<String> taraNames = [
  'ಜನ್ಮ ತಾರೆ', 'ಸಂಪತ್ ತಾರೆ', 'ವಿಪತ್ ತಾರೆ',
  'ಕ್ಷೇಮ ತಾರೆ', 'ಪ್ರತ್ಯಕ್ ತಾರೆ', 'ಸಾಧಕ ತಾರೆ',
  'ವಧ ತಾರೆ', 'ಮಿತ್ರ ತಾರೆ', 'ಪರಮ ಮಿತ್ರ ತಾರೆ',
];

TaraResult calculateTaraBala(int janmaNakIdx, int dinaNakIdx) {
  final taraIdx = (dinaNakIdx - janmaNakIdx + 27) % 27 % 9;
  final isGood = (taraIdx == 1 || taraIdx == 3 || taraIdx == 5 || taraIdx == 7 || taraIdx == 8);
  return TaraResult(taraIdx, taraNames[taraIdx], isGood);
}

// ============================================================
// CHANDRA BALA
// ============================================================
/// Moon's transit rashi counted from birth rashi. Good in 1,3,6,7,10,11.
bool calculateChandraBala(int janmaRashiIdx, int moonRashiIdx) {
  final count = ((moonRashiIdx - janmaRashiIdx + 12) % 12) + 1; // 1-indexed
  return const [1, 3, 6, 7, 10, 11].contains(count);
}

// ============================================================
// GURU BALA
// ============================================================
class BalaScore {
  final int score; // 2=Shubha, 1=Poojya, 0=Ashubha
  final String label;
  BalaScore(this.score, this.label);
}

/// Jupiter's transit rashi counted from birth rashi. 
/// Shubha: 2, 5, 7, 9, 11. Poojya: 1, 3, 6, 10. Ashubha: 4, 8, 12.
BalaScore calculateGuruBala(int janmaRashiIdx, int jupiterRashiIdx) {
  final count = ((jupiterRashiIdx - janmaRashiIdx + 12) % 12) + 1; // 1-indexed
  if (const [2, 5, 7, 9, 11].contains(count)) {
    return BalaScore(2, 'ಶುಭ');
  } else if (const [1, 3, 6, 10].contains(count)) {
    return BalaScore(1, 'ಪೂಜ್ಯ (ಶಾಂತಿ ಅಗತ್ಯ)');
  } else {
    return BalaScore(0, 'ಅಶುಭ');
  }
}


// ============================================================
// LAGNA WINDOW — time windows for each rashi lagna
// ============================================================

/// Malefic planets (Paapa Grahas) for shuddhi checks
/// Mars(ಕುಜ), Saturn(ಶನಿ), Rahu(ರಾಹು), Ketu(ಕೇತು), Sun(ರವಿ)
const List<String> paapGrahas = ['ಕುಜ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು', 'ರವಿ'];

class LagnaWindow {
  final int rashiIndex;    // 0-11
  final String rashiName;  // e.g. 'ಮೇಷ'
  final String startTime;  // e.g. '06:30 AM'
  final String endTime;    // e.g. '08:45 AM'
  final bool isAllowed;    // true if this lagna is allowed for the event

  // Shuddhi checks
  final bool lagnaShuddhi;         // No malefics in lagna rashi (1st house)
  final bool saptamaShuddhi;       // Clean 7th house (varies by event)
  final bool ashtamaShuddhi;       // Clean 8th house
  final bool dashamaShuddhi;       // Empty 10th house
  final bool chandraSaptamaShuddhi;// Sun/Saturn/Mars missing from Moon's 7th
  final bool guruAnukoola;         // Jupiter in Kendra/Trikona

  // Details for display
  final List<String> lagnaGrahas;    
  final List<String> saptamaGrahas;  
  final List<String> ashtamaGrahas;  
  final List<String> dashamaGrahas;
  final List<String> chandraSaptamaGrahas;
  final int guruFromLagna;           

  // Event-specific required shuddhis
  final Set<ShuddhiType> requiredShuddhis;

  LagnaWindow({
    required this.rashiIndex,
    required this.rashiName,
    required this.startTime,
    required this.endTime,
    required this.isAllowed,
    this.lagnaShuddhi = true,
    this.saptamaShuddhi = true,
    this.ashtamaShuddhi = true,
    this.dashamaShuddhi = true,
    this.chandraSaptamaShuddhi = true,
    this.guruAnukoola = false,
    this.lagnaGrahas = const [],
    this.saptamaGrahas = const [],
    this.ashtamaGrahas = const [],
    this.dashamaGrahas = const [],
    this.chandraSaptamaGrahas = const [],
    this.guruFromLagna = 0,
    this.requiredShuddhis = const {ShuddhiType.lagna},
  });

  /// Event-aware shuddhi — only checks the shuddhis required for this event
  bool get isShubha {
    if (!isAllowed) return false;
    if (requiredShuddhis.contains(ShuddhiType.lagna) && !lagnaShuddhi) return false;
    if (requiredShuddhis.contains(ShuddhiType.saptama) && !saptamaShuddhi) return false;
    if (requiredShuddhis.contains(ShuddhiType.ashtama) && !ashtamaShuddhi) return false;
    if (requiredShuddhis.contains(ShuddhiType.dashama) && !dashamaShuddhi) return false;
    if (requiredShuddhis.contains(ShuddhiType.chandraSaptama) && !chandraSaptamaShuddhi) return false;
    return true;
  }

  /// Best quality: all required shuddhi pass + guru anukoola
  bool get isPerfect => isShubha && guruAnukoola;
}

/// Helper method to find ALL planets in a rashi (for Dashama & Vivaha Saptama)
List<String> findAllPlanetsInRashi(int rashiIdx, Map<String, int> planetRashis) {
  final List<String> found = [];
  planetRashis.forEach((planet, rIdx) {
    if (rIdx == rashiIdx && planet != 'ರಾಹು' && planet != 'ಕೇತು') {
      found.add(planet);
    }
  });
  // If nodes are there, add them explicitly since sometimes they are filtered out
  if (planetRashis['ರಾಹು'] == rashiIdx) found.add('ರಾಹು');
  if (planetRashis['ಕೇತು'] == rashiIdx) found.add('ಕೇತು');
  return found;
}

/// Check if Guru (Jupiter) is in Kendra/Trikona or auspicious houses (2, 11) from lagna
bool isGuruAnukoolaForLagna(int lagnaRashiIdx, int guruRashiIdx) {
  final count = ((guruRashiIdx - lagnaRashiIdx + 12) % 12) + 1; // 1-indexed
  // Kendra: 1, 4, 7, 10 — Trikona: 5, 9 — Dhana/Labha: 2, 11
  return const [1, 2, 4, 5, 7, 9, 10, 11].contains(count);
}

/// Find malefic planets in a given rashi
List<String> findMaleficsInRashi(int rashiIdx, Map<String, int> planetRashis) {
  final List<String> found = [];
  for (final paapa in paapGrahas) {
    if (planetRashis[paapa] == rashiIdx) {
      found.add(paapa);
    }
  }
  return found;
}


// ============================================================
// DEITY-SPECIFIC TITHIS FOR DEVA PRATISHTHA
// ============================================================
/// For Deva Pratishtha, specific deities have preferred tithis
const Map<String, List<int>> deityTithiTable = {
  'ಗಣಪತಿ':     [3, 8, 13],  // Chaturthi
  'ಶಿವ':       [7, 12, 13], // Ashtami, Trayodashi, Chaturdashi
  'ವಿಷ್ಣು':    [10, 11, 12],// Ekadashi, Dwadashi
  'ದೇವಿ':      [7, 8, 13],  // Navami, Dashami
  'ಸೂರ್ಯ':     [6],         // Saptami
  'ಹನುಮಂತ':   [13],        // Chaturdashi (Tues pref)
  'ನಾಗ':       [4],         // Panchami
  'ಸಾಮಾನ್ಯ':  [1, 2, 4, 6, 7, 9, 10, 11, 12, 13], // General
};

// ============================================================
// MUHURTA CHECK RESULT — output of the rule engine
// ============================================================

class MuhurtaCheckItem {
  final String label;      // e.g. 'ತಿಥಿ', 'ನಕ್ಷತ್ರ'
  final String value;      // e.g. 'ಶುಕ್ಲ ತೃತೀಯ'
  final bool passed;
  final String? note;      // e.g. 'ಸಿದ್ಧ ಯೋಗ — ದೋಷ ಭಂಗ'

  MuhurtaCheckItem({
    required this.label,
    required this.value,
    required this.passed,
    this.note,
  });
}

class PersonBalaResult {
  final TaraResult taraBala;
  final bool chandraBala;
  final BalaScore guruBala;

  PersonBalaResult({
    required this.taraBala,
    required this.chandraBala,
    required this.guruBala,
  });
}

class MuhurtaDayResult {
  final int score;          // 0-100
  final String verdict;     // ಶ್ರೇಷ್ಠ / ಮಧ್ಯಮ / ಅಶುಭ
  final List<MuhurtaCheckItem> checks;
  final List<PersonBalaResult> personResults; // 1 or 2
  final List<String> doshas;
  final List<String> doshaBhangas; // active dosha cancellations
  final List<LagnaWindow> lagnaWindows; // available lagna windows for the day
  final bool hasAbhijit;    // true if Abhijit muhurta bonus applied
  final bool hasGodhuli;    // true if Godhuli Lagna bonus applied (Vivaha)
  final String? abhijitTime; // Abhijit muhurta time window string
  final String? godhuliTime; // Godhuli time window string

  MuhurtaDayResult({
    required this.score,
    required this.verdict,
    required this.checks,
    required this.personResults,
    required this.doshas,
    required this.doshaBhangas,
    this.lagnaWindows = const [],
    this.hasAbhijit = false,
    this.hasGodhuli = false,
    this.abhijitTime,
    this.godhuliTime,
  });
}


// ============================================================
// MAIN EVALUATION FUNCTION
// ============================================================

/// Evaluate a single day for a given muhurta event
MuhurtaDayResult evaluateMuhurta({
  required MuhurtaEvent event,
  required int tithiIndex,        // 0-29
  required String tithiName,
  required int nakshatraIndex,    // 0-26
  required String nakshatraName,
  required int varaIndex,         // 0=Sun..6=Sat
  required String varaName,
  required int yogaIndex,         // 0-26
  required String yogaName,
  required String karanaName,
  required int moonRashiIndex,    // 0-11
  required int jupiterRashiIndex, // 0-11
  required int sunRashiIndex,     // 0-11 (for Ayana check)
  // Person 1
  required int janmaNakIdx1,
  required int janmaRashiIdx1,
  // Person 2 (optional)
  int? janmaNakIdx2,
  int? janmaRashiIdx2,
  // Phase 3: Abhijit & Godhuli overrides
  String? abhijitTimeWindow,  // e.g. "11:48 AM - 12:20 PM"
  String? godhuliTimeWindow,  // e.g. "05:55 PM - 06:43 PM"
}) {
  final rules = muhurtaRules[event]!;
  final List<MuhurtaCheckItem> checks = [];
  final List<String> doshas = [];
  final List<String> doshaBhangas = [];
  int totalPoints = 0;
  int maxPoints = 0;
  bool hasAyanaDosha = false;

  // Paksha (used for display)
  final bool isShukla = tithiIndex < 15;
  final int pakshaRelTithi = tithiIndex % 15; // 0-14 within paksha

  // ── 1. TITHI CHECK (15 points) ──
  maxPoints += 15;
  bool tithiPassed = true;
  if (rules.requireShukla && !isShukla) {
    tithiPassed = false;
  } else if (rules.allowedTithis != null) {
    tithiPassed = rules.allowedTithis!.contains(pakshaRelTithi);
  }
  // Check Siddha Yoga override for failed tithi
  bool hasSiddhaYoga = false;
  if (!tithiPassed) {
    final siddhaList = siddhaYogaTable[varaIndex];
    if (siddhaList != null && siddhaList.contains(pakshaRelTithi)) {
      hasSiddhaYoga = true;
      tithiPassed = true;
      doshaBhangas.add('ಸಿದ್ಧ ಯೋಗ — ತಿಥಿ ದೋಷ ಭಂಗ');
    }
  }
  if (tithiPassed) totalPoints += 15;
  checks.add(MuhurtaCheckItem(
    label: 'ತಿಥಿ',
    value: tithiName,
    passed: tithiPassed,
    note: hasSiddhaYoga ? 'ಸಿದ್ಧ ಯೋಗ — ದೋಷ ಭಂಗ' : null,
  ));

  // ── 2. NAKSHATRA CHECK (15 points) ──
  maxPoints += 15;
  bool nakPassed = true;
  if (rules.allowedNakshatras != null) {
    nakPassed = rules.allowedNakshatras!.contains(nakshatraIndex);
  }
  // Check Amrita Siddhi Yoga override
  bool hasAmritaSiddhi = false;
  final amritaList = amritaSiddhiTable[varaIndex];
  final cleanNakName = nakshatraName.split(' ')[0]; // avoid full string
  if (amritaList != null && amritaList.contains(nakshatraIndex)) {
    hasAmritaSiddhi = true;
    if (!nakPassed) {
      nakPassed = true;
      doshaBhangas.add('ಅಮೃತ ಸಿದ್ಧಿ ಯೋಗ ($varaName + $cleanNakName) — ನಕ್ಷತ್ರ ದೋಷ ಭಂಗ');
    }
  }
  if (nakPassed) totalPoints += 15;
  checks.add(MuhurtaCheckItem(
    label: 'ನಕ್ಷತ್ರ',
    value: nakshatraName,
    passed: nakPassed,
    note: hasAmritaSiddhi ? 'ಅಮೃತ ಸಿದ್ಧಿ: $varaName + $cleanNakName ನಕ್ಷತ್ರ' : null,
  ));

  // ── 2B. AYANA CHECK (10 points) ──
  if (rules.requireUttarayana) {
    maxPoints += 10;
    // sidereal sun in Makara, Kumbha, Meena, Mesha, Vrishabha, Mithuna (indices 9,10,11,0,1,2)
    bool isUttarayana = (sunRashiIndex >= 9 || sunRashiIndex <= 2);
    if (!isUttarayana) {
      doshas.add('ಅಯನ ದೋಷ (ದಕ್ಷಿಣಾಯನ)');
      hasAyanaDosha = true;
    }
    if (isUttarayana) totalPoints += 10;
    checks.add(MuhurtaCheckItem(
      label: 'ಅಯನ (ಉತ್ತರಾಯಣ ಮಾತ್ರ)',
      value: isUttarayana ? 'ಉತ್ತರಾಯಣ' : 'ದಕ್ಷಿಣಾಯನ',
      passed: isUttarayana,
    ));
  }

  // ── 3. VARA CHECK (10 points) ──
  maxPoints += 10;
  bool varaPassed = true;
  if (rules.allowedVaras != null) {
    varaPassed = rules.allowedVaras!.contains(varaIndex);
  }
  if (varaPassed) totalPoints += 10;
  checks.add(MuhurtaCheckItem(
    label: 'ವಾರ',
    value: varaName,
    passed: varaPassed,
  ));

  // ── 4. YOGA CHECK (5 points) ──
  maxPoints += 5;
  bool yogaPassed = !blockedYogaIndices.contains(yogaIndex);
  if (yogaPassed) totalPoints += 5;
  checks.add(MuhurtaCheckItem(
    label: 'ಯೋಗ',
    value: yogaName,
    passed: yogaPassed,
    note: yogaPassed ? null : 'ಅಶುಭ ಯೋಗ',
  ));

  // ── 5. KARANA CHECK (5 points) ──
  maxPoints += 5;
  bool karanaPassed = true;
  if (rules.avoidVishti && karanaName.contains('ವಿಷ್ಟಿ') || karanaName.contains('ಭದ್ರಾ')) {
    karanaPassed = false;
    doshas.add('ವಿಷ್ಟಿ (ಭದ್ರಾ) ಕರಣ');
  }
  if (karanaPassed) totalPoints += 5;
  checks.add(MuhurtaCheckItem(
    label: 'ಕರಣ',
    value: karanaName,
    passed: karanaPassed,
  ));

  // ── 6. DAGDHA YOGA CHECK (5 points — HARD BLOCK) ──
  maxPoints += 5;
  bool hasDagdha = false;
  final dagdhaList = dagdhaYogaTable[varaIndex];
  if (dagdhaList != null && dagdhaList.contains(nakshatraIndex)) {
    hasDagdha = true;
    doshas.add('ದಗ್ಧ ಯೋಗ — ಸರ್ವಥಾ ನಿಷಿದ್ಧ');
  }
  if (!hasDagdha) totalPoints += 5;
  checks.add(MuhurtaCheckItem(
    label: 'ದಗ್ಧ ಯೋಗ',
    value: hasDagdha ? 'ಇದೆ ❌' : 'ಇಲ್ಲ ✓',
    passed: !hasDagdha,
    note: hasDagdha ? 'ದೋಷ ಭಂಗ ಇಲ್ಲ — ನಿಷೇಧ' : null,
  ));

  // ── 7. TARA BALA (10 pts per person) ──
  final List<PersonBalaResult> personResults = [];

  // Person 1
  final tara1 = calculateTaraBala(janmaNakIdx1, nakshatraIndex);
  final chandra1 = calculateChandraBala(janmaRashiIdx1, moonRashiIndex);
  final guru1 = calculateGuruBala(janmaRashiIdx1, jupiterRashiIndex);
  personResults.add(PersonBalaResult(taraBala: tara1, chandraBala: chandra1, guruBala: guru1));

  // Tara Bala (Person 1) — 10 pts
  maxPoints += 10;
  bool tara1Passed = tara1.isGood;
  // Tara dosha bhanga: Amrita Siddhi cancels minor tara dosha
  if (!tara1Passed && hasAmritaSiddhi) {
    tara1Passed = true;
    doshaBhangas.add('ಅಮೃತ ಸಿದ್ಧಿ — ತಾರಾ ದೋಷ ಭಂಗ (ವ್ಯಕ್ತಿ 1)');
  }
  if (tara1Passed) totalPoints += 10;

  // Chandra Bala (Person 1) — 10 pts
  maxPoints += 10;
  if (chandra1) totalPoints += 10;

  // Guru Bala (Person 1) — 10 pts
  maxPoints += 10;
  if (guru1.score == 2) {
    totalPoints += 10;
  } else if (guru1.score == 1) {
    totalPoints += 5; // Poojya gives partial points
    doshaBhangas.add('ಗುರು ಬಲ: ಪೂಜ್ಯ ಸ್ಥಾನ (ಶಾಂತಿ ಮಾಡಿ)');
  }

  checks.add(MuhurtaCheckItem(label: 'ತಾರಾ ಬಲ', value: tara1.taraName, passed: tara1Passed));
  checks.add(MuhurtaCheckItem(label: 'ಚಂದ್ರ ಬಲ', value: chandra1 ? '✓' : '✗', passed: chandra1));
  checks.add(MuhurtaCheckItem(label: 'ಗುರು ಬಲ', value: guru1.label, passed: guru1.score > 0));

  // Person 2 (if provided)
  if (janmaNakIdx2 != null && janmaRashiIdx2 != null) {
    final tara2 = calculateTaraBala(janmaNakIdx2, nakshatraIndex);
    final chandra2 = calculateChandraBala(janmaRashiIdx2, moonRashiIndex);
    final guru2 = calculateGuruBala(janmaRashiIdx2, jupiterRashiIndex);
    personResults.add(PersonBalaResult(taraBala: tara2, chandraBala: chandra2, guruBala: guru2));

    maxPoints += 30; // 10 tara + 10 chandra + 10 guru for person 2

    bool tara2Passed = tara2.isGood;
    if (!tara2Passed && hasAmritaSiddhi) {
      tara2Passed = true;
      doshaBhangas.add('ಅಮೃತ ಸಿದ್ಧಿ — ತಾರಾ ದೋಷ ಭಂಗ (ವ್ಯಕ್ತಿ 2)');
    }
    if (tara2Passed) totalPoints += 10;
    if (chandra2) totalPoints += 10;
    
    if (guru2.score == 2) {
      totalPoints += 10;
    } else if (guru2.score == 1) {
      totalPoints += 5;
      doshaBhangas.add('ಗುರು ಬಲ (ವ್ಯಕ್ತಿ 2): ಪೂಜ್ಯ ಸ್ಥಾನ (ಶಾಂತಿ ಮಾಡಿ)');
    }

    // Tara dosha bhanga for Vivaha: same rashi lord cancels
    if (event == MuhurtaEvent.vivaha) {
      final rashiLords = [4, 5, 3, 1, 0, 3, 5, 4, 8, 6, 6, 8]; // Mars,Venus,Mercury,Moon,Sun,Mercury,Venus,Mars,Jupiter,Saturn,Saturn,Jupiter
      if (rashiLords[janmaRashiIdx1] == rashiLords[janmaRashiIdx2]) {
        if (!tara1.isGood || !tara2.isGood) {
          doshaBhangas.add('ಸಮಾನ ರಾಶ್ಯಧಿಪತಿ — ತಾರಾ ದೋಷ ಭಂಗ');
        }
      }
    }
  }

  // ── AMRITA SIDDHI BONUS ──
  if (hasAmritaSiddhi) {
    totalPoints += 5; // Bonus
    maxPoints += 5;
    final txt = 'ಅಮೃತ ಸಿದ್ಧಿ ಯೋಗ: $varaName + $cleanNakName';
    if (!doshaBhangas.any((d) => d.contains('ಅಮೃತ ಸಿದ್ಧಿ'))) {
      doshaBhangas.add(txt);
    }
  }

  // ── ABHIJIT MUHURTA BONUS (5 points) ──
  // The 8th muhurta period (midday, ~local noon) is universally auspicious.
  // If abhijitTimeWindow is provided, it means this day has Abhijit muhurta.
  bool abhijitApplied = false;
  if (abhijitTimeWindow != null) {
    maxPoints += 5;
    totalPoints += 5;
    abhijitApplied = true;
    doshaBhangas.add('ಅಭಿಜಿತ್ ಮುಹೂರ್ತ ಲಭ್ಯ ($abhijitTimeWindow)');
    checks.add(MuhurtaCheckItem(
      label: 'ಅಭಿಜಿತ್',
      value: abhijitTimeWindow,
      passed: true,
      note: 'ಸರ್ವ ಕಾರ್ಯ ಶುಭ — ಮಧ್ಯಾಹ್ನ ಮುಹೂರ್ತ',
    ));
  }

  // ── GODHULI LAGNA BONUS (5 points — Vivaha only) ──
  // The period around sunset (~24 min before/after) is considered highly
  // auspicious for Vivaha per Muhurta Chintamani, as cows returning home
  // raise dust (Godhuli = cow-dust).
  bool godhuliApplied = false;
  if (event == MuhurtaEvent.vivaha && godhuliTimeWindow != null) {
    maxPoints += 5;
    totalPoints += 5;
    godhuliApplied = true;
    doshaBhangas.add('ಗೋಧೂಳಿ ಲಗ್ನ ಲಭ್ಯ ($godhuliTimeWindow)');
    checks.add(MuhurtaCheckItem(
      label: 'ಗೋಧೂಳಿ',
      value: godhuliTimeWindow,
      passed: true,
      note: 'ವಿವಾಹಕ್ಕೆ ಅತ್ಯಂತ ಶುಭ',
    ));
  }

  // ── COMPUTE FINAL SCORE ──
  final score = maxPoints > 0 ? ((totalPoints / maxPoints) * 100).round().clamp(0, 100) : 0;

  // Hard penalty for Dagdha or Ayana violation — cap at 30
  final finalScore = (hasDagdha || hasAyanaDosha) ? score.clamp(0, 30) : score;

  String verdict;
  if (finalScore >= 80) {
    verdict = 'ಶ್ರೇಷ್ಠ';
  } else if (finalScore >= 60) {
    verdict = 'ಮಧ್ಯಮ';
  } else {
    verdict = 'ಅಶುಭ';
  }

  return MuhurtaDayResult(
    score: finalScore,
    verdict: verdict,
    checks: checks,
    personResults: personResults,
    doshas: doshas,
    doshaBhangas: doshaBhangas,
    hasAbhijit: abhijitApplied,
    hasGodhuli: godhuliApplied,
    abhijitTime: abhijitTimeWindow,
    godhuliTime: godhuliTimeWindow,
  );
}

