import 'package:flutter/material.dart';
import '../core/transit_cache.dart';
import '../core/transit_calculator.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';

class PlanetsScreen extends StatefulWidget {
  const PlanetsScreen({super.key});

  @override
  State<PlanetsScreen> createState() => _PlanetsScreenState();
}

class _PlanetsScreenState extends State<PlanetsScreen> with SingleTickerProviderStateMixin {
  late int _selectedYear;
  late TabController _tabCtrl;
  
  bool _isLoading = true;
  TransitData? _transitData;

  // Planet filter: null means "All"
  String? _selectedPlanet;

  // Planet keys (English, language-independent)
  static const _planetKeys = [
    'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu', 'ketu',
  ];

  // Planet emoji icons
  static const _planetIcons = <String, String>{
    'sun': '☉', 'moon': '☽', 'mars': '♂', 'mercury': '☿',
    'jupiter': '♃', 'venus': '♀', 'saturn': '♄', 'rahu': '☊', 'ketu': '☋',
  };

  // Planet colors
  static final _planetColors = <String, Color>{
    'sun': Color(0xFFFF6B00), 'moon': Color(0xFF4A90D9),
    'mars': Color(0xFFE53935), 'mercury': Color(0xFF43A047),
    'jupiter': Color(0xFFFFC107), 'venus': Color(0xFFE91E8C),
    'saturn': Color(0xFF5C6BC0), 'rahu': Color(0xFF455A64),
    'ketu': Color(0xFF795548),
  };

  // Get localized planet name from English key
  static String _planetLabel(String key) {
    const _keyToLocale = {
      'sun': 'surya', 'moon': 'chandra', 'mars': 'mars',
      'mercury': 'mercury', 'jupiter': 'jupiter', 'venus': 'venus',
      'saturn': 'saturn', 'rahu': 'rahu', 'ketu': 'ketu',
    };
    return AppLocale.l(_keyToLocale[key] ?? key);
  }

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final data = await TransitCache.getYear(_selectedYear);
    
    if (mounted) {
      setState(() {
        _transitData = data;
        _isLoading = false;
      });
      // Pre-fetch adjacent years in background for instant navigation
      TransitCache.prefetchAdjacent(_selectedYear);
    }
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedYear += delta;
      _loadData();
    });
  }
  
  String _formatDate(DateTime d) {
    final months = [AppLocale.l('jan'), AppLocale.l('feb'), AppLocale.l('mar'), AppLocale.l('apr'), AppLocale.l('may'), AppLocale.l('jun'), AppLocale.l('jul'), AppLocale.l('aug'), AppLocale.l('sep'), AppLocale.l('oct'), AppLocale.l('nov'), AppLocale.l('dec')];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Color _getPlanetColor(String name) {
    return _planetColors[name] ?? kPurple1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(AppLocale.l('planets'), style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kBg,
        foregroundColor: kPurple1,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Year Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: kPurple1),
                  onPressed: () => _changeYear(-1),
                ),
                Text(
                  '$_selectedYear',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kText),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: kPurple1),
                  onPressed: () => _changeYear(1),
                ),
              ],
            ),
          ),
          
          // Planet Filter Chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // "All" chip
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(AppLocale.l('all'), style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12,
                      color: _selectedPlanet == null ? Colors.white : kText,
                    )),
                    selected: _selectedPlanet == null,
                    selectedColor: kPurple1,
                    backgroundColor: kCard,
                    onSelected: (_) => setState(() => _selectedPlanet = null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                // Planet chips
                ..._planetKeys.map((p) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: _selectedPlanet == p ? null : Text(
                      _planetIcons[p] ?? '', style: const TextStyle(fontSize: 14),
                    ),
                    label: Text(_planetLabel(p), style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12,
                      color: _selectedPlanet == p ? Colors.white : kText,
                    )),
                    selected: _selectedPlanet == p,
                    selectedColor: _getPlanetColor(p),
                    backgroundColor: kCard,
                    onSelected: (_) => setState(() => _selectedPlanet = p),
                    visualDensity: VisualDensity.compact,
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tabs
          TabBar(
            controller: _tabCtrl,
            labelColor: kPurple1,
            unselectedLabelColor: kMuted,
            indicatorColor: kPurple1,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: AppLocale.l('transits')), // Transits
              Tab(text: AppLocale.l('vakri')), // Vakri
              Tab(text: AppLocale.l('asta')), // Asta
            ],
          ),
          
          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transitData == null
                    ? Center(child: Text(AppLocale.l('noResults')))
                    : TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _buildTransits(),
                          _buildVakriList(),
                          _buildAstaList(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransits() {
    var transits = _transitData!.transits;
    // Filter by selected planet
    if (_selectedPlanet != null) {
      transits = transits.where((t) => t.planetName == _selectedPlanet).toList();
    }
    if (transits.isEmpty) {
      return Center(child: Text(
        _selectedPlanet != null ? '${_planetLabel(_selectedPlanet!)} — ${AppLocale.l('noTransits')}' : AppLocale.l('noTransits'),
        style: TextStyle(color: kMuted),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transits.length,
      itemBuilder: (context, index) {
        final ev = transits[index];
        final pColor = _getPlanetColor(ev.planetName);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: pColor.withValues(alpha: 0.3)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: pColor.withValues(alpha: 0.1),
              child: Text(
                _planetIcons[ev.planetName] ?? ev.planetName.substring(0, 1),
                style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            title: Text(_planetLabel(ev.planetName), style: TextStyle(fontWeight: FontWeight.bold, color: kText)),
            subtitle: Text('${trAll(ev.fromRashi)} → ${trAll(ev.toRashi)}', style: TextStyle(color: kMuted)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatDate(ev.date), style: TextStyle(color: kText, fontWeight: FontWeight.w600, fontSize: 12)),
                if (ev.time.isNotEmpty)
                  Text(ev.time, style: TextStyle(color: kMuted, fontWeight: FontWeight.w500, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVakriList() {
    var periods = _transitData!.vakriPeriods;
    if (_selectedPlanet != null) {
      periods = periods.where((v) => v.planetName == _selectedPlanet).toList();
    }
    if (periods.isEmpty) {
      return Center(child: Text(
        _selectedPlanet != null ? '${_planetLabel(_selectedPlanet!)} — ${AppLocale.l('noRetro')}' : AppLocale.l('noRetro'),
        style: TextStyle(color: kMuted),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final vp = periods[index];
        final startStr = _formatDate(vp.startDate);
        final endStr = vp.endDate != null ? _formatDate(vp.endDate!) : AppLocale.l('continues');
        final pColor = _getPlanetColor(vp.planetName);
        
        return Card(
          elevation: 0,
          color: pColor.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: pColor.withValues(alpha: 0.3)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: pColor.withValues(alpha: 0.15),
                  child: Text(
                    _planetIcons[vp.planetName] ?? '♦',
                    style: TextStyle(color: pColor, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                           Text(_planetLabel(vp.planetName), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: pColor)),
                           const SizedBox(width: 8),
                           Icon(Icons.turn_left, size: 16, color: pColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${AppLocale.l('start')}: $startStr', style: TextStyle(color: pColor.withValues(alpha: 0.8), fontSize: 13)),
                      Text('${AppLocale.l('end')}: $endStr', style: TextStyle(color: pColor.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAstaList() {
    var periods = _transitData!.astaPeriods;
    if (_selectedPlanet != null) {
      periods = periods.where((a) => a.planetName == _selectedPlanet).toList();
    }
    if (periods.isEmpty) {
      return Center(child: Text(
        _selectedPlanet != null ? '${_planetLabel(_selectedPlanet!)} — ${AppLocale.l('noCombust')}' : AppLocale.l('noCombust'),
        style: TextStyle(color: kMuted),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final ap = periods[index];
        final startStr = _formatDate(ap.startDate);
        final endStr = ap.endDate != null ? _formatDate(ap.endDate!) : AppLocale.l('continues');
        final pColor = _getPlanetColor(ap.planetName);
        
        return Card(
          elevation: 0,
          color: pColor.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: pColor.withValues(alpha: 0.3)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: pColor.withValues(alpha: 0.15),
                  child: Text(
                    _planetIcons[ap.planetName] ?? '◉',
                    style: TextStyle(color: pColor, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                           Text(_planetLabel(ap.planetName), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: pColor)),
                           const SizedBox(width: 8),
                           Icon(Icons.brightness_low, size: 16, color: pColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${AppLocale.l('start')}: $startStr', style: TextStyle(color: pColor.withValues(alpha: 0.8), fontSize: 13)),
                      Text('${AppLocale.l('end')}: $endStr', style: TextStyle(color: pColor.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
