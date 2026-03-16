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

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Calculate off main thread if needed, but sweph is fast enough for 365 days
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
    if (_transitData!.transits.isEmpty) {
      return Center(child: Text('ಯಾವುದೇ ಸಂಚಾರಗಳಿಲ್ಲ', style: TextStyle(color: kMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transitData!.transits.length,
      itemBuilder: (context, index) {
        final ev = _transitData!.transits[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: kBorder),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: kPurple1.withValues(alpha: 0.1),
              child: Text(ev.planetName.substring(0, 1), style: TextStyle(color: kPurple1, fontWeight: FontWeight.bold)),
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
    if (_transitData!.vakriPeriods.isEmpty) {
      return Center(child: Text('ಯಾವುದೇ ಗ್ರಹ ವಕ್ರಿಯಾಗಿಲ್ಲ', style: TextStyle(color: kMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transitData!.vakriPeriods.length,
      itemBuilder: (context, index) {
        final vp = _transitData!.vakriPeriods[index];
        final startStr = _formatDate(vp.startDate);
        final endStr = vp.endDate != null ? _formatDate(vp.endDate!) : 'ಮುಂದಿನ ವರ್ಷದವರೆಗೆ';
        
        return Card(
          elevation: 0,
          color: Colors.orange.shade50,
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: Colors.orange.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                           Text(vp.planetName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange.shade900)),
                           const SizedBox(width: 8),
                           Icon(Icons.turn_left, size: 16, color: Colors.orange.shade900),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('ಪ್ರಾರಂಭ: $startStr', style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
                      Text('ಅಂತ್ಯ: $endStr', style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
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
    if (_transitData!.astaPeriods.isEmpty) {
      return Center(child: Text('ಯಾವುದೇ ಗ್ರಹ ಅಸ್ತವಾಗಿಲ್ಲ', style: TextStyle(color: kMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transitData!.astaPeriods.length,
      itemBuilder: (context, index) {
        final ap = _transitData!.astaPeriods[index];
        final startStr = _formatDate(ap.startDate);
        final endStr = ap.endDate != null ? _formatDate(ap.endDate!) : 'ಮುಂದಿನ ವರ್ಷದವರೆಗೆ';
        
        return Card(
          elevation: 0,
          color: Colors.red.shade50,
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: Colors.red.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                           Text('(${ap.planetName})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade900)),
                           const SizedBox(width: 8),
                           Icon(Icons.brightness_low, size: 16, color: Colors.red.shade900),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('ಪ್ರಾರಂಭ: $startStr', style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                      Text('ಅಂತ್ಯ: $endStr', style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
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
