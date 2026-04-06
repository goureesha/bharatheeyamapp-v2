"""
Generate a sample Janma Patrike PDF using fpdf2 + uharfbuzz.
Proper Kannada text rendering with HarfBuzz text shaping.
"""
import os
import urllib.request
from fpdf import FPDF

OUTPUT_PDF = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sample_janma_patrike.pdf")

# ── Download Noto Sans Kannada static fonts ──
FONT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fonts")

def ensure_font(name, url):
    path = os.path.join(FONT_DIR, name)
    if not os.path.exists(path):
        os.makedirs(FONT_DIR, exist_ok=True)
        print(f"Downloading {name}...")
        urllib.request.urlretrieve(url, path)
    return path

FONT_REG = ensure_font("NotoSansKannada-Regular.ttf",
    "https://github.com/google/fonts/raw/main/ofl/notosanskannada/static/NotoSansKannada-Regular.ttf")
FONT_BOLD = ensure_font("NotoSansKannada-Bold.ttf",
    "https://github.com/google/fonts/raw/main/ofl/notosanskannada/static/NotoSansKannada-Bold.ttf")


class JanmaPatrikePDF(FPDF):
    def __init__(self):
        super().__init__(orientation='P', unit='mm', format='A4')
        self.set_auto_page_break(auto=False)
        # Register Kannada fonts
        self.add_font('Kn', '', FONT_REG, uni=True)
        self.add_font('Kn', 'B', FONT_BOLD, uni=True)

    # ── Color presets ──
    C_PRIMARY   = (46, 26, 71)
    C_SECONDARY = (106, 27, 154)
    C_ACCENT    = (198, 40, 40)
    C_HEADER_BG = (245, 240, 232)
    C_PANCHANG  = (245, 251, 245)
    C_TABLE_HDR = (74, 20, 140)
    C_TABLE_ALT = (245, 240, 232)
    C_BORDER    = (158, 158, 158)
    C_TEXT      = (33, 33, 33)
    C_TEXT_LT   = (97, 97, 97)
    C_CHART_BG  = (255, 255, 255)
    C_CHART_CTR = (245, 240, 232)
    C_DASHA_ALT = (232, 234, 246)
    C_PAGE_BG   = (255, 255, 248)
    C_WHITE     = (255, 255, 255)

    def _bg(self):
        self.set_fill_color(*self.C_PAGE_BG)
        self.rect(0, 0, 210, 297, 'F')

    def _text(self, x, y, txt, size=8, bold=False, color=None, align='L', w=0):
        self.set_font('Kn', 'B' if bold else '', size)
        self.set_text_color(*(color or self.C_TEXT))
        if align == 'C' and w > 0:
            tw = self.get_string_width(txt)
            x = x + (w - tw) / 2
        elif align == 'R' and w > 0:
            tw = self.get_string_width(txt)
            x = x + w - tw
        self.text(x, y, txt)

    def _rect(self, x, y, w, h, fill=None, border=None, bw=0.2):
        if fill:
            self.set_fill_color(*fill)
            self.rect(x, y, w, h, 'F')
        if border:
            self.set_draw_color(*border)
            self.set_line_width(bw)
            self.rect(x, y, w, h, 'D')

    def _line(self, x1, y1, x2, y2, color=None, w=0.2):
        self.set_draw_color(*(color or self.C_BORDER))
        self.set_line_width(w)
        self.line(x1, y1, x2, y2)

    def _field(self, x, y, label, value, lw=32):
        self._text(x, y, label + ':', size=7, bold=True)
        self._text(x + lw, y, value, size=7)

    def draw_header(self, y, subtitle=None, person=None):
        M = 18; AW = 174
        self._rect(M, y, AW, 18, fill=self.C_HEADER_BG, border=self.C_PRIMARY, bw=0.5)
        self._text(M, y+5, '\u0cb6\u0ccd\u0cb0\u0cc0 \u0c97\u0ca3\u0cc7\u0cb6\u0cbe\u0caf \u0ca8\u0cae\u0c83 \u0964\u0964 \u0cb6\u0ccd\u0cb0\u0cc0 \u0c97\u0cc1\u0cb0\u0cc1\u0cad\u0ccd\u0caf\u0ccb \u0ca8\u0cae\u0c83 \u0964\u0964',
                   size=9, bold=True, color=self.C_ACCENT, align='C', w=AW)
        title = subtitle or '\u0c9c\u0ca8\u0ccd\u0cae \u0caa\u0ca4\u0ccd\u0cb0\u0cbf\u0c95\u0cc6'
        self._text(M, y+12, title, size=14, bold=True, color=self.C_PRIMARY, align='C', w=AW)
        if person:
            self._text(M, y+17, person, size=7, bold=True, color=self.C_TEXT, align='C', w=AW)
        else:
            self._text(M, y+17, '\u0cad\u0cbe\u0cb0\u0ca4\u0cc0\u0caf\u0c82 \u0c9c\u0ccd\u0caf\u0ccb\u0ca4\u0cbf\u0cb7 \u0c85\u0caa\u0ccd\u0cb2\u0cbf\u0c95\u0cc7\u0cb6\u0ca8\u0ccd',
                       size=7, color=self.C_TEXT_LT, align='C', w=AW)
        return y + 20

    def draw_footer(self):
        y = 285; M = 18; AW = 174
        self._line(M, y, M+AW, y, self.C_BORDER, 0.2)
        self._text(M, y+4, '\u0cb6\u0ccd\u0cb0\u0cc0 \u0cb0\u0cbe\u0cae\u0c9a\u0c82\u0ca6\u0ccd\u0cb0 \u0c9c\u0ccd\u0caf\u0ccb\u0ca4\u0cbf\u0cb7',
                   size=6.5, bold=True)
        self._text(M, y+4, '\u0cad\u0cbe\u0cb0\u0ca4\u0cc0\u0caf\u0c82', size=6.5, color=self.C_TEXT_LT, align='C', w=AW)
        self._text(M, y+4, '9480603273', size=6.5, bold=True, align='R', w=AW)
        self._text(M, y+7.5, '\u0cac\u0cc6\u0c82\u0c97\u0cb3\u0cc2\u0cb0\u0cc1', size=6, color=self.C_TEXT_LT)

    def draw_south_chart(self, x, y, sz, planets, center_label):
        cell = sz / 4
        # Background
        self._rect(x, y, sz, sz, fill=self.C_CHART_BG, border=(51,51,51), bw=0.4)
        # Grid lines
        for i in range(1, 4):
            self._line(x, y + i*cell, x+sz, y + i*cell, (85,85,85), 0.2)
            self._line(x + i*cell, y, x + i*cell, y+sz, (85,85,85), 0.2)
        # Center
        self._rect(x+cell, y+cell, 2*cell, 2*cell, fill=self.C_CHART_CTR, border=(51,51,51), bw=0.3)
        self._text(x+cell, y+cell + cell + 1.5, center_label, size=8, bold=True, color=self.C_PRIMARY, align='C', w=2*cell)

        # Rashi positions: index -> (row, col)
        positions = [
            (0,1),(0,2),(0,3),(1,3),(2,3),(3,3),
            (3,2),(3,1),(3,0),(2,0),(1,0),(0,0),
        ]
        for ri, (row, col) in enumerate(positions):
            cx = x + col * cell + 1
            cy = y + row * cell + cell/2 + 1
            plist = planets.get(ri, [])
            if plist:
                self._text(cx, cy, ' '.join(plist), size=6, bold=True, color=self.C_TEXT)
            else:
                self._text(cx, cy, '\u0cb6\u0ccd\u0cb0\u0cc0:', size=6, bold=True, color=self.C_ACCENT)


def build_page1(pdf):
    pdf.add_page()
    pdf._bg()
    M = 18; AW = 174; COL = AW / 2

    # ── Header ──
    y = pdf.draw_header(8)
    y += 2

    # ── Personal Details ──
    bh = 18
    pdf._rect(M, y, AW, bh, border=pdf.C_BORDER, bw=0.15)
    fields = [
        [('\u0c9c\u0cbe\u0ca4\u0c95\u0cb0 \u0cb9\u0cc6\u0cb8\u0cb0\u0cc1', '\u0cb0\u0cbe\u0cae\u0c95\u0cc3\u0cb7\u0ccd\u0ca3'), ('\u0c9c\u0ca8\u0ccd\u0cae \u0c8a\u0cb0\u0cc1', '\u0cac\u0cc6\u0c82\u0c97\u0cb3\u0cc2\u0cb0\u0cc1')],
        [('\u0c9c\u0ca8\u0ca8 \u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95', '12-06-1997'), ('\u0c9c\u0ca8\u0ccd\u0cae \u0cb8\u0cae\u0caf', '08:00 AM')],
        [('\u0ca4\u0c82\u0ca6\u0cc6 \u0cb9\u0cc6\u0cb8\u0cb0\u0cc1', '\u0cb6\u0c82\u0c95\u0cb0'), ('\u0ca4\u0cbe\u0caf\u0cbf \u0cb9\u0cc6\u0cb8\u0cb0\u0cc1', '\u0cb2\u0c95\u0ccd\u0cb7\u0ccd\u0cae\u0cbf')],
        [('\u0c97\u0ccb\u0ca4\u0ccd\u0cb0', '\u0cad\u0cbe\u0cb0\u0ca6\u0ccd\u0cb5\u0cbe\u0c9c'), ('\u0cb2\u0c97\u0ccd\u0ca8 \u0cb0\u0cbe\u0cb6\u0cbf', '\u0c95\u0cb0\u0ccd\u0c95\u0cbe\u0c9f\u0c95')],
    ]
    for i, row in enumerate(fields):
        fy = y + 2 + i * 4
        pdf._field(M+2, fy, row[0][0], row[0][1], lw=30)
        pdf._field(M+COL+2, fy, row[1][0], row[1][1], lw=28)
    y += bh + 2

    # ── Panchanga ──
    pdf._text(M, y+3.5, '\u0caa\u0c82\u0c9a\u0cbe\u0c82\u0c97 \u0cb5\u0cbf\u0cb5\u0cb0', size=9, bold=True, color=pdf.C_SECONDARY, align='C', w=AW)
    y += 5
    prows = [
        [('\u0cb8\u0c82\u0cb5\u0ca4\u0ccd\u0cb8\u0cb0', '\u0caa\u0ccd\u0cb2\u0cb5'), ('\u0c9a\u0c82\u0ca6\u0ccd\u0cb0 \u0cae\u0cbe\u0cb8', '\u0c9c\u0ccd\u0caf\u0cc7\u0cb7\u0ccd\u0ca0')],
        [('\u0cb0\u0cb5\u0cbf \u0cae\u0cbe\u0cb8', '\u0cae\u0cbf\u0ca5\u0cc1\u0ca8'), ('\u0c97\u0ca4 \u0ca6\u0cbf\u0ca8', '28')],
        [('\u0ca4\u0cbf\u0ca5\u0cbf', '\u0cb6\u0cc1. \u0cb8\u0caa\u0ccd\u0ca4\u0cae\u0cbf'), ('\u0cb5\u0cbe\u0cb0', '\u0c97\u0cc1\u0cb0\u0cc1\u0cb5\u0cbe\u0cb0')],
        [('\u0ca8\u0c95\u0ccd\u0cb7\u0ca4\u0ccd\u0cb0', '\u0c85\u0cb6\u0ccd\u0cb5\u0cbf\u0ca8\u0cbf - 1'), ('\u0c95\u0cb0\u0ca3', '\u0cb5\u0ca3\u0cbf\u0c9c')],
        [('\u0caf\u0ccb\u0c97', '\u0cb6\u0ccb\u0cad\u0ca8'), ('\u0c8b\u0ca4\u0cc1', '\u0c97\u0ccd\u0cb0\u0cc0\u0cb7\u0ccd\u0cae')],
        [('\u0cb5\u0cbf\u0cb7 \u0c98\u0c9f\u0cbf', '12-34'), ('\u0c85\u0cae\u0cc3\u0ca4 \u0c98\u0c9f\u0cbf', '45-23')],
        [('\u0c89\u0ca6\u0caf\u0cbe\u0ca6\u0cbf \u0c98\u0c9f\u0cbf', '18-19'), ('\u0c9a\u0c82\u0ca6\u0ccd\u0cb0 \u0cb0\u0cbe\u0cb6\u0cbf', '\u0cae\u0cc7\u0cb7')],
        [('\u0cb8\u0cc2\u0cb0\u0ccd\u0caf\u0ccb\u0ca6\u0caf', '05:56'), ('\u0cb8\u0cc2\u0cb0\u0ccd\u0caf\u0cbe\u0cb8\u0ccd\u0ca4', '18:42')],
    ]
    ph = len(prows) * 4 + 3
    pdf._rect(M, y, AW, ph, fill=pdf.C_PANCHANG, border=pdf.C_BORDER, bw=0.15)
    for i, row in enumerate(prows):
        fy = y + 2 + i * 4
        pdf._field(M+2, fy, row[0][0], row[0][1], lw=32)
        pdf._field(M+COL+2, fy, row[1][0], row[1][1], lw=30)
    y += ph + 2

    # ── Graha Sthiti Table ──
    pdf._text(M, y+3.5, '\u0ca4\u0ca4\u0ccd\u0c95\u0cbe\u0cb2 \u0c97\u0ccd\u0cb0\u0cb9\u0cb8\u0ccd\u0ca5\u0cbf\u0ca4\u0cbf', size=9, bold=True, color=pdf.C_SECONDARY, align='C', w=AW)
    y += 5

    headers = ['\u0c97\u0ccd\u0cb0\u0cb9', '\u0cb0\u0cbe\u0cb6\u0cbf', '\u0c85\u0c82\u0cb6', '\u0ca8\u0c95\u0ccd\u0cb7\u0ca4\u0ccd\u0cb0', '\u0caa\u0cbe\u0ca6', '\u0cb5\u0c95\u0ccd\u0cb0', '\u0c85\u0cb8\u0ccd\u0ca4']
    col_widths = [26, 22, 22, 32, 16, 16, 16]  # total ~150, will scale
    # Scale to fit AW
    total = sum(col_widths)
    col_widths = [c * AW / total for c in col_widths]

    rh = 5  # row height
    # Header row
    pdf._rect(M, y, AW, rh, fill=pdf.C_TABLE_HDR)
    cx = M
    for hi, hw in zip(headers, col_widths):
        pdf._text(cx+1, y+3.5, hi, size=6.5, bold=True, color=pdf.C_WHITE, align='C', w=hw-2)
        cx += hw
    y += rh

    planets = [
        ('\u0cb2\u0c97\u0ccd\u0ca8', '\u0c95\u0cb0\u0ccd\u0c95\u0cbe', '15\u00b023\'', '\u0caa\u0cc1\u0cb7\u0ccd\u0caf', '2', '-', '-'),
        ('\u0cb0\u0cb5\u0cbf', '\u0cb5\u0cc3\u0cb7\u0cad', '27\u00b045\'', '\u0cae\u0cc3\u0c97\u0cb6\u0cbf\u0cb0', '3', '-', '-'),
        ('\u0c9a\u0c82\u0ca6\u0ccd\u0cb0', '\u0cae\u0cc7\u0cb7', '10\u00b012\'', '\u0c85\u0cb6\u0ccd\u0cb5\u0cbf\u0ca8\u0cbf', '1', '-', '-'),
        ('\u0c95\u0cc1\u0c9c', '\u0c95\u0ca8\u0ccd\u0caf\u0cbe', '21\u00b033\'', '\u0cb9\u0cb8\u0ccd\u0ca4', '4', '-', '-'),
        ('\u0cac\u0cc1\u0ca7', '\u0cae\u0cbf\u0ca5\u0cc1\u0ca8', '03\u00b018\'', '\u0cae\u0cc3\u0c97\u0cb6\u0cbf\u0cb0', '1', '-', '\u0c85'),
        ('\u0c97\u0cc1\u0cb0\u0cc1', '\u0cae\u0c95\u0cb0', '25\u00b006\'', '\u0ca7\u0ca8\u0cbf\u0cb7\u0ccd\u0ca0', '3', '\u0cb5', '-'),
        ('\u0cb6\u0cc1\u0c95\u0ccd\u0cb0', '\u0c95\u0cb0\u0ccd\u0c95\u0cbe', '11\u00b051\'', '\u0caa\u0cc1\u0cb7\u0ccd\u0caf', '1', '-', '-'),
        ('\u0cb6\u0ca8\u0cbf', '\u0cae\u0cc7\u0cb7', '09\u00b022\'', '\u0c85\u0cb6\u0ccd\u0cb5\u0cbf\u0ca8\u0cbf', '3', '-', '-'),
        ('\u0cb0\u0cbe\u0cb9\u0cc1', '\u0c95\u0ca8\u0ccd\u0caf\u0cbe', '28\u00b015\'', '\u0c9a\u0cbf\u0ca4\u0ccd\u0cb0', '2', '-', '-'),
        ('\u0c95\u0cc7\u0ca4\u0cc1', '\u0cae\u0cc0\u0ca8', '28\u00b015\'', '\u0cb0\u0cc7\u0cb5\u0ca4\u0cbf', '4', '-', '-'),
    ]
    for pi, prow in enumerate(planets):
        bg = pdf.C_TABLE_ALT if pi % 2 == 0 else pdf.C_WHITE
        pdf._rect(M, y, AW, rh, fill=bg)
        cx = M
        for vi, (val, cw) in enumerate(zip(prow, col_widths)):
            bold = (vi == 0)
            pdf._text(cx+1, y+3.5, val, size=6.5, bold=bold, align='C', w=cw-2)
            cx += cw
        y += rh
    pdf._rect(M, y - rh*(len(planets)+1), AW, rh*(len(planets)+1), border=pdf.C_BORDER, bw=0.15)
    y += 3

    # ── 3 Kundali Charts ──
    chart_sz = (AW - 8) / 3
    rashi_p = {0: ['\u0c9a\u0c82','\u0cb6'], 1: ['\u0cb0'], 2: ['\u0cac\u0cc1'], 3: ['\u0cb2','\u0cb6\u0cc1'],
               5: ['\u0c95\u0cc1','\u0cb0\u0cbe'], 9: ['\u0c97\u0cc1'], 11: ['\u0c95\u0cc7']}
    nav_p = {0: ['\u0c97\u0cc1'], 1: ['\u0cb0'], 2: ['\u0cac\u0cc1','\u0c95\u0cc1'], 3: ['\u0cb2'],
             4: ['\u0cb6\u0cc1'], 6: ['\u0c9a\u0c82'], 7: ['\u0cb6'], 8: ['\u0cb0\u0cbe'], 11: ['\u0c95\u0cc7']}
    bhav_p = {0: ['\u0c9a\u0c82','\u0cb6'], 1: ['\u0cb0'], 2: ['\u0cac\u0cc1'], 3: ['\u0cb2','\u0cb6\u0cc1'],
              5: ['\u0c95\u0cc1','\u0cb0\u0cbe'], 9: ['\u0c97\u0cc1'], 11: ['\u0c95\u0cc7']}

    charts = [('\u0cb0\u0cbe\u0cb6\u0cbf', rashi_p), ('\u0ca8\u0cb5\u0cbe\u0c82\u0cb6', nav_p), ('\u0cad\u0cbe\u0cb5', bhav_p)]
    for ci, (label, pmap) in enumerate(charts):
        cx = M + ci * (chart_sz + 4)
        pdf.draw_south_chart(cx, y, chart_sz, pmap, label)
        pdf._text(cx, y + chart_sz + 3, label + ' \u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf',
                  size=7, bold=True, color=pdf.C_PRIMARY, align='C', w=chart_sz)

    pdf.draw_footer()


def build_page2(pdf):
    pdf.add_page()
    pdf._bg()
    M = 18; AW = 174; COL = AW / 2

    # ── Header ──
    y = pdf.draw_header(8,
        subtitle='\u0c9c\u0ca8\u0ccd\u0cae \u0caa\u0ca4\u0ccd\u0cb0\u0cbf\u0c95\u0cc6 \u2014 \u0ca6\u0cb6\u0cbe \u0cb5\u0cbf\u0cb5\u0cb0',
        person='\u0cb0\u0cbe\u0cae\u0c95\u0cc3\u0cb7\u0ccd\u0ca3 \u2014 12-06-1997')
    y += 3

    # ── Nakshatra & Dasha Details ──
    pdf._text(M, y+3.5, '\u0ca8\u0c95\u0ccd\u0cb7\u0ca4\u0ccd\u0cb0 \u0cae\u0ca4\u0ccd\u0ca4\u0cc1 \u0ca6\u0cb6\u0cbe \u0cb5\u0cbf\u0cb5\u0cb0',
              size=9, bold=True, color=pdf.C_SECONDARY, align='C', w=AW)
    y += 5
    dd_rows = [
        [('\u0c9c\u0ca8\u0ccd\u0cae \u0ca8\u0c95\u0ccd\u0cb7\u0ca4\u0ccd\u0cb0', '\u0c85\u0cb6\u0ccd\u0cb5\u0cbf\u0ca8\u0cbf'), ('\u0ca8\u0c95\u0ccd\u0cb7\u0ca4\u0ccd\u0cb0 \u0caa\u0cbe\u0ca6', '1')],
        [('\u0ca8\u0c95\u0ccd\u0cb7\u0ca4\u0ccd\u0cb0 \u0caa\u0cb0\u0cae \u0c98\u0c9f\u0cbf', '53-20'), ('\u0c97\u0ca4 \u0c98\u0c9f\u0cbf', '18-19')],
        [('\u0c85\u0cb6\u0ccd\u0caf \u0c98\u0c9f\u0cbf', '34-41'), ('\u0c89\u0ca6\u0caf\u0cbe\u0ca6\u0cbf \u0c98\u0c9f\u0cbf', '18-19')],
        [('\u0cb6\u0cbf\u0cb7\u0ccd\u0c9f \u0ca6\u0cb6\u0cbe \u0ca8\u0cbe\u0ca5', '\u0c95\u0cc7\u0ca4\u0cc1'), ('\u0cb6\u0cbf\u0cb7\u0ccd\u0c9f \u0ca6\u0cb6\u0cbe \u0cb6\u0cc7\u0cb7', '4\u0cb5 7\u0ca4\u0cbf 12\u0ca6\u0cbf')],
    ]
    ddh = len(dd_rows) * 4 + 3
    pdf._rect(M, y, AW, ddh, border=pdf.C_BORDER, bw=0.15)
    for i, row in enumerate(dd_rows):
        fy = y + 2 + i * 4
        pdf._field(M+2, fy, row[0][0], row[0][1], lw=38)
        pdf._field(M+COL+2, fy, row[1][0], row[1][1], lw=36)
    y += ddh + 3

    # ── Mahadasha Table ──
    pdf._text(M, y+3.5, '\u0cb5\u0cbf\u0c82\u0cb6\u0ccb\u0ca4\u0ccd\u0ca4\u0cb0\u0cc0 \u0cae\u0cb9\u0cbe \u0ca6\u0cb6\u0cbe',
              size=9, bold=True, color=pdf.C_SECONDARY, align='C', w=AW)
    y += 5

    d_headers = ['\u0c95\u0ccd\u0cb0.', '\u0ca6\u0cb6\u0cbe \u0ca8\u0cbe\u0ca5', '\u0cb5\u0cb0\u0ccd\u0cb7', '\u0c86\u0cb0\u0c82\u0cad \u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95', '\u0c85\u0c82\u0ca4\u0ccd\u0caf \u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95']
    d_widths = [14, 36, 18, 53, 53]
    dtot = sum(d_widths)
    d_widths = [w * AW / dtot for w in d_widths]
    rh = 6

    pdf._rect(M, y, AW, rh, fill=pdf.C_TABLE_HDR)
    cx = M
    for h, w in zip(d_headers, d_widths):
        pdf._text(cx+1, y+4, h, size=6.5, bold=True, color=pdf.C_WHITE, align='C', w=w-2)
        cx += w
    y += rh

    dashas = [
        ('1', '\u0c95\u0cc7\u0ca4\u0cc1', '7', '12-06-1997', '12-06-2004'),
        ('2', '\u0cb6\u0cc1\u0c95\u0ccd\u0cb0', '20', '12-06-2004', '12-06-2024'),
        ('3', '\u0cb0\u0cb5\u0cbf', '6', '12-06-2024', '12-06-2030'),
        ('4', '\u0c9a\u0c82\u0ca6\u0ccd\u0cb0', '10', '12-06-2030', '12-06-2040'),
        ('5', '\u0c95\u0cc1\u0c9c', '7', '12-06-2040', '12-06-2047'),
        ('6', '\u0cb0\u0cbe\u0cb9\u0cc1', '18', '12-06-2047', '12-06-2065'),
        ('7', '\u0c97\u0cc1\u0cb0\u0cc1', '16', '12-06-2065', '12-06-2081'),
        ('8', '\u0cb6\u0ca8\u0cbf', '19', '12-06-2081', '12-06-2100'),
        ('9', '\u0cac\u0cc1\u0ca7', '17', '12-06-2100', '12-06-2117'),
    ]
    for di, drow in enumerate(dashas):
        bg = pdf.C_DASHA_ALT if di % 2 == 0 else pdf.C_WHITE
        pdf._rect(M, y, AW, rh, fill=bg)
        cx = M
        for vi, (val, cw) in enumerate(zip(drow, d_widths)):
            bold = (vi == 1)
            pdf._text(cx+1, y+4, val, size=6.5, bold=bold, align='C', w=cw-2)
            cx += cw
        y += rh
    pdf._rect(M, y - rh*(len(dashas)+1), AW, rh*(len(dashas)+1), border=pdf.C_BORDER, bw=0.15)
    y += 4

    # Balance
    pdf._text(M, y+3, '\u0cb6\u0cbf\u0cb7\u0ccd\u0c9f \u0ca6\u0cb6\u0cc6: \u0c95\u0cc7\u0ca4\u0cc1 \u2014 \u0cb6\u0cc7\u0cb7: 4\u0cb5 7\u0ca4\u0cbf 12\u0ca6\u0cbf',
              size=8, bold=True, color=pdf.C_ACCENT, align='C', w=AW)
    y += 8

    # ── Antardasha Table ──
    pdf._text(M, y+3.5, '\u0c85\u0c82\u0ca4\u0cb0\u0ccd \u0ca6\u0cb6\u0cbe \u0cb5\u0cbf\u0cb5\u0cb0 (\u0caa\u0ccd\u0cb0\u0cb8\u0ccd\u0ca4\u0cc1\u0ca4 \u0cae\u0cb9\u0cbe \u0ca6\u0cb6\u0cc6)',
              size=9, bold=True, color=pdf.C_SECONDARY, align='C', w=AW)
    y += 5

    a_headers = ['\u0c85\u0c82\u0ca4\u0cb0\u0ccd \u0ca6\u0cb6\u0cbe', '\u0c86\u0cb0\u0c82\u0cad \u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95', '\u0c85\u0c82\u0ca4\u0ccd\u0caf \u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95']
    a_widths = [60, 57, 57]
    atot = sum(a_widths)
    a_widths = [w * AW / atot for w in a_widths]

    pdf._rect(M, y, AW, rh, fill=pdf.C_SECONDARY)
    cx = M
    for h, w in zip(a_headers, a_widths):
        pdf._text(cx+1, y+4, h, size=6.5, bold=True, color=pdf.C_WHITE, align='C', w=w-2)
        cx += w
    y += rh

    antardashas = [
        ('\u0c95\u0cc7\u0ca4\u0cc1/\u0c95\u0cc7\u0ca4\u0cc1', '12-06-1997', '07-11-1997'),
        ('\u0c95\u0cc7\u0ca4\u0cc1/\u0cb6\u0cc1\u0c95\u0ccd\u0cb0', '07-11-1997', '07-01-1999'),
        ('\u0c95\u0cc7\u0ca4\u0cc1/\u0cb0\u0cb5\u0cbf', '07-01-1999', '15-05-1999'),
        ('\u0c95\u0cc7\u0ca4\u0cc1/\u0c9a\u0c82\u0ca6\u0ccd\u0cb0', '15-05-1999', '15-12-1999'),
        ('\u0c95\u0cc7\u0ca4\u0cc1/\u0c95\u0cc1\u0c9c', '15-12-1999', '12-05-2000'),
        ('\u0c95\u0cc7\u0ca4\u0cc1/\u0cb0\u0cbe\u0cb9\u0cc1', '12-05-2000', '30-05-2001'),
        ('\u0c95\u0cc7\u0ca4\u0cc1/\u0c97\u0cc1\u0cb0\u0cc1', '30-05-2001', '06-05-2002'),
        ('\u0c95\u0cc7\u0ca4\u0cc1/\u0cb6\u0ca8\u0cbf', '06-05-2002', '14-06-2003'),
        ('\u0c95\u0cc7\u0ca4\u0cc1/\u0cac\u0cc1\u0ca7', '14-06-2003', '12-06-2004'),
    ]
    for ai, arow in enumerate(antardashas):
        bg = pdf.C_TABLE_ALT if ai % 2 == 0 else pdf.C_WHITE
        pdf._rect(M, y, AW, rh, fill=bg)
        cx = M
        for vi, (val, cw) in enumerate(zip(arow, a_widths)):
            bold = (vi == 0)
            pdf._text(cx+1, y+4, val, size=6.5, bold=bold, align='C', w=cw-2)
            cx += cw
        y += rh
    pdf._rect(M, y - rh*(len(antardashas)+1), AW, rh*(len(antardashas)+1), border=pdf.C_BORDER, bw=0.15)

    pdf.draw_footer()


def main():
    pdf = JanmaPatrikePDF()
    build_page1(pdf)
    build_page2(pdf)
    pdf.output(OUTPUT_PDF)
    size_kb = os.path.getsize(OUTPUT_PDF) / 1024
    print(f"PDF generated: {OUTPUT_PDF}")
    print(f"File size: {size_kb:.1f} KB")


if __name__ == '__main__':
    main()
