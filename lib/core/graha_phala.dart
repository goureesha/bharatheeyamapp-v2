import 'calculator.dart';

/// Graha Phala — per-planet results based on Rashi, Navamsha, Dvadashamsha, Drekkana.
/// Based on Brihat Jataka Chapter 18 (Graha Bhava Phala) and related texts.
class GrahaPhala {
  final String planet;
  final String rashiPhala;
  final String rashiShloka;
  final String navamshaPhala;
  final String dvadashamshaPhala;
  final String drekkanaPhala;
  final String rashi;
  final String navamshaRashi;
  final String dvadamshaRashi;
  final String drekkanaRashi;

  const GrahaPhala({
    required this.planet,
    required this.rashiPhala,
    this.rashiShloka = '',
    required this.navamshaPhala,
    required this.dvadashamshaPhala,
    required this.drekkanaPhala,
    required this.rashi,
    required this.navamshaRashi,
    required this.dvadamshaRashi,
    required this.drekkanaRashi,
  });

  static const _rashiNames = ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕ','ಸಿಂಹ','ಕನ್ಯಾ','ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ'];
  static const _rashiLords = ['Mars','Venus','Mercury','Moon','Sun','Mercury','Venus','Mars','Jupiter','Saturn','Saturn','Jupiter'];

  static int _rashiOf(double lon) => ((lon ~/ 30) % 12).toInt();
  static int _d9Rashi(double lon) {
    final inSign = lon % 30;
    final navPada = (inSign / (30.0 / 9.0)).floor();
    final baseRashi = _rashiOf(lon);
    final fireStart = [0, 3, 6, 9]; // Fire sign starts for each element
    return (fireStart[baseRashi % 4] + navPada) % 12;
  }
  static int _d12Rashi(double lon) {
    final inSign = lon % 30;
    return ((_rashiOf(lon)) + (inSign / 2.5).floor()) % 12;
  }
  static int _d3Rashi(double lon) {
    final dr = lon % 30;
    final d1 = _rashiOf(lon);
    if (dr < 10) return d1;
    if (dr < 20) return (d1 + 4) % 12;
    return (d1 + 8) % 12;
  }

  // ═══════════════════════════════════════
  // RASHI PHALA — Planet in Sign results
  // Brihat Jataka Ch.18 (Rashishiladhyaya)
  // ═══════════════════════════════════════

  // BJ 18.1-4: Sun in signs
  static const _sunShloka = {
    0: 'ख्यातोऽटनोऽल्पधनधान्यसुतः प्रतापी शूरश्च मेषगतभानौ',
    1: 'वस्त्रगन्धोपजीवी स्त्रीद्वेषी गीतवाद्यनिपुणो वृषभे',
    2: 'व्याकरणज्ञो दैवज्ञो धनी मिथुने भानौ',
    3: 'सेवावृत्तिर्दरिद्रः क्रूरश्चन्द्रर्क्षे रवौ',
    4: 'वनचरो बलवान् मूर्खो भानौ सिंहगते',
    5: 'स्त्रैणो यन्त्रज्ञो विषभीतिः कन्यागते भानौ',
    6: 'सुराविक्रयी पण्यजीवी परस्त्रीरतो नीचस्तुलागते',
    7: 'दुःखी विमानितो बद्धो वृश्चिके रवौ',
    8: 'धनवान् मन्त्रवित् सपुत्रो धन्वीशे भानौ',
    9: 'धननाशो पितृवियोगो मकरे भानौ',
    10: 'नीचः सुतभाग्यपरिच्युतोऽस्वो घटे',
    11: 'तोयोत्थपण्यविभवो वनितादृतोऽन्त्ये',
  };

  // BJ 18.5-8: Moon in signs
  static const _moonShloka = {
    0: 'अल्पधनो विकलश्चपलो मेषे शशिनि',
    1: 'सुभगो धनवान् भोगी वृषभे शशिनि',
    2: 'विद्वान् कलाप्रियो रसिको मिथुने चन्द्रे',
    3: 'स्थिरमनाः गृहसुखी जलप्रीतिः कर्कटे चन्द्रे',
    4: 'उदारः क्रोधी वनप्रियः सिंहे शशिनि',
    5: 'विनयी परसेवकः कन्यायां चन्द्रे',
    6: 'कामुको रूपवान् वणिक् तुलायां चन्द्रे',
    7: 'ईर्ष्यालुः कलहप्रियो वृश्चिके शशिनि',
    8: 'साहसी धीरो यात्राप्रियो धनुषि चन्द्रे',
    9: 'कष्टशीलो कृषिकारो मकरे शशिनि',
    10: 'पापी मद्यपो स्त्रीलोलः कुम्भे चन्द्रे',
    11: 'रूपवान् धार्मिको विद्वान् सुखी मीने शशिनि',
  };

  // BJ 18.9-12: Mars in signs
  static const _marsShloka = {
    0: 'सेनाधिपो धैर्यवान् व्रणचिह्नो मेषे कुजे',
    1: 'स्त्रीप्रियः कृषिकारः स्थिरो वृषभे भौमे',
    2: 'क्रूरो मेधावी शास्त्रज्ञो मिथुने कुजे',
    3: 'गृहकलहो धननाशश्च कर्कटे कुजे',
    4: 'शत्रुजयी वनवासी सिंहे भौमे',
    5: 'शत्रुभयं रोगः चिन्ता कन्यायां कुजे',
    6: 'कामी रोगी शस्त्रभीतिः तुलायां कुजे',
    7: 'रोगी परस्त्रीसङ्गी वृश्चिके कुजे',
    8: 'सेनापतिर्धनयशश्च धनुषि भौमे',
    9: 'धर्मनिष्ठः कार्यसिद्धिः मकरे कुजे',
    10: 'क्रूरो धननाशश्चोरभयं कुम्भे कुजे',
    11: 'जलभयं रोगो दुःखं मीने भौमे',
  };

  // BJ 18.13-15: Mercury in signs
  static const _mercuryShloka = {
    0: 'द्यूतप्रियो मृषावादी चञ्चलो मेषे बुधे',
    1: 'विद्वान् कलाकारो धनी वृषभे बुधे',
    2: 'शास्त्रज्ञो वाग्मी ज्ञानी मिथुने सौम्ये',
    3: 'गीतनृत्यप्रियः सुखी कर्कटे बुधे',
    4: 'मन्त्रविद् यन्त्रज्ञो सिंहे बुधे',
    5: 'शास्त्रपारङ्गतो गणितज्ञो कन्यायां सौम्ये',
    6: 'वाणिज्यकुशलः सङ्गीतरतो तुलायां बुधे',
    7: 'विद्याकीर्तियशस्वी वृश्चिके सौम्ये',
    8: 'कार्यसिद्धिः पराक्रमी धनुषि बुधे',
    9: 'शिल्पी लेखकः कविर्मकरे बुधे',
    10: 'मेधावी धैर्यवान् सङ्घटको कुम्भे सौम्ये',
    11: 'वेदान्ती धार्मिकः सुखी मीने बुधे',
  };

  // BJ 18.16-18: Jupiter in signs
  static const _jupiterShloka = {
    0: 'विद्वान् धनवान् यशस्वी मेषे गुरौ',
    1: 'सुभगो भूमिवाहनधनसम्पन्नो वृषभे गुरौ',
    2: 'वाग्मी बहुश्रुतो राजसम्मानी मिथुने गुरौ',
    3: 'धनवान् मेधावी मन्त्री कर्कटे गुरौ',
    4: 'अल्पसन्तानः शत्रुभयं सिंहे बृहस्पतौ',
    5: 'सेवकः शत्रुः दुःखी कन्यायां गुरौ',
    6: 'वाग्मी विद्वान् सुखी तुलायां बृहस्पतौ',
    7: 'नीचसङ्गो मानभङ्गो वृश्चिके गुरौ',
    8: 'धनपुत्रराजमर्यादा धनुषि गुरौ',
    9: 'राजसेवा धनयशो मकरे बृहस्पतौ',
    10: 'दरिद्रः दुःखी मानहीनः कुम्भे गुरौ',
    11: 'विद्याधनसुखमोक्षः मीने गुरौ',
  };

  // BJ 18.19-21: Venus in signs
  static const _venusShloka = {
    0: 'कामुकः स्त्रीवशो धननाशो मेषे शुक्रे',
    1: 'सुखी धनवान् सुन्दरपत्नी वृषभे शुक्रे',
    2: 'कलाकारो विद्वान् मिथुने भार्गवे',
    3: 'गृहसुखं वाहनं मित्रं कर्कटे शुक्रे',
    4: 'शत्रुः मानहानिः सिंहे शुक्रे',
    5: 'शत्रुजयी धनलाभः कन्यायां भार्गवे',
    6: 'सुखी राजसम्मानः कलाप्रियो तुलायां शुक्रे',
    7: 'मानहानिर्रोगः कलहो वृश्चिके शुक्रे',
    8: 'धनं स्त्रीसुखं वाहनं धनुषि भार्गवे',
    9: 'धननाशः स्त्रीकष्टं मकरे शुक्रे',
    10: 'कामुकः परस्त्रीसङ्गी कुम्भे शुक्रे',
    11: 'धनसुखसङ्गीतप्रीतिः मीने भार्गवे',
  };

  // BJ 18.22-24: Saturn in signs
  static const _saturnShloka = {
    0: 'अटनशीलः क्रूरो रोगी मेषे शनौ',
    1: 'कृषिकारः सेवको मन्दो वृषभे शनौ',
    2: 'मेधावी दुःसङ्गी मिथुने मन्दे',
    3: 'दरिद्रो दुःखी चिन्ताकुलो कर्कटे शनौ',
    4: 'शत्रुवान् वनवासी क्रूरो सिंहे शनौ',
    5: 'रोगी अटनशीलः सेवकः कन्यायां मन्दे',
    6: 'धनविद्यावान् वणिक् तुलायां शनौ',
    7: 'बन्धनं मानहानिर्रोगो वृश्चिके शनौ',
    8: 'धैर्यवान् साहसी यात्राप्रियो धनुषि मन्दे',
    9: 'धर्मनिष्ठः कार्यसिद्धिः मकरे शनौ',
    10: 'नीचकर्मा चौर्यं मृषावादी कुम्भे शनौ',
    11: 'सेवकः कष्टकारी रोगी मीने मन्दे',
  };

  static const _sunInSign = {
    0: 'ಕ್ರೂರ ಕೃತ್ಯ, ಧೈರ್ಯ, ಅಸ್ಥಿರ ಸಂಪತ್ತು', // Mesha
    1: 'ಸಂಗೀತ ಪ್ರಿಯ, ಆಲಸ್ಯ, ಸ್ವಲ್ಪ ಧನ',
    2: 'ವಿದ್ವಾಂಸ, ಜ್ಯೋತಿಷ ಜ್ಞಾನ, ವಾಗ್ಮಿ',
    3: 'ಸೇವಕ ವೃತ್ತಿ, ದರಿದ್ರ, ಕ್ರೂರ',
    4: 'ರಾಜಸೇವೆ, ಪರಾಕ್ರಮ, ಅರಣ್ಯವಾಸ',
    5: 'ಸ್ತ್ರೀ ಸ್ವಭಾವ, ಯಂತ್ರ ಜ್ಞಾನ, ವಿಷ ಭಯ',
    6: 'ಮದ್ಯಪಾನ, ವ್ಯಾಪಾರ, ಪರಸ್ತ್ರೀ ಸಂಗ',
    7: 'ದುಃಖ, ಅಪಮಾನ, ಬಂಧನ',
    8: 'ಧನವಂತ, ಮಂತ್ರವಿದ್ಯೆ, ಸಂತಾನ ಸುಖ',
    9: 'ಧನ ನಷ್ಟ, ಪಿತೃ ವಿಯೋಗ',
    10: 'ಬುದ್ಧಿವಂತ, ಲೋಭಿ, ಅನ್ಯರ ಸೇವೆ',
    11: 'ರೋಗಿ, ದುಃಖಿ, ನೀಚ ಸಂಗ',
  };

  static const _moonInSign = {
    0: 'ಚಂಚಲ, ಸ್ವಲ್ಪ ಧನ, ರಕ್ತ ಸಮಸ್ಯೆ',
    1: 'ಸುಂದರ, ಧನವಂತ, ಭೋಗಿ, ವಿಶಾಲ ಹೃದಯ',
    2: 'ವಿದ್ಯಾವಂತ, ಕಲಾ ಪ್ರಿಯ, ರಸಿಕ',
    3: 'ಸ್ಥಿರ ಮನ, ಗೃಹ ಸುಖ, ಜಲ ಪ್ರೀತಿ',
    4: 'ಉದಾರ, ಕ್ರೋಧಿ, ಅರಣ್ಯ ಪ್ರೀತಿ',
    5: 'ನಮ್ರ, ಪರಸೇವಕ, ದುರ್ಬಲ ದೇಹ',
    6: 'ಕಾಮುಕ, ಸುಂದರ, ವ್ಯಾಪಾರಿ',
    7: 'ಅಸೂಯೆ, ಕಲಹ, ಬಾಧೆ',
    8: 'ಸಾಹಸಿ, ಧೈರ್ಯ, ಪ್ರವಾಸ',
    9: 'ಕಷ್ಟಪಡುವವನು, ವ್ಯವಸಾಯ, ಸ್ವಲ್ಪ ಧನ',
    10: 'ಪಾಪಿ, ಮದ್ಯಪಾನ, ಸ್ತ್ರೀ ಲೋಲ',
    11: 'ಸುಂದರ, ಧಾರ್ಮಿಕ, ವಿದ್ಯಾವಂತ, ಸುಖಿ',
  };

  static const _marsInSign = {
    0: 'ಸೇನಾಧಿಪ, ಧೈರ್ಯ, ಗಾಯ ಚಿಹ್ನೆ',
    1: 'ಹೆಂಡತಿ ಪ್ರೀತಿ, ಕೃಷಿ, ಸ್ಥಿರ',
    2: 'ಕ್ರೂರ, ಬುದ್ಧಿವಂತ, ಶಾಸ್ತ್ರಜ್ಞ',
    3: 'ಗೃಹದಲ್ಲಿ ಕಲಹ, ಧನ ನಷ್ಟ',
    4: 'ಶತ್ರು ಜಯ, ಅರಣ್ಯ ವಾಸ',
    5: 'ಶತ್ರು ಭಯ, ರೋಗ, ಚಿಂತೆ',
    6: 'ಕಾಮುಕ, ರೋಗ, ಶಸ್ತ್ರ ಭಯ',
    7: 'ರೋಗಿ, ಪರಸ್ತ್ರೀ ಸಂಗ',
    8: 'ಸೇನಾಧಿಪ, ಧನ, ಯಶ',
    9: 'ಧರ್ಮನಿಷ್ಠ, ಕಾರ್ಯಸಿದ್ಧಿ',
    10: 'ಕ್ರೂರ, ಧನ ನಷ್ಟ, ಚೋರ ಭಯ',
    11: 'ಜಲ ಭಯ, ರೋಗ, ದುಃಖ',
  };

  static const _mercuryInSign = {
    0: 'ಜೂಜು ಪ್ರಿಯ, ಸುಳ್ಳು, ಚಂಚಲ',
    1: 'ವಿದ್ಯಾವಂತ, ಕಲಾಕಾರ, ಧನವಂತ',
    2: 'ಶಾಸ್ತ್ರಜ್ಞ, ವಾಗ್ಮಿ, ಜ್ಞಾನಿ',
    3: 'ಸಂಗೀತ, ನೃತ್ಯ ಪ್ರಿಯ, ಸುಖಿ',
    4: 'ಮಂತ್ರವಿದ, ಯಂತ್ರಜ್ಞ',
    5: 'ಶಾಸ್ತ್ರ ಪಾರಂಗತ, ಗಣಿತ ಜ್ಞಾನ',
    6: 'ವ್ಯಾಪಾರ ಕುಶಲ, ಸಂಗೀತ',
    7: 'ವಿದ್ಯೆ, ಕೀರ್ತಿ, ಯಶ',
    8: 'ಕಾರ್ಯ ಸಿದ್ಧಿ, ಪರಾಕ್ರಮ',
    9: 'ಶಿಲ್ಪಿ, ಲೇಖಕ, ಕವಿ',
    10: 'ಬುದ್ಧಿವಂತ, ಧೈರ್ಯ, ಸಂಘಟಕ',
    11: 'ವೇದಾಂತಿ, ಧಾರ್ಮಿಕ, ಸುಖಿ',
  };

  static const _jupiterInSign = {
    0: 'ವಿದ್ವಾಂಸ, ಧನವಂತ, ಯಶಸ್ವಿ',
    1: 'ಸುಂದರ, ಧನ, ಭೂಮಿ, ವಾಹನ',
    2: 'ವಾಗ್ಮಿ, ಬಹುಶ್ರುತ, ರಾಜ ಸನ್ಮಾನ',
    3: 'ಧನವಂತ, ಬುದ್ಧಿವಂತ, ಮಂತ್ರಿ',
    4: 'ಅಲ್ಪ ಸಂತಾನ, ಶತ್ರು ಭಯ',
    5: 'ಸೇವಕ, ಶತ್ರು, ದುಃಖ',
    6: 'ವಾಗ್ಮಿ, ವಿದ್ಯಾವಂತ, ಸುಖಿ',
    7: 'ನೀಚ ಸಂಗ, ಅಪಮಾನ',
    8: 'ಧನ, ಪುತ್ರ, ರಾಜ ಮರ್ಯಾದೆ',
    9: 'ರಾಜಸೇವೆ, ಧನ, ಯಶ',
    10: 'ಬಡತನ, ದುಃಖ, ಅವಮಾನ',
    11: 'ವಿದ್ಯಾ, ಧನ, ಸುಖ, ಮೋಕ್ಷ',
  };

  static const _venusInSign = {
    0: 'ಕಾಮುಕ, ಸ್ತ್ರೀ ವಶ, ಧನ ನಷ್ಟ',
    1: 'ಸುಖಿ, ಧನವಂತ, ಸುಂದರ ಪತ್ನಿ',
    2: 'ಕಲಾಕಾರ, ವಿದ್ಯಾವಂತ',
    3: 'ಗೃಹ ಸುಖ, ವಾಹನ, ಮಿತ್ರ',
    4: 'ಶತ್ರು, ಅಪಮಾನ, ಕೆಟ್ಟ ಸ್ತ್ರೀ ಸಂಗ',
    5: 'ಶತ್ರು ಜಯ, ಧನ ಲಾಭ',
    6: 'ಸುಖಿ, ರಾಜ ಸನ್ಮಾನ, ಕಲಾ',
    7: 'ಅಪಮಾನ, ರೋಗ, ಕಲಹ',
    8: 'ಧನ, ಸ್ತ್ರೀ ಸುಖ, ವಾಹನ',
    9: 'ಧನ ನಷ್ಟ, ಸ್ತ್ರೀ ಕಷ್ಟ',
    10: 'ಕಾಮುಕ, ಪರಸ್ತ್ರೀ ಸಂಗ',
    11: 'ಧನ, ಸುಖ, ಸಂಗೀತ ಪ್ರೀತಿ',
  };

  static const _saturnInSign = {
    0: 'ಅಲೆಮಾರಿ, ಕ್ರೂರ, ರೋಗಿ',
    1: 'ಕೃಷಿ, ಸೇವಕ, ಆಲಸ್ಯ',
    2: 'ಬುದ್ಧಿವಂತ, ಕೆಟ್ಟ ಸ್ನೇಹ',
    3: 'ದರಿದ್ರ, ದುಃಖಿ, ಚಿಂತೆ',
    4: 'ಶತ್ರು, ಅರಣ್ಯವಾಸ, ಕ್ರೂರ',
    5: 'ರೋಗಿ, ಅಲೆಮಾರಿ, ಸೇವಕ',
    6: 'ಧನ, ವಿದ್ಯೆ, ವ್ಯಾಪಾರ',
    7: 'ಬಂಧನ, ಅಪಮಾನ, ರೋಗ',
    8: 'ಧೈರ್ಯ, ಸಾಹಸ, ಪ್ರವಾಸ',
    9: 'ಧರ್ಮನಿಷ್ಠ, ಕಾರ್ಯಸಿದ್ಧಿ',
    10: 'ನೀಚ ಕಾರ್ಯ, ಕಳ್ಳತನ, ಸುಳ್ಳು',
    11: 'ಸೇವಕ, ಕಷ್ಟ, ರೋಗ',
  };

  // ═══════════════════════════════════════
  // DREKKANA PHALA — Planet in Drekkana
  // 1st drek: same sign, 2nd: +4, 3rd: +8
  // ═══════════════════════════════════════

  static const _drekPhala = {
    0: 'ಧೈರ್ಯ, ಪರಾಕ್ರಮ, ನಾಯಕತ್ವ', // Mesha
    1: 'ಭೋಗ, ಸುಖ, ಸ್ಥಿರತೆ',
    2: 'ವಿದ್ಯೆ, ಬುದ್ಧಿ, ಸಂವಹನ',
    3: 'ಭಾವುಕತೆ, ಗೃಹ ಪ್ರೀತಿ',
    4: 'ಅಧಿಕಾರ, ಯಶ, ಪ್ರತಿಷ್ಠೆ',
    5: 'ವಿಶ್ಲೇಷಣೆ, ಸೇವೆ, ಆರೋಗ್ಯ',
    6: 'ಸಮತೋಲನ, ಕಲೆ, ನ್ಯಾಯ',
    7: 'ರಹಸ್ಯ, ತೀಕ್ಷ್ಣತೆ, ಪರಿವರ್ತನೆ',
    8: 'ಧರ್ಮ, ಜ್ಞಾನ, ಭಾಗ್ಯ',
    9: 'ಕರ್ತವ್ಯ, ಶ್ರಮ, ಫಲ',
    10: 'ಸ್ವಾತಂತ್ರ್ಯ, ನವೀನತೆ',
    11: 'ಅಧ್ಯಾತ್ಮ, ಕಲ್ಪನೆ, ಮೋಕ್ಷ',
  };

  // ═══════════════════════════════════════
  // NAVAMSHA PHALA — Planet dignity in D9
  // ═══════════════════════════════════════

  static String _navamshaPhalaFor(String pEng, int navR) {
    final lord = _rashiLords[navR];
    final ownSigns = {
      'Sun': {4}, 'Moon': {3}, 'Mars': {0,7}, 'Mercury': {2,5},
      'Jupiter': {8,11}, 'Venus': {1,6}, 'Saturn': {9,10},
    };
    final exalted = {'Sun':0,'Moon':1,'Mars':9,'Mercury':5,'Jupiter':3,'Venus':11,'Saturn':6};
    final debilitated = {'Sun':6,'Moon':7,'Mars':3,'Mercury':11,'Jupiter':9,'Venus':5,'Saturn':0};

    if (exalted[pEng] == navR) return 'ನವಾಂಶ ಉಚ್ಚ — ಅತ್ಯಂತ ಶುಭ ಫಲ, ಬಲಿಷ್ಠ';
    if (debilitated[pEng] == navR) return 'ನವಾಂಶ ನೀಚ — ದುರ್ಬಲ, ಕಷ್ಟ';
    if (ownSigns[pEng]?.contains(navR) == true) return 'ಸ್ವ ನವಾಂಶ — ಸ್ವಬಲ, ಸ್ಥಿರ ಫಲ';
    // Friendly/enemy
    const friends = {
      'Sun': {'Moon','Mars','Jupiter'}, 'Moon': {'Sun','Mercury'},
      'Mars': {'Sun','Moon','Jupiter'}, 'Mercury': {'Sun','Venus'},
      'Jupiter': {'Sun','Moon','Mars'}, 'Venus': {'Mercury','Saturn'},
      'Saturn': {'Mercury','Venus'},
    };
    if (friends[pEng]?.contains(lord) == true) return 'ಮಿತ್ರ ನವಾಂಶ — ಮಧ್ಯಮ ಶುಭ';
    return 'ಶತ್ರು ನವಾಂಶ — ಅಶುಭ ಫಲ, ಅಡಚಣೆ';
  }

  // ═══════════════════════════════════════
  // DVADASHAMSHA PHALA — D12 position
  // Parents, lineage, ancestral karma
  // ═══════════════════════════════════════

  static String _dvadamshaPhalaFor(String pEng, int d12R) {
    final lord = _rashiLords[d12R];
    final ownSigns = {
      'Sun': {4}, 'Moon': {3}, 'Mars': {0,7}, 'Mercury': {2,5},
      'Jupiter': {8,11}, 'Venus': {1,6}, 'Saturn': {9,10},
    };
    if (ownSigns[pEng]?.contains(d12R) == true) return 'ಸ್ವ ದ್ವಾದಶಾಂಶ — ಪಿತೃ/ಮಾತೃ ಸುಖ, ವಂಶ ಗೌರವ';
    const friends = {
      'Sun': {'Moon','Mars','Jupiter'}, 'Moon': {'Sun','Mercury'},
      'Mars': {'Sun','Moon','Jupiter'}, 'Mercury': {'Sun','Venus'},
      'Jupiter': {'Sun','Moon','Mars'}, 'Venus': {'Mercury','Saturn'},
      'Saturn': {'Mercury','Venus'},
    };
    if (friends[pEng]?.contains(lord) == true) return 'ಮಿತ್ರ ದ್ವಾದಶಾಂಶ — ಮಧ್ಯಮ ಪಿತೃ ಸುಖ';
    return 'ಶತ್ರು ದ್ವಾದಶಾಂಶ — ಪಿತೃ ಕಷ್ಟ, ವಂಶ ಸಮಸ್ಯೆ';
  }

  /// Generate GrahaPhala for all 7 planets.
  static List<GrahaPhala> generate(KundaliResult chart) {
    const planetMap = {
      'Sun': 'ರವಿ', 'Moon': 'ಚಂದ್ರ', 'Mars': 'ಕುಜ',
      'Mercury': 'ಬುಧ', 'Jupiter': 'ಗುರು', 'Venus': 'ಶುಕ್ರ', 'Saturn': 'ಶನಿ',
    };
    const signPhalas = {
      'Sun': _sunInSign, 'Moon': _moonInSign, 'Mars': _marsInSign,
      'Mercury': _mercuryInSign, 'Jupiter': _jupiterInSign,
      'Venus': _venusInSign, 'Saturn': _saturnInSign,
    };

    final results = <GrahaPhala>[];
    for (final entry in planetMap.entries) {
      final pEng = entry.key;
      final pKn = entry.value;
      final info = chart.planets[pKn];
      if (info == null) continue;

      final lon = info.longitude;
      final r = _rashiOf(lon);
      final d9r = _d9Rashi(lon);
      final d12r = _d12Rashi(lon);
      final d3r = _d3Rashi(lon);

      const shlokaMap = {
        'Sun': _sunShloka, 'Moon': _moonShloka, 'Mars': _marsShloka,
        'Mercury': _mercuryShloka, 'Jupiter': _jupiterShloka,
        'Venus': _venusShloka, 'Saturn': _saturnShloka,
      };
      results.add(GrahaPhala(
        planet: pKn,
        rashi: _rashiNames[r],
        navamshaRashi: _rashiNames[d9r],
        dvadamshaRashi: _rashiNames[d12r],
        drekkanaRashi: _rashiNames[d3r],
        rashiPhala: signPhalas[pEng]?[r] ?? '',
        rashiShloka: shlokaMap[pEng]?[r] ?? '',
        navamshaPhala: _navamshaPhalaFor(pEng, d9r),
        dvadashamshaPhala: _dvadamshaPhalaFor(pEng, d12r),
        drekkanaPhala: _drekPhala[d3r] ?? '',
      ));
    }
    return results;
  }
}
