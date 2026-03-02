import streamlit as st
import swisseph as swe
import datetime
import math
import json
import os
from geopy.geocoders import Nominatim

# ==========================================
# 1. DATABASE & FILE HANDLING
# ==========================================
DB_FILE = "kundli_db.json"

def load_db():
    if not os.path.exists(DB_FILE):
        return {}
    with open(DB_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def save_db(name, data):
    db = load_db()
    db[name] = data
    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)

# ==========================================
# 2. PAGE CONFIG & MULTI-COLOR THEME
# ==========================================
st.set_page_config(
    page_title="ಭಾರತೀಯಮ್", 
    layout="centered", 
    page_icon="🕉️", 
    initial_sidebar_state="expanded"
)

st.markdown("""
<style>
    @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Kannada:wght@400;600;800&display=swap');
    
    .stApp { 
        background-color: #FFFDF7 !important; 
        font-family: 'Noto Sans Kannada', sans-serif; 
        color: #2D3748 !important; 
    }
    
    .header-box { 
        background: linear-gradient(135deg, #8E2DE2, #4A00E0); 
        color: #FFFFFF !important; 
        padding: 20px; 
        text-align: center; 
        font-weight: 800; 
        font-size: 26px; 
        border-radius: 16px; 
        margin-bottom: 24px; 
        box-shadow: 0 4px 15px rgba(74, 0, 224, 0.3); 
        border-bottom: 4px solid #F6D365; 
        letter-spacing: 1px;
    }
    
    div[data-testid="stInput"] { 
        background-color: #FFFFFF; 
        border-radius: 10px; 
    }
    
    .stButton>button[kind="primary"] { 
        background: linear-gradient(135deg, #DD6B20, #C05621) !important;
        color: white !important; 
        font-weight: 800; 
        border-radius: 12px; 
        border: none; 
        padding: 12px; 
        box-shadow: 0 4px 10px rgba(221, 107, 32, 0.3);
    }
    
    .stButton>button[kind="secondary"] { 
        background-color: #E6FFFA !important; 
        color: #319795 !important; 
        font-weight: 800; 
        border: 2px solid #319795 !important; 
        border-radius: 12px; 
    }
    
    div[data-testid="stTabs"] button[aria-selected="false"] p { 
        color: #718096 !important; 
        font-weight: 600 !important; 
    }
    div[data-testid="stTabs"] button[aria-selected="true"] p { 
        color: #047857 !important; 
        font-weight: 800 !important; 
    }
    div[data-testid="stTabs"] button[aria-selected="true"] { 
        border-bottom: 3px solid #047857 !important; 
    }
    
    div[data-testid="stRadio"] label p {
        font-weight: 800 !important;
        color: #2B6CB0 !important;
        font-size: 15px !important;
    }

    div[data-testid="stToggle"] label p {
        font-weight: 800 !important;
        color: #2B6CB0 !important;
        font-size: 15px !important;
        white-space: normal !important;
    }
    
    .grid-container { 
        display: grid; 
        grid-template-columns: repeat(4, 1fr); 
        grid-template-rows: repeat(4, 1fr); 
        width: 100%; max-width: 400px; 
        aspect-ratio: 1 / 1; 
        margin: 0 auto; gap: 4px; 
        background: #E2E8F0; 
        border: 4px solid #E2E8F0; 
        border-radius: 12px; 
        box-shadow: 0 4px 15px rgba(0,0,0,0.05);
    }
    .box { 
        background: #FFFFFF; 
        position: relative; 
        display: flex; 
        flex-direction: column; 
        align-items: center; 
        justify-content: flex-start; 
        padding: 22px 2px 2px 2px; 
        font-size: 12px; 
        font-weight: 800; 
        text-align: center; 
        border-radius: 8px;
        box-shadow: inset 0 0 5px rgba(0,0,0,0.02);
        overflow-y: auto; 
    }
    
    /* Scrollbar styling for small boxes */
    .box::-webkit-scrollbar {
        width: 4px;
    }
    .box::-webkit-scrollbar-track {
        background: transparent;
    }
    .box::-webkit-scrollbar-thumb {
        background-color: #CBD5E0;
        border-radius: 4px;
    }
    
    .center-box { 
        grid-column: 2/4; 
        grid-row: 2/4; 
        background: linear-gradient(135deg, #F6D365 0%, #FDA085 100%); 
        display: flex; 
        flex-direction: column; 
        align-items: center; 
        justify-content: center; 
        color: #742A2A !important; 
        font-weight: 900; 
        text-align: center; 
        font-size: 15px; 
        border-radius: 8px;
        border: 2px solid #FFFFFF;
        padding: 0px;
        overflow-y: hidden;
    }
    
    .lbl { 
        position: absolute; top: 3px; left: 5px; 
        font-size: 10px; color: #2F855A !important; 
        font-weight: 900; 
        background: #FFFFFF;
        padding-right: 4px;
        border-radius: 2px;
        z-index: 2;
    }
    .hi { color: #E53E3E !important; font-weight: 900; text-decoration: underline; margin-bottom: 2px; z-index: 1;} 
    .pl { color: #2B6CB0 !important; font-weight: 800; margin-bottom: 2px; z-index: 1;} 
    .sp { color: #805AD5 !important; font-weight: 800; font-size: 11px; margin-bottom: 2px; z-index: 1;} 
    .bindu { font-size: 22px; color: #DD6B20 !important; font-weight: 900; }
    
    .card { 
        background: #FFFFFF; border-radius: 16px; padding: 20px; 
        margin-bottom: 16px; border: 1px solid #E2E8F0; 
        box-shadow: 0 4px 16px rgba(0,0,0,0.03); 
    }
    .key { color: #4A5568 !important; font-weight: 800; width: 45%; }
    .key-val-table td { 
        border-bottom: 1px solid #EDF2F7; 
        padding: 12px 6px; color: #2D3748 !important; 
        font-size: 14px;
    }
    .key-val-table th {
        border-bottom: 2px solid #EDF2F7;
        padding: 12px 6px; color: #2D3748 !important;
        font-size: 14px; text-align: left;
    }
    
    .bav-table th {
        background-color: #EDF2F7;
        color: #2D3748;
        padding: 6px 2px;
        font-size: 11px;
    }
    .bav-table td {
        padding: 8px 2px;
        font-size: 12px;
        border-bottom: 1px solid #EDF2F7;
    }
    
    details { 
        margin-bottom: 8px; border: 1px solid #EDF2F7; 
        border-radius: 10px; overflow: hidden; background: #FFFFFF; 
    }
    summary { 
        padding: 14px; font-size: 14px; 
        border-bottom: 1px solid #EDF2F7; color: #2D3748 !important; 
        cursor: pointer;
    }
    
    .md-node { 
        background: linear-gradient(135deg, #FF9933, #DD6B20) !important; 
        color: #FFFFFF !important; 
        font-weight: 800; 
    }
    .md-node span { color: white !important; }
    .ad-node { 
        background: #FFFDF7 !important; color: #C05621 !important; 
        font-weight: 800; border-left: 4px solid #FF9933; 
    }
    .ad-node span { color: #C05621 !important; }
    .pd-node { 
        background: #FFFFFF !important; color: #319795 !important; 
        font-weight: 700; border-left: 4px solid #81E6D9; 
    }
    .pd-node span { color: #319795 !important; }
    .date-label { font-size: 12px; opacity: 0.9; float: right; font-weight: normal; }
</style>
""", unsafe_allow_html=True)

# ==========================================
# 3. CORE MATH ENGINE
# ==========================================
swe.set_ephe_path(None)
geolocator = Nominatim(user_agent="bharatheeyam_v45_upagrahas_only")

KN_PLANETS = {
    0: "ರವಿ", 1: "ಚಂದ್ರ", 2: "ಬುಧ", 3: "ಶುಕ್ರ", 4: "ಕುಜ", 
    5: "ಗುರು", 6: "ಶನಿ", 101: "ರಾಹು", 102: "ಕೇತು", 
    "Ma": "ಮಾಂದಿ", "Lagna": "ಲಗ್ನ"
}

PLANET_ORDER = [
    "ಲಗ್ನ", "ರವಿ", "ಚಂದ್ರ", "ಕುಜ", "ಬುಧ", 
    "ಗುರು", "ಶುಕ್ರ", "ಶನಿ", "ರಾಹು", "ಕೇತು", "ಮಾಂದಿ"
]

KN_RASHI = [
    "ಮೇಷ", "ವೃಷಭ", "ಮಿಥುನ", "ಕರ್ಕ", "ಸಿಂಹ", "ಕನ್ಯಾ", 
    "ತುಲಾ", "ವೃಶ್ಚಿಕ", "ಧನು", "ಮಕರ", "ಕುಂಭ", "ಮೀನ"
]

KN_VARA = [
    "ಭಾನುವಾರ", "ಸೋಮವಾರ", "ಮಂಗಳವಾರ", "ಬುಧವಾರ", 
    "ಗುರುವಾರ", "ಶುಕ್ರವಾರ", "ಶನಿವಾರ"
]
KN_TITHI = [
    "ಶುಕ್ಲ ಪಾಡ್ಯಮಿ", "ಶುಕ್ಲ ದ್ವಿತೀಯ", "ಶುಕ್ಲ ತೃತೀಯ", "ಶುಕ್ಲ ಚತುರ್ಥಿ",
    "ಶುಕ್ಲ ಪಂಚಮಿ", "ಶುಕ್ಲ ಷಷ್ಠಿ", "ಶುಕ್ಲ ಸಪ್ತಮಿ", "ಶುಕ್ಲ ಅಷ್ಟಮಿ",
    "ಶುಕ್ಲ ನವಮಿ", "ಶುಕ್ಲ ದಶಮಿ", "ಶುಕ್ಲ ಏಕಾದಶಿ", "ಶುಕ್ಲ ದ್ವಾದಶಿ",
    "ಶುಕ್ಲ ತ್ರಯೋದಶಿ", "ಶುಕ್ಲ ಚತುರ್ದಶಿ", "ಹುಣ್ಣಿಮೆ", "ಕೃಷ್ಣ ಪಾಡ್ಯಮಿ",
    "ಕೃಷ್ಣ ದ್ವಿತೀಯ", "ಕೃಷ್ಣ ತೃತೀಯ", "ಕೃಷ್ಣ ಚತುರ್ಥಿ", "ಕೃಷ್ಣ ಪಂಚಮಿ",
    "ಕೃಷ್ಣ ಷಷ್ಠಿ", "ಕೃಷ್ಣ ಸಪ್ತಮಿ", "ಕೃಷ್ಣ ಅಷ್ಟಮಿ", "ಕೃಷ್ಣ ನವಮಿ",
    "ಕೃಷ್ಣ ದಶಮಿ", "ಕೃಷ್ಣ ಏಕಾದಶಿ", "ಕೃಷ್ಣ ದ್ವಾದಶಿ", "ಕೃಷ್ಣ ತ್ರಯೋದಶಿ",
    "ಕೃಷ್ಣ ಚತುರ್ದಶಿ", "ಅಮಾವಾಸ್ಯೆ"
]
KN_NAK = [
    "ಅಶ್ವಿನಿ", "ಭರಣಿ", "ಕೃತಿಕಾ", "ರೋಹಿಣಿ", "ಮೃಗಶಿರ", "ಆರಿದ್ರಾ",
    "ಪುನರ್ವಸು", "ಪುಷ್ಯ", "ಆಶ್ಲೇಷ", "ಮಘ", "ಪೂರ್ವ ಫಾಲ್ಗುಣಿ",
    "ಉತ್ತರ ಫಾಲ್ಗುಣಿ", "ಹಸ್ತ", "ಚಿತ್ತಾ", "ಸ್ವಾತಿ", "ವಿಶಾಖ",
    "ಅನುರಾಧ", "ಜ್ಯೇಷ್ಠ", "ಮೂಲ", "ಪೂರ್ವಾಷಾಢ", "ಉತ್ತರಾಷಾಢ",
    "ಶ್ರವಣ", "ಧನಿಷ್ಠ", "ಶತಭಿಷ", "ಪೂರ್ವಾಭಾದ್ರ", "ಉತ್ತರಾಭಾದ್ರ",
    "ರೇವತಿ"
]
KN_YOGA = [
    "ವಿಷ್ಕಂಭ", "ಪ್ರೀತಿ", "ಆಯುಷ್ಮಾನ್", "ಸೌಭಾಗ್ಯ", "ಶೋಭನ",
    "ಅತಿಗಂಡ", "ಸುಕರ್ಮ", "ಧೃತಿ", "ಶೂಲ", "ಗಂಡ",
    "ವೃದ್ಧಿ", "ಧ್ರುವ", "ವ್ಯಾಘಾತ", "ಹರ್ಷಣ", "ವಜ್ರ",
    "ಸಿದ್ಧಿ", "ವ್ಯತೀಪಾತ", "ವರೀಯಾನ್", "ಪರಿಘ", "ಶಿವ",
    "ಸಿದ್ಧ", "ಸಾಧ್ಯ", "ಶುಭ", "ಶುಕ್ಲ", "ಬ್ರಹ್ಮ",
    "ಇಂದ್ರ", "ವೈಧೃತಿ"
]
LORDS = ["ಕೇತು","ಶುಕ್ರ","ರವಿ","ಚಂದ್ರ","ಕುಜ","ರಾಹು","ಗುರು","ಶನಿ","ಬುಧ"]
YEARS = [7, 20, 6, 10, 7, 18, 16, 19, 17]

def get_altitude_manual(jd, lat, lon):
    try:
        res = swe.calc_ut(jd, swe.SUN, swe.FLG_EQUATORIAL | swe.FLG_SWIEPH)
        ra = res[0][0]
        dec = res[0][1]
        gmst = swe.sidtime(jd)
        lst = gmst + (lon / 15.0)
        ha_deg = ((lst * 15.0) - ra + 360) % 360
        if ha_deg > 180: 
            ha_deg -= 360
            
        lat_rad = math.radians(lat)
        dec_rad = math.radians(dec)
        ha_rad = math.radians(ha_deg)
        
        p1 = math.sin(lat_rad) * math.sin(dec_rad)
        p2 = math.cos(lat_rad) * math.cos(dec_rad) * math.cos(ha_rad)
        sin_alt = p1 + p2
        
        return math.degrees(math.asin(sin_alt))
    except Exception:
        return 0

def find_sunrise_set_for_date(year, month, day, lat, lon):
    jd_start = swe.julday(year, month, day, 0.0) 
    rise_time, set_time = jd_start + 0.25, jd_start + 0.75 # Safe defaults
    step = 1/24.0
    current = jd_start - 0.3 
    
    try:
        # Using -0.583 for Mid-Limb Sunrise (center of sun including refraction)
        for i in range(30): 
            alt1 = get_altitude_manual(current, lat, lon)
            alt2 = get_altitude_manual(current + step, lat, lon)
            if alt1 < -0.583 and alt2 >= -0.583:
                l, h = current, current + step
                for _ in range(20): 
                    m = (l + h) / 2
                    if get_altitude_manual(m, lat, lon) < -0.583: 
                        l = m
                    else: 
                        h = m
                rise_time = h
            if alt1 > -0.583 and alt2 <= -0.583:
                l, h = current, current + step
                for _ in range(20): 
                    m = (l + h) / 2
                    if get_altitude_manual(m, lat, lon) > -0.583: 
                        l = m
                    else: 
                        h = m
                set_time = h
            current += step
    except Exception:
        pass
        
    return rise_time, set_time

def find_nak_limit(jd, target_deg):
    low = jd - 1.2
    high = jd + 1.2
    try:
        for _ in range(20):
            mid = (low + high) / 2
            ayan = swe.get_ayanamsa(mid)
            m_deg = (swe.calc_ut(mid, swe.MOON)[0][0] - ayan) % 360
            diff = (m_deg - target_deg + 180) % 360 - 180
            if diff < 0: 
                low = mid
            else: 
                high = mid
        return mid
    except Exception:
        return jd

def fmt_ghati(decimal_val):
    g = int(decimal_val)
    rem = decimal_val - g
    v = int(round(rem * 60))
    if v == 60: 
        g += 1
        v = 0
    return str(g) + "." + str(v).zfill(2)

def fmt_deg(dec_deg):
    rem = dec_deg % 30
    t_sec = int(round(rem * 3600))
    dg = int(t_sec / 3600)
    mn = int((t_sec % 3600) / 60)
    sc = int(t_sec % 60)
    if dg == 30:
        dg = 29
        mn = 59
        sc = 59
    s_dg = str(dg)
    s_mn = str(mn).zfill(2)
    s_sc = str(sc).zfill(2)
    return s_dg + "° " + s_mn + "' " + s_sc + '"'

def calculate_ashtakavarga(positions):
    P_KEYS = ["ರವಿ", "ಚಂದ್ರ", "ಕುಜ", "ಬುಧ", "ಗುರು", "ಶುಕ್ರ", "ಶನಿ", "ಲಗ್ನ"]
    r_idx = {k: int(positions[k] / 30) for k in P_KEYS}
    
    sav = [0] * 12
    bav = {p: [0]*12 for p in ["ರವಿ", "ಚಂದ್ರ", "ಕುಜ", "ಬುಧ", "ಗುರು", "ಶುಕ್ರ", "ಶನಿ"]}
    
    BAV_RULES = {
        "ರವಿ": [
            [1,2,4,7,8,9,10,11], [3,6,10,11], [1,2,4,7,8,9,10,11], 
            [3,5,6,9,10,11,12], [5,6,9,11], [6,7,12], 
            [1,2,4,7,8,9,10,11], [3,4,6,10,11,12]
        ],
        "ಚಂದ್ರ": [
            [3,6,7,8,10,11], [1,3,6,7,10,11], [2,3,5,6,9,10,11],
            [1,3,4,5,7,8,10,11], [1,4,7,8,10,11,12], [3,4,5,7,9,10,11],
            [3,5,6,11], [3,6,10,11]
        ],
        "ಕುಜ": [
            [3,5,6,10,11], [3,6,11], [1,2,4,7,8,10,11],
            [3,5,6,11], [6,10,11,12], [6,8,11,12],
            [1,4,7,8,9,10,11], [1,3,6,10,11]
        ],
        "ಬುಧ": [
            [5,6,9,11,12], [2,4,6,8,10,11], [1,2,4,7,8,9,10,11],
            [1,3,5,6,9,10,11,12], [6,8,11,12], [1,2,3,4,5,8,9,11],
            [1,2,4,7,8,9,10,11], [1,2,4,6,8,10,11]
        ],
        "ಗುರು": [
            [1,2,3,4,7,8,9,10,11], [2,5,7,9,11], [1,2,4,7,8,10,11],
            [1,2,4,5,6,9,10,11], [1,2,3,4,7,8,10,11], [2,5,6,9,10,11],
            [3,5,6,12], [1,2,4,5,6,9,10,11]
        ],
        "ಶುಕ್ರ": [
            [8,11,12], [1,2,3,4,5,8,9,11,12], [3,5,6,9,11,12],
            [3,5,6,9,11], [5,8,9,10,11], [1,2,3,4,5,8,9,10,11],
            [3,4,5,8,9,10,11], [1,2,3,4,5,8,9,11]
        ],
        "ಶನಿ": [
            [1,2,4,7,8,10,11], [3,6,11], [3,5,6,10,11,12],
            [6,8,9,10,11,12], [5,6,11,12], [6,11,12],
            [3,5,6,11], [1,3,4,6,10,11]
        ]
    }
    
    for target in ["ರವಿ", "ಚಂದ್ರ", "ಕುಜ", "ಬುಧ", "ಗುರು", "ಶುಕ್ರ", "ಶನಿ"]:
        rules = BAV_RULES[target]
        for ref_idx, ref_planet in enumerate(P_KEYS):
            ref_rashi = r_idx[ref_planet]
            for h in rules[ref_idx]:
                sign_idx = (ref_rashi + h - 1) % 12
                bav[target][sign_idx] += 1
                sav[sign_idx] += 1
                
    return sav, bav

# ==========================================
# 4. MAIN CALCULATIONS & SPEED LOGIC
# ==========================================
def calculate_mandi(jd_birth, lat, lon, dob_obj):
    y = dob_obj.year
    m = dob_obj.month
    d = dob_obj.day
    sr_civil, ss_civil = find_sunrise_set_for_date(y, m, d, lat, lon)
    
    py_weekday = dob_obj.weekday()
    civil_weekday_idx = (py_weekday + 1) % 7 
    
    is_night = False
    if jd_birth >= sr_civil and jd_birth < ss_civil: 
        is_night = False
    else: 
        is_night = True
        
    start_base = 0.0
    duration = 0.0
    vedic_wday = 0
    panch_sr = 0.0
    
    if not is_night:
        vedic_wday = civil_weekday_idx
        panch_sr = sr_civil
        start_base = sr_civil
        duration = ss_civil - sr_civil
    else:
        if jd_birth < sr_civil:
            vedic_wday = (civil_weekday_idx - 1) % 7
            prev_d = dob_obj - datetime.timedelta(days=1)
            p_y = prev_d.year
            p_m = prev_d.month
            p_d = prev_d.day
            p_sr, p_ss = find_sunrise_set_for_date(p_y, p_m, p_d, lat, lon)
            start_base = p_ss
            duration = sr_civil - p_ss
            panch_sr = p_sr
        else:
            vedic_wday = civil_weekday_idx
            next_d = dob_obj + datetime.timedelta(days=1)
            n_y = next_d.year
            n_m = next_d.month
            n_d = next_d.day
            n_sr, n_ss = find_sunrise_set_for_date(n_y, n_m, n_d, lat, lon)
            start_base = ss_civil
            duration = n_sr - ss_civil
            panch_sr = sr_civil

    if not is_night: 
        factors = [26, 22, 18, 14, 10, 6, 2] 
    else: 
        factors = [10, 6, 2, 26, 22, 18, 14] 
        
    factor = factors[vedic_wday]
    mandi_jd = start_base + (duration * factor / 30.0)
    
    return mandi_jd, is_night, panch_sr, vedic_wday, start_base

def get_full_calculations(jd_birth, lat, lon, dob_obj, ayan_mode, node_mode):
    try:
        swe.set_sid_mode(ayan_mode)
        swe.set_topo(float(lon), float(lat), 0)
        ayan = swe.get_ayanamsa(jd_birth)
        positions = {}
        speeds = {} 
        extra_details = {}
        
        for pid in [0, 1, 2, 3, 4, 5, 6]:
            flag = swe.FLG_SWIEPH | swe.FLG_SIDEREAL | swe.FLG_SPEED
            res = swe.calc_ut(jd_birth, pid, flag)
            deg = res[0][0] % 360
            speed = res[0][3]
            
            positions[KN_PLANETS[pid]] = deg
            speeds[KN_PLANETS[pid]] = speed
            
            nak_idx = int(deg / 13.333333333)
            pada = int((deg % 13.333333333) / 3.333333333) + 1
            extra_details[KN_PLANETS[pid]] = {
                "nak": KN_NAK[nak_idx % 27], 
                "pada": pada
            }

        node_flag = swe.FLG_SWIEPH | swe.FLG_SIDEREAL | swe.FLG_SPEED
        rahu_res = swe.calc_ut(jd_birth, node_mode, node_flag)
        rahu_deg = rahu_res[0][0] % 360
        rahu_speed = rahu_res[0][3]
        
        positions[KN_PLANETS[101]] = rahu_deg
        speeds[KN_PLANETS[101]] = rahu_speed
        
        positions[KN_PLANETS[102]] = (rahu_deg + 180) % 360
        speeds[KN_PLANETS[102]] = rahu_speed
        
        nodes = [
            (KN_PLANETS[101], rahu_deg), 
            (KN_PLANETS[102], (rahu_deg + 180) % 360)
        ]
        
        for p, d in nodes:
            nak_idx = int(d / 13.333333333)
            pada = int((d % 13.333333333) / 3.333333333) + 1
            extra_details[p] = {"nak": KN_NAK[nak_idx % 27], "pada": pada}

        houses_res = swe.houses(jd_birth, float(lat), float(lon), b'P')
        cusps = houses_res[0]
        
        if len(cusps) == 13:
            asc_deg = (cusps[1] - ayan) % 360
            bhava_sphutas = [(cusps[i] - ayan) % 360 for i in range(1, 13)]
        else:
            asc_deg = (cusps[0] - ayan) % 360
            bhava_sphutas = [(cusps[i] - ayan) % 360 for i in range(0, 12)]

        positions[KN_PLANETS["Lagna"]] = asc_deg
        speeds[KN_PLANETS["Lagna"]] = 0
        nak_idx = int(asc_deg / 13.333333333)
        pada = int((asc_deg % 13.333333333) / 3.333333333) + 1
        extra_details[KN_PLANETS["Lagna"]] = {
            "nak": KN_NAK[nak_idx % 27], 
            "pada": pada
        }

        res = calculate_mandi(jd_birth, lat, lon, dob_obj)
        mandi_time_jd = res[0]
        is_night = res[1]
        panch_sr = res[2]
        w_idx = res[3]
        debug_base = res[4]
        
        h_mandi = swe.houses(mandi_time_jd, float(lat), float(lon), b'P')
        a_mandi = swe.get_ayanamsa(mandi_time_jd)
        mandi_deg = (h_mandi[1][0] - a_mandi) % 360
        positions[KN_PLANETS["Ma"]] = mandi_deg
        speeds[KN_PLANETS["Ma"]] = 0
        
        nak_idx = int(mandi_deg / 13.333333333)
        pada = int((mandi_deg % 13.333333333) / 3.333333333) + 1
        extra_details[KN_PLANETS["Ma"]] = {
            "nak": KN_NAK[nak_idx % 27], 
            "pada": pada
        }

        m_deg = positions["ಚಂದ್ರ"]
        s_deg = positions["ರವಿ"]
        t_idx = int(((m_deg - s_deg + 360) % 360) / 12)
        n_idx = int(m_deg / 13.333333333)
        
        y_deg = (m_deg + s_deg) % 360
        y_idx = int(y_deg / 13.333333333)
        yoga_name = KN_YOGA[y_idx]
        
        k_idx = int(((m_deg - s_deg + 360) % 360) / 6)
        if k_idx == 0:
            k_name = "ಕಿಂಸ್ತುಘ್ನ"
        elif k_idx == 57:
            k_name = "ಶಕುನಿ"
        elif k_idx == 58:
            k_name = "ಚತುಷ್ಪಾದ"
        elif k_idx == 59:
            k_name = "ನಾಗ"
        else:
            k_arr = ["ಬವ", "ಬಾಲವ", "ಕೌಲವ", "ತೈತಿಲ", "ಗರ", "ವಣಿಜ", "ಭದ್ರಾ (ವಿಷ್ಟಿ)"]
            k_name = k_arr[(k_idx - 1) % 7]
            
        r_idx = int(m_deg / 30)
        rasi_name = KN_RASHI[r_idx]
        
        js = find_nak_limit(jd_birth, n_idx * 13.333333333)
        je = find_nak_limit(jd_birth, (n_idx + 1) * 13.333333333)
        
        perc = (m_deg % 13.333333333) / 13.333333333
        bal = YEARS[n_idx % 9] * (1 - perc)
        dt_birth = datetime.datetime.fromtimestamp((jd_birth - 2440587.5) * 86400)
        
        sav_bindus, bav_bindus = calculate_ashtakavarga(positions)
        
        # --- UPAGRAHAS & 16 ADVANCED SPHUTAS ---
        S = positions["ರವಿ"]
        M = positions["ಚಂದ್ರ"]
        J = positions["ಗುರು"]
        V = positions["ಶುಕ್ರ"]
        Ma = positions["ಕುಜ"]
        R = positions[KN_PLANETS[101]]
        Asc = positions["ಲಗ್ನ"]
        Md = positions["ಮಾಂದಿ"]
        
        dhooma = (S + 133.333333) % 360
        vyatipata = (360 - dhooma) % 360
        parivesha = (vyatipata + 180) % 360
        indrachapa = (360 - parivesha) % 360
        upaketu = (indrachapa + 16.666667) % 360
        
        bhrigu = (M + R) / 2
        beeja = (S + V + J) % 360
        kshetra = (M + Ma + J) % 360
        yogi = (S + M + 93.333333) % 360
        trisphuta = (Asc + M + Md) % 360
        chatusphuta = (trisphuta + S) % 360
        panchasphuta = (chatusphuta + R) % 360
        prana = (Asc * 5 + Md) % 360
        deha = (M * 8 + Md) % 360
        mrityu = (Md * 7 + S) % 360
        sookshma = (prana + deha + mrityu) % 360
        
        adv_sphutas = {
            "ಧೂಮ": dhooma, "ವ್ಯತೀಪಾತ": vyatipata, "ಪರಿವೇಷ": parivesha,
            "ಇಂದ್ರಚಾಪ": indrachapa, "ಉಪಕೇತು": upaketu, "ಭೃಗು ಬಿ.": bhrigu,
            "ಬೀಜ": beeja, "ಕ್ಷೇತ್ರ": kshetra, "ಯೋಗಿ": yogi,
            "ತ್ರಿಸ್ಫುಟ": trisphuta, "ಚತುಃಸ್ಫುಟ": chatusphuta,
            "ಪಂಚಸ್ಫುಟ": panchasphuta, "ಪ್ರಾಣ": prana, "ದೇಹ": deha,
            "ಮೃತ್ಯು": mrityu, "ಸೂಕ್ಷ್ಮ ತ್ರಿ.": sookshma
        }
        
        pan = {
            "t": KN_TITHI[min(t_idx, 29)], 
            "v": KN_VARA[w_idx], 
            "n": KN_NAK[n_idx % 27],
            "y": yoga_name,
            "k": k_name,
            "r": rasi_name,
            "sr": panch_sr, 
            "udayadi": fmt_ghati((jd_birth - panch_sr) * 60), 
            "gata": fmt_ghati((jd_birth - js) * 60), 
            "parama": fmt_ghati((je - js) * 60), 
            "rem": fmt_ghati((je - jd_birth) * 60),
            "d_bal": str(int(bal)) + "ವ " + str(int((bal%1)*12)) + "ತಿ",
            "n_idx": n_idx, 
            "perc": perc, 
            "date_obj": dt_birth,
            "lord_bal": LORDS[n_idx%9],
            "sav_bindus": sav_bindus,
            "bav_bindus": bav_bindus,
            "adv_sphutas": adv_sphutas
        }
        return positions, pan, extra_details, bhava_sphutas, speeds
    except Exception as e:
        st.error(f"ಲೆಕ್ಕಾಚಾರದಲ್ಲಿ ದೋಷ: {str(e)}")
        return {}, {}, {}, [], {}

# ==========================================
# 5. DIALOG UI FOR PLANET POPUP
# ==========================================
@st.dialog("ಗ್ರಹದ ಸಂಪೂರ್ಣ ವಿವರ")
def show_planet_popup(p_name, deg, speed, sun_deg):
    try:
        deg_fmt = fmt_deg(deg)
        
        is_asta = False
        gathi_str = "ಅನ್ವಯಿಸುವುದಿಲ್ಲ"
        
        if p_name not in ["ರವಿ", "ರಾಹು", "ಕೇತು", "ಲಗ್ನ", "ಮಾಂದಿ"]:
            diff = abs(deg - sun_deg)
            if diff > 180: diff = 360 - diff
            limits = {"ಚಂದ್ರ": 12, "ಕುಜ": 17, "ಬುಧ": 14, "ಗುರು": 11, "ಶುಕ್ರ": 10, "ಶನಿ": 15}
            if diff <= limits.get(p_name, 0):
                is_asta = True
                
            if p_name == "ಚಂದ್ರ": gathi_str = "ನೇರ"
            elif speed < 0: gathi_str = "ವಕ್ರಿ"
            else: gathi_str = "ನೇರ"
            
        elif p_name in ["ರಾಹು", "ಕೇತು"]:
            gathi_str = "ವಕ್ರಿ"
        elif p_name == "ರವಿ":
            gathi_str = "ನೇರ"
            
        asta_text = "ಹೌದು" if is_asta else "ಇಲ್ಲ"
        if p_name in ["ರವಿ", "ರಾಹು", "ಕೇತು", "ಲಗ್ನ", "ಮಾಂದಿ"]: 
            asta_text = "ಅನ್ವಯಿಸುವುದಿಲ್ಲ"
            
        d1_idx = int(deg/30)
        d1_name = KN_RASHI[d1_idx]
        
        r_val = int(deg/30)
        dr_val = deg % 30
        is_odd = (r_val % 2 == 0)
        if is_odd: d2_idx = 4 if dr_val < 15 else 3
        else: d2_idx = 3 if dr_val < 15 else 4
        
        if dr_val < 10: true_d3_idx = d1_idx
        elif dr_val < 20: true_d3_idx = (d1_idx + 4) % 12
        else: true_d3_idx = (d1_idx + 8) % 12
        
        if dr_val < 10: p1_part = " 1"
        elif dr_val < 20: p1_part = " 2"
        else: p1_part = " 3"
        d3_d1_str = d1_name + p1_part
        
        d9_exact = (deg * 9) % 360
        d9_idx = int(d9_exact / 30)
        d9_name = KN_RASHI[d9_idx]
        
        deg_in_d9 = d9_exact % 30
        if deg_in_d9 < 10: p9_part = " 1"
        elif deg_in_d9 < 20: p9_part = " 2"
        else: p9_part = " 3"
        d3_d9_str = d9_name + p9_part
        
        d12_idx = (int(deg/30) + int((deg%30)/2.5)) % 12
        d12_name = KN_RASHI[d12_idx]
        
        deg_in_d12 = (deg % 2.5) * 12
        if deg_in_d12 < 10: p12_part = " 1"
        elif deg_in_d12 < 20: p12_part = " 2"
        else: p12_part = " 3"
        d3_d12_str = d12_name + p12_part
        
        if is_odd:
            if dr_val < 5: d30_idx = 0
            elif dr_val < 10: d30_idx = 10
            elif dr_val < 18: d30_idx = 8
            elif dr_val < 25: d30_idx = 2
            else: d30_idx = 6
        else:
            if dr_val < 5: d30_idx = 5
            elif dr_val < 12: d30_idx = 2
            elif dr_val < 20: d30_idx = 8
            elif dr_val < 25: d30_idx = 10
            else: d30_idx = 0
            
        h_arr = []
        h_arr.append("<div class='card'><table class='key-val-table'>")
        h_arr.append("<tr><td class='key'>ಸ್ಫುಟ</td><td>" + deg_fmt + "</td></tr>")
        h_arr.append("<tr><td class='key'>ಗತಿ</td><td><b>" + gathi_str + "</b></td></tr>")
        h_arr.append("<tr><td class='key'>ಅಸ್ತ</td><td><b>" + asta_text + "</b></td></tr>")
        h_arr.append("</table></div>")
        st.markdown("".join(h_arr), unsafe_allow_html=True)
        
        st.markdown("#### 📊 ವರ್ಗಗಳು")
        v_arr = []
        v_arr.append("<div class='card'><table class='key-val-table'>")
        v_arr.append("<tr><td class='key'>ರಾಶಿ</td><td>" + KN_RASHI[d1_idx] + "</td></tr>")
        v_arr.append("<tr><td class='key'>ಹೋರಾ</td><td>" + KN_RASHI[d2_idx] + "</td></tr>")
        v_arr.append("<tr><td class='key'>ದ್ರೇಕ್ಕಾಣ</td><td>" + KN_RASHI[true_d3_idx] + "</td></tr>")
        v_arr.append("<tr><td class='key'>ನವಾಂಶ</td><td>" + KN_RASHI[d9_idx] + "</td></tr>")
        v_arr.append("<tr><td class='key'>ದ್ವಾದಶಾಂಶ</td><td>" + KN_RASHI[d12_idx] + "</td></tr>")
        v_arr.append("<tr><td class='key'>ತ್ರಿಂಶಾಂಶ</td><td>" + KN_RASHI[d30_idx] + "</td></tr>")
        v_arr.append("</table></div>")
        st.markdown("".join(v_arr), unsafe_allow_html=True)
        
        st.markdown("#### 📐 ಉಪ-ದ್ರೇಕ್ಕಾಣ")
        sd_arr = []
        sd_arr.append("<div class='card'><table class='key-val-table'>")
        sd_arr.append("<tr><td class='key'>ರಾಶಿ ದ್ರೇಕ್ಕಾಣ</td><td>" + d3_d1_str + "</td></tr>")
        sd_arr.append("<tr><td class='key'>ನವಾಂಶ ದ್ರೇಕ್ಕಾಣ</td><td>" + d3_d9_str + "</td></tr>")
        sd_arr.append("<tr><td class='key'>ದ್ವಾದಶಾಂಶ ದ್ರೇಕ್ಕಾಣ</td><td>" + d3_d12_str + "</td></tr>")
        sd_arr.append("</table></div>")
        st.markdown("".join(sd_arr), unsafe_allow_html=True)
    except Exception:
        st.error("ವಿವರಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.")

# ==========================================
# 6. SESSION STATE & UI
# ==========================================
if 'page' not in st.session_state: 
    st.session_state.page = "input"
if 'data' not in st.session_state: 
    st.session_state.data = {}
if 'notes' not in st.session_state: 
    st.session_state.notes = ""
if 'aroodhas' not in st.session_state: 
    st.session_state.aroodhas = {}
    
if 'name_input' not in st.session_state: 
    st.session_state.name_input = ""
if 'place_input' not in st.session_state: 
    st.session_state.place_input = "Yellapur"
if 'lat' not in st.session_state: 
    st.session_state.lat = 14.98
if 'lon' not in st.session_state: 
    st.session_state.lon = 74.73

if 'dob_input' not in st.session_state:
    tz_ist = datetime.timezone(datetime.timedelta(hours=5, minutes=30))
    now = datetime.datetime.now(tz_ist)
    
    st.session_state.dob_input = now.date()
    
    h24 = now.hour
    h12 = h24 % 12
    if h12 == 0:
        h12 = 12
        
    st.session_state.h_input = h12
    st.session_state.m_input = now.minute
    
    if h24 < 12:
        st.session_state.ampm_input = "AM"
    else:
        st.session_state.ampm_input = "PM"

st.markdown('<div class="header-box">ಭಾರತೀಯಮ್</div>', unsafe_allow_html=True)

if st.session_state.page == "input":
    with st.container():
        
        saved_db = load_db()
        if len(saved_db) > 0:
            st.markdown("<div class='card'>", unsafe_allow_html=True)
            st.markdown("#### 📂 ಉಳಿಸಿದ ಜಾತಕ")
            c_sel, c_btn = st.columns([3, 1])
            k_list = [""] + list(saved_db.keys())
            
            sel_n = c_sel.selectbox("ಆಯ್ಕೆಮಾಡಿ", k_list, label_visibility="collapsed")
            
            if c_btn.button("ತೆಗೆಯಿರಿ", use_container_width=True):
                if sel_n != "":
                    prof = saved_db[sel_n]
                    st.session_state.name_input = sel_n
                    
                    try:
                        dt_obj = datetime.datetime.strptime(prof['d'], "%Y-%m-%d")
                        st.session_state.dob_input = dt_obj.date()
                    except: pass
                    
                    st.session_state.h_input = prof.get('h', 12)
                    st.session_state.m_input = prof.get('m', 0)
                    st.session_state.ampm_input = prof.get('ampm', 'AM')
                    st.session_state.lat = prof.get('lat', 14.98)
                    st.session_state.lon = prof.get('lon', 74.73)
                    st.session_state.place_input = prof.get('p', 'Yellapur')
                    st.rerun()
            st.markdown("</div>", unsafe_allow_html=True)
        
        st.markdown("<div class='card'>", unsafe_allow_html=True)
        st.markdown("#### ✨ ಹೊಸ ಜಾತಕ")
        
        name = st.text_input("ಹೆಸರು", key="name_input")
        
        d_min = datetime.date(1800, 1, 1)
        d_max = datetime.date(2100, 12, 31)
        
        dob = st.date_input(
            "ದಿನಾಂಕ", 
            key="dob_input", 
            min_value=d_min, 
            max_value=d_max
        )
        
        c1, c2, c3 = st.columns(3)
        h = c1.number_input("ಗಂಟೆ", 1, 12, key="h_input")
        m = c2.number_input("ನಿಮಿಷ", 0, 59, key="m_input")
        ampm = c3.selectbox("ಬೆಳಿಗ್ಗೆ/ಮಧ್ಯಾಹ್ನ", ["AM", "PM"], key="ampm_input")
        
        place_q = st.text_input("ಊರು ಹುಡುಕಿ", key="place_input")
        if st.button("ಹುಡುಕಿ"):
            try:
                # Added timeout to prevent geolocator crashes
                loc = geolocator.geocode(place_q, timeout=10)
                if loc: 
                    st.session_state.lat = loc.latitude
                    st.session_state.lon = loc.longitude
                    st.success("📍 " + loc.address)
                else:
                    st.error("ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.")
            except Exception: 
                st.error("ಸ್ಥಳ ಸಂಪರ್ಕಿಸುವಲ್ಲಿ ದೋಷ. ದಯವಿಟ್ಟು ಅಕ್ಷಾಂಶ/ರೇಖಾಂಶವನ್ನು ನೇರವಾಗಿ ನಮೂದಿಸಿ.")
                
        lat = st.number_input("ಅಕ್ಷಾಂಶ", key="lat", format="%.4f")
        lon = st.number_input("ರೇಖಾಂಶ", key="lon", format="%.4f")
        
        with st.expander("⚙️ ಸುಧಾರಿತ ಆಯ್ಕೆಗಳು"):
            ca, cn = st.columns(2)
            ayan_opts = ["ಲಾಹಿರಿ", "ರಾಮನ್", "ಕೆ.ಪಿ"]
            ayan_sel = ca.selectbox("ಅಯನಾಂಶ", ayan_opts)
            
            node_opts = ["ನಿಜ ರಾಹು", "ಸರಾಸರಿ ರಾಹು"]
            node_sel = cn.selectbox("ರಾಹು ಗಣನೆ", node_opts)
            
        st.markdown("<br>", unsafe_allow_html=True)
        
        if st.button("ಜಾತಕ ರಚಿಸಿ", type="primary"):
            h24 = h + (12 if ampm == "PM" and h != 12 else 0)
            h24 = 0 if ampm == "AM" and h == 12 else h24
            jd = swe.julday(dob.year, dob.month, dob.day, h24 + m/60.0 - 5.5)
            
            ayan_map = {
                "ಲಾಹಿರಿ": swe.SIDM_LAHIRI, 
                "ರಾಮನ್": swe.SIDM_RAMAN, 
                "ಕೆ.ಪಿ": swe.SIDM_KRISHNAMURTI
            }
            ayan_mode = ayan_map[ayan_sel]
            
            node_mode = swe.TRUE_NODE if node_sel == "ನಿಜ ರಾಹು" else swe.MEAN_NODE
            
            p1, p2, p3, p4, p5 = get_full_calculations(jd, lat, lon, dob, ayan_mode, node_mode)
            
            if p1 and p2:
                st.session_state.data = {
                    "pos": p1, "pan": p2, "details": p3, "bhavas": p4, "speeds": p5
                }
                st.session_state.page = "dashboard"
                st.rerun()
            else:
                st.error("ಜಾತಕ ಲೆಕ್ಕಾಚಾರದಲ್ಲಿ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ದಿನಾಂಕ/ಸಮಯ ಪರಿಶೀಲಿಸಿ.")
        st.markdown("</div>", unsafe_allow_html=True)

elif st.session_state.page == "dashboard" and st.session_state.data:
    try:
        pos = st.session_state.data.get('pos', {})
        pan = st.session_state.data.get('pan', {})
        details = st.session_state.data.get('details', {})
        bhavas = st.session_state.data.get('bhavas', [])
        speeds = st.session_state.data.get('speeds', {})
        sav_vals = pan.get('sav_bindus', [0]*12)
        bav_vals = pan.get('bav_bindus', {})
        adv_sp = pan.get('adv_sphutas', {})
        
        c_bk, c_sv = st.columns(2)
        
        if c_bk.button("⬅️ ಹಿಂದಕ್ಕೆ"): 
            st.session_state.page = "input"
            st.rerun()
            
        if c_sv.button("💾 ಉಳಿಸಿ"):
            d_str = st.session_state.dob_input.strftime("%Y-%m-%d")
            
            prof_data = {
                "d": d_str,
                "h": st.session_state.h_input,
                "m": st.session_state.m_input,
                "ampm": st.session_state.ampm_input,
                "lat": st.session_state.lat,
                "lon": st.session_state.lon,
                "p": st.session_state.place_input
            }
            
            n_val = st.session_state.name_input
            if n_val == "":
                n_val = "Unknown_" + d_str
                
            save_db(n_val, prof_data)
            st.success("ಉಳಿಸಲಾಗಿದೆ!")
        
        tabs = ["ಕುಂಡಲಿ", "ಗ್ರಹ ಸ್ಫುಟ", "ಉಪಗ್ರಹ ಸ್ಫುಟ", "ಆರೂಢ", "ದಶ", "ಪಂಚಾಂಗ", "ಭಾವ", "ಅಷ್ಟಕವರ್ಗ", "ಟಿಪ್ಪಣಿ", "ಚಂದಾದಾರಿಕೆ", "ಬಗ್ಗೆ"]
        t1, t_graha, t2, t3, t4, t5, t6, t7, t8, t9, t10 = st.tabs(tabs)
        
        with t1:
            c_v, c_b = st.columns(2)
            
            d_names = {
                1: "ರಾಶಿ", 
                2: "ಹೋರಾ",
                3: "ದ್ರೇಕ್ಕಾಣ", 
                9: "ನವಾಂಶ", 
                12: "ದ್ವಾದಶಾಂಶ", 
                30: "ತ್ರಿಂಶಾಂಶ"
            }
            
            opts = [1, 2, 3, 9, 12, 30]
            v_opt_base = c_v.selectbox("ವರ್ಗ", opts, format_func=lambda x: d_names[x])
            
            mode_opts = ["ರಾಶಿ", "ಭಾವ", "ನವಾಂಶ"]
            c_mode = c_b.radio("ಚಾರ್ಟ್ ವಿಧ", mode_opts, horizontal=True)
            
            show_sphutas = st.toggle("ಸ್ಫುಟಗಳನ್ನು ಕುಂಡಲಿಯಲ್ಲಿ ತೋರಿಸಿ", value=False)
            st.markdown("<br>", unsafe_allow_html=True)
            
            if c_mode == "ಭಾವ":
                v_opt = 1
                b_opt = True
            elif c_mode == "ನವಾಂಶ":
                v_opt = 9
                b_opt = False
            else:
                v_opt = v_opt_base
                b_opt = False
            
            bxs = {i: "" for i in range(12)}
            ld = pos.get(KN_PLANETS["Lagna"], 0) 
            
            render_items = list(PLANET_ORDER)
            render_pos = dict(pos)
            
            if show_sphutas and adv_sp:
                for k, v in adv_sp.items():
                    render_items.append(k)
                    render_pos[k] = v
            
            for n in render_items:
                if n not in render_pos: continue
                d = render_pos[n]
                if v_opt == 1: 
                    if not b_opt:
                        ri = int(d/30)
                    else:
                        ri = (int(ld/30) + int(((d - ld + 360)%360 + 15)/30)) % 12
                elif v_opt == 2:
                    r = int(d/30)
                    dr = d % 30
                    is_odd_sign = (r % 2 == 0)
                    if is_odd_sign:
                        if dr < 15: ri = 4 
                        else: ri = 3 
                    else:
                        if dr < 15: ri = 3 
                        else: ri = 4 
                elif v_opt == 30: 
                    r = int(d/30)
                    dr = d%30
                    is_odd = (r % 2 == 0)
                    if is_odd:
                        if dr < 5: ri = 0
                        elif dr < 10: ri = 10
                        elif dr < 18: ri = 8
                        elif dr < 25: ri = 2
                        else: ri = 6
                    else:
                        if dr < 5: ri = 5
                        elif dr < 12: ri = 2
                        elif dr < 20: ri = 8
                        elif dr < 25: ri = 10
                        else: ri = 0
                elif v_opt == 9: 
                    block = int(d/30)%4
                    start = [0, 9, 6, 3][block]
                    steps = int((d%30)/3.33333)
                    ri = (start + steps) % 12
                elif v_opt == 3: 
                    ri = (int(d/30) + (int((d%30)/10)*4)) % 12
                elif v_opt == 12: 
                    ri = (int(d/30) + int((d%30)/2.5)) % 12
                else: 
                    ri = int(d/30)
                    
                if n in ["ಲಗ್ನ", "ಮಾಂದಿ"]:
                    cls = "hi"
                elif n in adv_sp:
                    cls = "sp"
                else:
                    cls = "pl"
                    
                bxs[ri] += "<div class='" + cls + "'>" + n + "</div>"
                
            grid = [11, 0, 1, 2, 10, None, None, 3, 9, None, None, 4, 8, 7, 6, 5]
            
            glines = []
            glines.append("<div class='grid-container'>")
            
            c_count = 0
            for idx in grid:
                if idx is None:
                    if c_count == 0: 
                        g_txt = "<div class='center-box'>ಭಾರತೀಯಮ್<br>"
                        if c_mode == "ಭಾವ":
                            g_txt += "ಭಾವ"
                        elif c_mode == "ನವಾಂಶ":
                            g_txt += "ನವಾಂಶ"
                        else:
                            g_txt += d_names[v_opt]
                        g_txt += "</div>"
                        glines.append(g_txt)
                        c_count = 1
                else: 
                    bx_str = "<div class='box'><span class='lbl'>" 
                    bx_str += KN_RASHI[idx] + "</span>" + bxs[idx] + "</div>"
                    glines.append(bx_str)
                    
            glines.append("</div>")
            st.markdown("".join(glines), unsafe_allow_html=True)
            
            st.markdown("<br><h4 style='text-align:center; color:#2B6CB0;'>🔍 ಗ್ರಹಗಳ ವಿಸ್ತೃತ ವಿವರ</h4>", unsafe_allow_html=True)
            btn_cols = st.columns(4)
            
            for i, p_n in enumerate(PLANET_ORDER):
                if p_n in pos:
                    if btn_cols[i % 4].button(p_n, key="pop_" + p_n, use_container_width=True):
                        show_planet_popup(p_n, pos[p_n], speeds.get(p_n, 0), pos.get("ರವಿ", 0))

        with t_graha:
            st.markdown("<h4 style='text-align:center; color:#2B6CB0;'>🪐 ಗ್ರಹ ಸ್ಫುಟ</h4>", unsafe_allow_html=True)
            g_lines = []
            g_lines.append("<div class='card'><table class='key-val-table' style='width:100%;'>")
            g_lines.append("<tr><th>ಗ್ರಹ</th><th style='text-align:right'>ಸ್ಫುಟ (ಅಂಶ)</th><th style='text-align:right'>ನಕ್ಷತ್ರ - ಪಾದ</th></tr>")
            
            for p in PLANET_ORDER:
                if p in pos and p in details:
                    d = pos[p]
                    deg_fmt = fmt_deg(d)
                    nak_name = details[p].get('nak', '')
                    pada_num = str(details[p].get('pada', ''))
                    
                    g_lines.append("<tr><td><b>" + p + "</b></td>")
                    g_lines.append("<td style='text-align:right'>" + deg_fmt + "</td>")
                    g_lines.append("<td style='text-align:right'>" + nak_name + " - " + pada_num + "</td></tr>")
                
            g_lines.append("</table></div>")
            st.markdown("".join(g_lines), unsafe_allow_html=True)
        
        with t2:
            slines = []
            slines.append("<div class='card'><table class='key-val-table' style='width:100%;'>")
            slines.append("<tr><th>ಉಪಗ್ರಹ ಸ್ಫುಟ</th><th>ರಾಶಿ</th>")
            slines.append("<th style='text-align:right'>ಅಂಶ</th>")
            slines.append("<th style='text-align:right'>ನಕ್ಷತ್ರ</th></tr>")
            
            sphuta_order = [
                "ಧೂಮ", "ವ್ಯತೀಪಾತ", "ಪರಿವೇಷ", "ಇಂದ್ರಚಾಪ", "ಉಪಕೇತು",
                "ಭೃಗು ಬಿ.", "ಬೀಜ", "ಕ್ಷೇತ್ರ", "ಯೋಗಿ",
                "ತ್ರಿಸ್ಫುಟ", "ಚತುಃಸ್ಫುಟ", "ಪಂಚಸ್ಫುಟ",
                "ಪ್ರಾಣ", "ದೇಹ", "ಮೃತ್ಯು", "ಸೂಕ್ಷ್ಮ ತ್ರಿ."
            ]
            
            for sp in sphuta_order:
                if sp in adv_sp:
                    d = adv_sp[sp]
                    r_name = KN_RASHI[int(d/30)]
                    deg_fmt = fmt_deg(d)
                    
                    nak_idx = int(d / 13.333333333)
                    pada = int((d % 13.333333333) / 3.333333333) + 1
                    nak_name = KN_NAK[nak_idx % 27]
                    pada_num = str(pada)
                    
                    sr = "<tr><td><b>" + sp + "</b></td><td>" + r_name + "</td>"
                    sr += "<td style='text-align:right'>" + deg_fmt + "</td>"
                    sr += "<td style='text-align:right'>" + nak_name + "-" + pada_num + "</td></tr>"
                    slines.append(sr)
                
            slines.append("</table></div>")
            st.markdown("".join(slines), unsafe_allow_html=True)
            
        with t3:
            st.markdown("#### ಆರೂಢ ಚಕ್ರ")
            
            c_aro1, c_aro2, c_aro3 = st.columns([2, 2, 1])
            aro_options = ["ಆರೂಢ", "ಉದಯ", "ಲಗ್ನಾಂಶ", "ಛತ್ರ", "ಸ್ಪೃಷ್ಟಾಂಗ", "ಚಂದ್ರ", "ತಾಂಬೂಲ"]
            
            selected_aro = c_aro1.selectbox("ಆರೂಢ ಆಯ್ಕೆಮಾಡಿ", aro_options)
            selected_rashi = c_aro2.selectbox("ರಾಶಿ ಆಯ್ಕೆಮಾಡಿ", KN_RASHI)
            
            st.markdown("""<style>div[data-testid="column"]:nth-of-type(3) { display: flex; align-items: flex-end; padding-bottom: 2px; }</style>""", unsafe_allow_html=True)
            if c_aro3.button("ಸೇರಿಸಿ", use_container_width=True):
                st.session_state.aroodhas[selected_aro] = KN_RASHI.index(selected_rashi)
                st.rerun()

            if len(st.session_state.aroodhas) > 0:
                if st.button("ತೆರವುಗೊಳಿಸಿ", key="clear_aro"):
                    st.session_state.aroodhas = {}
                    st.rerun()

            bxs_aro = {i: "" for i in range(12)}
            for a_name, r_idx in st.session_state.aroodhas.items():
                bxs_aro[r_idx] += f"<div class='hi'>{a_name}</div>"

            grid_aro = [11, 0, 1, 2, 10, None, None, 3, 9, None, None, 4, 8, 7, 6, 5]
            alines = ["<div class='grid-container' style='margin-top:20px;'>"]
            c_count_a = 0
            for idx in grid_aro:
                if idx is None:
                    if c_count_a == 0: 
                        alines.append("<div class='center-box'>ಆರೂಢ<br>ಚಕ್ರ</div>")
                        c_count_a = 1
                else: 
                    alines.append(f"<div class='box'><span class='lbl'>{KN_RASHI[idx]}</span>{bxs_aro[idx]}</div>")
            alines.append("</div>")
            st.markdown("".join(alines), unsafe_allow_html=True)

        with t4:
            lord_b = pan.get('lord_bal', '')
            d_b = pan.get('d_bal', '')
            bal_txt = "ಶಿಷ್ಟ ದಶೆ: " + lord_b + " ಉಳಿಕೆ: " + d_b
            ht = "<div class='card' style='color:#DD6B20; font-weight:900;'>"
            ht += bal_txt + "</div>"
            st.markdown(ht, unsafe_allow_html=True)
            
            if 'date_obj' in pan:
                dlines = []
                cur_d = pan['date_obj']
                si = pan.get('n_idx', 0) % 9
                perc = pan.get('perc', 0)
                
                for i in range(9):
                    im = (si + i) % 9
                    y_mul = (1 - perc) if i == 0 else 1
                    md_dur = YEARS[im] * y_mul
                    md_end = cur_d + datetime.timedelta(days=md_dur*365.25)
                    
                    dlines.append("<details><summary class='md-node'><span>")
                    dlines.append(LORDS[im] + "</span><span class='date-label'>")
                    dlines.append(md_end.strftime('%d-%m-%y') + "</span></summary>")
                    
                    cad = cur_d
                    for j in range(9):
                        ia = (im + j) % 9
                        ad_y = (YEARS[im] * YEARS[ia] / 120.0)
                        if i == 0: ad_y *= (1 - perc)
                        ae = cad + datetime.timedelta(days=ad_y*365.25)
                        
                        dlines.append("<details><summary class='ad-node'><span>")
                        dlines.append(LORDS[ia] + "</span><span class='date-label'>")
                        dlines.append(ae.strftime('%d-%m-%y') + "</span></summary>")
                        
                        cpd = cad
                        for k in range(9):
                            ip = (ia + k) % 9
                            pd_y = (ad_y * YEARS[ip] / 120.0)
                            pe = cpd + datetime.timedelta(days=pd_y*365.25)
                            
                            p_div = "<div class='pd-node' style='padding:10px 15px; "
                            p_div += "border-bottom:1px solid #EDF2F7; display:flex; "
                            p_div += "justify-content:space-between'><span>"
                            p_div += LORDS[ip] + "</span><span>" 
                            p_div += pe.strftime('%d-%m-%y') + "</span></div>"
                            
                            dlines.append(p_div)
                            cpd = pe
                        dlines.append("</details>")
                        cad = ae
                    dlines.append("</details>")
                    cur_d = md_end
                    
                st.markdown("".join(dlines), unsafe_allow_html=True)
        
        with t5:
            st.markdown("<div class='card'>", unsafe_allow_html=True)
            st.markdown(f"<p style='color:#2B6CB0; font-weight:800; margin:0;'>ಸ್ಥಳ: <span style='color:#2D3748;'>{st.session_state.place_input}</span></p>", unsafe_allow_html=True)
            st.markdown(f"<p style='color:#2B6CB0; font-weight:800; margin:0;'>ದಿನಾಂಕ: <span style='color:#2D3748;'>{st.session_state.dob_input.strftime('%d-%m-%Y')}</span></p>", unsafe_allow_html=True)
            st.markdown(f"<p style='color:#2B6CB0; font-weight:800; margin:0;'>ಸಮಯ: <span style='color:#2D3748;'>{st.session_state.h_input}:{str(st.session_state.m_input).zfill(2)} {st.session_state.ampm_input}</span></p>", unsafe_allow_html=True)
            st.markdown("</div>", unsafe_allow_html=True)
            
            p_lines = []
            p_lines.append("<div class='card'><table class='key-val-table'>")
            
            arr = [
                ("ವಾರ", str(pan.get('v', ''))),
                ("ತಿಥಿ", str(pan.get('t', ''))),
                ("ನಕ್ಷತ್ರ", str(pan.get('n', ''))),
                ("ಯೋಗ", str(pan.get('y', ''))),
                ("ಕರಣ", str(pan.get('k', ''))),
                ("ಚಂದ್ರ ರಾಶಿ", str(pan.get('r', ''))),
                ("ಉದಯಾದಿ ಘಟಿ", str(pan.get('udayadi', ''))),
                ("ಗತ ಘಟಿ", str(pan.get('gata', ''))),
                ("ಪರಮ ಘಟಿ", str(pan.get('parama', ''))),
                ("ಶೇಷ ಘಟಿ", str(pan.get('rem', '')))
            ]
            
            for k, v in arr:
                p_lines.append("<tr><td class='key'>" + k + "</td><td>")
                p_lines.append(v + "</td></tr>")
                
            p_lines.append("</table></div>")
            st.markdown("".join(p_lines), unsafe_allow_html=True)
                
        with t6:
            blines = []
            blines.append("<div class='card'><table class='key-val-table'>")
            blines.append("<tr><th>ಭಾವ</th><th>ಮಧ್ಯ (Sphuta)</th>")
            blines.append("<th>ರಾಶಿ</th></tr>")
            
            for i, deg in enumerate(bhavas):
                bhava_num = str(i + 1)
                r_name = KN_RASHI[int(deg/30)]
                d_fmt = fmt_deg(deg)
                
                br = "<tr><td><b>" + bhava_num + "</b></td><td>" + d_fmt
                br += "</td><td>" + r_name + "</td></tr>"
                blines.append(br)
                
            blines.append("</table></div>")
            st.markdown("".join(blines), unsafe_allow_html=True)
            
        with t7:
            st.markdown("<h4 style='text-align:center; color:#DD6B20;'>ಸರ್ವಾಷ್ಟಕವರ್ಗ (SAV)</h4>", unsafe_allow_html=True)
            
            grid_sav = [11, 0, 1, 2, 10, None, None, 3, 9, None, None, 4, 8, 7, 6, 5]
            
            slines = []
            slines.append("<div class='grid-container'>")
            
            c_count = 0
            for idx in grid_sav:
                if idx is None:
                    if c_count == 0: 
                        s_txt = "<div class='center-box'>ಒಟ್ಟು ಬಿಂದು<br>"
                        s_txt += f"<span style='font-size:20px; color:#E53E3E;'>{sum(sav_vals)}</span></div>"
                        slines.append(s_txt)
                        c_count = 1
                else: 
                    bx_str = "<div class='box'><span class='lbl'>" 
                    bx_str += KN_RASHI[idx] + "</span><div class='bindu'>" + str(sav_vals[idx]) + "</div></div>"
                    slines.append(bx_str)
                    
            slines.append("</div>")
            st.markdown("".join(slines), unsafe_allow_html=True)
            
            st.markdown("<br><h4 style='text-align:center; color:#2B6CB0;'>📝 ಬಿನ್ನಾಷ್ಟಕವರ್ಗ (BAV Detail)</h4>", unsafe_allow_html=True)
            
            t_arr = []
            t_arr.append("<div class='card' style='overflow-x:auto;'>")
            t_arr.append("<table class='bav-table' style='width:100%; text-align:center;'>")
            t_arr.append("<tr><th>ರಾಶಿ</th><th>ರವಿ</th><th>ಚಂ</th><th>ಕು</th><th>ಬು</th>")
            t_arr.append("<th>ಗು</th><th>ಶು</th><th>ಶ</th><th>ಒಟ್ಟು</th></tr>")
            
            for i in range(12):
                tr = "<tr><td><b>" + KN_RASHI[i] + "</b></td>"
                for p in ["ರವಿ", "ಚಂದ್ರ", "ಕುಜ", "ಬುಧ", "ಗುರು", "ಶುಕ್ರ", "ಶನಿ"]:
                    val = bav_vals.get(p, [0]*12)[i] if bav_vals else 0
                    tr += "<td>" + str(val) + "</td>"
                tr += "<td style='color:#E53E3E; font-weight:bold;'>" + str(sav_vals[i]) + "</td></tr>"
                t_arr.append(tr)
                
            t_arr.append("</table></div>")
            st.markdown("".join(t_arr), unsafe_allow_html=True)

        with t8:
            val = st.session_state.notes
            st.session_state.notes = st.text_area("ಟಿಪ್ಪಣಿಗಳು", value=val, height=300)

        with t9:
            st.markdown("<div class='card' style='text-align:center;'>", unsafe_allow_html=True)
            st.markdown("### 🚫 ಜಾಹೀರಾತು-ಮುಕ್ತ")
            
            info_text = "<p style='color:#718096; font-weight:600;'>ಜಾಹೀರಾತುಗಳಿಲ್ಲದೆ ನಿರಂತರವಾಗಿ ಆ್ಯಪ್ ಬಳಸಿ.<br></p>"
            st.markdown(info_text, unsafe_allow_html=True)
            
            st.markdown("<br>", unsafe_allow_html=True)
            st.button("ಜಾಹೀರಾತು ತೆಗೆಯಿರಿ (₹99)", type="primary", use_container_width=True)
            st.markdown("</div>", unsafe_allow_html=True)

        with t10:
            st.markdown("<div class='card'>", unsafe_allow_html=True)
            st.markdown("#### ಭಾರತೀಯಮ್")
            
            info = "<p style='color:#4A5568; font-size:14px; line-height:1.6;'>"
            info += "<b>ಆವೃತ್ತಿ: 1.0.1</b><br><br>"
            info += "ನಿಖರವಾದ ವೈದಿಕ ಜ್ಯೋತಿಷ್ಯ ಲೆಕ್ಕಾಚಾರಗಳಿಗಾಗಿ ವಿನ್ಯಾಸಗೊಳಿಸಲಾಗಿದೆ.</p>"
            st.markdown(info, unsafe_allow_html=True)
            
            st.markdown("<br>", unsafe_allow_html=True)
            
            st.link_button("</> ಮೂಲ ಕೋಡ್", "https://github.com/your-username/bharatheeyam", use_container_width=True)
            
            st.markdown("</div>", unsafe_allow_html=True)

    except Exception as e:
        st.error(f"ಡ್ಯಾಶ್‌ಬೋರ್ಡ್ ಲೋಡ್ ಮಾಡುವಲ್ಲಿ ದೋಷ: {str(e)}")
        if st.button("ಹಿಂದಕ್ಕೆ ಹೋಗಿ"):
            st.session_state.page = "input"
            st.rerun()

