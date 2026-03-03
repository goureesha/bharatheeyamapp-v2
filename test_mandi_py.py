import sys
import os
import math
import datetime

try:
    import swisseph as swe
except ImportError:
    os.system('pip install pyswisseph')
    import swisseph as swe

swe.set_ephe_path('bharatheeyam_py/Bharatheeyam-main')

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
            p_sr, p_ss = find_sunrise_set_for_date(prev_d.year, prev_d.month, prev_d.day, lat, lon)
            start_base = p_ss
            duration = sr_civil - p_ss
            panch_sr = p_sr
        else:
            vedic_wday = civil_weekday_idx
            next_d = dob_obj + datetime.timedelta(days=1)
            n_sr, n_ss = find_sunrise_set_for_date(next_d.year, next_d.month, next_d.day, lat, lon)
            start_base = ss_civil
            duration = n_sr - ss_civil
            panch_sr = sr_civil
            
    if not is_night:
        factors = [26, 22, 18, 14, 10, 6, 2]
    else:
        factors = [10, 6, 2, 26, 22, 18, 14]
        
    factor = factors[vedic_wday]
    mandi_time_jd = start_base + (duration * factor / 30.0)

    print(f"PYTHON: Is Night: {is_night}")
    print(f"PYTHON: Vedic Weekday: {vedic_wday}")
    print(f"PYTHON: Start Base JD: {start_base}")
    print(f"PYTHON: Duration: {duration}")
    print(f"PYTHON: Factor: {factor}")
    print(f"PYTHON: Mandi Time JD: {mandi_time_jd}")
    
    return mandi_time_jd

lat = 14.9667
lon = 74.7167
dt = datetime.datetime(2026, 3, 1, 17, 6) # 01 March 2026, 05:06 PM
jd_birth = swe.julday(dt.year, dt.month, dt.day, 17 + 6/60.0 - 5.5)

calculate_mandi(jd_birth, lat, lon, dt)
