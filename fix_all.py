"""
Surgical removal of specific yogas from viyoni_janma.dart.
Starts from the last known-good commit (82d10c6) backup.
Only removes yogas.add(...) blocks, NOT shared variable definitions.
Also adds the Navamsha/Chaya feature and dvigraha rashi fix.
"""
import re, copy

good_path = r'D:\bharatheeyamapp clone\viyoni_good.dart.bak'
out_path = r'D:\bharatheeyamapp clone\lib\core\viyoni_janma.dart'

with open(out_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Yoga names to remove - these are the exact names in yogas.add(Yoga(...name:'...'
remove_names = [
    "ಪಕ್ಷಿ ಜನ್ಮ ಯೋಗ",
    "ವೃಕ್ಷ ಜನ್ಮ ಯೋಗ",
    "ವೃಕ್ಷ ಪ್ರಕಾರ ಯೋಗ",
    "ನವಾಂಶ ವೃಕ್ಷ ಸಂಖ್ಯೆ",
    "ಋತುದರ್ಶನ ಯೋಗ",
    "ಮಿಲನ ಯೋಗ",
    "ಮಿಲನ ಸ್ವರೂಪ ಯೋಗ",
    "ಪಿತೃ-ಮಾತೃ ಕಾರಕ ಯೋಗ",
    "ಪುತ್ರ ಜನನ ಯೋಗ (೧೨,೧೩)",
    "ಪುತ್ರಿ ಜನನ ಯೋಗ (೧೨)",
    "ಗರ್ಭ ಮಾಸಾಧಿಪತಿ ಫಲ (೧೬)",
    "ಜನನ ಕಾಲ ನಿರ್ಣಯ (೨೧)",
    "ಅನ್ಯಜಾತ ಯೋಗ (ಜಕ ೫)",
    "ಹೆರಿಗೆ ಮನೆ ಲಕ್ಷಣ (ಜಕ ೧೮)",
    "ಹೆರಿಗೆ ಮನೆ ಸ್ವರೂಪ (ಜಕ ೧೯)",
    "ಹೆರಿಗೆ ಕೋಣೆ ದಿಕ್ಕು (ಜಕ ೨೦)",
    "ಹಾಸಿಗೆ ಪಾದ ಯೋಗ (ಜಕ ೨೧)",
    "ಉಪಸೂತಿಕಾ ಯೋಗ (ಜಕ ೨೨)",
    "ಶಿಶು ಶರೀರ/ಬಣ್ಣ (ಜಕ ೨೩)",
    "ದೇಹಾಂಗ ರಾಶಿ ಮ್ಯಾಪ್ (ಜಕ ೨೪)",
]

# Strategy: Find each yogas.add(Yoga(... block and its surrounding if() block
# Only remove the yogas.add and its conditional wrapper, NOT preceding var defs

def find_yoga_add_blocks(lines, name):
    """Find the yogas.add(Yoga(...name:'<name>'...)) block and its if wrapper."""
    for i, line in enumerate(lines):
        if f"name: '{name}'" in line:
            # Find the yogas.add( start - go backwards
            add_start = i
            for j in range(i, max(0, i-8), -1):
                if 'yogas.add(Yoga(' in lines[j]:
                    add_start = j
                    break
            
            # Find the closing )); of yogas.add
            add_end = i
            depth = 0
            for j in range(add_start, min(len(lines), add_start + 15)):
                for ch in lines[j]:
                    if ch == '(': depth += 1
                    elif ch == ')': depth -= 1
                if depth <= 0 and j > add_start:
                    add_end = j
                    break
            
            # Check if the line before yogas.add is an if(...) { — if so, include it
            # Also find matching closing }
            block_start = add_start
            block_end = add_end + 1
            
            # Look backwards for the if() that wraps this yoga
            for j in range(add_start - 1, max(0, add_start - 5), -1):
                stripped = lines[j].strip()
                if stripped.startswith('if (') and stripped.endswith('{'):
                    block_start = j
                    # Find matching } after the add_end
                    for k in range(add_end + 1, min(len(lines), add_end + 3)):
                        if lines[k].strip() == '}':
                            block_end = k + 1
                            break
                    break
                elif stripped == '' or stripped.startswith('//'):
                    continue
                else:
                    break
            
            return (block_start, block_end, name)
    return None

# Find all blocks to remove
to_remove = []
for name in remove_names:
    result = find_yoga_add_blocks(lines, name)
    if result:
        to_remove.append(result)
        print(f"FOUND L{result[0]+1}-L{result[1]}: {name}")
    else:
        print(f"NOT FOUND: {name}")

# Sort by start descending to remove from bottom first
to_remove.sort(key=lambda x: x[0], reverse=True)

# Remove blocks
for start, end, name in to_remove:
    # Before removing, check if any of these lines define variables used elsewhere
    # We'll be conservative - only remove lines within the if() block
    del lines[start:end]

# === Apply Navamsha/Chaya feature ===
# 1. Modify detectAll to add includeNavamsha parameter
detectall_found = False
for i, line in enumerate(lines):
    if 'static List<Yoga> detectAll(KundaliResult chart)' in line:
        lines[i] = line.replace(
            'static List<Yoga> detectAll(KundaliResult chart)',
            'static List<Yoga> detectAll(KundaliResult chart, {bool includeNavamsha = false})'
        )
        detectall_found = True
        break

# 2. Find "return allYogas;" in detectAll and insert Chaya pass before it
for i, line in enumerate(lines):
    if 'return allYogas;' in line and i < 120:  # Should be within detectAll
        chaya_code = """
    // ── ಛಾಯಾ (Navamsha) pass ──
    if (includeNavamsha) {
      final navChart = _toNavamshaChart(chart);
      final navSeen = <String>{};
      for (int ref = 0; ref < 12; ref++) {
        final yogas = detect(navChart, lagnaRashi: ref);
        for (final y in yogas) {
          final rashiKey = '${y.name}|${y.result}|${y.rashi}';
          if (seen.contains(rashiKey)) continue;
          final key = 'CHAYA|${y.name}|${y.result}|${y.rashi}';
          if (!navSeen.contains(key)) {
            navSeen.add(key);
            allYogas.add(Yoga(
              shloka: y.shloka,
              name: '\\u0c9b\\u0cbe\\u0caf\\u0cbe: ${y.name}',
              description: '\\u27ea${_rashiNamesShort[ref]} \\u0cb2\\u0c97\\u0ccd\\u0ca8 \\u2014 \\u0ca8\\u0cb5\\u0cbe\\u0c82\\u0cb6 \\u0c86\\u0ca7\\u0cbe\\u0cb0\\u27eb\\n${y.description}',
              result: '${y.result} (\\u0c9b\\u0cbe\\u0caf\\u0cbe)',
              rashi: y.rashi,
              planets: y.planets,
              refLagna: ref,
            ));
          }
        }
      }
    }

"""
        lines.insert(i, chaya_code)
        break

# 3. Add _toNavamshaChart method after detectAll closing
for i, line in enumerate(lines):
    if '/// Detect all active yogas for the given chart.' in line:
        nav_method = """
  /// Convert a chart to navamsha-equivalent longitudes.
  static KundaliResult _toNavamshaChart(KundaliResult chart) {
    final navPlanets = <String, PlanetInfo>{};
    for (final e in chart.planets.entries) {
      final navR = _d9Rashi(e.value.longitude);
      final navLon = navR * 30.0 + 15.0;
      navPlanets[e.key] = PlanetInfo(
        name: e.value.name,
        longitude: navLon,
        speed: e.value.speed,
        nakshatra: e.value.nakshatra,
        pada: e.value.pada,
        rashi: _rashiNames[navR],
        rashiIndex: navR,
        subDrekD1: e.value.subDrekD1,
        subDrekD9: e.value.subDrekD9,
        subDrekD12: e.value.subDrekD12,
        d9OfD9: e.value.d9OfD9,
        isCombust: e.value.isCombust,
      );
    }
    final lagLon = chart.bhavas.isNotEmpty ? chart.bhavas[0] : 0.0;
    final navLagR = _d9Rashi(lagLon);
    final navBhavas = List<double>.generate(12, (i) => ((navLagR + i) * 30.0 + 15.0) % 360);
    return KundaliResult(
      planets: navPlanets,
      bhavas: navBhavas,
      shadbala: chart.shadbala,
      panchang: chart.panchang,
      dashas: chart.dashas,
      advSphutas: chart.advSphutas,
    );
  }

"""
        lines.insert(i, nav_method)
        break

# 4. Fix dvigraha rashi: dyTogetherRashi should return lagRashi
for i, line in enumerate(lines):
    if 'int dyTogetherRashi(String p1, String p2)' in line:
        # Replace next line
        if i+1 < len(lines) and 'allPLons[p1]' in lines[i+1]:
            lines[i+1] = '      return lagRashi;\n'
        break

# Write output
with open(out_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

content = ''.join(lines)
print(f"\nDone! Lines: {len(lines)}")
print(f"Balance: {content.count('{')}/{content.count('}')} {content.count('(')}/{content.count(')')}")
print(f"allPLons defined: {'allPLons' in content and 'final allPLons' in content}")
print(f"rashiLords defined: {'const rashiLords' in content}")
print(f"h7Rashi defined: {'final h7Rashi' in content}")
print(f"jupInTrikona defined: {'final jupInTrikona' in content}")
