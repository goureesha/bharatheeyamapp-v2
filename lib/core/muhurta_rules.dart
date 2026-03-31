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
};

// ============================================================
// PANCHANGA-BASED RULES PER EVENT
// ============================================================

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
  /// Allowed lagna rashi indices (0-11). Null = not checked in Phase 1.
  final List<int>? allowedLagnas;

  const MuhurtaEventRules({
    this.allowedTithis,
    this.allowedNakshatras,
    this.allowedVaras,
    this.avoidVishti = true,
    this.requireShukla = false,
    this.allowedLagnas,
  });
}

/// Mapping of event types to their Panchanga rules
const Map<MuhurtaEvent, MuhurtaEventRules> muhurtaRules = {
  // ── ವಿವಾಹ (Marriage) ──
  MuhurtaEvent.vivaha: MuhurtaEventRules(
    // Shukla: 2,3,5,7,10,11,12,13 (indices 1,2,4,6,9,10,11,12)
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    // Rohini(3), Mrigashira(4), Magha(9), U.Phalguni(11), Hasta(12), Swati(14),
    // Anuradha(16), Moola(18), U.Ashadha(20), U.Bhadra(25), Revati(26)
    allowedNakshatras: [3, 4, 9, 11, 12, 14, 16, 18, 20, 25, 26],
    // Mon(1), Wed(3), Thu(4), Fri(5)
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: [2, 5, 6, 8, 11], // Mithuna, Kanya, Tula, Dhanu, Meena
  ),

  // ── ಉಪನಯನ (Thread Ceremony) ──
  MuhurtaEvent.upanayana: MuhurtaEventRules(
    // Shukla: 2,3,5,10,11,12; Krishna: 2,3,5 (indices 1,2,4,9,10,11 + 16,17,19)
    allowedTithis: [1, 2, 4, 9, 10, 11, 16, 17, 19],
    // Ashwini(0), Rohini(3), Mrigashira(4), Punarvasu(6), Pushya(7), Hasta(12),
    // Chitra(13), Swati(14), Anuradha(16), Shravana(21), Dhanishtha(22),
    // Shatabhisha(23), U.Phalguni(11), U.Ashadha(20), U.Bhadra(25), Revati(26)
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 14, 16, 20, 21, 22, 23, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    allowedLagnas: [2, 5, 8, 11],
  ),

  // ── ಗೃಹಪ್ರವೇಶ (House Warming) ──
  MuhurtaEvent.grihaPrevesha: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    // Sthira: Rohini(3), U.Phalguni(11), U.Ashadha(20), U.Bhadra(25)
    // Mridu: Mrigashira(4), Chitra(13), Anuradha(16), Revati(26)
    allowedNakshatras: [3, 4, 11, 13, 16, 20, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: [1, 4, 7, 10], // Sthira rashis
  ),

  // ── ದೇವ ಪ್ರತಿಷ್ಠಾ (Deity Installation) ──
  MuhurtaEvent.devaPratishtha: MuhurtaEventRules(
    // Deity-specific tithis are handled separately; general shubha tithis here
    allowedTithis: [1, 2, 4, 6, 7, 9, 10, 11, 12, 13],
    // Sthira nakshatras preferred
    allowedNakshatras: [3, 4, 11, 12, 13, 14, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: [1, 4, 7, 10],
  ),

  // ── ಅಕ್ಷರಾಭ್ಯಾಸ (Starting Education) ──
  MuhurtaEvent.aksharabhyasa: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 9, 10],
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 14, 20, 21, 22, 25, 26],
    allowedVaras: [3, 4], // Wed, Thu (Mercury + Jupiter days)
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: [2, 5, 8],
  ),

  // ── ಯಾತ್ರಾ (Travel) ──
  MuhurtaEvent.yatra: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 4, 7, 12, 16, 21, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    allowedLagnas: [0, 3, 6, 9], // Chara rashis
  ),

  // ── ವ್ಯಾಪಾರ (Business Start) ──
  MuhurtaEvent.vyapara: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 12],
    allowedNakshatras: [0, 3, 6, 7, 11, 12, 13, 14, 16, 21, 22, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: [2, 5, 6, 8, 10],
  ),

  // ── ಅನ್ನಪ್ರಾಶನ (First Feeding) ──
  MuhurtaEvent.annaprashana: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 14, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
  ),

  // ── ನಾಮಕರಣ (Naming Ceremony) ──
  MuhurtaEvent.namakarana: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 14, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
  ),

  // ── ಸೀಮಂತ (Prenatal Rite) ──
  MuhurtaEvent.seemanta: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [3, 4, 11, 13, 16, 20, 25, 26], // Mridu + Sthira
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
  ),

  // ── ಚೌಲ (Tonsure) ──
  MuhurtaEvent.chowla: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 4, 6, 7, 12, 13, 14, 21, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
  ),

  // ── ವಾಸ್ತು ಶಿಲಾನ್ಯಾಸ (Foundation Laying) ──
  MuhurtaEvent.vastuShilanyas: MuhurtaEventRules(
    allowedTithis: [1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [0, 3, 4, 6, 7, 11, 12, 13, 14, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    requireShukla: true,
    allowedLagnas: [1, 4, 7, 10],
  ),

  // ── ಔಷಧ (Medical Treatment) ──
  MuhurtaEvent.aushadha: MuhurtaEventRules(
    // Avoid Rikta tithis (3,8,13 = Chaturthi, Navami, Chaturdashi)
    allowedTithis: [0, 1, 2, 4, 5, 6, 9, 10, 11, 12, 14,
                    15, 16, 17, 19, 20, 21, 24, 25, 26, 29],
    allowedNakshatras: [0, 3, 4, 7, 12, 16, 21, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    allowedLagnas: [2, 5, 8, 11],
  ),

  // ── ಕೃಷಿ (Agriculture) ──
  MuhurtaEvent.krishi: MuhurtaEventRules(
    allowedTithis: [0, 1, 2, 4, 6, 9, 10, 11, 12],
    allowedNakshatras: [3, 4, 11, 12, 13, 14, 16, 20, 21, 25, 26],
    allowedVaras: [1, 3, 4, 5],
    avoidVishti: true,
    allowedLagnas: [1, 3, 5, 11], // Earth/Water signs
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
/// Jupiter's transit rashi counted from birth rashi. Good in 2,5,7,9,11.
bool calculateGuruBala(int janmaRashiIdx, int jupiterRashiIdx) {
  final count = ((jupiterRashiIdx - janmaRashiIdx + 12) % 12) + 1; // 1-indexed
  return const [2, 5, 7, 9, 11].contains(count);
}


// ============================================================
// LAGNA WINDOW — time windows for each rashi lagna
// ============================================================

class LagnaWindow {
  final int rashiIndex;    // 0-11
  final String rashiName;  // e.g. 'ಮೇಷ'
  final String startTime;  // e.g. '06:30 AM'
  final String endTime;    // e.g. '08:45 AM'
  final bool isAllowed;    // true if this lagna is allowed for the event

  LagnaWindow({
    required this.rashiIndex,
    required this.rashiName,
    required this.startTime,
    required this.endTime,
    required this.isAllowed,
  });
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
  final bool guruBala;

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

  MuhurtaDayResult({
    required this.score,
    required this.verdict,
    required this.checks,
    required this.personResults,
    required this.doshas,
    required this.doshaBhangas,
    this.lagnaWindows = const [],
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
  // Person 1
  required int janmaNakIdx1,
  required int janmaRashiIdx1,
  // Person 2 (optional)
  int? janmaNakIdx2,
  int? janmaRashiIdx2,
}) {
  final rules = muhurtaRules[event]!;
  final List<MuhurtaCheckItem> checks = [];
  final List<String> doshas = [];
  final List<String> doshaBhangas = [];
  int totalPoints = 0;
  int maxPoints = 0;

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
  if (amritaList != null && amritaList.contains(nakshatraIndex)) {
    hasAmritaSiddhi = true;
    if (!nakPassed) {
      nakPassed = true;
      doshaBhangas.add('ಅಮೃತ ಸಿದ್ಧಿ ಯೋಗ — ನಕ್ಷತ್ರ ದೋಷ ಭಂಗ');
    }
  }
  if (nakPassed) totalPoints += 15;
  checks.add(MuhurtaCheckItem(
    label: 'ನಕ್ಷತ್ರ',
    value: nakshatraName,
    passed: nakPassed,
    note: hasAmritaSiddhi ? 'ಅಮೃತ ಸಿದ್ಧಿ ಯೋಗ' : null,
  ));

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
  if (guru1) totalPoints += 10;

  checks.add(MuhurtaCheckItem(label: 'ತಾರಾ ಬಲ', value: tara1.taraName, passed: tara1Passed));
  checks.add(MuhurtaCheckItem(label: 'ಚಂದ್ರ ಬಲ', value: chandra1 ? '✓' : '✗', passed: chandra1));
  checks.add(MuhurtaCheckItem(label: 'ಗುರು ಬಲ', value: guru1 ? '✓' : '✗', passed: guru1));

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
    if (guru2) totalPoints += 10;

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
  }

  // ── COMPUTE FINAL SCORE ──
  final score = maxPoints > 0 ? ((totalPoints / maxPoints) * 100).round().clamp(0, 100) : 0;

  // Hard penalty for Dagdha — cap at 30
  final finalScore = hasDagdha ? score.clamp(0, 30) : score;

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
  );
}
