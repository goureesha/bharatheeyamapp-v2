import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import '../widgets/common.dart';
import '../services/pooja_list_service.dart';

// ─── Pooja screen translations (self-contained, 5 languages) ───
const Map<String, Map<String, String>> _poojaStrings = {
  'kn': {
    'title': 'ಪೂಜಾ ಪಟ್ಟಿ', 'newList': 'ಹೊಸ ಪೂಜಾ ಪಟ್ಟಿ',
    'hintName': 'ಉದಾ: ಗಣೇಶ ಪೂಜೆ, ಸತ್ಯನಾರಾಯಣ ಪೂಜೆ...',
    'cancel': 'ರದ್ದು', 'create': 'ರಚಿಸಿ', 'save': 'ಉಳಿಸಿ', 'delete': 'ಅಳಿಸಿ',
    'rename': 'ಹೆಸರು ಬದಲಾಯಿಸಿ', 'noLists': 'ಯಾವುದೇ ಪೂಜಾ ಪಟ್ಟಿ ಇಲ್ಲ',
    'tapCreate': '+ ಒತ್ತಿ ಹೊಸ ಪಟ್ಟಿ ರಚಿಸಿ', 'createList': 'ಪಟ್ಟಿ ರಚಿಸಿ',
    'items': 'ಐಟಂಗಳು', 'noItems': 'ಯಾವುದೇ ಐಟಂಗಳಿಲ್ಲ', 'item': 'ಐಟಂ', 'qty': 'ಪ್ರಮಾಣ',
    'addItem': 'ಐಟಂ ಸೇರಿಸಿ', 'selectItem': 'ಐಟಂ ಆಯ್ಕೆ ಮಾಡಿ', 'selectQty': 'ಪ್ರಮಾಣ',
    'customItem': '── ಕಸ್ಟಮ್ ಐಟಂ ──', 'typeItemName': 'ಐಟಂ ಹೆಸರು ಟೈಪ್ ಮಾಡಿ...',
    'editItem': 'ಐಟಂ ಬದಲಾಯಿಸಿ', 'itemName': 'ಐಟಂ ಹೆಸರು',
    'added': 'ಸೇರಿಸಲಾಗಿದೆ', 'selectItemErr': 'ಐಟಂ ಆಯ್ಕೆ ಮಾಡಿ',
    'purohit': 'ಪುರೋಹಿತರ ವಿವರ', 'purohitName': 'ಪುರೋಹಿತರ ಹೆಸರು', 'mobile': 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ',
    'addPurohit': 'ಪುರೋಹಿತರ ಹೆಸರು ಸೇರಿಸಿ',
    'shareWA': 'WhatsApp ಹಂಚಿಕೊಳ್ಳಿ', 'downloadPdf': 'PDF ಡೌನ್‌ಲೋಡ್',
    'viewPlain': 'ಪಟ್ಟಿ ನೋಡಿ', 'addDefaults': 'ಡೀಫಾಲ್ಟ್ ಐಟಂ ಸೇರಿಸಿ', 'removeDefaults': 'ಡೀಫಾಲ್ಟ್ ಐಟಂ ತೆಗೆಯಿರಿ',
    'deleteQ': 'ಅಳಿಸಬೇಕೇ?', 'deleteMsg': 'ಈ ಪಟ್ಟಿ ಮತ್ತು ಎಲ್ಲಾ ಐಟಂಗಳನ್ನು ಅಳಿಸಲಾಗುತ್ತದೆ.',
    'useDropdown': 'ಮೇಲಿನ ಡ್ರಾಪ್‌ಡೌನ್ ಬಳಸಿ ಸೇರಿಸಿ', 'total': 'ಒಟ್ಟು',
    'allDefaultsExist': 'ಎಲ್ಲಾ ಡೀಫಾಲ್ಟ್ ಐಟಂ ಈಗಾಗಲೇ ಇದೆ', 'defaultsAdded': 'ಡೀಫಾಲ್ಟ್ ಐಟಂ ಸೇರಿಸಲಾಗಿದೆ',
    'defaultsRemoved': 'ಡೀಫಾಲ್ಟ್ ಐಟಂ ತೆಗೆಯಲಾಗಿದೆ', 'noDefaultsToRemove': 'ತೆಗೆಯಲು ಡೀಫಾಲ್ಟ್ ಐಟಂ ಇಲ್ಲ',
    'listName': 'ಪಟ್ಟಿ ಹೆಸರು', 'poojaList': 'ಪೂಜಾ ಸಾಮಗ್ರಿ ಪಟ್ಟಿ', 'itemsDone': 'ಐಟಂ ಮುಗಿದಿದೆ',
  },
  'hi': {
    'title': 'पूजा सूची', 'newList': 'नई पूजा सूची',
    'hintName': 'उदा: गणेश पूजा, सत्यनारायण पूजा...',
    'cancel': 'रद्द', 'create': 'बनाएं', 'save': 'सेव', 'delete': 'हटाएं',
    'rename': 'नाम बदलें', 'noLists': 'कोई पूजा सूची नहीं',
    'tapCreate': '+ दबाएं नई सूची बनाएं', 'createList': 'सूची बनाएं',
    'items': 'सामग्री', 'noItems': 'कोई सामग्री नहीं', 'item': 'सामग्री', 'qty': 'मात्रा',
    'addItem': 'सामग्री जोड़ें', 'selectItem': 'सामग्री चुनें', 'selectQty': 'मात्रा',
    'customItem': '── कस्टम सामग्री ──', 'typeItemName': 'सामग्री का नाम टाइप करें...',
    'editItem': 'सामग्री बदलें', 'itemName': 'सामग्री का नाम',
    'added': 'जोड़ा गया', 'selectItemErr': 'सामग्री चुनें',
    'purohit': 'पुरोहित विवरण', 'purohitName': 'पुरोहित का नाम', 'mobile': 'मोबाइल नंबर',
    'addPurohit': 'पुरोहित का नाम जोड़ें',
    'shareWA': 'WhatsApp शेयर', 'downloadPdf': 'PDF डाउनलोड',
    'viewPlain': 'सूची देखें', 'addDefaults': 'डिफ़ॉल्ट सामग्री जोड़ें', 'removeDefaults': 'डिफ़ॉल्ट सामग्री हटाएं',
    'deleteQ': 'हटाना है?', 'deleteMsg': 'यह सूची और सभी सामग्री हटाई जाएगी.',
    'useDropdown': 'ऊपर ड्रॉपडाउन से जोड़ें', 'total': 'कुल',
    'allDefaultsExist': 'सभी डिफ़ॉल्ट सामग्री पहले से है', 'defaultsAdded': 'डिफ़ॉल्ट सामग्री जोड़ी गई',
    'defaultsRemoved': 'डिफ़ॉल्ट सामग्री हटाई गई', 'noDefaultsToRemove': 'हटाने को डिफ़ॉल्ट सामग्री नहीं',
    'listName': 'सूची नाम', 'poojaList': 'पूजा सामग्री सूची', 'itemsDone': 'सामग्री पूर्ण',
  },
  'ta': {
    'title': 'பூஜை பட்டியல்', 'newList': 'புதிய பூஜை பட்டியல்',
    'hintName': 'எ.கா: விநாயகர் பூஜை, சத்யநாராயண பூஜை...',
    'cancel': 'ரத்து', 'create': 'உருவாக்கு', 'save': 'சேமி', 'delete': 'நீக்கு',
    'rename': 'பெயர் மாற்று', 'noLists': 'பூஜை பட்டியல் இல்லை',
    'tapCreate': '+ புதிய பட்டியல் உருவாக்கு', 'createList': 'பட்டியல் உருவாக்கு',
    'items': 'பொருட்கள்', 'noItems': 'பொருட்கள் இல்லை', 'item': 'பொருள்', 'qty': 'அளவு',
    'addItem': 'பொருள் சேர்', 'selectItem': 'பொருள் தேர்வு', 'selectQty': 'அளவு',
    'customItem': '── தனிப்பயன் பொருள் ──', 'typeItemName': 'பொருளின் பெயர் தட்டச்சு...',
    'editItem': 'பொருள் திருத்து', 'itemName': 'பொருளின் பெயர்',
    'added': 'சேர்க்கப்பட்டது', 'selectItemErr': 'பொருள் தேர்வு செய்யவும்',
    'purohit': 'புரோஹிதர் விவரம்', 'purohitName': 'புரோஹிதர் பெயர்', 'mobile': 'மொபைல் எண்',
    'addPurohit': 'புரோஹிதர் பெயர் சேர்',
    'shareWA': 'WhatsApp பகிர்', 'downloadPdf': 'PDF பதிவிறக்கு',
    'viewPlain': 'பட்டியல் பார்', 'addDefaults': 'இயல்புநிலை சேர்', 'removeDefaults': 'இயல்புநிலை நீக்கு',
    'deleteQ': 'நீக்கவா?', 'deleteMsg': 'இந்த பட்டியலும் அனைத்து பொருட்களும் நீக்கப்படும்.',
    'useDropdown': 'மேலே உள்ள டிராப்டவுன் பயன்படுத்தி சேர்க்கவும்', 'total': 'மொத்தம்',
    'allDefaultsExist': 'அனைத்து இயல்புநிலை ஏற்கனவே உள்ளன', 'defaultsAdded': 'இயல்புநிலை சேர்க்கப்பட்டன',
    'defaultsRemoved': 'இயல்புநிலை நீக்கப்பட்டன', 'noDefaultsToRemove': 'நீக்க இயல்புநிலை இல்லை',
    'listName': 'பட்டியல் பெயர்', 'poojaList': 'பூஜை சாமக்ரி பட்டியல்', 'itemsDone': 'பொருட்கள் முடிந்தது',
  },
  'te': {
    'title': 'పూజ జాబితా', 'newList': 'కొత్త పూజ జాబితా',
    'hintName': 'ఉదా: గణేశ పూజ, సత్యనారాయణ పూజ...',
    'cancel': 'రద్దు', 'create': 'సృష్టించు', 'save': 'సేవ్', 'delete': 'తొలగించు',
    'rename': 'పేరు మార్చు', 'noLists': 'పూజ జాబితా లేదు',
    'tapCreate': '+ కొత్త జాబితా సృష్టించు', 'createList': 'జాబితా సృష్టించు',
    'items': 'వస్తువులు', 'noItems': 'వస్తువులు లేవు', 'item': 'వస్తువు', 'qty': 'పరిమాణం',
    'addItem': 'వస్తువు చేర్చు', 'selectItem': 'వస్తువు ఎంచుకోండి', 'selectQty': 'పరిమాణం',
    'customItem': '── కస్టమ్ వస్తువు ──', 'typeItemName': 'వస్తువు పేరు టైప్ చేయండి...',
    'editItem': 'వస్తువు మార్చు', 'itemName': 'వస్తువు పేరు',
    'added': 'చేర్చబడింది', 'selectItemErr': 'వస్తువు ఎంచుకోండి',
    'purohit': 'పురోహితుడి వివరాలు', 'purohitName': 'పురోహితుడి పేరు', 'mobile': 'మొబైల్ నంబర్',
    'addPurohit': 'పురోహితుడి పేరు చేర్చండి',
    'shareWA': 'WhatsApp షేర్', 'downloadPdf': 'PDF డౌన్‌లోడ్',
    'viewPlain': 'జాబితా చూడు', 'addDefaults': 'డిఫాల్ట్ చేర్చు', 'removeDefaults': 'డిఫాల్ట్ తొలగించు',
    'deleteQ': 'తొలగించాలా?', 'deleteMsg': 'ఈ జాబితా మరియు అన్ని వస్తువులు తొలగించబడతాయి.',
    'useDropdown': 'పైన డ్రాప్‌డౌన్ ఉపయోగించి చేర్చండి', 'total': 'మొత్తం',
    'allDefaultsExist': 'అన్ని డిఫాల్ట్ ఇప్పటికే ఉన్నాయి', 'defaultsAdded': 'డిఫాల్ట్ చేర్చబడ్డాయి',
    'defaultsRemoved': 'డిఫాల్ట్ తొలగించబడ్డాయి', 'noDefaultsToRemove': 'తొలగించడానికి డిఫాల్ట్ లేవు',
    'listName': 'జాబితా పేరు', 'poojaList': 'పూజ సామగ్రి జాబితా', 'itemsDone': 'వస్తువులు పూర్తి',
  },
  'ml': {
    'title': 'പൂജാ പട്ടിക', 'newList': 'പുതിയ പൂജാ പട്ടിക',
    'hintName': 'ഉദാ: ഗണേശ പൂജ, സത്യനാരായണ പൂജ...',
    'cancel': 'റദ്ദാക്കുക', 'create': 'സൃഷ്ടിക്കുക', 'save': 'സേവ്', 'delete': 'ഇല്ലാതാക്കുക',
    'rename': 'പേര് മാറ്റുക', 'noLists': 'പൂജാ പട്ടിക ഇല്ല',
    'tapCreate': '+ പുതിയ പട്ടിക സൃഷ്ടിക്കുക', 'createList': 'പട്ടിക സൃഷ്ടിക്കുക',
    'items': 'വസ്തുക്കൾ', 'noItems': 'വസ്തുക്കൾ ഇല്ല', 'item': 'വസ്തു', 'qty': 'അളവ്',
    'addItem': 'വസ്തു ചേർക്കുക', 'selectItem': 'വസ്തു തിരഞ്ഞെടുക്കുക', 'selectQty': 'അളവ്',
    'customItem': '── കസ്റ്റം വസ്തു ──', 'typeItemName': 'വസ്തുവിന്റെ പേര് ടൈപ്പ് ചെയ്യുക...',
    'editItem': 'വസ്തു മാറ്റുക', 'itemName': 'വസ്തുവിന്റെ പേര്',
    'added': 'ചേർത്തു', 'selectItemErr': 'വസ്തു തിരഞ്ഞെടുക്കുക',
    'purohit': 'പുരോഹിതന്റെ വിവരങ്ങൾ', 'purohitName': 'പുരോഹിതന്റെ പേര്', 'mobile': 'മൊബൈൽ നമ്പർ',
    'addPurohit': 'പുരോഹിതന്റെ പേര് ചേർക്കുക',
    'shareWA': 'WhatsApp ഷെയർ', 'downloadPdf': 'PDF ഡൗൺലോഡ്',
    'viewPlain': 'പട്ടിക കാണുക', 'addDefaults': 'ഡിഫോൾട്ട് ചേർക്കുക', 'removeDefaults': 'ഡിഫോൾട്ട് നീക്കുക',
    'deleteQ': 'ഇല്ലാതാക്കണോ?', 'deleteMsg': 'ഈ പട്ടികയും എല്ലാ വസ്തുക്കളും ഇല്ലാതാക്കപ്പെടും.',
    'useDropdown': 'മുകളിലെ ഡ്രോപ്പ്ഡൗൺ ഉപയോഗിച്ച് ചേർക്കുക', 'total': 'ആകെ',
    'allDefaultsExist': 'എല്ലാ ഡിഫോൾട്ടും ഇതിനകം ഉണ്ട്', 'defaultsAdded': 'ഡിഫോൾട്ട് ചേർത്തു',
    'defaultsRemoved': 'ഡിഫോൾട്ട് നീക്കി', 'noDefaultsToRemove': 'നീക്കാൻ ഡിഫോൾട്ട് ഇല്ല',
    'listName': 'പട്ടിക പേര്', 'poojaList': 'പൂജാ സാമഗ്രി പട്ടിക', 'itemsDone': 'വസ്തുക്കൾ പൂർത്തിയായി',
  },
};

String _p(String key) {
  final lang = AppLocale.current;
  return _poojaStrings[lang]?[key] ?? _poojaStrings['kn']?[key] ?? key;
}

/// Default items added to every new pooja list
const List<Map<String, String>> _defaultPoojaItems = [
  // ── ಮೂಲ ಸಾಮಗ್ರಿ (Basic) ──
  {'n': 'ಅಕ್ಕಿ', 'q': '1 kg'},
  {'n': 'ಅರಿಶಿನ', 'q': '50 gm'},
  {'n': 'ಕುಂಕುಮ', 'q': '1 packet'},
  {'n': 'ರಂಗೋಲಿ', 'q': ''},
  {'n': 'ಹಸಿರು ಬಣ್ಣ', 'q': ''},
  {'n': 'ಕಪ್ಪು ಬಣ್ಣ', 'q': ''},
  {'n': 'ಇತರ ಬಣ್ಣ', 'q': ''},
  {'n': 'ಗಂಧ', 'q': ''},

  // ── ಹೂವು / ಎಲೆ ──
  {'n': 'ಶಿಂಗಾರ ಹೂ', 'q': ''},
  {'n': 'ಇತರ ಹೂ', 'q': ''},
  {'n': 'ತುಳಸಿ', 'q': ''},
  {'n': 'ಬಿಲ್ವಪತ್ರೆ', 'q': ''},
  {'n': 'ದರ್ಬೆ', 'q': ''},
  {'n': 'ಹಲಸಿನ ಕುಡಿ', 'q': ''},
  {'n': 'ಮಾವಿನ ಕುಡಿ', 'q': ''},

  // ── ದಾರ / ನೂಲು ──
  {'n': 'ರಜ್ಜು', 'q': ''},
  {'n': 'ನೂಲುಂಡೆ', 'q': ''},
  {'n': 'ಜನಿವಾರ', 'q': ''},

  // ── ಎಲೆ / ಹಣ್ಣು ──
  {'n': 'ವೀಳ್ಯದೆಲೆ ಕಟ್ಟು', 'q': ''},
  {'n': 'ಅಡಿಕೆ', 'q': '10'},
  {'n': 'ಬಾಳೆ ಎಲೆ', 'q': ''},
  {'n': 'ಬಾಳೆ ಹಣ್ಣು', 'q': '1 dozen'},
  {'n': 'ಲಿಂಬೆ ಹಣ್ಣು', 'q': ''},
  {'n': 'ಇತರ ಹಣ್ಣು', 'q': ''},
  {'n': 'ತೆಂಗಿನ ಕಾಯಿ', 'q': '2'},
  {'n': 'ಸೀಯಾಳ', 'q': ''},
  {'n': 'ಕುಂಬಳ ಕಾಯಿ', 'q': ''},

  // ── ಪಂಚಾಮೃತ / ದ್ರವ ──
  {'n': 'ಗೋಮಯ', 'q': ''},
  {'n': 'ಗೋಮೂತ್ರ', 'q': ''},
  {'n': 'ಹಾಲು', 'q': ''},
  {'n': 'ತುಪ್ಪ', 'q': '250 ml'},
  {'n': 'ಸಕ್ಕರೆ', 'q': ''},
  {'n': 'ಜೇನುತುಪ್ಪ', 'q': ''},
  {'n': 'ಕಬ್ಬಿನ ಹಾಲು', 'q': ''},

  // ── ದೀಪ / ಧೂಪ ──
  {'n': 'ಊದುಬತ್ತಿ', 'q': '1 packet'},
  {'n': 'ಕರ್ಪೂರ', 'q': '1 packet'},
  {'n': 'ಹತ್ತಿಬತ್ತಿ ಕಟ್ಟು', 'q': ''},
  {'n': 'ದೀಪದ ಎಣ್ಣೆ', 'q': '100 ml'},

  // ── ಧಾನ್ಯ / ಕಾಳು ──
  {'n': 'ಚಕ್ಕೆ ಹೊರೆ', 'q': ''},
  {'n': 'ಕರಿ ಎಳ್ಳು', 'q': ''},
  {'n': 'ಬಿಳಿ ಸಾಸಿವೆ', 'q': ''},
  {'n': 'ಅರಳು', 'q': ''},
  {'n': 'ಭತ್ತ', 'q': ''},
  {'n': 'ಗೋಧಿ', 'q': ''},
  {'n': 'ಅವರೆ', 'q': ''},
  {'n': 'ಉದ್ದು', 'q': ''},
  {'n': 'ಕಡಲೆ', 'q': ''},
  {'n': 'ತೊಗರಿ', 'q': ''},
  {'n': 'ಹೆಸರು', 'q': ''},
  {'n': 'ಹುರುಳಿ', 'q': ''},

  // ── ಮಸಾಲೆ / ಒಣ ಹಣ್ಣು ──
  {'n': 'ಜಾಯಿಕಾಯಿ', 'q': ''},
  {'n': 'ಒಣದ್ರಾಕ್ಷಿ', 'q': ''},
  {'n': 'ಉತ್ತುತ್ತೆ', 'q': ''},
  {'n': 'ಗೋಡಂಬಿ', 'q': ''},
  {'n': 'ಕಾಳು ಮೆಣಸು', 'q': ''},
  {'n': 'ಲವಂಗ', 'q': ''},
  {'n': 'ಏಲಕ್ಕಿ', 'q': ''},

  // ── ತಿಂಡಿ ──
  {'n': 'ಬೆಲ್ಲ', 'q': '250 gm'},
  {'n': 'ಅವಲಕ್ಕಿ', 'q': ''},
  {'n': 'ಬಾಳೆ ಎಲೆ ದೊನ್ನೆ', 'q': ''},

  // ── ವಸ್ತ್ರ ──
  {'n': 'ಪಟ್ಟೆ ಮಡಿ', 'q': ''},
  {'n': 'ವೇಷ್ಟಿ ಪಂಚೆ', 'q': ''},
  {'n': 'ಮುಂಡುಪಂಚೆ', 'q': ''},
  {'n': 'ಸೀರೆ', 'q': ''},
  {'n': 'ಕಣ', 'q': ''},
  {'n': 'ಶಾಲು', 'q': ''},
  {'n': 'ಪಾಣಿ ಪಂಚೆ', 'q': ''},
  {'n': 'ಬಾತ್ ಟವಲ್', 'q': ''},

  // ── ಪಾತ್ರೆ ──
  {'n': 'ಕೊಡಪಾನ', 'q': ''},
  {'n': 'ತಂಬಿಗೆ', 'q': ''},
  {'n': 'ಹರಿವಾಣ', 'q': ''},
  {'n': 'ಕವಳಿಗೆ ಸೌಟು', 'q': ''},
  {'n': 'ಹಿತ್ತಾಳೆ ಬುಟ್ಟಿ', 'q': ''},

  // ── ಇತರ ──
  {'n': 'ಇಟ್ಟಿಗೆ', 'q': ''},
  {'n': 'ಹೊಯ್ಗೆ', 'q': ''},
  {'n': 'ಬಾಳೆ ಕಂಬ (ದಿಂಡು)', 'q': ''},
  {'n': 'ಪಂಚರತ್ನ', 'q': ''},
  {'n': 'ಕನ್ನಡಿ', 'q': ''},
  {'n': 'ಗೋಪಿ', 'q': ''},
  {'n': 'ಬೆಳ್ಳಿ', 'q': ''},
  {'n': 'ಕಬ್ಬಿನ ಜಲ್ಲೆ', 'q': ''},
  {'n': '1 ರೂಪಾಯಿ ನಾಣ್ಯ', 'q': ''},
  {'n': 'ಚಿಲ್ಲರೆ ರೊಕ್ಕ', 'q': ''},

  // ── ಸಮಿಧ ──
  {'n': 'ಅಶ್ವತ್ಥ', 'q': ''},
  {'n': 'ಪಾಲಾಶ (ಮುತ್ತುಗ)', 'q': ''},
  {'n': 'ಅತ್ತಿ', 'q': ''},
  {'n': 'ಕದಿರ', 'q': ''},
  {'n': 'ಶಮಿ', 'q': ''},
  {'n': 'ದೂರ್ವೆ', 'q': ''},
  {'n': 'ಎಕ್ಕೆ', 'q': ''},

  // ── ವಿಶೇಷ ──
  {'n': 'ನವಗ್ರಹ ರತ್ನ ಸೆಟ್', 'q': ''},
  {'n': 'ಕಾಶಿ ತೀರ್ಥ (1 ಬಾಟಲಿ)', 'q': ''},
];

List<PoojaItem> _createDefaultItems() {
  return _defaultPoojaItems.map((m) => PoojaItem(
    name: m['n']!,
    quantity: m['q']!,
  )).toList();
}

class PoojaListsScreen extends StatefulWidget {
  const PoojaListsScreen({super.key});

  @override
  State<PoojaListsScreen> createState() => _PoojaListsScreenState();
}

class _PoojaListsScreenState extends State<PoojaListsScreen> {
  List<PoojaList> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lists = await PoojaListService.loadAll();
    if (mounted) setState(() { _lists = lists; _loading = false; });
  }

  Future<void> _save() async {
    await PoojaListService.saveAll(_lists);
  }

  void _createNewList() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text(_p('newList'), style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: kText),
          decoration: InputDecoration(
            hintText: _p('hintName'),
            hintStyle: TextStyle(color: kMuted, fontSize: 14),
            filled: true, fillColor: kBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_p('cancel'), style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final newList = PoojaList(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                items: [],
              );
              setState(() => _lists.insert(0, newList));
              _save();
              _openList(newList);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: Text(_p('create')),
          ),
        ],
      ),
    );
  }

  void _openList(PoojaList list) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PoojaListDetailScreen(list: list)),
    );
    await _save();
    if (mounted) setState(() {});
  }

  void _renameList(int index) {
    final list = _lists[index];
    final ctrl = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text(_p('rename'), style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: kText),
          decoration: InputDecoration(
            filled: true, fillColor: kBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_p('cancel'), style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => list.name = name);
              _save();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: Text(_p('save')),
          ),
        ],
      ),
    );
  }

  void _deleteList(int index) {
    final list = _lists[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('${_p('deleteQ')} "${list.name}"', style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: Text(_p('deleteMsg'), style: TextStyle(color: kMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_p('cancel'), style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _lists.removeAt(index));
              _save();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(_p('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text(_p('title'), style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: kOrange),
            onPressed: _createNewList,
            tooltip: 'New List',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt_rounded, size: 80, color: kMuted.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(_p('noLists'), style: TextStyle(fontSize: 18, color: kMuted, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(_p('tapCreate'), style: TextStyle(fontSize: 14, color: kMuted)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createNewList,
                        icon: const Icon(Icons.add),
                        label: Text(_p('createList')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kOrange, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lists.length,
                  itemBuilder: (context, index) {
                    final list = _lists[index];
                    final total = list.items.length;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _openList(list),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kBorder),
                            boxShadow: [
                              BoxShadow(color: kOrange.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: kOrange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.temple_hindu_rounded, color: kOrange, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(list.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
                                      const SizedBox(height: 4),
                                      Text(
                                        total == 0 ? _p('noItems') : '$total ${_p('items')}',
                                        style: TextStyle(fontSize: 13, color: kMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                // Edit button
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: kPurple2, size: 20),
                                  onPressed: () => _renameList(index),
                                  tooltip: 'Rename',
                                ),
                                // Delete button
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7), size: 20),
                                  onPressed: () => _deleteList(index),
                                  tooltip: 'Delete',
                                ),
                                Icon(Icons.chevron_right, color: kMuted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _lists.isNotEmpty
          ? FloatingActionButton(
              onPressed: _createNewList,
              backgroundColor: kOrange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ─── Detail Screen: Items inside a single pooja list ───

class _PoojaListDetailScreen extends StatefulWidget {
  final PoojaList list;
  const _PoojaListDetailScreen({required this.list});

  @override
  State<_PoojaListDetailScreen> createState() => _PoojaListDetailScreenState();
}

class _PoojaListDetailScreenState extends State<_PoojaListDetailScreen> {
  late PoojaList _list;
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _customNameCtrl = TextEditingController();

  // Dropdown state
  String? _selectedItem;
  bool _isCustomItem = false;

  // Default item names for dropdown (getter so it updates with language)
  List<String> get _dropdownItems => [
    _p('customItem'),
    ..._defaultPoojaItems.map((m) => m['n']!),
  ];

  @override
  void initState() {
    super.initState();
    _list = widget.list;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _customNameCtrl.dispose();
    super.dispose();
  }

  void _addItemFromDropdown() {
    final itemName = _isCustomItem ? _customNameCtrl.text.trim() : _selectedItem;
    if (itemName == null || itemName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_p('selectItemErr')), backgroundColor: Colors.orange),
      );
      return;
    }
    final qty = _qtyCtrl.text.trim();
    setState(() {
      _list.items.add(PoojaItem(name: itemName, quantity: qty));
      _selectedItem = null;
      _isCustomItem = false;
      _customNameCtrl.clear();
      _qtyCtrl.clear();
    });
    _saveList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$itemName ${_p('added')}'), backgroundColor: kGreen, duration: Duration(seconds: 1)),
    );
  }

  void _addDefaultItems() {
    final defaults = _createDefaultItems();
    final existingNames = _list.items.map((i) => i.name).toSet();
    final toAdd = defaults.where((d) => !existingNames.contains(d.name)).toList();
    if (toAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_p('allDefaultsExist')), backgroundColor: kMuted));
      return;
    }
    setState(() => _list.items.addAll(toAdd));
    _saveList();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${toAdd.length} ${_p('defaultsAdded')}'), backgroundColor: kGreen));
  }

  void _removeDefaultItems() {
    final defaultNames = _defaultPoojaItems.map((m) => m['n']!).toSet();
    final before = _list.items.length;
    setState(() => _list.items.removeWhere((i) => defaultNames.contains(i.name)));
    final removed = before - _list.items.length;
    _saveList();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(removed > 0 ? '$removed ${_p('defaultsRemoved')}' : _p('noDefaultsToRemove')),
      backgroundColor: removed > 0 ? Colors.red : kMuted,
    ));
  }

  void _editItem(int index) {
    final item = _list.items[index];
    _nameCtrl.text = item.name;
    _qtyCtrl.text = item.quantity;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text(_p('editItem'), style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nameCtrl, autofocus: true, style: TextStyle(color: kText), decoration: _inputDeco(_p('itemName'))),
          const SizedBox(height: 12),
          TextField(controller: _qtyCtrl, style: TextStyle(color: kText), decoration: _inputDeco(_p('qty'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_p('cancel'), style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() { item.name = name; item.quantity = _qtyCtrl.text.trim(); });
              _saveList();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: Text(_p('save')),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() => _list.items.removeAt(index));
    _saveList();
  }

  void _toggleItem(int index) {
    setState(() => _list.items[index].checked = !_list.items[index].checked);
    _saveList();
  }

  void _uncheckAll() {
    setState(() { for (final item in _list.items) item.checked = false; });
    _saveList();
  }

  void _renameList() {
    final ctrl = TextEditingController(text: _list.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text(_p('rename'), style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: TextField(controller: ctrl, autofocus: true, style: TextStyle(color: kText), decoration: _inputDeco(_p('listName'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_p('cancel'), style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _list.name = name);
              _saveList();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: Text(_p('save')),
          ),
        ],
      ),
    );
  }

  void _editPurohitInfo() {
    final nameCtrl = TextEditingController(text: _list.purohitName);
    final phoneCtrl = TextEditingController(text: _list.purohitPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text(_p('purohit'), style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, autofocus: true, style: TextStyle(color: kText), decoration: _inputDeco(_p('purohitName'))),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, style: TextStyle(color: kText), keyboardType: TextInputType.phone, decoration: _inputDeco(_p('mobile'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_p('cancel'), style: TextStyle(color: kMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _list.purohitName = nameCtrl.text.trim(); _list.purohitPhone = phoneCtrl.text.trim(); });
              _saveList();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
            child: Text(_p('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveList() async { await PoojaListService.updateList(_list); }

  String _formatListText() {
    final buf = StringBuffer();
    buf.writeln('📋 ${_list.name}');
    if (_list.purohitName.isNotEmpty || _list.purohitPhone.isNotEmpty) {
      buf.writeln('👤 Purohit: ${_list.purohitName}');
      if (_list.purohitPhone.isNotEmpty) buf.writeln('📞 ${_list.purohitPhone}');
    }
    buf.writeln('${'─' * 30}');
    for (int i = 0; i < _list.items.length; i++) {
      final item = _list.items[i];
      final check = item.checked ? '✅' : '⬜';
      final qty = item.quantity.isNotEmpty ? '  (${item.quantity})' : '';
      buf.writeln('$check ${i + 1}. ${item.name}$qty');
    }
    buf.writeln('${'─' * 30}');
    buf.writeln('📊 ${_list.checkedCount} / ${_list.items.length} items done');
    buf.writeln('\n— Bharatheeyam App');
    return buf.toString();
  }

  void _shareList() async {
    final text = _formatListText();
    final waUrl = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(waUrl)) { await launchUrl(waUrl); }
    else { await Share.share(text, subject: _list.name); }
  }

  void _exportPdf() async {
    try {
      // Load Kannada fonts for PDF
      final regularFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansKannada-Regular.ttf'));
      final boldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansKannada-Bold.ttf'));

      final purple = PdfColor.fromHex('#4A148C');
      final blue = PdfColor.fromHex('#1565C0');
      final grey = PdfColor.fromHex('#757575');
      final headerBg = PdfColor.fromHex('#F3E5F5');
      final borderColor = PdfColor.fromHex('#E0E0E0');
      final altRow = PdfColor.fromHex('#FAFAFA');

      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (pw.Context context) {
            // Show header only on first page
            if (context.pageNumber > 1) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(_list.name, style: pw.TextStyle(font: boldFont, fontSize: 14, color: purple)),
              );
            }
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Pooja Name - centered, large
                pw.Center(child: pw.Text(_list.name, style: pw.TextStyle(font: boldFont, fontSize: 26, color: purple))),
                pw.SizedBox(height: 4),
                pw.Center(child: pw.Text('${_list.items.length} items', style: pw.TextStyle(font: regularFont, fontSize: 12, color: grey))),
                pw.SizedBox(height: 14),
                // Purohit details box
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: headerBg,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    if (_list.purohitName.isNotEmpty)
                      pw.Text('Purohit: ${_list.purohitName}', style: pw.TextStyle(font: boldFont, fontSize: 13, color: purple)),
                    if (_list.purohitPhone.isNotEmpty)
                      pw.Padding(padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text('Phone: ${_list.purohitPhone}', style: pw.TextStyle(font: regularFont, fontSize: 12, color: blue))),
                    if (_list.purohitName.isEmpty && _list.purohitPhone.isEmpty)
                      pw.Text('Pooja Samagri List', style: pw.TextStyle(font: boldFont, fontSize: 13, color: purple)),
                  ]),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 0.5, color: borderColor),
                pw.SizedBox(height: 8),
              ],
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by Bharatheeyam App', style: pw.TextStyle(font: regularFont, fontSize: 9, color: grey)),
                  pw.Text('Page ${context.pageNumber} / ${context.pagesCount}', style: pw.TextStyle(font: regularFont, fontSize: 9, color: grey)),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // Table with header row + item rows — auto-paginates
              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: headerBg),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('#', style: pw.TextStyle(font: boldFont, fontSize: 12))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Item', style: pw.TextStyle(font: boldFont, fontSize: 12))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Quantity', style: pw.TextStyle(font: boldFont, fontSize: 12))),
                    ],
                  ),
                  // Item rows
                  ...List.generate(_list.items.length, (i) {
                    final item = _list.items[i];
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: i % 2 == 0 ? PdfColors.white : altRow),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${i + 1}', style: pw.TextStyle(font: regularFont, fontSize: 11, color: grey))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item.name, style: pw.TextStyle(font: regularFont, fontSize: 11))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item.quantity, style: pw.TextStyle(font: regularFont, fontSize: 11, color: grey))),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save(), name: '${_list.name}_list.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF export failed: $e'), backgroundColor: Colors.red));
    }
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: kMuted),
    filled: true, fillColor: kBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
  );

  @override
  Widget build(BuildContext context) {
    final total = _list.items.length;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: GestureDetector(
          onTap: _renameList,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(_list.name, style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            Icon(Icons.edit, size: 16, color: kMuted),
          ]),
        ),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: kMuted),
            color: kCard,
            onSelected: (val) {
              if (val == 'add_defaults') _addDefaultItems();
              if (val == 'remove_defaults') _removeDefaultItems();
              if (val == 'share') _shareList();
              if (val == 'pdf') _exportPdf();
              if (val == 'view') _viewPlainList();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, color: kGreen, size: 20), const SizedBox(width: 10), Text(_p('shareWA'), style: TextStyle(color: kText))])),
              PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red, size: 20), const SizedBox(width: 10), Text(_p('downloadPdf'), style: TextStyle(color: kText))])),
              PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.view_list, color: Color(0xFF2980B9), size: 20), const SizedBox(width: 10), Text(_p('viewPlain'), style: TextStyle(color: kText))])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'add_defaults', child: Row(children: [Icon(Icons.playlist_add, color: kPurple2, size: 20), const SizedBox(width: 10), Text(_p('addDefaults'), style: TextStyle(color: kText))])),
              PopupMenuItem(value: 'remove_defaults', child: Row(children: [Icon(Icons.playlist_remove, color: kMuted, size: 20), const SizedBox(width: 10), Text(_p('removeDefaults'), style: TextStyle(color: kText))])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Add Item Section (Dropdowns + Add Button) ───
          Container(
            padding: const EdgeInsets.all(14),
            color: kCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_p('addItem'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kOrange)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item dropdown or custom text field
                    Expanded(
                      flex: 3,
                      child: _isCustomItem
                        ? TextField(
                            controller: _customNameCtrl,
                            autofocus: true,
                            style: TextStyle(color: kText, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: _p('typeItemName'),
                              hintStyle: TextStyle(color: kMuted, fontSize: 13),
                              filled: true, fillColor: kBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange, width: 2)),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.close, size: 18, color: kMuted),
                                onPressed: () => setState(() { _isCustomItem = false; _customNameCtrl.clear(); }),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedItem,
                                hint: Text(_p('selectItem'), style: TextStyle(color: kMuted, fontSize: 13)),
                                dropdownColor: kCard,
                                style: TextStyle(color: kText, fontSize: 14),
                                icon: Icon(Icons.arrow_drop_down, color: kOrange),
                                items: _dropdownItems.map((item) {
                                  final isCustom = item == _p('customItem');
                                  return DropdownMenuItem(value: item, child: Text(item, style: TextStyle(
                                    color: isCustom ? kOrange : kText,
                                    fontWeight: isCustom ? FontWeight.w800 : FontWeight.w500, fontSize: 14,
                                  )));
                                }).toList(),
                                onChanged: (val) {
                                  if (val == _p('customItem')) {
                                    setState(() { _isCustomItem = true; _selectedItem = null; });
                                  } else {
                                    setState(() => _selectedItem = val);
                                  }
                                },
                              ),
                            ),
                          ),
                    ),
                    const SizedBox(width: 8),
                    // Quantity text field
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _qtyCtrl,
                        style: TextStyle(color: kText, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _p('selectQty'),
                          hintStyle: TextStyle(color: kMuted, fontSize: 13),
                          filled: true,
                          fillColor: kBg,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kOrange)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addItemFromDropdown,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kOrange, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                        ),
                        child: const Icon(Icons.add, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2a2a3a)),

          // Item count
          if (total > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: kCard,
              child: Text('$total ${_p('items')}', style: TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w600)),
            ),

          // Purohit info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: kCard,
            child: Row(children: [
              Icon(Icons.person, color: kPurple2, size: 22),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: _editPurohitInfo,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_list.purohitName.isNotEmpty ? _list.purohitName : _p('addPurohit'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _list.purohitName.isNotEmpty ? kText : kMuted)),
                  if (_list.purohitPhone.isNotEmpty)
                    Text(_list.purohitPhone, style: TextStyle(fontSize: 13, color: kMuted)),
                ]),
              )),
              IconButton(icon: Icon(Icons.edit_outlined, color: kPurple2, size: 20), onPressed: _editPurohitInfo, tooltip: 'Edit Purohit', visualDensity: VisualDensity.compact),
              if (_list.purohitPhone.isNotEmpty)
                IconButton(icon: Icon(Icons.phone, color: kGreen, size: 20), onPressed: () => launchUrl(Uri.parse('tel:${_list.purohitPhone}')), tooltip: 'Call Purohit', visualDensity: VisualDensity.compact),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFF2a2a3a)),

          // Items list
          Expanded(
            child: _list.items.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.playlist_add, size: 64, color: kMuted.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(_p('noItems'), style: TextStyle(fontSize: 16, color: kMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(_p('useDropdown'), style: TextStyle(fontSize: 13, color: kMuted)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _list.items.length,
                    itemBuilder: (context, index) {
                      final item = _list.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                            decoration: BoxDecoration(
                              color: kCard, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kBorder),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(children: [
                                // Serial number
                                Text('${index + 1}.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kMuted)),
                                const SizedBox(width: 12),
                                // Name & quantity
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
                                  if (item.quantity.isNotEmpty)
                                    Text(item.quantity, style: TextStyle(fontSize: 13, color: kMuted)),
                                ])),
                                // Edit
                                IconButton(icon: Icon(Icons.edit_outlined, color: kPurple2, size: 20), onPressed: () => _editItem(index), tooltip: 'Edit', visualDensity: VisualDensity.compact),
                                // Delete
                                IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7), size: 20), onPressed: () => _deleteItem(index), tooltip: 'Delete', visualDensity: VisualDensity.compact),
                              ]),
                            ),
                          ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _viewPlainList() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _PlainListViewPage(list: _list)));
  }
}


// ─── Plain List View Page ───

class _PlainListViewPage extends StatelessWidget {
  final PoojaList list;
  const _PlainListViewPage({required this.list});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text(list.name, style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purohit info
            if (list.purohitName.isNotEmpty || list.purohitPhone.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: kPurple2, size: 22),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (list.purohitName.isNotEmpty)
                          Text('Purohit: ${list.purohitName}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
                        if (list.purohitPhone.isNotEmpty)
                          Text(list.purohitPhone, style: TextStyle(fontSize: 14, color: kMuted)),
                      ],
                    ),
                  ],
                ),
              ),

            // Items table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kOrange.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 35, child: Text('#', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kOrange))),
                        Expanded(flex: 3, child: Text(_p('item'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kOrange))),
                        Expanded(flex: 2, child: Text(_p('qty'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kOrange))),
                      ],
                    ),
                  ),
                  // Rows
                  ...List.generate(list.items.length, (i) {
                    final item = list.items[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: kBorder, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 35, child: Text('${i + 1}', style: TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600))),
                          Expanded(flex: 3, child: Text(item.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText))),
                          Expanded(flex: 2, child: Text(item.quantity, style: TextStyle(fontSize: 14, color: kMuted))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Summary
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '${_p('total')}: ${list.items.length} ${_p('items')}',
                style: TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
