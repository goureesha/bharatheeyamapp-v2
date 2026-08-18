import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    'purohit': 'ಪುರೋಹಿತರ ವಿವರ', 'purohitName': 'ಪುರೋಹಿತರ ಹೆಸರು', 'mobile': 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ', 'address': 'ವಿಳಾಸ', 'poojaDate': 'ಪೂಜೆ ದಿನಾಂಕ',
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
    'purohit': 'पुरोहित विवरण', 'purohitName': 'पुरोहित का नाम', 'mobile': 'मोबाइल नंबर', 'address': 'पता', 'poojaDate': 'पूजा तिथि',
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
    'purohit': 'புரோஹிதர் விவரம்', 'purohitName': 'புரோஹிதர் பெயர்', 'mobile': 'மொபைல் எண்', 'address': 'முகவரி', 'poojaDate': 'பூஜை தேதி',
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
    'purohit': 'పురోహితుడి వివరాలు', 'purohitName': 'పురోహితుడి పేరు', 'mobile': 'మొబైల్ నంబర్', 'address': 'చిరునామా', 'poojaDate': 'పూజ తేదీ',
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
    'purohit': 'പുരോഹിതന്റെ വിവരങ്ങൾ', 'purohitName': 'പുരോഹിതന്റെ പേര്', 'mobile': 'മൊബൈൽ നമ്പർ', 'address': 'വിലാസം', 'poojaDate': 'പൂജ തീയതി',
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

/// Pooja item name translation map: Kannada → locale
const Map<String, Map<String, String>> _poojaItemTr = {
  'hi': {
    'ಅಕ್ಕಿ': 'चावल', 'ಅರಿಶಿನ': 'हल्दी', 'ಕುಂಕುಮ': 'कुमकुम', 'ರಂಗೋಲಿ': 'रंगोली',
    'ಹಸಿರು ಬಣ್ಣ': 'हरा रंग', 'ಕಪ್ಪು ಬಣ್ಣ': 'काला रंग', 'ಇತರ ಬಣ್ಣ': 'अन्य रंग', 'ಗಂಧ': 'चंदन',
    'ಶಿಂಗಾರ ಹೂ': 'शृंगार फूल', 'ಇತರ ಹೂ': 'अन्य फूल', 'ತುಳಸಿ': 'तुलसी', 'ಬಿಲ್ವಪತ್ರೆ': 'बेलपत्र',
    'ದರ್ಬೆ': 'दर्भ', 'ಹಲಸಿನ ಕುಡಿ': 'कटहल पत्ता', 'ಮಾವಿನ ಕುಡಿ': 'आम पत्ता',
    'ರಜ್ಜು': 'रज्जु', 'ನೂಲುಂಡೆ': 'सूत', 'ಜನಿವಾರ': 'जनेऊ',
    'ವೀಳ್ಯದೆಲೆ ಕಟ್ಟು': 'पान पत्ता', 'ಅಡಿಕೆ': 'सुपारी', 'ಬಾಳೆ ಎಲೆ': 'केले का पत्ता',
    'ಬಾಳೆ ಹಣ್ಣು': 'केला', 'ಲಿಂಬೆ ಹಣ್ಣು': 'नींबू', 'ಇತರ ಹಣ್ಣು': 'अन्य फल',
    'ತೆಂಗಿನ ಕಾಯಿ': 'नारियल', 'ಸೀಯಾಳ': 'हरा नारियल', 'ಕುಂಬಳ ಕಾಯಿ': 'कद्दू',
    'ಗೋಮಯ': 'गोमय', 'ಗೋಮೂತ್ರ': 'गोमूत्र', 'ಹಾಲು': 'दूध', 'ತುಪ್ಪ': 'घी',
    'ಸಕ್ಕರೆ': 'शक्कर', 'ಜೇನುತುಪ್ಪ': 'शहद', 'ಕಬ್ಬಿನ ಹಾಲು': 'गन्ने का रस',
    'ಊದುಬತ್ತಿ': 'अगरबत्ती', 'ಕರ್ಪೂರ': 'कपूर', 'ಹತ್ತಿಬತ್ತಿ ಕಟ್ಟು': 'रूई बत्ती', 'ದೀಪದ ಎಣ್ಣೆ': 'दीपक तेल',
    'ಚಕ್ಕೆ ಹೊರೆ': 'दालचीनी', 'ಕರಿ ಎಳ್ಳು': 'काले तिल', 'ಬಿಳಿ ಸಾಸಿವೆ': 'सफेद सरसों',
    'ಅರಳು': 'मुरमुरे', 'ಭತ್ತ': 'धान', 'ಗೋಧಿ': 'गेहूं', 'ಅವರೆ': 'सेम',
    'ಉದ್ದು': 'उड़द', 'ಕಡಲೆ': 'चना', 'ತೊಗರಿ': 'तुअर', 'ಹೆಸರು': 'मूंग', 'ಹುರುಳಿ': 'कुलथी',
    'ಜಾಯಿಕಾಯಿ': 'जायफल', 'ಒಣದ್ರಾಕ್ಷಿ': 'किशमिश', 'ಉತ್ತುತ್ತೆ': 'बादाम',
    'ಗೋಡಂಬಿ': 'काजू', 'ಕಾಳು ಮೆಣಸು': 'काली मिर्च', 'ಲವಂಗ': 'लौंग', 'ಏಲಕ್ಕಿ': 'इलायची',
    'ಬೆಲ್ಲ': 'गुड़', 'ಅವಲಕ್ಕಿ': 'पोहा', 'ಬಾಳೆ ಎಲೆ ದೊನ್ನೆ': 'केले के पत्ते का दोना',
    'ಪಟ್ಟೆ ಮಡಿ': 'पट्टे मड़ी', 'ವೇಷ್ಟಿ ಪಂಚೆ': 'धोती', 'ಮುಂಡುಪಂಚೆ': 'मुंडू',
    'ಸೀರೆ': 'साड़ी', 'ಕಣ': 'कण', 'ಶಾಲು': 'शॉल', 'ಪಾಣಿ ಪಂಚೆ': 'पाणी पंचे', 'ಬಾತ್ ಟವಲ್': 'तौलिया',
    'ಕೊಡಪಾನ': 'कलश', 'ತಂಬಿಗೆ': 'तांबे का लोटा', 'ಹರಿವಾಣ': 'थाली',
    'ಕವಳಿಗೆ ಸೌಟು': 'चम्मच', 'ಹಿತ್ತಾಳೆ ಬುಟ್ಟಿ': 'पीतल टोकरी',
    'ಇಟ್ಟಿಗೆ': 'ईंट', 'ಹೊಯ್ಗೆ': 'रेत', 'ಬಾಳೆ ಕಂಬ (ದಿಂಡು)': 'केले का तना',
    'ಪಂಚರತ್ನ': 'पंचरत्न', 'ಕನ್ನಡಿ': 'दर्पण', 'ಗೋಪಿ': 'गोपी चंदन', 'ಬೆಳ್ಳಿ': 'चांदी',
    'ಕಬ್ಬಿನ ಜಲ್ಲೆ': 'गन्ने का टुकड़ा', '1 ರೂಪಾಯಿ ನಾಣ್ಯ': '1 रुपये का सिक्का', 'ಚಿಲ್ಲರೆ ರೊಕ್ಕ': 'छुट्टे पैसे',
    'ಅಶ್ವತ್ಥ': 'अश्वत्थ (पीपल)', 'ಪಾಲಾಶ (ಮುತ್ತುಗ)': 'पलाश', 'ಅತ್ತಿ': 'उदुम्बर (गूलर)',
    'ಕದಿರ': 'खदिर', 'ಶಮಿ': 'शमी', 'ದೂರ್ವೆ': 'दूर्वा', 'ಎಕ್ಕೆ': 'अर्क (आक)',
    'ನವಗ್ರಹ ರತ್ನ ಸೆಟ್': 'नवग्रह रत्न सेट', 'ಕಾಶಿ ತೀರ್ಥ (1 ಬಾಟಲಿ)': 'काशी तीर्थ (1 बोतल)',
  },
  'ta': {
    'ಅಕ್ಕಿ': 'அரிசி', 'ಅರಿಶಿನ': 'மஞ்சள்', 'ಕುಂಕುಮ': 'குங்குமம்', 'ರಂಗೋಲಿ': 'கோலம்',
    'ಹಸಿರು ಬಣ್ಣ': 'பச்சை நிறம்', 'ಕಪ್ಪು ಬಣ್ಣ': 'கருப்பு நிறம்', 'ಇತರ ಬಣ್ಣ': 'பிற நிறம்', 'ಗಂಧ': 'சந்தனம்',
    'ಶಿಂಗಾರ ಹೂ': 'அலங்கார பூ', 'ಇತರ ಹೂ': 'பிற பூ', 'ತುಳಸಿ': 'துளசி', 'ಬಿಲ್ವಪತ್ರೆ': 'வில்வம்',
    'ದರ್ಬೆ': 'தர்ப்பை', 'ಹಲಸಿನ ಕುಡಿ': 'பலா இலை', 'ಮಾವಿನ ಕುಡಿ': 'மா இலை',
    'ರಜ್ಜು': 'ரஜ்ஜு', 'ನೂಲುಂಡೆ': 'நூல்', 'ಜನಿವಾರ': 'பூணூல்',
    'ವೀಳ್ಯದೆಲೆ ಕಟ್ಟು': 'வெற்றிலை', 'ಅಡಿಕೆ': 'பாக்கு', 'ಬಾಳೆ ಎಲೆ': 'வாழை இலை',
    'ಬಾಳೆ ಹಣ್ಣು': 'வாழைப்பழம்', 'ಲಿಂಬೆ ಹಣ್ಣು': 'எலுமிச்சை', 'ಇತರ ಹಣ್ಣು': 'பிற பழம்',
    'ತೆಂಗಿನ ಕಾಯಿ': 'தேங்காய்', 'ಸೀಯಾಳ': 'இளநீர்', 'ಕುಂಬಳ ಕಾಯಿ': 'பூசணிக்காய்',
    'ಗೋಮಯ': 'கோமயம்', 'ಗೋಮೂತ್ರ': 'கோமூத்திரம்', 'ಹಾಲು': 'பால்', 'ತುಪ್ಪ': 'நெய்',
    'ಸಕ್ಕರೆ': 'சர்க்கரை', 'ಜೇನುತುಪ್ಪ': 'தேன்', 'ಕಬ್ಬಿನ ಹಾಲು': 'கரும்பு சாறு',
    'ಊದುಬತ್ತಿ': 'ஊதுபத்தி', 'ಕರ್ಪೂರ': 'கற்பூரம்', 'ಹತ್ತಿಬತ್ತಿ ಕಟ್ಟು': 'பருத்தி திரி', 'ದೀಪದ ಎಣ್ಣೆ': 'விளக்கு எண்ணெய்',
    'ಚಕ್ಕೆ ಹೊರೆ': 'பட்டை', 'ಕರಿ ಎಳ್ಳು': 'கருப்பு எள்', 'ಬಿಳಿ ಸಾಸಿವೆ': 'வெள்ளை கடுகு',
    'ಅರಳು': 'பொரி', 'ಭತ್ತ': 'நெல்', 'ಗೋಧಿ': 'கோதுமை', 'ಅವರೆ': 'அவரை',
    'ಉದ್ದು': 'உளுந்து', 'ಕಡಲೆ': 'கடலை', 'ತೊಗರಿ': 'துவரை', 'ಹೆಸರು': 'பாசிப்பருப்பு', 'ಹುರುಳಿ': 'கொள்ளு',
    'ಜಾಯಿಕಾಯಿ': 'ஜாதிக்காய்', 'ಒಣದ್ರಾಕ್ಷಿ': 'உலர் திராக்ஷை', 'ಉತ್ತುತ್ತೆ': 'பாதாம்',
    'ಗೋಡಂಬಿ': 'முந்திரி', 'ಕಾಳು ಮೆಣಸು': 'மிளகு', 'ಲವಂಗ': 'கிராம்பு', 'ಏಲಕ್ಕಿ': 'ஏலக்காய்',
    'ಬೆಲ್ಲ': 'வெல்லம்', 'ಅವಲಕ್ಕಿ': 'அவல்', 'ಬಾಳೆ ಎಲೆ ದೊನ್ನೆ': 'வாழை இலை கிண்ணம்',
    'ಪಟ್ಟೆ ಮಡಿ': 'பட்டே மடி', 'ವೇಷ್ಟಿ ಪಂಚೆ': 'வேஷ்டி', 'ಮುಂಡುಪಂಚೆ': 'முண்டு',
    'ಸೀರೆ': 'புடவை', 'ಕಣ': 'கண்', 'ಶಾಲು': 'ஷால்', 'ಪಾಣಿ ಪಂಚೆ': 'பாணி பஞ்சே', 'ಬಾತ್ ಟವಲ್': 'துண்டு',
    'ಕೊಡಪಾನ': 'கலசம்', 'ತಂಬಿಗೆ': 'செம்பு', 'ಹರಿವಾಣ': 'தட்டு',
    'ಕವಳಿಗೆ ಸೌಟು': 'கரண்டி', 'ಹಿತ್ತಾಳೆ ಬುಟ್ಟಿ': 'பித்தளை கூடை',
    'ಇಟ್ಟಿಗೆ': 'செங்கல்', 'ಹೊಯ್ಗೆ': 'மணல்', 'ಬಾಳೆ ಕಂಬ (ದಿಂಡು)': 'வாழை தண்டு',
    'ಪಂಚರತ್ನ': 'பஞ்சரத்னம்', 'ಕನ್ನಡಿ': 'கண்ணாடி', 'ಗೋಪಿ': 'கோபி சந்தனம்', 'ಬೆಳ್ಳಿ': 'வெள்ளி',
    'ಕಬ್ಬಿನ ಜಲ್ಲೆ': 'கரும்பு', '1 ರೂಪಾಯಿ ನಾಣ್ಯ': '1 ரூபாய் நாணயம்', 'ಚಿಲ್ಲರೆ ರೊಕ್ಕ': 'சில்லறை',
    'ಅಶ್ವತ್ಥ': 'அரசு', 'ಪಾಲಾಶ (ಮುತ್ತುಗ)': 'பலாசம்', 'ಅತ್ತಿ': 'அத்தி',
    'ಕದಿರ': 'கதிர', 'ಶಮಿ': 'ஜமி', 'ದೂರ್ವೆ': 'அருகம்புல்', 'ಎಕ್ಕೆ': 'எருக்கு',
    'ನವಗ್ರಹ ರತ್ನ ಸೆಟ್': 'நவகிரக ரத்ன செட்', 'ಕಾಶಿ ತೀರ್ಥ (1 ಬಾಟಲಿ)': 'காசி தீர்த்தம் (1 பாட்டில்)',
  },
  'te': {
    'ಅಕ್ಕಿ': 'బియ్యం', 'ಅರಿಶಿನ': 'పసుపు', 'ಕುಂಕುಮ': 'కుంకుమ', 'ರಂಗೋಲಿ': 'ముగ్గు',
    'ಹಸಿರು ಬಣ್ಣ': 'ఆకుపచ్చ రంగు', 'ಕಪ್ಪು ಬಣ್ಣ': 'నలుపు రంగు', 'ಇತರ ಬಣ್ಣ': 'ఇతర రంగు', 'ಗಂಧ': 'గంధం',
    'ಶಿಂಗಾರ ಹೂ': 'అలంకార పువ్వు', 'ಇತರ ಹೂ': 'ఇతర పువ్వు', 'ತುಳಸಿ': 'తులసి', 'ಬಿಲ್ವಪತ್ರೆ': 'మారేడు దళం',
    'ದರ್ಬೆ': 'దర్భ', 'ಹಲಸಿನ ಕುಡಿ': 'పనస ఆకు', 'ಮಾವಿನ ಕುಡಿ': 'మామిడి ఆకు',
    'ರಜ್ಜು': 'రజ్జు', 'ನೂಲುಂಡೆ': 'దారం', 'ಜನಿವಾರ': 'యజ్ఞోపవీతం',
    'ವೀಳ್ಯದೆಲೆ ಕಟ್ಟು': 'తమలపాకు', 'ಅಡಿಕೆ': 'పోక', 'ಬಾಳೆ ಎಲೆ': 'అరటి ఆకు',
    'ಬಾಳೆ ಹಣ್ಣು': 'అరటి పండు', 'ಲಿಂಬೆ ಹಣ್ಣು': 'నిమ్మ', 'ಇತರ ಹಣ್ಣು': 'ఇతర పండ్లు',
    'ತೆಂಗಿನ ಕಾಯಿ': 'కొబ్బరికాయ', 'ಸೀಯಾಳ': 'లేత కొబ్బరి', 'ಕುಂಬಳ ಕಾಯಿ': 'గుమ్మడికాయ',
    'ಗೋಮಯ': 'గోమయం', 'ಗೋಮೂತ್ರ': 'గోమూత్రం', 'ಹಾಲು': 'పాలు', 'ತುಪ್ಪ': 'నెయ్యి',
    'ಸಕ್ಕರೆ': 'పంచదార', 'ಜೇನುತುಪ್ಪ': 'తేనె', 'ಕಬ್ಬಿನ ಹಾಲು': 'చెరకు రసం',
    'ಊದುಬತ್ತಿ': 'అగరబత్తి', 'ಕರ್ಪೂರ': 'కర్పూరం', 'ಹತ್ತಿಬತ್ತಿ ಕಟ್ಟು': 'ప్రత్తి వత్తి', 'ದೀಪದ ಎಣ್ಣೆ': 'దీపం నూనె',
    'ಚಕ್ಕೆ ಹೊರೆ': 'దాల్చిన చెక్క', 'ಕರಿ ಎಳ್ಳು': 'నల్ల నువ్వులు', 'ಬಿಳಿ ಸಾಸಿವೆ': 'తెల్ల ఆవాలు',
    'ಅರಳು': 'మురమురాలు', 'ಭತ್ತ': 'వరి', 'ಗೋಧಿ': 'గోధుమ', 'ಅವರೆ': 'చిక్కుడు',
    'ಉದ್ದು': 'మినప', 'ಕಡಲೆ': 'శనగ', 'ತೊಗರಿ': 'కందులు', 'ಹೆಸರು': 'పెసర', 'ಹುರುಳಿ': 'ఉలవలు',
    'ಜಾಯಿಕಾಯಿ': 'జాజికాయ', 'ಒಣದ್ರಾಕ್ಷಿ': 'ఎండు ద్రాక్ష', 'ಉತ್ತುತ್ತೆ': 'బాదం',
    'ಗೋಡಂಬಿ': 'జీడిపప్పు', 'ಕಾಳು ಮೆಣಸು': 'మిరియాలు', 'ಲವಂಗ': 'లవంగాలు', 'ಏಲಕ್ಕಿ': 'ఏలకులు',
    'ಬೆಲ್ಲ': 'బెల్లం', 'ಅವಲಕ್ಕಿ': 'అటుకులు', 'ಬಾಳೆ ಎಲೆ ದೊನ್ನೆ': 'అరటి ఆకు దొప్ప',
    'ಪಟ್ಟೆ ಮಡಿ': 'పట్టె మడి', 'ವೇಷ್ಟಿ ಪಂಚೆ': 'పంచ', 'ಮುಂಡುಪಂಚೆ': 'ముండు',
    'ಸೀರೆ': 'చీర', 'ಕಣ': 'కణం', 'ಶಾಲು': 'షాలు', 'ಪಾಣಿ ಪಂಚೆ': 'పాణి పంచె', 'ಬಾತ್ ಟವಲ್': 'టవల్',
    'ಕೊಡಪಾನ': 'కలశం', 'ತಂಬಿಗೆ': 'చెంబు', 'ಹರಿವಾಣ': 'పళ్ళెం',
    'ಕವಳಿಗೆ ಸೌಟು': 'గరిటె', 'ಹಿತ್ತಾಳೆ ಬುಟ್ಟಿ': 'ఇత్తడి బుట్ట',
    'ಇಟ್ಟಿಗೆ': 'ఇటుక', 'ಹೊಯ್ಗೆ': 'ఇసుక', 'ಬಾಳೆ ಕಂಬ (ದಿಂಡು)': 'అరటి స్తంభం',
    'ಪಂಚರತ್ನ': 'పంచరత్నం', 'ಕನ್ನಡಿ': 'అద్దం', 'ಗೋಪಿ': 'గోపీ చందనం', 'ಬೆಳ್ಳಿ': 'వెండి',
    'ಕಬ್ಬಿನ ಜಲ್ಲೆ': 'చెరకు ముక్క', '1 ರೂಪಾಯಿ ನಾಣ್ಯ': '1 రూపాయి నాణెం', 'ಚಿಲ್ಲರೆ ರೊಕ್ಕ': 'చిల్లర',
    'ಅಶ್ವತ್ಥ': 'రావి', 'ಪಾಲಾಶ (ಮುತ್ತುಗ)': 'పలాశం', 'ಅತ್ತಿ': 'అత్తి',
    'ಕದಿರ': 'ఖదిర', 'ಶಮಿ': 'జమ్మి', 'ದೂರ್ವೆ': 'గరిక', 'ಎಕ್ಕೆ': 'జిల్లేడు',
    'ನವಗ್ರಹ ರತ್ನ ಸೆಟ್': 'నవగ్రహ రత్న సెట్', 'ಕಾಶಿ ತೀರ್ಥ (1 ಬಾಟಲಿ)': 'కాశీ తీర్థం (1 బాటిల్)',
  },
  'ml': {
    'ಅಕ್ಕಿ': 'അരി', 'ಅರಿಶಿನ': 'മഞ്ഞൾ', 'ಕುಂಕುಮ': 'കുങ്കുമം', 'ರಂಗೋಲಿ': 'രംഗോലി',
    'ಹಸಿರು ಬಣ್ಣ': 'പച്ച നിറം', 'ಕಪ್ಪು ಬಣ್ಣ': 'കറുപ്പ് നിറം', 'ಇತರ ಬಣ್ಣ': 'മറ്റ് നിറം', 'ಗಂಧ': 'ചന്ദനം',
    'ಶಿಂಗಾರ ಹೂ': 'അലങ്കാര പൂക്കൾ', 'ಇತರ ಹೂ': 'മറ്റ് പൂക്കൾ', 'ತುಳಸಿ': 'തുളസി', 'ಬಿಲ್ವಪತ್ರೆ': 'കൂവളത്തില',
    'ದರ್ಬೆ': 'ദർഭ', 'ಹಲಸಿನ ಕುಡಿ': 'പ്ലാവില', 'ಮಾವಿನ ಕುಡಿ': 'മാവില',
    'ರಜ್ಜು': 'രജ്ജു', 'ನೂಲುಂಡೆ': 'നൂൽ', 'ಜನಿವಾರ': 'പൂണൂൽ',
    'ವೀಳ್ಯದೆಲೆ ಕಟ್ಟು': 'വെറ്റില', 'ಅಡಿಕೆ': 'അടയ്ക്ക', 'ಬಾಳೆ ಎಲೆ': 'വാഴയില',
    'ಬಾಳೆ ಹಣ್ಣು': 'വാഴപ്പഴം', 'ಲಿಂಬೆ ಹಣ್ಣು': 'ചെറുനാരങ്ങ', 'ಇತರ ಹಣ್ಣು': 'മറ്റ് പഴം',
    'ತೆಂಗಿನ ಕಾಯಿ': 'തേങ്ങ', 'ಸೀಯಾಳ': 'ഇളനീർ', 'ಕುಂಬಳ ಕಾಯಿ': 'മത്തങ്ങ',
    'ಗೋಮಯ': 'ഗോമയം', 'ಗೋಮೂತ್ರ': 'ഗോമൂത്രം', 'ಹಾಲು': 'പാൽ', 'ತುಪ್ಪ': 'നെയ്യ്',
    'ಸಕ್ಕರೆ': 'പഞ്ചസാര', 'ಜೇನುತುಪ್ಪ': 'തേൻ', 'ಕಬ್ಬಿನ ಹಾಲು': 'കരിമ്പിൻ നീര്',
    'ಊದುಬತ್ತಿ': 'ഊദുബത്തി', 'ಕರ್ಪೂರ': 'കർപ്പൂരം', 'ಹತ್ತಿಬತ್ತಿ ಕಟ್ಟು': 'പരുത്തി തിരി', 'ದೀಪದ ಎಣ್ಣೆ': 'വിളക്കെണ്ണ',
    'ಚಕ್ಕೆ ಹೊರೆ': 'ചക്കപ്പട്ട', 'ಕರಿ ಎಳ್ಳು': 'കറുത്ത എള്ള്', 'ಬಿಳಿ ಸಾಸಿವೆ': 'വെളുത്ത കടുക്',
    'ಅರಳು': 'പൊരി', 'ಭತ್ತ': 'നെല്ല്', 'ಗೋಧಿ': 'ഗോതമ്പ്', 'ಅವರೆ': 'അവര',
    'ಉದ್ದು': 'ഉഴുന്ന്', 'ಕಡಲೆ': 'കടല', 'ತೊಗರಿ': 'തുവര', 'ಹೆಸರು': 'ചെറുപയർ', 'ಹುರುಳಿ': 'മുതിര',
    'ಜಾಯಿಕಾಯಿ': 'ജാതിക്ക', 'ಒಣದ್ರಾಕ್ಷಿ': 'ഉണക്ക മുന്തിരി', 'ಉತ್ತುತ್ತೆ': 'ബദാം',
    'ಗೋಡಂಬಿ': 'കശുവണ്ടി', 'ಕಾಳು ಮೆಣಸು': 'കുരുമുളക്', 'ಲವಂಗ': 'ഗ്രാമ്പൂ', 'ಏಲಕ್ಕಿ': 'ഏലക്ക',
    'ಬೆಲ್ಲ': 'ശർക്കര', 'ಅವಲಕ್ಕಿ': 'അവൽ', 'ಬಾಳೆ ಎಲೆ ದೊನ್ನೆ': 'വാഴയില കിണ്ണം',
    'ಪಟ್ಟೆ ಮಡಿ': 'പട്ടെ മടി', 'ವೇಷ್ಟಿ ಪಂಚೆ': 'മുണ്ട്', 'ಮುಂಡುಪಂಚೆ': 'മുണ്ടുപഞ്ചെ',
    'ಸೀರೆ': 'സാരി', 'ಕಣ': 'കണം', 'ಶಾಲು': 'ഷാൾ', 'ಪಾಣಿ ಪಂಚೆ': 'പാണി പഞ്ചെ', 'ಬಾತ್ ಟವಲ್': 'ടവ്വൽ',
    'ಕೊಡಪಾನ': 'കലശം', 'ತಂಬಿಗೆ': 'ചെമ്പ്', 'ಹರಿವಾಣ': 'തട്ടം',
    'ಕವಳಿಗೆ ಸೌಟು': 'തവി', 'ಹಿತ್ತಾಳೆ ಬುಟ್ಟಿ': 'പിച്ചള കൊട്ട',
    'ಇಟ್ಟಿಗೆ': 'ഇഷ്ടിക', 'ಹೊಯ್ಗೆ': 'മണൽ', 'ಬಾಳೆ ಕಂಬ (ದಿಂಡು)': 'വാഴത്തണ്ട്',
    'ಪಂಚರತ್ನ': 'പഞ്ചരത്നം', 'ಕನ್ನಡಿ': 'കണ്ണാടി', 'ಗೋಪಿ': 'ഗോപീ ചന്ദനം', 'ಬೆಳ್ಳಿ': 'വെള്ളി',
    'ಕಬ್ಬಿನ ಜಲ್ಲೆ': 'കരിമ്പ്', '1 ರೂಪಾಯಿ ನಾಣ್ಯ': '1 രൂപ നാണയം', 'ಚಿಲ್ಲರೆ ರೊಕ್ಕ': 'ചില്ലറ',
    'ಅಶ್ವತ್ಥ': 'അരയാൽ', 'ಪಾಲಾಶ (ಮುತ್ತುಗ)': 'പ്ലാശ്', 'ಅತ್ತಿ': 'അത്തി',
    'ಕದಿರ': 'ഖദിര', 'ಶಮಿ': 'ശമി', 'ದೂರ್ವೆ': 'കറുക', 'ಎಕ್ಕೆ': 'എരിക്ക്',
    'ನವಗ್ರಹ ರತ್ನ ಸೆಟ್': 'നവഗ്രഹ രത്ന സെറ്റ്', 'ಕಾಶಿ ತೀರ್ಥ (1 ಬಾಟಲಿ)': 'കാശി തീർഥം (1 ബോട്ടിൽ)',
  },
};

/// Translate a pooja item name from Kannada to current locale
String _trPoojaItem(String knName) {
  final lang = AppLocale.current;
  if (lang == 'kn') return knName;
  return _poojaItemTr[lang]?[knName] ?? knName;
}

List<PoojaItem> _createDefaultItems() {
  return _defaultPoojaItems.map((m) => PoojaItem(
    name: _trPoojaItem(m['n']!),
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
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              // Pre-fill purohit from Settings defaults
              final prefs = await SharedPreferences.getInstance();
              final newList = PoojaList(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                items: [],
                purohitName: prefs.getString('default_jyotishi_name') ?? '',
                purohitPhone: prefs.getString('default_jyotishi_phone') ?? '',
                purohitAddress: prefs.getString('default_jyotishi_address') ?? '',
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
    ..._defaultPoojaItems.map((m) => _trPoojaItem(m['n']!)),
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
    final defaultNames = _defaultPoojaItems.expand((m) => [m['n']!, _trPoojaItem(m['n']!)]).toSet();
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
    // Fall back to Settings defaults if per-list purohit fields are empty
    final prefs = await SharedPreferences.getInstance();
    final nameCtrl = TextEditingController(text: _list.purohitName.isNotEmpty ? _list.purohitName : (prefs.getString('default_jyotishi_name') ?? ''));
    final phoneCtrl = TextEditingController(text: _list.purohitPhone.isNotEmpty ? _list.purohitPhone : (prefs.getString('default_jyotishi_phone') ?? ''));
    final addressCtrl = TextEditingController(text: _list.purohitAddress.isNotEmpty ? _list.purohitAddress : (prefs.getString('default_jyotishi_address') ?? ''));
    final now = DateTime.now();
    final dateCtrl = TextEditingController(text: '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text('${_p('downloadPdf')}', style: TextStyle(fontWeight: FontWeight.w900, color: kText, fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_p('purohit'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
              const SizedBox(height: 4),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: _p('purohitName'), prefixIcon: Icon(Icons.person, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 10),
              TextField(controller: addressCtrl, maxLines: 2, decoration: InputDecoration(labelText: _p('address'), prefixIcon: Icon(Icons.location_on_outlined, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: _p('mobile'), prefixIcon: Icon(Icons.phone, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 14),
              Text(_p('poojaDate'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
              const SizedBox(height: 4),
              TextField(controller: dateCtrl, decoration: InputDecoration(labelText: _p('poojaDate'), prefixIcon: Icon(Icons.calendar_today, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('📋 ${_list.name}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF4A148C))),
                  Text('${_list.items.length} ${_p('itemsDone').split(' ').last}', style: TextStyle(fontSize: 12, color: kMuted)),
                ]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_p('cancel'), style: TextStyle(color: kMuted))),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _list.purohitName = nameCtrl.text.trim();
                _list.purohitPhone = phoneCtrl.text.trim();
                _list.purohitAddress = addressCtrl.text.trim();
              });
              _saveList();
              _generatePoojaPdf(dateCtrl.text.trim(), shareMode: true);
            },
            icon: const Icon(Icons.share, size: 18),
            label: Text(AppLocale.l('pdfShareDirect')),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4A148C), side: BorderSide(color: const Color(0xFF4A148C))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _list.purohitName = nameCtrl.text.trim();
                _list.purohitPhone = phoneCtrl.text.trim();
                _list.purohitAddress = addressCtrl.text.trim();
              });
              _saveList();
              _generatePoojaPdf(dateCtrl.text.trim());
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: Text('PDF ${_p('save')}'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _generatePoojaPdf(String poojaDate, {bool shareMode = false}) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: const Color(0xFF4A148C)),
            const SizedBox(height: 16),
            Text(AppLocale.l('pdfCreating'), style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14, decoration: TextDecoration.none)),
          ]),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      final controller = ScreenshotController();
      const double pageWidth = 793.0;
      const double pageHeight = 1122.0;
      final targetSize = const Size(pageWidth, pageHeight);

      final purple = const Color(0xFF4A148C);
      final grey = const Color(0xFF757575);
      final headerBg = const Color(0xFFF3E5F5);
      final borderColor = const Color(0xFFE0E0E0);
      final altRow = const Color(0xFFFAFAFA);

      // Calculate items per page: page 1 has header (~280px), subsequent pages have small header (~100px)
      // Each item row ~35px, available height page1 ~680px, page2+ ~920px
      const int itemsPerPage1 = 18;
      const int itemsPerPageN = 26;

      final totalItems = _list.items.length;
      final List<List<PoojaItem>> pages = [];

      if (totalItems <= itemsPerPage1) {
        pages.add(_list.items);
      } else {
        pages.add(_list.items.sublist(0, itemsPerPage1));
        int start = itemsPerPage1;
        while (start < totalItems) {
          final end = (start + itemsPerPageN).clamp(0, totalItems);
          pages.add(_list.items.sublist(start, end));
          start = end;
        }
      }

      // Build header for page 1 (purohit left, logo center, date right)
      Widget buildPage1Header() {
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Purohit info
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_list.purohitName.isNotEmpty)
                        Text(_list.purohitName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: purple)),
                      if (_list.purohitAddress.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 2), child: Text(_list.purohitAddress, style: TextStyle(fontSize: 10, color: grey))),
                      if (_list.purohitPhone.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 2), child: Text('📞 ${_list.purohitPhone}', style: TextStyle(fontSize: 11, color: const Color(0xFF1565C0)))),
                    ],
                  ),
                ),
                // Center: Logo + App name + Pooja name
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.png', width: 48, height: 48),
                      const SizedBox(height: 4),
                      Text(trAll(AppLocale.l('appName')), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: purple)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: headerBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: purple.withOpacity(0.2)),
                        ),
                        child: Text(_list.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: purple)),
                      ),
                    ],
                  ),
                ),
                // Right: Pooja date
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (poojaDate.isNotEmpty) ...[
                        Text(_p('poojaDate'), style: TextStyle(fontSize: 10, color: grey, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(poojaDate, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: purple)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(thickness: 1, color: borderColor),
          ],
        );
      }

      // Build header for page 2+ (just logo + pooja name)
      Widget buildPageNHeader() {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 32, height: 32),
                const SizedBox(width: 10),
                Text(_list.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: purple)),
              ],
            ),
            const SizedBox(height: 8),
            Divider(thickness: 0.5, color: borderColor),
          ],
        );
      }

      // Build table header row
      Widget buildTableHeader() {
        return Container(
          decoration: BoxDecoration(color: headerBg),
          child: Row(children: [
            SizedBox(width: 40, child: Padding(padding: const EdgeInsets.all(8), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
            Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(8), child: Text(_p('itemName'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
            Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(8), child: Text(_p('quantity'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          ]),
        );
      }

      // Build item rows
      Widget buildItemRows(List<PoojaItem> items, int startIdx) {
        return Column(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final idx = startIdx + i;
            return Container(
              decoration: BoxDecoration(
                color: idx % 2 == 0 ? Colors.white : altRow,
                border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
              ),
              child: Row(children: [
                SizedBox(width: 40, child: Padding(padding: const EdgeInsets.all(8), child: Text('${idx + 1}', style: TextStyle(fontSize: 11, color: grey)))),
                Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(8), child: Text(item.name, style: const TextStyle(fontSize: 11)))),
                Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(8), child: Text(item.quantity, style: TextStyle(fontSize: 11, color: grey)))),
              ]),
            );
          }),
        );
      }

      // Footer
      Widget buildFooter() {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_list.items.length} ${_p('itemsDone').split(' ').last}', style: TextStyle(fontSize: 10, color: grey)),
            Text(trAll(AppLocale.l('appName')), style: TextStyle(fontSize: 9, color: grey)),
          ],
        );
      }

      final doc = pw.Document();

      for (int p = 0; p < pages.length; p++) {
        final isFirstPage = p == 0;
        final pageItems = pages[p];
        final startIdx = isFirstPage ? 0 : itemsPerPage1 + (p - 1) * itemsPerPageN;

        final pageWidget = Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Material(
              color: Colors.white,
              child: Container(
                width: pageWidth,
                height: pageHeight,
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirstPage) buildPage1Header() else buildPageNHeader(),
                    const SizedBox(height: 8),
                    buildTableHeader(),
                    buildItemRows(pageItems, startIdx),
                    const Spacer(),
                    buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        );

        final Uint8List imageBytes = await controller.captureFromWidget(
          pageWidget,
          targetSize: targetSize,
          pixelRatio: 2.5,
          delay: const Duration(milliseconds: 10),
        );

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      if (shareMode) {
        await Printing.sharePdf(bytes: await doc.save(), filename: '${_list.name}_list.pdf');
      } else {
        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save(), name: '${_list.name}_list.pdf');
      }
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
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
