import sys
import os
import math

try:
    import swisseph as swe
except ImportError:
    os.system('pip install pyswisseph')
    import swisseph as swe

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

lat = 14.9667
lon = 74.7167
sr, ss = find_sunrise_set_for_date(2026, 3, 1, lat, lon)
print(f"Python Sunrise JD: {sr}")
print(f"Python Sunset JD: {ss}")
