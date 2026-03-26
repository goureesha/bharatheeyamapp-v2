/// Comprehensive offline place database
/// Karnataka Taluks + Major Indian cities + World capitals

const Map<String, List<double>> karnatakaPlaces = {
  // ─── Bagalkot District ───
  'ಬಾಗಲಕೋಟ (Bagalkot)': [16.18, 75.70],
  'ಬಾದಾಮಿ (Badami)': [15.92, 75.68],
  'ಬೀಳಗಿ (Bilagi)': [16.35, 75.62],
  'ಹುನಗುಂದ (Hungund)': [16.06, 76.06],
  'ಜಮಖಂಡಿ (Jamkhandi)': [16.50, 75.29],
  'ಮುಧೋಳ (Mudhol)': [16.33, 75.28],

  // ─── Bangalore Urban ───
  'ಬೆಂಗಳೂರು ಉತ್ತರ (Bangalore North)': [13.02, 77.59],
  'ಬೆಂಗಳೂರು ದಕ್ಷಿಣ (Bangalore South)': [12.90, 77.58],
  'ಅನೆಕಲ್ (Anekal)': [12.71, 77.70],

  // ─── Bangalore Rural ───
  'ದೇವನಹಳ್ಳಿ (Devanahalli)': [13.25, 77.71],
  'ದೊಡ್ಡಬಳ್ಳಾಪುರ (Doddaballapur)': [13.29, 77.54],
  'ಹೊಸಕೋಟೆ (Hoskote)': [13.07, 77.80],
  'ನೆಲಮಂಗಲ (Nelamangala)': [13.10, 77.39],

  // ─── Belagavi (Belgaum) District ───
  'ಬೆಳಗಾವಿ (Belagavi)': [15.85, 74.50],
  'ಅಥಣಿ (Athani)': [16.72, 75.06],
  'ಬೈಲಹೊಂಗಲ (Bailhongal)': [15.81, 74.86],
  'ಚಿಕ್ಕೋಡಿ (Chikkodi)': [16.43, 74.59],
  'ಗೋಕಾಕ (Gokak)': [16.17, 74.82],
  'ಹುಕ್ಕೇರಿ (Hukkeri)': [16.23, 74.60],
  'ಖಾನಾಪುರ (Khanapur)': [15.64, 74.51],
  'ರಾಮದುರ್ಗ (Ramdurg)': [15.95, 75.29],
  'ರಾಯಬಾಗ (Raybag)': [16.49, 74.77],
  'ಸವದತ್ತಿ (Savadatti)': [15.77, 75.34],

  // ─── Bellary District ───
  'ಬಳ್ಳಾರಿ (Bellary)': [15.14, 76.92],
  'ಹೊಸಪೇಟೆ (Hospet)': [15.27, 76.39],
  'ಕೂಡ್ಲಿಗಿ (Kudligi)': [14.90, 76.39],
  'ಸಂಡೂರ (Sandur)': [15.09, 76.55],
  'ಸಿರುಗುಪ್ಪ (Siruguppa)': [15.63, 76.90],
  'ಹಡಗಲಿ (Hadagali)': [15.02, 75.93],
  'ಹಗರಿಬೊಮ್ಮನಹಳ್ಳಿ (Hagaribommanahalli)': [15.04, 76.21],

  // ─── Bidar District ───
  'ಬೀದರ (Bidar)': [17.91, 77.52],
  'ಔರಾದ (Aurad)': [18.25, 77.42],
  'ಬಸವಕಲ್ಯಾಣ (Basavakalyan)': [17.87, 76.95],
  'ಭಾಲ್ಕಿ (Bhalki)': [18.04, 77.21],
  'ಹುಮನಾಬಾದ (Humnabad)': [17.77, 77.14],

  // ─── Chamarajanagar District ───
  'ಚಾಮರಾಜನಗರ (Chamarajanagar)': [11.92, 76.94],
  'ಗುಂಡ್ಲುಪೇಟೆ (Gundlupet)': [11.80, 76.69],
  'ಕೊಳ್ಳೇಗಾಲ (Kollegal)': [12.15, 77.11],
  'ಯಳಂದೂರು (Yelandur)': [12.06, 77.03],

  // ─── Chikballapur District ───
  'ಚಿಕ್ಕಬಳ್ಳಾಪುರ (Chikballapur)': [13.44, 77.73],
  'ಬಾಗೇಪಲ್ಲಿ (Bagepalli)': [13.78, 77.79],
  'ಚಿಂತಾಮಣಿ (Chintamani)': [13.40, 78.05],
  'ಗೌರಿಬಿದನೂರು (Gauribidanur)': [13.61, 77.52],
  'ಗುಡಿಬಂಡೆ (Gudibande)': [13.62, 77.70],
  'ಶಿಡ್ಲಘಟ್ಟ (Sidlaghatta)': [13.39, 77.86],

  // ─── Chikkamagalur District ───
  'ಚಿಕ್ಕಮಗಳೂರು (Chikmagalur)': [13.32, 75.77],
  'ಕಡೂರು (Kadur)': [13.55, 76.01],
  'ಕೊಪ್ಪ (Koppa)': [13.53, 75.35],
  'ಮೂಡಿಗೆರೆ (Mudigere)': [13.13, 75.64],
  'ನರಸಿಂಹರಾಜಪುರ (NR Pura)': [13.60, 75.52],
  'ಶೃಂಗೇರಿ (Sringeri)': [13.42, 75.25],
  'ತರೀಕೆರೆ (Tarikere)': [13.71, 75.81],

  // ─── Chitradurga District ───
  'ಚಿತ್ರದುರ್ಗ (Chitradurga)': [14.22, 76.40],
  'ಚಲ್ಲಕೆರೆ (Challakere)': [14.32, 76.65],
  'ಹಿರಿಯೂರು (Hiriyur)': [13.94, 76.62],
  'ಹೊಳಲ್ಕೆರೆ (Holalkere)': [14.04, 76.18],
  'ಹೊಸದುರ್ಗ (Hosadurga)': [13.80, 76.29],
  'ಮೊಳಕಾಲ್ಮುರು (Molakalmuru)': [14.72, 76.75],

  // ─── Dakshina Kannada District ───
  'ಮಂಗಳೂರು (Mangalore)': [12.91, 74.86],
  'ಬಂಟ್ವಾಳ (Bantwal)': [12.89, 75.03],
  'ಬೆಳ್ತಂಗಡಿ (Belthangady)': [12.97, 75.30],
  'ಕಡಬ (Kadaba)': [12.76, 75.21],
  'ಪುತ್ತೂರು (Puttur)': [12.76, 75.20],
  'ಸುಳ್ಯ (Sullia)': [12.56, 75.39],

  // ─── Davanagere District ───
  'ದಾವಣಗೆರೆ (Davanagere)': [14.46, 75.92],
  'ಚನ್ನಗಿರಿ (Channagiri)': [14.02, 75.93],
  'ಹರಿಹರ (Harihar)': [14.52, 75.81],
  'ಹೊನ್ನಾಳಿ (Honnali)': [14.24, 75.65],
  'ಜಗಳೂರು (Jagalur)': [14.52, 76.34],

  // ─── Dharwad District ───
  'ಧಾರವಾಡ (Dharwad)': [15.46, 75.01],
  'ಹುಬ್ಬಳ್ಳಿ (Hubli)': [15.36, 75.12],
  'ಕಲಘಟಗಿ (Kalghatgi)': [15.18, 75.07],
  'ಕುಂದಗೋಳ (Kundgol)': [15.26, 75.25],
  'ನವಲಗುಂದ (Navalgund)': [15.57, 75.37],

  // ─── Gadag District ───
  'ಗದಗ (Gadag)': [15.43, 75.63],
  'ಮುಂಡರಗಿ (Mundargi)': [15.21, 75.88],
  'ನರಗುಂದ (Nargund)': [15.72, 75.38],
  'ರೋಣ (Ron)': [15.69, 75.73],
  'ಶಿರಹಟ್ಟಿ (Shirahatti)': [15.23, 75.57],

  // ─── Gulbarga (Kalaburagi) District ───
  'ಕಲಬುರಗಿ (Kalaburagi)': [17.33, 76.83],
  'ಆಳಂದ (Aland)': [17.57, 76.57],
  'ಅಫಜಲಪುರ (Afzalpur)': [17.20, 76.36],
  'ಚಿಂಚೋಳಿ (Chincholi)': [17.47, 77.42],
  'ಚಿತ್ತಾಪುರ (Chittapur)': [17.12, 77.09],
  'ಜೇವರ್ಗಿ (Jevargi)': [16.90, 76.77],
  'ಸೇಡಂ (Sedam)': [17.18, 77.27],

  // ─── Hassan District ───
  'ಹಾಸನ (Hassan)': [13.01, 76.10],
  'ಅಲೂರು (Alur)': [12.97, 75.99],
  'ಅರಕಲಗೂಡು (Arkalgud)': [12.76, 76.06],
  'ಅರಸೀಕೆರೆ (Arsikere)': [13.31, 76.26],
  'ಬೇಲೂರು (Belur)': [13.16, 75.87],
  'ಚನ್ನರಾಯಪಟ್ಟಣ (Channarayapatna)': [12.90, 76.39],
  'ಹೊಳೆನರಸೀಪುರ (Holenarasipura)': [12.79, 76.24],
  'ಸಕಲೇಶಪುರ (Sakleshpur)': [12.94, 75.78],

  // ─── Haveri District ───
  'ಹಾವೇರಿ (Haveri)': [14.79, 75.40],
  'ಬ್ಯಾಡಗಿ (Byadgi)': [14.67, 75.49],
  'ಹಾನಗಲ್ (Hangal)': [14.77, 75.12],
  'ಹಿರೇಕೆರೂರ (Hirekerur)': [14.46, 75.40],
  'ರಾಣೆಬೆನ್ನೂರ (Ranebennur)': [14.62, 75.63],
  'ಸವಣೂರ (Savanur)': [14.98, 75.33],
  'ಶಿಗ್ಗಾಂವ (Shiggaon)': [14.99, 75.22],

  // ─── Kodagu District ───
  'ಮಡಿಕೇರಿ (Madikeri)': [12.42, 75.74],
  'ಸೋಮವಾರಪೇಟೆ (Somwarpet)': [12.59, 75.86],
  'ವಿರಾಜಪೇಟೆ (Virajpet)': [12.20, 75.80],

  // ─── Kolar District ───
  'ಕೋಲಾರ (Kolar)': [13.14, 78.13],
  'ಬಂಗಾರಪೇಟೆ (Bangarapet)': [12.99, 78.18],
  'ಕೆ.ಜಿ.ಎಫ್ (KGF)': [12.96, 78.27],
  'ಮಾಲೂರು (Malur)': [13.00, 77.94],
  'ಮುಳಬಾಗಿಲು (Mulbagal)': [13.17, 78.39],
  'ಶ್ರೀನಿವಾಸಪುರ (Srinivaspur)': [13.34, 78.21],

  // ─── Koppal District ───
  'ಕೊಪ್ಪಳ (Koppal)': [15.35, 76.15],
  'ಗಂಗಾವತಿ (Gangavathi)': [15.43, 76.53],
  'ಕುಷ್ಟಗಿ (Kushtagi)': [15.76, 76.19],
  'ಯಲಬುರ್ಗಾ (Yelburga)': [15.59, 76.01],

  // ─── Mandya District ───
  'ಮಂಡ್ಯ (Mandya)': [12.52, 76.90],
  'ಕೆ.ಆರ್.ಪೇಟೆ (KR Pet)': [12.66, 76.49],
  'ಮದ್ದೂರು (Maddur)': [12.58, 77.05],
  'ಮಳವಳ್ಳಿ (Malavalli)': [12.39, 77.06],
  'ನಾಗಮಂಗಲ (Nagamangala)': [12.82, 76.76],
  'ಪಾಂಡವಪುರ (Pandavapura)': [12.49, 76.68],
  'ಶ್ರೀರಂಗಪಟ್ಟಣ (Srirangapatna)': [12.42, 76.69],

  // ─── Mysore District ───
  'ಮೈಸೂರು (Mysore)': [12.30, 76.64],
  'ಹುಣಸೂರು (Hunsur)': [12.30, 76.29],
  'ಕೆ.ಆರ್.ನಗರ (KR Nagar)': [12.43, 76.39],
  'ನಂಜನಗೂಡು (Nanjangud)': [12.12, 76.68],
  'ಪಿರಿಯಾಪಟ್ಟಣ (Piriyapatna)': [12.34, 76.10],
  'ತಿ.ನರಸೀಪುರ (T Narasipura)': [12.21, 76.90],
  'ಎಚ್.ಡಿ.ಕೋಟೆ (HD Kote)': [12.09, 76.33],

  // ─── Raichur District ───
  'ರಾಯಚೂರು (Raichur)': [16.21, 77.35],
  'ದೇವದುರ್ಗ (Devadurga)': [15.99, 76.64],
  'ಲಿಂಗಸುಗೂರು (Lingsugur)': [16.16, 76.52],
  'ಮಾನ್ವಿ (Manvi)': [15.99, 77.05],
  'ಸಿಂಧನೂರು (Sindhanur)': [15.77, 76.76],

  // ─── Ramanagar District ───
  'ರಾಮನಗರ (Ramanagar)': [12.72, 77.28],
  'ಚನ್ನಪಟ್ಟಣ (Channapatna)': [12.65, 77.21],
  'ಕನಕಪುರ (Kanakapura)': [12.55, 77.42],
  'ಮಾಗಡಿ (Magadi)': [12.96, 77.23],

  // ─── Shimoga District ───
  'ಶಿವಮೊಗ್ಗ (Shimoga)': [13.93, 75.57],
  'ಭದ್ರಾವತಿ (Bhadravathi)': [13.83, 75.71],
  'ಹೊಸನಗರ (Hosanagar)': [13.90, 75.07],
  'ಸಾಗರ (Sagar)': [14.17, 75.02],
  'ಶಿಕಾರಿಪುರ (Shikaripura)': [14.27, 75.35],
  'ಸೊರಬ (Sorab)': [14.38, 75.09],
  'ತೀರ್ಥಹಳ್ಳಿ (Thirthahalli)': [13.69, 75.24],

  // ─── Tumkur District ───
  'ತುಮಕೂರು (Tumkur)': [13.34, 77.12],
  'ಚಿಕ್ಕನಾಯಕನಹಳ್ಳಿ (CN Halli)': [13.39, 76.62],
  'ಗುಬ್ಬಿ (Gubbi)': [13.31, 76.94],
  'ಕುಣಿಗಲ್ (Kunigal)': [13.02, 77.03],
  'ಮಧುಗಿರಿ (Madhugiri)': [13.66, 77.21],
  'ಪಾವಗಡ (Pavagada)': [14.10, 77.28],
  'ಸಿರಾ (Sira)': [13.74, 76.90],
  'ತಿಪಟೂರು (Tiptur)': [13.26, 76.48],
  'ತುರುವೆಕೆರೆ (Turuvekere)': [13.16, 76.67],
  'ಕೊರಟಗೆರೆ (Koratagere)': [13.52, 77.24],

  // ─── Udupi District ───
  'ಉಡುಪಿ (Udupi)': [13.34, 74.74],
  'ಕಾರ್ಕಳ (Karkala)': [13.22, 74.99],
  'ಕುಂದಾಪುರ (Kundapura)': [13.63, 74.69],

  // ─── Uttara Kannada District ───
  'ಕಾರವಾರ (Karwar)': [14.81, 74.13],
  'ಅಂಕೋಲ (Ankola)': [14.66, 74.30],
  'ಭಟ್ಕಳ (Bhatkal)': [13.97, 74.56],
  'ಹಳಿಯಾಳ (Haliyal)': [15.33, 74.76],
  'ಹೊನ್ನಾವರ (Honnavar)': [14.28, 74.44],
  'ಜೋಯಿಡಾ (Joida)': [15.28, 74.48],
  'ಕುಮಟ (Kumta)': [14.43, 74.41],
  'ಮುಂಡಗೋಡ (Mundgod)': [14.97, 75.04],
  'ಸಿದ್ದಾಪುರ (Siddapur)': [14.35, 74.89],
  'ಸಿರ್ಸಿ (Sirsi)': [14.62, 74.83],
  'ಯಲ್ಲಾಪುರ (Yellapur)': [14.98, 74.73],

  // ─── Vijayapura (Bijapur) District ───
  'ವಿಜಯಪುರ (Vijayapura)': [16.83, 75.71],
  'ಬಸವನ ಬಾಗೇವಾಡಿ (Basavana Bagevadi)': [16.57, 75.97],
  'ಇಂಡಿ (Indi)': [17.18, 75.96],
  'ಮುದ್ದೇಬಿಹಾಳ (Muddebihal)': [16.34, 76.14],
  'ಸಿಂದಗಿ (Sindagi)': [16.92, 76.23],

  // ─── Yadgir District ───
  'ಯಾದಗಿರಿ (Yadgir)': [16.77, 77.14],
  'ಶಹಾಪುರ (Shahapur)': [16.70, 76.84],
  'ಸುರಪುರ (Shorapur)': [16.52, 76.76],

  // ─── Vijayanagar District (new) ───
  'ಹೊಸಪೇಟೆ (Hosapete)': [15.27, 76.39],
  'ಹಂಪಿ (Hampi)': [15.33, 76.46],

  // ─── Bijapur Taluk area extras ───
  'ಬಾಬಲೇಶ್ವರ (Babaleshwar)': [16.98, 75.91],
};

const Map<String, List<double>> otherPlaces = {
  // ─── Other Indian Major Cities ───
  'Hyderabad': [17.39, 78.49],
  'Chennai': [13.08, 80.27],
  'Mumbai': [19.08, 72.88],
  'Delhi': [28.70, 77.10],
  'Kolkata': [22.57, 88.36],
  'Pune': [18.52, 73.86],
  'Ahmedabad': [23.02, 72.57],
  'Jaipur': [26.91, 75.79],
  'Lucknow': [26.85, 80.95],
  'Bhopal': [23.26, 77.41],
  'Coimbatore': [11.01, 76.96],
  'Madurai': [9.92, 78.12],
  'Kochi': [9.93, 76.27],
  'Thiruvananthapuram': [8.52, 76.94],
  'Visakhapatnam': [17.69, 83.22],
  'Vijayawada': [16.51, 80.65],
  'Tirupati': [13.63, 79.42],
  'Nagpur': [21.15, 79.09],
  'Surat': [21.17, 72.83],
  'Varanasi': [25.32, 82.97],
  'Patna': [25.61, 85.14],
  'Chandigarh': [30.73, 76.77],
  'Goa (Panaji)': [15.50, 73.83],

  // ─── World Capitals ───
  'London (UK)': [51.51, -0.13],
  'New York (USA)': [40.71, -74.01],
  'Dubai (UAE)': [25.20, 55.27],
  'Singapore': [1.35, 103.82],
  'Sydney (Australia)': [-33.87, 151.21],
  'Toronto (Canada)': [43.65, -79.38],
  'Tokyo (Japan)': [35.68, 139.69],
  'Colombo (Sri Lanka)': [6.93, 79.84],
  'Kathmandu (Nepal)': [27.72, 85.32],
};

/// Combined offline places map
final Map<String, List<double>> offlinePlaces = {
  ...karnatakaPlaces,
  ...otherPlaces,
};

/// Known timezone offsets for international cities (non-IST).
/// All Karnataka + other Indian cities default to 5.5 (IST).
const Map<String, double> _knownTimezones = {
  'London (UK)': 0.0,
  'New York (USA)': -5.0,
  'Dubai (UAE)': 4.0,
  'Singapore': 8.0,
  'Sydney (Australia)': 10.0,
  'Toronto (Canada)': -5.0,
  'Tokyo (Japan)': 9.0,
  'Colombo (Sri Lanka)': 5.5,
  'Kathmandu (Nepal)': 5.75,
};

/// Returns the timezone offset for a known place, or estimates it from longitude.
double getTimezoneForPlace(String placeName, double lon) {
  // Check known international timezones first
  if (_knownTimezones.containsKey(placeName)) {
    return _knownTimezones[placeName]!;
  }
  
  // All known internal offline places (Karnataka + Indian cities) are IST
  if (offlinePlaces.containsKey(placeName) && !_knownTimezones.containsKey(placeName)) {
    return 5.5;
  }
  
  // For online Nominatim searches, check if the place is in India
  final lowerName = placeName.toLowerCase();
  if (lowerName.contains('india') || lowerName.contains('ಭಾರತ')) {
    return 5.5;
  }
  
  // Unknown place: estimate from longitude, rounded to nearest 0.5
  return (lon / 15.0 * 2).round() / 2.0;
}
