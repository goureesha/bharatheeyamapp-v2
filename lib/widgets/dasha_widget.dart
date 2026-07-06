import 'package:flutter/material.dart';
import '../core/calculator.dart';
import 'common.dart';
import '../constants/strings.dart';

class DashaWidget extends StatelessWidget {
  final List<DashaEntry> dashas;
  const DashaWidget({super.key, required this.dashas});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: dashas.map((md) => _MahaBlock(md: md, fmt: _fmt)).toList(),
      ),
    );
  }
}

// Level 1: Mahadasha (orange gradient)
class _MahaBlock extends StatelessWidget {
  final DashaEntry md;
  final String Function(DateTime) fmt;
  const _MahaBlock({required this.md, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFF9933), Color(0xFFDD6B20)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ExpansionTile(
          title: Row(children: [
            Text(appPlanetNames[md.lord] ?? tr(md.lord), style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            const Spacer(),
            Text(fmt(md.end), style: TextStyle(
              color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: md.antardashas.map((ad) => _AntarBlock(ad: ad, fmt: fmt)).toList(),
        ),
      ),
    );
  }
}

// Level 2: Bhukti/Antardasha (warm white with orange accent)
class _AntarBlock extends StatelessWidget {
  final DashaEntry ad;
  final String Function(DateTime) fmt;
  const _AntarBlock({required this.ad, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final hasSub = ad.antardashas.isNotEmpty;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        color: const Color(0xFFFFFDF7),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          trailing: hasSub ? null : const SizedBox.shrink(),
          title: Row(children: [
            Container(width: 4, height: 24, color: const Color(0xFFFF9933),
              margin: const EdgeInsets.only(right: 10)),
            Text(appPlanetNames[ad.lord] ?? tr(ad.lord), style: TextStyle(
              color: kOrange2, fontWeight: FontWeight.w900, fontSize: 15)),
            const Spacer(),
            Text(fmt(ad.end), style: TextStyle(
              color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          children: hasSub
            ? ad.antardashas.map((pd) => _PratyantaraBlock(pd: pd, fmt: fmt)).toList()
            : [],
        ),
      ),
    );
  }
}

// Level 3: Pratyantara Dasha (teal accent)
class _PratyantaraBlock extends StatelessWidget {
  final DashaEntry pd;
  final String Function(DateTime) fmt;
  const _PratyantaraBlock({required this.pd, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final hasSub = pd.antardashas.isNotEmpty;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: kBorder)),
          color: kCard,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
          trailing: hasSub ? null : const SizedBox.shrink(),
          childrenPadding: EdgeInsets.zero,
          title: Row(children: [
            Container(width: 3, height: 18, color: const Color(0xFF81E6D9),
              margin: const EdgeInsets.only(right: 10)),
            Text(appPlanetNames[pd.lord] ?? tr(pd.lord), style: TextStyle(
              color: kTeal, fontWeight: FontWeight.w800, fontSize: 14)),
            const Spacer(),
            Text(fmt(pd.end), style: TextStyle(
              color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          children: hasSub
            ? pd.antardashas.map((sd) => _SookshmaRow(sd: sd, fmt: fmt)).toList()
            : [],
        ),
      ),
    );
  }
}

// Level 4: Sookshma Dasha (purple accent, expandable)
class _SookshmaRow extends StatelessWidget {
  final DashaEntry sd;
  final String Function(DateTime) fmt;
  const _SookshmaRow({required this.sd, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final hasSub = sd.antardashas.isNotEmpty;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5))),
          color: const Color(0xFFF9F5FF),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 0),
          trailing: hasSub ? null : const SizedBox.shrink(),
          childrenPadding: EdgeInsets.zero,
          title: Row(children: [
            Container(width: 2, height: 14, color: kPurple2.withOpacity(0.6),
              margin: const EdgeInsets.only(right: 8)),
            Text(appPlanetNames[sd.lord] ?? tr(sd.lord), style: TextStyle(
              color: kPurple2, fontWeight: FontWeight.w700, fontSize: 12)),
            const Spacer(),
            Text(fmt(sd.end), style: TextStyle(
              color: kMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
          children: hasSub
            ? sd.antardashas.map((pr) => _PranaRow(pr: pr, fmt: fmt)).toList()
            : [],
        ),
      ),
    );
  }
}

// Level 5: Prana Dasha (rose/pink accent, flat row)
class _PranaRow extends StatelessWidget {
  final DashaEntry pr;
  final String Function(DateTime) fmt;
  const _PranaRow({required this.pr, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.3))),
        color: const Color(0xFFFFF5F5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 5),
      child: Row(children: [
        Container(width: 2, height: 12, color: const Color(0xFFE53E3E).withOpacity(0.5),
          margin: const EdgeInsets.only(right: 6)),
        Text(appPlanetNames[pr.lord] ?? tr(pr.lord), style: TextStyle(
          color: const Color(0xFFE53E3E), fontWeight: FontWeight.w600, fontSize: 11)),
        const Spacer(),
        Text(fmt(pr.end), style: TextStyle(
          color: kMuted, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
