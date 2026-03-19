import 'package:flutter/material.dart';
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

  // Planet names for filter chips
  static const _planets = [
    'ಸೂರ್ಯ', 'ಚಂದ್ರ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು',
  ];

  // Planet emoji icons
  static const _planetIcons = {
    'ಸೂರ್ಯ': '☉', 'ಚಂದ್ರ': '☽', 'ಮಂಗಳ': '♂', 'ಬುಧ': '☿',
    'ಗುರು': '♃', 'ಶುಕ್ರ': '♀', 'ಶನಿ': '♄', 'ರಾಹು': '☊', 'ಕೇತು': '☋',
  };

  // Planet colors
  static const _planetColors = {
    'ಸೂರ್ಯ': Color(0xFFFF6B00), 'ಚಂದ್ರ': Color(0xFF4A90D9),
    'ಮಂಗಳ': Color(0xFFE53935), 'ಬುಧ': Color(0xFF43A047),
    'ಗುರು': Color(0xFFFFC107), 'ಶುಕ್ರ': Color(0xFFE91E8C),
    'ಶನಿ': Color(0xFF5C6BC0), 'ರಾಹು': Color(0xFF455A64),
    'ಕೇತು': Color(0xFF795548),
  };

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final data = await TransitCalculator.calculateAnnualEvents(_selectedYear);
    
    if (mounted) {
      setState(() {
        _transitData = data;
        _isLoading = false;
      });
    }
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedYear += delta;
      _loadData();
    });
  }
  
  String _formatDate(DateTime d) {
    const months = ['ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್', 'ಜುಲೈ', 'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Color _getPlanetColor(String name) {
    return _planetColors[name] ?? kPurple1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ಗ್ರಹಗಳ ಮಾಹಿತಿ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
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
                    label: Text('ಎಲ್ಲಾ', style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12,
                      color: _selectedPlanet == null ? Colors.white : kText,
                    )),
                    selected: _selectedPlanet == null,
                    selectedColor: kPurple1,
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (_) => setState(() => _selectedPlanet = null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                // Planet chips
                ..._planets.map((p) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: _selectedPlanet == p ? null : Text(
                      _planetIcons[p] ?? '', style: const TextStyle(fontSize: 14),
                    ),
                    label: Text(p, style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12,
                      color: _selectedPlanet == p ? Colors.white : kText,
                    )),
                    selected: _selectedPlanet == p,
                    selectedColor: _getPlanetColor(p),
                    backgroundColor: Colors.grey.shade100,
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
            tabs: const [
              Tab(text: 'ಸಂಚಾರ'), // Transits
              Tab(text: 'ವಕ್ರಿ'), // Vakri
              Tab(text: 'ಅಸ್ತ'), // Asta
            ],
          ),
          
          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transitData == null
                    ? const Center(child: Text('ಡೇಟಾ ಲಭ್ಯವಿಲ್ಲ'))
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
        _selectedPlanet != null ? '$_selectedPlanet - ಯಾವುದೇ ಸಂಚಾರಗಳಿಲ್ಲ' : 'ಯಾವುದೇ ಸಂಚಾರಗಳಿಲ್ಲ',
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
             side: BorderSide(color: pColor.withOpacity(0.3)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: pColor.withOpacity(0.1),
              child: Text(
                _planetIcons[ev.planetName] ?? ev.planetName.substring(0, 1),
                style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            title: Text(ev.planetName, style: TextStyle(fontWeight: FontWeight.bold, color: kText)),
            subtitle: Text(ev.description, style: TextStyle(color: kMuted)),
            trailing: Text(_formatDate(ev.date), style: TextStyle(color: kText, fontWeight: FontWeight.w600, fontSize: 12)),
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
        _selectedPlanet != null ? '$_selectedPlanet - ವಕ್ರಿಯಾಗಿಲ್ಲ' : 'ಯಾವುದೇ ಗ್ರಹ ವಕ್ರಿಯಾಗಿಲ್ಲ',
        style: TextStyle(color: kMuted),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final vp = periods[index];
        final startStr = _formatDate(vp.startDate);
        final endStr = vp.endDate != null ? _formatDate(vp.endDate!) : 'ಮುಂದಿನ ವರ್ಷದವರೆಗೆ';
        final pColor = _getPlanetColor(vp.planetName);
        
        return Card(
          elevation: 0,
          color: pColor.withOpacity(0.05),
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: pColor.withOpacity(0.3)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: pColor.withOpacity(0.15),
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
                           Text(vp.planetName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: pColor)),
                           const SizedBox(width: 8),
                           Icon(Icons.turn_left, size: 16, color: pColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('ಪ್ರಾರಂಭ: $startStr', style: TextStyle(color: pColor.withOpacity(0.8), fontSize: 13)),
                      Text('ಅಂತ್ಯ: $endStr', style: TextStyle(color: pColor.withOpacity(0.8), fontSize: 13)),
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
        _selectedPlanet != null ? '$_selectedPlanet - ಅಸ್ತವಾಗಿಲ್ಲ' : 'ಯಾವುದೇ ಗ್ರಹ ಅಸ್ತವಾಗಿಲ್ಲ',
        style: TextStyle(color: kMuted),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final ap = periods[index];
        final startStr = _formatDate(ap.startDate);
        final endStr = ap.endDate != null ? _formatDate(ap.endDate!) : 'ಮುಂದಿನ ವರ್ಷದವರೆಗೆ';
        final pColor = _getPlanetColor(ap.planetName);
        
        return Card(
          elevation: 0,
          color: pColor.withOpacity(0.05),
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: pColor.withOpacity(0.3)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: pColor.withOpacity(0.15),
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
                           Text(ap.planetName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: pColor)),
                           const SizedBox(width: 8),
                           Icon(Icons.brightness_low, size: 16, color: pColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('ಪ್ರಾರಂಭ: $startStr', style: TextStyle(color: pColor.withOpacity(0.8), fontSize: 13)),
                      Text('ಅಂತ್ಯ: $endStr', style: TextStyle(color: pColor.withOpacity(0.8), fontSize: 13)),
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
