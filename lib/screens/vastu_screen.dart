import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';

// ─── English names (constant, language-independent) ───
const List<String> _yoniEnglish = [
  'Dhwaja (Flag)', 'Dhumra (Smoke)', 'Simha (Lion)', 'Shwana (Dog)',
  'Vrushabha (Bull)', 'Vira (Hero)', 'Gaja (Elephant)', 'Vaayasa (Crow)',
];

const List<String> _taraEnglish = [
  'Janma', 'Sampat', 'Vipat', 'Kshema',
  'Pratyak', 'Sadhana', 'Naidhana', 'Mitra', 'Parama Mitra',
];

const Set<int> _goodYoni = {0, 2, 4, 6};
const Set<int> _goodTara = {1, 3, 5, 7, 8};

// ─── Kolu/Hasta types (1 angula = 3 cm) ───
class _KoluType {
  final String id;
  final int angula;
  _KoluType(this.id, this.angula);
  double get cm => angula * 3.0;
  double get feetPerHasta => cm / 30.48;
}

final List<_KoluType> _koluTypes = [
  _KoluType('kishku', 24),
  _KoluType('prajapatya', 25),
  _KoluType('dhanurmushti', 26),
  _KoluType('dhanugraha', 27),
  _KoluType('prachya', 28),
  _KoluType('vaideha', 29),
  _KoluType('vaipulya', 30),
  _KoluType('prakeerna', 31),
];

/// Format total inches as  30′ 10″
String _fmtFtIn(int totalInches) {
  final ft = totalInches ~/ 12;
  final inches = totalInches % 12;
  if (inches == 0) return '$ft′';
  return '$ft′ $inches″';
}

/// Format area (sq inches) as sq ft string
String _fmtSqFt(int sqInches) {
  final sqft = sqInches / 144.0;
  if (sqft == sqft.roundToDouble()) return '${sqft.toInt()}';
  return sqft.toStringAsFixed(1);
}



// ─── Vastu-specific translations (self-contained, all 5 languages) ───
const Map<String, Map<String, String>> _vastuStrings = {
  'kn': {
    'title': 'ವಾಸ್ತು ಅಳತೆಗಳು', 'sub': '',
    'ownerNak': 'ಯಜಮಾನನ ನಕ್ಷತ್ರ', 'selectNak': 'ನಕ್ಷತ್ರ ಆಯ್ಕೆ ಮಾಡಿ',
    'length': 'ಉದ್ದ (ಅಡಿ)', 'breadth': 'ಅಗಲ (ಅಡಿ)', 'area': 'ವಿಸ್ತೀರ್ಣ (ಚ.ಅಡಿ)',
    'tabLB': 'ಉದ್ದ × ಅಗಲ', 'tabSqft': 'ವಿಸ್ತೀರ್ಣ (ಚ.ಅಡಿ)',
    'search': 'ಹುಡುಕಿ', 'goodOnly': 'ಶುಭ ಫಲಿತಾಂಶ ಮಾತ್ರ',
    'allResults': 'ಎಲ್ಲಾ ಫಲಿತಾಂಶ', 'noResults': 'ಯಾವುದೇ ಶುಭ ಫಲಿತಾಂಶ ಸಿಗಲಿಲ್ಲ',
    'hint': 'ವಿವರ ನಮೂದಿಸಿ ಮತ್ತು ಹುಡುಕಿ', 'hintEn': '',
    'sqftHint': 'ಪ್ರತಿ ಚ.ಅಡಿಗೆ ಸಾಧ್ಯವಿರುವ ಉದ್ದ × ಅಗಲ ಜೋಡಿಗಳನ್ನು ಹುಡುಕುತ್ತೇವೆ (ಕನಿಷ್ಟ ಬದಿ: 5 ಅಡಿ)',
    'formula': 'ಶಾಸ್ತ್ರ ಸೂತ್ರ:',
    'peridhi': 'ಪರಿಧಿ', 'hasta': 'ಹಸ್ತ',
    'aaya': 'ಆದಾಯ', 'vyaya': 'ವ್ಯಯ',
    'buildingNak': 'ಕಟ್ಟಡದ ನಕ್ಷತ್ರ', 'tarabala': 'ತಾರಾಬಲ',
    'shubha': 'ಶುಭ', 'aayaGt': 'ಆಯ > ವ್ಯಯ ✓', 'aayaLe': 'ಆಯ ≤ ವ್ಯಯ ✗',
    'selectNakErr': 'ಯಜಮಾನನ ನಕ್ಷತ್ರ ಆಯ್ಕೆ ಮಾಡಿ',
    'yoni': 'ಯೋನಿ', 'tithi': 'ತಿಥಿ', 'vaara': 'ವಾರ',
    'adi': 'ಅಡಿ', 'sqAdi': 'ಚ.ಅಡಿ', 'all': 'ಎಲ್ಲಾ',
    'minLabel': 'ಕನಿಷ್ಠ', 'maxLabel': 'ಗರಿಷ್ಠ',
    'fromLabel': 'ಇಂದ', 'toLabel': 'ವರೆಗೆ',
    'errMinMax': 'ಕನಿಷ್ಠ ≤ ಗರಿಷ್ಠ ಇರಬೇಕು',
    'errRange': 'ವ್ಯಾಪ್ತಿ ತುಂಬಾ ದೊಡ್ಡದು, ಕಡಿಮೆ ಮಾಡಿ',
    'errMaxSqft': 'ಗರಿಷ್ಠ 5000 ಚ.ಅಡಿ',
    'koluType': 'ಕೋಲು ಪ್ರಕಾರ', 'angula': 'ಅಂಗುಲ', 'custom': 'ಕಸ್ಟಮ್', 'koluName': 'ಕೋಲು ಹೆಸರು',
    'kishku': 'ಕಿಷ್ಕು', 'prajapatya': 'ಪ್ರಾಜಾಪತ್ಯ', 'dhanurmushti': 'ಧನುರ್ಮುಷ್ಟಿ', 'dhanugraha': 'ಧನುರ್ಗ್ರಹ',
    'prachya': 'ಪ್ರಾಚ್ಯ', 'vaideha': 'ವೈದೇಹ', 'vaipulya': 'ವೈಪುಲ್ಯ', 'prakeerna': 'ಪ್ರಕೀರ್ಣ',
    'vayassu': 'ವಯಸ್ಸು', 'v0': 'ಬಾಲ', 'v1': 'ಕೌಮಾರ', 'v2': 'ಯೌವನ', 'v3': 'ಮಧ್ಯರ್ಕ', 'v4': 'ನಿಧನ',
    'vaara0': 'ಆದಿತ್ಯ', 'vaara1': 'ಸೋಮ', 'vaara2': 'ಮಂಗಳ', 'vaara3': 'ಬುಧ', 'vaara4': 'ಗುರು', 'vaara5': 'ಶುಕ್ರ', 'vaara6': 'ಶನಿ',
    'a1': 'ಧ್ವಜ', 'a2': 'ಧೂಮ್ರ', 'a3': 'ಸಿಂಹ', 'a4': 'ಶ್ವಾನ', 'a5': 'ವೃಷಭ', 'a6': 'ವೀರ', 'a7': 'ಗಜ', 'a8': 'ವಾಯಸ',
    't1': 'ಜನ್ಮ ತಾರೆ', 't2': 'ಸಂಪತ್ ತಾರೆ', 't3': 'ವಿಪತ್ ತಾರೆ', 't4': 'ಕ್ಷೇಮ ತಾರೆ',
    't5': 'ಪ್ರತ್ಯಕ್ ತಾರೆ', 't6': 'ಸಾಧನ ತಾರೆ', 't7': 'ನೈಧನ ತಾರೆ', 't8': 'ಮಿತ್ರ ತಾರೆ', 't9': 'ಪರಮ ಮಿತ್ರ ತಾರೆ',
    'q1': 'ಸಾಮಾನ್ಯ', 'q2': 'ಅತಿ ಉತ್ತಮ', 'q3': 'ಕೆಟ್ಟದು', 'q4': 'ಉತ್ತಮ',
  },
  'hi': {
    'title': 'वास्तु मापन', 'sub': 'Vastu Measurements',
    'ownerNak': 'मकान मालिक का नक्षत्र (Owner\'s Nakshatra)', 'selectNak': 'नक्षत्र चुनें',
    'length': 'लम्बाई / Length (Feet)', 'breadth': 'चौड़ाई / Breadth (Feet)', 'area': 'क्षेत्रफल / Area (Sq Ft)',
    'tabLB': 'लम्बाई × चौड़ाई (L × B)', 'tabSqft': 'क्षेत्रफल (Sq Ft)',
    'search': 'खोजें (Search)', 'goodOnly': 'शुभ परिणाम (Good only)',
    'allResults': 'सभी परिणाम (All)', 'noResults': 'कोई शुभ परिणाम नहीं मिला',
    'hint': 'विवरण दर्ज करें और खोजें', 'hintEn': 'Enter details and search',
    'sqftHint': 'प्रत्येक Sq Ft के लिए संभव लम्बाई × चौड़ाई जोड़ियां खोजी जाएंगी (min side: 5 ft)',
    'formula': 'शास्त्र सूत्र (Shastra Formula):',
    'peridhi': 'परिधि', 'hasta': 'हस्त',
    'aaya': 'आय', 'vyaya': 'व्यय',
    'buildingNak': 'भवन नक्षत्र', 'tarabala': 'ताराबल',
    'shubha': 'शुभ', 'aayaGt': 'आय > व्यय ✓', 'aayaLe': 'आय ≤ व्यय ✗',
    'selectNakErr': 'मकान मालिक का नक्षत्र चुनें',
    'yoni': 'योनि', 'tithi': 'तिथि', 'vaara': 'वार',
    'adi': 'फीट', 'sqAdi': 'वर्ग.फीट', 'all': 'सभी',
    'minLabel': 'न्यूनतम', 'maxLabel': 'अधिकतम',
    'fromLabel': 'से', 'toLabel': 'तक',
    'errMinMax': 'न्यूनतम ≤ अधिकतम होना चाहिए',
    'errRange': 'रेंज बहुत बड़ी है, कम करें',
    'errMaxSqft': 'अधिकतम 5000 वर्ग.फीट',
    'koluType': 'कोलु प्रकार', 'angula': 'अंगुल', 'custom': 'कस्टम', 'koluName': 'कोलु नाम',
    'kishku': 'किष्कु', 'prajapatya': 'प्राजापत्य', 'dhanurmushti': 'धनुर्मुष्टि', 'dhanugraha': 'धनुर्ग्रह',
    'prachya': 'प्राच्य', 'vaideha': 'वैदेह', 'vaipulya': 'वैपुल्य', 'prakeerna': 'प्रकीर्ण',
    'vayassu': 'वयस्सु', 'v0': 'बाल', 'v1': 'कौमार', 'v2': 'यौवन', 'v3': 'मध्यर्क', 'v4': 'निधन',
    'vaara0': 'रवि', 'vaara1': 'सोम', 'vaara2': 'मंगल', 'vaara3': 'बुध', 'vaara4': 'गुरु', 'vaara5': 'शुक्र', 'vaara6': 'शनि',
    'a1': 'ध्वज', 'a2': 'धूम्र', 'a3': 'सिंह', 'a4': 'श्वान', 'a5': 'वृषभ', 'a6': 'खर', 'a7': 'गज', 'a8': 'ध्वांक्ष',
    't1': 'जन्म तारा', 't2': 'सम्पत् तारा', 't3': 'विपत् तारा', 't4': 'क्षेम तारा',
    't5': 'प्रत्यक् तारा', 't6': 'साधन तारा', 't7': 'नैधन तारा', 't8': 'मित्र तारा', 't9': 'परम मित्र तारा',
    'q1': 'सामान्य', 'q2': 'अति उत्तम', 'q3': 'बुरा', 'q4': 'उत्तम',
  },
  'ta': {
    'title': 'வாஸ்து அளவீடுகள்', 'sub': 'Vastu Measurements',
    'ownerNak': 'உரிமையாளர் நக்ஷத்திரம் (Owner\'s Nakshatra)', 'selectNak': 'நக்ஷத்திரம் தேர்வு',
    'length': 'நீளம் / Length (Feet)', 'breadth': 'அகலம் / Breadth (Feet)', 'area': 'பரப்பளவு / Area (Sq Ft)',
    'tabLB': 'நீளம் × அகலம் (L × B)', 'tabSqft': 'பரப்பளவு (Sq Ft)',
    'search': 'தேடு (Search)', 'goodOnly': 'நல்ல முடிவுகள் (Good only)',
    'allResults': 'அனைத்து முடிவுகள் (All)', 'noResults': 'நல்ல முடிவுகள் இல்லை',
    'hint': 'விவரங்களை உள்ளிட்டு தேடுங்கள்', 'hintEn': 'Enter details and search',
    'sqftHint': 'ஒவ்வொரு Sq Ft க்கும் சாத்தியமான நீளம் × அகலம் ஜோடிகள் (min side: 5 ft)',
    'formula': 'சாஸ்திர சூத்திரம் (Shastra Formula):',
    'peridhi': 'சுற்றளவு', 'hasta': 'ஹஸ்தம்',
    'aaya': 'ஆயம்', 'vyaya': 'வியயம்',
    'buildingNak': 'கட்டிட நக்ஷத்திரம்', 'tarabala': 'தாராபலம்',
    'shubha': 'சுபம்', 'aayaGt': 'ஆயம் > வியயம் ✓', 'aayaLe': 'ஆயம் ≤ வியயம் ✗',
    'selectNakErr': 'உரிமையாளர் நக்ஷத்திரம் தேர்வு செய்யவும்',
    'yoni': 'யோனி', 'tithi': 'திதி', 'vaara': 'வாரம்',
    'adi': 'அடி', 'sqAdi': 'ச.அடி', 'all': 'அனைத்தும்',
    'minLabel': 'குறைந்தபட்சம்', 'maxLabel': 'அதிகபட்சம்',
    'fromLabel': 'இருந்து', 'toLabel': 'வரை',
    'errMinMax': 'குறைந்தபட்சம் ≤ அதிகபட்சம்',
    'errRange': 'வரம்பு மிகப் பெரியது',
    'errMaxSqft': 'அதிகபட்சம் 5000 ச.அடி',
    'koluType': 'கோலு வகை', 'angula': 'அங்குலம்', 'custom': 'கஸ்டம்', 'koluName': 'கோலு பெயர்',
    'kishku': 'கிஷ்கு', 'prajapatya': 'ப்ராஜாபத்ய', 'dhanurmushti': 'தனுர்முஷ்டி', 'dhanugraha': 'தனுர்க்ரஹ',
    'prachya': 'ப்ராச்ய', 'vaideha': 'வைதேஹ', 'vaipulya': 'வைபுல்ய', 'prakeerna': 'ப்ரகீர்ண',
    'vayassu': 'வயஸ்ஸு', 'v0': 'பால', 'v1': 'கௌமார', 'v2': 'யௌவன', 'v3': 'மத்யர்க', 'v4': 'நிதன',
    'vaara0': 'ஞாயிறு', 'vaara1': 'திங்கள்', 'vaara2': 'செவ்வாய்', 'vaara3': 'புதன்', 'vaara4': 'வியாழன்', 'vaara5': 'வெள்ளி', 'vaara6': 'சனி',
    'a1': 'த்வஜம்', 'a2': 'தூம்ரம்', 'a3': 'சிம்மம்', 'a4': 'ச்வானம்', 'a5': 'விருஷபம்', 'a6': 'கரம்', 'a7': 'கஜம்', 'a8': 'த்வாங்க்ஷம்',
    't1': 'ஜன்ம தாரை', 't2': 'சம்பத் தாரை', 't3': 'விபத் தாரை', 't4': 'க்ஷேம தாரை',
    't5': 'ப்ரத்யக் தாரை', 't6': 'சாதன தாரை', 't7': 'நைதன தாரை', 't8': 'மித்ர தாரை', 't9': 'பரம மித்ர தாரை',
    'q1': 'சாதாரணம்', 'q2': 'மிக நல்லது', 'q3': 'கெட்டது', 'q4': 'நல்லது',
  },
  'te': {
    'title': 'వాస్తు కొలతలు', 'sub': 'Vastu Measurements',
    'ownerNak': 'యజమాని నక్షత్రం (Owner\'s Nakshatra)', 'selectNak': 'నక్షత్రం ఎంచుకోండి',
    'length': 'పొడవు / Length (Feet)', 'breadth': 'వెడల్పు / Breadth (Feet)', 'area': 'వైశాల్యం / Area (Sq Ft)',
    'tabLB': 'పొడవు × వెడల్పు (L × B)', 'tabSqft': 'వైశాల్యం (Sq Ft)',
    'search': 'వెతుకు (Search)', 'goodOnly': 'శుభ ఫలితాలు (Good only)',
    'allResults': 'అన్ని ఫలితాలు (All)', 'noResults': 'శుభ ఫలితాలు దొరకలేదు',
    'hint': 'వివరాలు నమోదు చేసి వెతకండి', 'hintEn': 'Enter details and search',
    'sqftHint': 'ప్రతి Sq Ft కి సాధ్యమైన పొడవు × వెడల్పు జతలు వెతకబడతాయి (min side: 5 ft)',
    'formula': 'శాస్త్ర సూత్రం (Shastra Formula):',
    'peridhi': 'చుట్టుకొలత', 'hasta': 'హస్తం',
    'aaya': 'ఆయం', 'vyaya': 'వ్యయం',
    'buildingNak': 'భవన నక్షత్రం', 'tarabala': 'తారాబలం',
    'shubha': 'శుభం', 'aayaGt': 'ఆయం > వ్యయం ✓', 'aayaLe': 'ఆయం ≤ వ్యయం ✗',
    'selectNakErr': 'యజమాని నక్షత్రం ఎంచుకోండి',
    'yoni': 'యోని', 'tithi': 'తిథి', 'vaara': 'వారం',
    'adi': 'అడి', 'sqAdi': 'చ.అడి', 'all': 'అన్నీ',
    'minLabel': 'కనిష్ఠం', 'maxLabel': 'గరిష్ఠం',
    'fromLabel': 'నుండి', 'toLabel': 'వరకు',
    'errMinMax': 'కనిష్ఠం ≤ గరిష్ఠం ఉండాలి',
    'errRange': 'పరిధి చాలా పెద్దది',
    'errMaxSqft': 'గరిష్ఠం 5000 చ.అడి',
    'koluType': 'కోలు రకం', 'angula': 'అంగుళం', 'custom': 'కస్టమ్', 'koluName': 'కోలు పేరు',
    'kishku': 'కిష్కు', 'prajapatya': 'ప్రాజాపత్య', 'dhanurmushti': 'ధనుర్ముష్టి', 'dhanugraha': 'ధనుర్గ్రహ',
    'prachya': 'ప్రాచ్య', 'vaideha': 'వైదేహ', 'vaipulya': 'వైపుల్య', 'prakeerna': 'ప్రకీర్ణ',
    'vayassu': 'వయస్సు', 'v0': 'బాల', 'v1': 'కౌమార', 'v2': 'యౌవన', 'v3': 'మధ్యర్క', 'v4': 'నిధన',
    'vaara0': 'ఆదిత్య', 'vaara1': 'సోమ', 'vaara2': 'మంగళ', 'vaara3': 'బుధ', 'vaara4': 'గురు', 'vaara5': 'శుక్ర', 'vaara6': 'శని',
    'a1': 'ధ్వజం', 'a2': 'ధూమ్రం', 'a3': 'సింహం', 'a4': 'శ్వానం', 'a5': 'వృషభం', 'a6': 'ఖరం', 'a7': 'గజం', 'a8': 'ధ్వాంక్షం',
    't1': 'జన్మ తార', 't2': 'సంపత్ తార', 't3': 'విపత్ తార', 't4': 'క్షేమ తార',
    't5': 'ప్రత్యక్ తార', 't6': 'సాధన తార', 't7': 'నైధన తార', 't8': 'మిత్ర తార', 't9': 'పరమ మిత్ర తార',
    'q1': 'సాధారణం', 'q2': 'అతి ఉత్తమం', 'q3': 'చెడ్డది', 'q4': 'ఉత్తమం',
  },
  'ml': {
    'title': 'വാസ്തു അളവുകൾ', 'sub': 'Vastu Measurements',
    'ownerNak': 'ഉടമയുടെ നക്ഷത്രം (Owner\'s Nakshatra)', 'selectNak': 'നക്ഷത്രം തിരഞ്ഞെടുക്കുക',
    'length': 'നീളം / Length (Feet)', 'breadth': 'വീതി / Breadth (Feet)', 'area': 'വിസ്തീർണ്ണം / Area (Sq Ft)',
    'tabLB': 'നീളം × വീതി (L × B)', 'tabSqft': 'വിസ്തീർണ്ണം (Sq Ft)',
    'search': 'തിരയുക (Search)', 'goodOnly': 'ശുഭ ഫലങ്ങൾ (Good only)',
    'allResults': 'എല്ലാ ഫലങ്ങളും (All)', 'noResults': 'ശുഭ ഫലങ്ങൾ കണ്ടെത്തിയില്ല',
    'hint': 'വിവരങ്ങൾ നൽകി തിരയുക', 'hintEn': 'Enter details and search',
    'sqftHint': 'ഓരോ Sq Ft നും സാധ്യമായ നീളം × വീതി ജോഡികൾ (min side: 5 ft)',
    'formula': 'ശാസ്ത്ര സൂത്രം (Shastra Formula):',
    'peridhi': 'ചുറ്റളവ്', 'hasta': 'ഹസ്തം',
    'aaya': 'ആയം', 'vyaya': 'വ്യയം',
    'buildingNak': 'കെട്ടിട നക്ഷത്രം', 'tarabala': 'താരാബലം',
    'shubha': 'ശുഭം', 'aayaGt': 'ആയം > വ്യയം ✓', 'aayaLe': 'ആയം ≤ വ്യയം ✗',
    'selectNakErr': 'ഉടമയുടെ നക്ഷത്രം തിരഞ്ഞെടുക്കുക',
    'yoni': 'യോനി', 'tithi': 'തിഥി', 'vaara': 'വാരം',
    'adi': 'അടി', 'sqAdi': 'ച.അടി', 'all': 'എല്ലാം',
    'minLabel': 'കുറഞ്ഞത്', 'maxLabel': 'കൂടിയത്',
    'fromLabel': 'മുതൽ', 'toLabel': 'വരെ',
    'errMinMax': 'കുറഞ്ഞത് ≤ കൂടിയത് ആയിരിക്കണം',
    'errRange': 'പരിധി വളരെ വലുതാണ്',
    'errMaxSqft': 'കൂടിയത് 5000 ച.അടി',
    'koluType': 'കോലു തരം', 'angula': 'അംഗുലം', 'custom': 'കസ്റ്റം', 'koluName': 'കോലു പേര്',
    'kishku': 'കിഷ്കു', 'prajapatya': 'പ്രാജാപത്യ', 'dhanurmushti': 'ധനുർമുഷ്ടി', 'dhanugraha': 'ധനുർഗ്രഹ',
    'prachya': 'പ്രാച്യ', 'vaideha': 'വൈദേഹ', 'vaipulya': 'വൈപുല്യ', 'prakeerna': 'പ്രകീർണ',
    'vayassu': 'വയസ്സ്', 'v0': 'ബാല', 'v1': 'കൗമാര', 'v2': 'യൗവന', 'v3': 'മധ്യർക', 'v4': 'നിധന',
    'vaara0': 'ഞായർ', 'vaara1': 'തിങ്കൾ', 'vaara2': 'ചൊവ്വ', 'vaara3': 'ബുധൻ', 'vaara4': 'വ്യാഴം', 'vaara5': 'വെള്ളി', 'vaara6': 'ശനി',
    'a1': 'ധ്വജം', 'a2': 'ധൂമ്രം', 'a3': 'സിംഹം', 'a4': 'ശ്വാനം', 'a5': 'വൃഷഭം', 'a6': 'ഖരം', 'a7': 'ഗജം', 'a8': 'ധ്വാങ്ക്ഷം',
    't1': 'ജന്മ താര', 't2': 'സമ്പത്ത് താര', 't3': 'വിപത്ത് താര', 't4': 'ക്ഷേമ താര',
    't5': 'പ്രത്യക് താര', 't6': 'സാധന താര', 't7': 'നൈധന താര', 't8': 'മിത്ര താര', 't9': 'പരമ മിത്ര താര',
    'q1': 'സാധാരണം', 'q2': 'അതി ഉത്തമം', 'q3': 'ചീത്ത', 'q4': 'ഉത്തമം',
  },
};

String _v(String key) {
  final lang = AppLocale.current;
  return _vastuStrings[lang]?[key] ?? _vastuStrings['kn']?[key] ?? key;
}

List<String> get _yoniNames => [_v('a1'), _v('a2'), _v('a3'), _v('a4'), _v('a5'), _v('a6'), _v('a7'), _v('a8')];
List<String> get _taraNames => [_v('t1'), _v('t2'), _v('t3'), _v('t4'), _v('t5'), _v('t6'), _v('t7'), _v('t8'), _v('t9')];
List<String> get _taraQuality => [_v('q1'), _v('q2'), _v('q3'), _v('q4'), _v('q3'), _v('q4'), _v('q3'), _v('q4'), _v('q2')];

// ─── Shared result model (hasta-first approach) ───
class _VastuResult {
  final int hasta;          // exact whole-number hasta
  final double perimeterCm; // hasta × koluCm
  final double sumCm;       // L + B in cm = perimeterCm / 2
  // Valid length/breadth range in cm
  final double minLenCm;
  final double maxLenCm;
  final double minBreCm;
  final double maxBreCm;
  final int yoniIndex;
  final int yoniValue;
  final int aadaayaValue;
  final int vyayaValue;
  final bool aadaayaGtVyaya;
  final int nakIndex;
  final int taraIndex;
  final int tithiValue;
  final int vaaraValue;
  final int vayassuIndex;

  _VastuResult({
    required this.hasta, required this.perimeterCm, required this.sumCm,
    required this.minLenCm, required this.maxLenCm,
    required this.minBreCm, required this.maxBreCm,
    required this.yoniIndex, required this.yoniValue,
    required this.aadaayaValue,
    required this.vyayaValue, required this.aadaayaGtVyaya,
    required this.nakIndex, required this.taraIndex,
    required this.tithiValue, required this.vaaraValue,
    required this.vayassuIndex,
  });

  bool get isGoodYoni => _goodYoni.contains(yoniIndex);
  bool get isGoodTara => _goodTara.contains(taraIndex);
  bool get isGoodVayassu => vayassuIndex != 4; // nidhana is not good
  bool get isExcellent => isGoodYoni && isGoodTara && aadaayaGtVyaya && isGoodVayassu;
}

// ─── Calculation from integer hasta ───
_VastuResult _calcFromHasta(int hasta, double koluCm, int ownerNak,
    double minLenCm, double maxLenCm, double minBreCm, double maxBreCm) {
  final perimeterCm = hasta * koluCm;
  final sumCm = perimeterCm / 2; // L + B

  // Valid L range: L ∈ [minLen, maxLen] and B = sumCm - L ∈ [minBre, maxBre]
  final lMin = max(minLenCm, sumCm - maxBreCm);
  final lMax = min(maxLenCm, sumCm - minBreCm);
  final bMin = sumCm - lMax;
  final bMax = sumCm - lMin;

  // Shastra formulas — directly on integer hasta (no floor needed)
  final yoniRem = (hasta * 3) % 8;
  final yoniValue = yoniRem == 0 ? 8 : yoniRem;
  final yoniIndex = yoniValue - 1;

  final aadaayaRem = (hasta * 8) % 12;
  final aadaayaValue = aadaayaRem == 0 ? 12 : aadaayaRem;

  final vyayaRem = (hasta * 3) % 14;
  final vyayaValue = vyayaRem == 0 ? 14 : vyayaRem;

  final nakRem = (hasta * 8) % 27;
  final nakValue = nakRem == 0 ? 27 : nakRem;
  final nakIndex = nakValue - 1;

  final tithiRem = (hasta * 8) % 30;
  final tithiValue = tithiRem == 0 ? 30 : tithiRem;

  final vaaraRem = (hasta * 8) % 7;
  final vaaraValue = vaaraRem == 0 ? 7 : vaaraRem;

  final vayassuQuotient = (hasta * 8) ~/ 27;
  final vayassuRem = vayassuQuotient % 5;
  final vayassuIndex = vayassuRem == 0 ? 4 : vayassuRem - 1;

  final diff = (nakIndex - ownerNak + 27) % 27;
  final taraIndex = diff % 9;

  return _VastuResult(
    hasta: hasta, perimeterCm: perimeterCm, sumCm: sumCm,
    minLenCm: lMin, maxLenCm: lMax,
    minBreCm: bMin, maxBreCm: bMax,
    yoniIndex: yoniIndex, yoniValue: yoniValue,
    aadaayaValue: aadaayaValue,
    vyayaValue: vyayaValue, aadaayaGtVyaya: aadaayaValue > vyayaValue,
    nakIndex: nakIndex, taraIndex: taraIndex,
    tithiValue: tithiValue, vaaraValue: vaaraValue,
    vayassuIndex: vayassuIndex,
  );
}

/// Format cm to feet′ inches″
String _cmToFtIn(double cm) {
  final totalInches = (cm / 2.54).round();
  final ft = totalInches ~/ 12;
  final inches = totalInches % 12;
  if (inches == 0) return '$ft′';
  return '$ft′ $inches″';
}

/// Format cm as readable string
String _fmtCm(double cm) {
  if (cm == cm.roundToDouble()) return '${cm.toInt()} cm';
  return '${cm.toStringAsFixed(1)} cm';
}

// ─── Find factor pairs for a given area (min side >= 5 ft) ───
List<List<int>> _factorPairs(int area, {int minSide = 5}) {
  final pairs = <List<int>>[];
  final limit = sqrt(area).floor();
  for (int i = minSide; i <= limit; i++) {
    if (area % i == 0) {
      final j = area ~/ i;
      if (j >= minSide) pairs.add([i, j]);
    }
  }
  return pairs;
}

// ═══════════════════════════════════════════
// MAIN SCREEN WITH TABS
// ═══════════════════════════════════════════

class VastuScreen extends StatefulWidget {
  const VastuScreen({super.key});

  @override
  State<VastuScreen> createState() => _VastuScreenState();
}

class _VastuScreenState extends State<VastuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int? _ownerNakIndex;
  int _koluIndex = 0; // default: Kishku (24 angula), -1 = custom
  final _customKoluNameCtrl = TextEditingController(text: '');
  final _customKoluCmCtrl = TextEditingController(text: '72');

  // Get effective kolu cm and display name
  double get _effectiveKoluCm {
    if (_koluIndex == -1) return double.tryParse(_customKoluCmCtrl.text) ?? 72;
    return _koluTypes[_koluIndex].cm;
  }
  String get _effectiveKoluName {
    if (_koluIndex == -1) return _customKoluNameCtrl.text.isNotEmpty ? _customKoluNameCtrl.text : _v('custom');
    return _v(_koluTypes[_koluIndex].id);
  }

  final _minLenCtrl = TextEditingController(text: '30');
  final _maxLenCtrl = TextEditingController(text: '40');
  final _minBreadthCtrl = TextEditingController(text: '40');
  final _maxBreadthCtrl = TextEditingController(text: '50');

  final _minSqftCtrl = TextEditingController(text: '1000');
  final _maxSqftCtrl = TextEditingController(text: '1200');

  List<_VastuResult> _results = [];
  bool _searched = false;
  bool _showOnlyGood = true;
  int? _selectedYoni; // null = all, 0-7 = specific yoni index

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() { _searched = false; _results = []; });
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _minLenCtrl.dispose();
    _maxLenCtrl.dispose();
    _minBreadthCtrl.dispose();
    _maxBreadthCtrl.dispose();
    _minSqftCtrl.dispose();
    _maxSqftCtrl.dispose();
    _customKoluNameCtrl.dispose();
    _customKoluCmCtrl.dispose();
    super.dispose();
  }

  bool _validateNak() {
    if (_ownerNakIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_v('selectNakErr')),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  /// Hasta-first L×B search: find valid whole-number hastas, then back-calculate L×B
  void _searchLB() {
    if (!_validateNak()) return;
    final minL = int.tryParse(_minLenCtrl.text) ?? 10;
    final maxL = int.tryParse(_maxLenCtrl.text) ?? 50;
    final minB = int.tryParse(_minBreadthCtrl.text) ?? 10;
    final maxB = int.tryParse(_maxBreadthCtrl.text) ?? 50;

    if (minL > maxL || minB > maxB) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_v('errMinMax')), backgroundColor: Colors.red),
      );
      return;
    }

    final koluCm = _effectiveKoluCm;
    // Convert feet to cm (1 foot = 30.48 cm)
    final minLenCm = minL * 30.48;
    final maxLenCm = maxL * 30.48;
    final minBreCm = minB * 30.48;
    final maxBreCm = maxB * 30.48;

    // Perimeter range in cm
    final minPerimCm = 2 * (minLenCm + minBreCm);
    final maxPerimCm = 2 * (maxLenCm + maxBreCm);

    // Valid whole-number hasta range
    final minHasta = (minPerimCm / koluCm).ceil();
    final maxHasta = (maxPerimCm / koluCm).floor();

    final results = <_VastuResult>[];
    for (int h = minHasta; h <= maxHasta; h++) {
      final sumCm = (h * koluCm) / 2;
      // Check if valid L×B exists within user's range
      final lMin = max(minLenCm, sumCm - maxBreCm);
      final lMax = min(maxLenCm, sumCm - minBreCm);
      if (lMin <= lMax) {
        results.add(_calcFromHasta(h, koluCm, _ownerNakIndex!,
            minLenCm, maxLenCm, minBreCm, maxBreCm));
      }
    }
    _sortAndSet(results);
  }

  void _searchSqft() {
    if (!_validateNak()) return;
    final minSq = int.tryParse(_minSqftCtrl.text) ?? 500;
    final maxSq = int.tryParse(_maxSqftCtrl.text) ?? 2000;

    if (minSq > maxSq) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_v('errMinMax')), backgroundColor: Colors.red),
      );
      return;
    }
    if (maxSq - minSq > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_v('errMaxSqft')), backgroundColor: Colors.red),
      );
      return;
    }

    final results = <_VastuResult>[];
    final koluCm = _effectiveKoluCm;
    final seen = <int>{};
    for (int sq = minSq; sq <= maxSq; sq++) {
      final pairs = _factorPairs(sq);
      if (pairs.isEmpty) continue;
      for (final pair in pairs) {
        // pair is in feet; calculate perimeter and hasta
        final perimCm = 2 * (pair[0] + pair[1]) * 30.48;
        final hastaExact = perimCm / koluCm;
        final hasta = hastaExact.round();
        if (seen.add(hasta)) {
          final lenCm = pair[1] * 30.48; // longer side
          final breCm = pair[0] * 30.48; // shorter side
          results.add(_calcFromHasta(hasta, koluCm, _ownerNakIndex!,
              breCm, lenCm, breCm, lenCm));
        }
      }
    }
    _sortAndSet(results);
  }

  void _sortAndSet(List<_VastuResult> results) {
    results.sort((a, b) {
      if (a.isExcellent && !b.isExcellent) return -1;
      if (!a.isExcellent && b.isExcellent) return 1;
      return a.hasta.compareTo(b.hasta);
    });
    setState(() { _results = results; _searched = true; });
  }

  List<_VastuResult> get _filteredResults {
    var list = _showOnlyGood ? _results.where((r) => r.isExcellent).toList() : _results;
    if (_selectedYoni != null) {
      list = list.where((r) => r.yoniIndex == _selectedYoni).toList();
    }
    return list;
  }

  Widget _yoniChip(int? yoniIdx, String label) {
    final selected = _selectedYoni == yoniIdx;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _selectedYoni = yoniIdx);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? kPurple2 : kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? kPurple2 : kBorder, width: 1.5),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : kText,
          )),
        ),
      ),
    );
  }

  Color _yoniColor(int i) => _goodYoni.contains(i) ? Colors.green : Colors.red;
  Color _vayassuColor(int i) => i == 2 ? Colors.green : (i == 1 || i == 3) ? Colors.orange : Colors.red;

  Color _taraColor(int i) => _goodTara.contains(i)
      ? (i == 1 || i == 8 ? Colors.green : Colors.teal)
      : (i == 0 ? Colors.orange : Colors.red);

  // ═══════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final naks = appNak;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_v('title'), style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w900)),
            Text(_v('sub'), style: TextStyle(color: kMuted, fontSize: 11)),
          ],
        ),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: _v('tabLB')),
            Tab(text: _v('tabSqft')),
          ],
          labelColor: kPurple2,
          unselectedLabelColor: kMuted,
          indicatorColor: kPurple2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Shared: Nakshatra dropdown ──
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_v('ownerNak'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _ownerNakIndex,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: _v('selectNak'),
                      hintStyle: TextStyle(color: kMuted, fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: List.generate(27, (i) => DropdownMenuItem(
                      value: i,
                      child: Text('${i + 1}. ${naks[i]}', style: TextStyle(fontSize: 14, color: kText)),
                    )),
                    onChanged: (v) => setState(() => _ownerNakIndex = v),
                  ),
                  const SizedBox(height: 12),
                  Text(_v('koluType'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _koluIndex,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      ...List.generate(_koluTypes.length, (i) {
                        final k = _koluTypes[i];
                        return DropdownMenuItem(
                          value: i,
                          child: Text(
                            '${_v(k.id)}  (${k.angula} ${_v('angula')} = ${k.cm.toInt()} cm)',
                            style: TextStyle(fontSize: 13, color: kText),
                          ),
                        );
                      }),
                      DropdownMenuItem(
                        value: -1,
                        child: Text('✏️ ${_v('custom')}', style: TextStyle(fontSize: 13, color: kOrange, fontWeight: FontWeight.w700)),
                      ),
                    ],
                    onChanged: (v) => setState(() { _koluIndex = v!; _searched = false; _results = []; }),
                  ),
                  if (_koluIndex == -1) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _customKoluNameCtrl,
                          decoration: InputDecoration(
                            labelText: _v('koluName'),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          style: TextStyle(fontSize: 13, color: kText),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _customKoluCmCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'cm',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          style: TextStyle(fontSize: 13, color: kText),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),

            // ── Tab content ──
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ListenableBuilder(
                      listenable: _tabCtrl,
                      builder: (context, _) {
                        return _tabCtrl.index == 0 ? _buildLBInputs() : _buildSqftInputs();
                      },
                    ),
                  ),

                  // Formula info
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPurple2.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kPurple2.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_v('formula'), style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800, color: kPurple2)),
                          const SizedBox(height: 4),
                          Text('• ${_v('peridhi')} (cm) = 2 × (${_v('length').split(' /')[0].split(' (')[0]} + ${_v('breadth').split(' /')[0].split(' (')[0]}) × 30.48',
                            style: TextStyle(fontSize: 10, color: kMuted)),
                          Text('• ${_v('hasta')} = ${_v('peridhi')} (cm) ÷ ${_effectiveKoluCm.toInt()}  (whole number only)',
                            style: TextStyle(fontSize: 10, color: kMuted)),
                          Text('• 1 foot = 30.48 cm  |  1 $_effectiveKoluName = ${_effectiveKoluCm.toInt()} cm',
                            style: TextStyle(fontSize: 10, color: kOrange, fontWeight: FontWeight.w700)),
                          Text('• ${_v('yoni')} = (${_v('hasta')} × 3) % 8',
                            style: TextStyle(fontSize: 10, color: kMuted)),
                          Text('• ${_v('aaya')} = (${_v('hasta')} × 8) % 12  |  ${_v('vyaya')} = (${_v('hasta')} × 3) % 14',
                            style: TextStyle(fontSize: 10, color: kMuted)),
                          Text('• ${AppLocale.l('nakshatra')} = (${_v('hasta')} × 8) % 27  |  ${_v('tithi')} = (${_v('hasta')} × 8) % 30',
                            style: TextStyle(fontSize: 10, color: kMuted)),
                          Text('• ${_v('vaara')} = (${_v('hasta')} × 8) % 7',
                            style: TextStyle(fontSize: 10, color: kMuted)),
                          Text('• ${_v('vayassu')} = ((${_v('hasta')} × 8) ÷ 27) % 5',
                            style: TextStyle(fontSize: 10, color: kMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Search button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _tabCtrl.index == 0 ? _searchLB : _searchSqft,
                          icon: const Icon(Icons.search, size: 20),
                          label: Text(_v('search'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPurple2,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // ── Filter toggle ──
                  if (_searched)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Icon(_showOnlyGood ? Icons.filter_alt : Icons.filter_alt_off,
                                size: 16, color: _showOnlyGood ? kGreen : kMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _showOnlyGood ? _v('goodOnly') : _v('allResults'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted),
                              ),
                            ),
                            Text('${_filteredResults.length}/${_results.length}',
                              style: TextStyle(fontSize: 12, color: kPurple2, fontWeight: FontWeight.w800)),
                            Switch(
                              value: _showOnlyGood,
                              activeColor: kGreen,
                              onChanged: (v) => setState(() => _showOnlyGood = v),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Yoni filter chips ──
                  if (_searched)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _yoniChip(null, _v('all')),
                              const SizedBox(width: 6),
                              ...List.generate(8, (i) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _yoniChip(i, _yoniNames[i]),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── Results ──
                  if (!_searched)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.home_work_rounded, size: 64, color: kPurple2.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(_v('hint'), style: TextStyle(color: kMuted, fontSize: 14)),
                            Text(_v('hintEn'), style: TextStyle(color: kMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  else if (_filteredResults.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.red.withOpacity(0.4)),
                            const SizedBox(height: 8),
                            Text(_v('noResults'), style: TextStyle(color: kMuted, fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildResultCard(_filteredResults[index]),
                        ),
                        childCount: _filteredResults.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1: L × B inputs ───
  Widget _buildLBInputs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_v('length'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _field(_minLenCtrl, _v('minLabel'))),
            _sep(),
            Expanded(child: _field(_maxLenCtrl, _v('maxLabel'))),
          ]),
          const SizedBox(height: 12),
          Text(_v('breadth'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _field(_minBreadthCtrl, _v('minLabel'))),
            _sep(),
            Expanded(child: _field(_maxBreadthCtrl, _v('maxLabel'))),
          ]),
        ],
      ),
    );
  }

  // ─── Tab 2: Sq Ft inputs ───
  Widget _buildSqftInputs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_v('area'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPurple2)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _field(_minSqftCtrl, _v('fromLabel'))),
            _sep(),
            Expanded(child: _field(_maxSqftCtrl, _v('toLabel'))),
          ]),
          const SizedBox(height: 8),
          Text(
            _v('sqftHint'),
            style: TextStyle(fontSize: 10, color: kMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kMuted, fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      style: TextStyle(fontSize: 14, color: kText),
    );
  }

  Widget _sep() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text('–', style: TextStyle(fontSize: 20, color: kMuted)),
  );

  // ─── Result card ───
  Widget _buildResultCard(_VastuResult r) {
    final naks = appNak;
    final isExcellent = r.isExcellent;
    final borderColor = isExcellent ? Colors.green.withOpacity(0.5) : kBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isExcellent ? 1.5 : 1),
        boxShadow: [
          if (isExcellent)
            BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: L × B with area and shubha badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isExcellent
                        ? [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]
                        : [kPurple2.withOpacity(0.1), kPurple2.withOpacity(0.03)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_cmToFtIn(r.minLenCm)} × ${_cmToFtIn(r.maxBreCm)}',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
                    color: isExcellent ? Colors.green.shade700 : kPurple2),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(r.minLenCm * r.maxBreCm / (30.48 * 30.48)).toStringAsFixed(1)} ${_v('sqAdi')}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
              const Spacer(),
              if (isExcellent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 3),
                    Text(_v('shubha'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Perimeter / Hasta
          Text('${_v('peridhi')}: ${_cmToFtIn(r.perimeterCm)} (${_fmtCm(r.perimeterCm)})  |  ${_v('hasta')}: ${r.hasta}  ($_effectiveKoluName)',
            style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          // Yoni
          Row(children: [
            Icon(Icons.flag_rounded, size: 14, color: _yoniColor(r.yoniIndex)),
            const SizedBox(width: 4),
            Text('${_v('yoni')}: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
            Flexible(child: Text(
              '${_yoniNames[r.yoniIndex]} [${r.yoniValue}]',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _yoniColor(r.yoniIndex)),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
          const SizedBox(height: 3),

          // Vayassu
          Row(children: [
            Icon(Icons.person, size: 14, color: _vayassuColor(r.vayassuIndex)),
            const SizedBox(width: 4),
            Text('${_v('vayassu')}: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
            Text(
              _v('v${r.vayassuIndex}'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _vayassuColor(r.vayassuIndex)),
            ),
          ]),
          const SizedBox(height: 3),

          // Aadaaya & Vyaya
          Row(children: [
            Icon(Icons.trending_up, size: 14, color: kMuted),
            const SizedBox(width: 4),
            Text('${_v('aaya')}: ${r.aadaayaValue}  |  ${_v('vyaya')}: ${r.vyayaValue}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: r.aadaayaGtVyaya ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                r.aadaayaGtVyaya ? _v('aayaGt') : _v('aayaLe'),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                  color: r.aadaayaGtVyaya ? Colors.green.shade700 : Colors.red.shade700),
              ),
            ),
          ]),
          const SizedBox(height: 3),

          // Tithi, Vaara
          Row(children: [
            Icon(Icons.calendar_today, size: 12, color: kMuted),
            const SizedBox(width: 4),
            Expanded(child: Text(
              '${_v('tithi')}: ${r.tithiValue}  |  ${_v('vaara')}: ${_v('vaara${r.vaaraValue - 1}')}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
          const SizedBox(height: 6),

          // Building Nakshatra
          Row(children: [
            Icon(Icons.star, size: 14, color: kOrange),
            const SizedBox(width: 4),
            Text('${_v('buildingNak')}: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
            Flexible(child: Text(naks[r.nakIndex],
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText),
              overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),

          // Tarabala
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _taraColor(r.taraIndex).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Icons.shield, size: 14, color: _taraColor(r.taraIndex)),
              const SizedBox(width: 6),
              Text('${_v('tarabala')}: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted)),
              Flexible(child: Text(
                '${_taraNames[r.taraIndex]} - ${_taraQuality[r.taraIndex]}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _taraColor(r.taraIndex)),
                overflow: TextOverflow.ellipsis,
              )),
            ]),
          ),
        ],
      ),
    );
  }
}
