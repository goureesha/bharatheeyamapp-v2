import 'package:flutter/material.dart';
import '../core/muhurta_rules.dart';
import '../core/user_muhurta_rules.dart';
import '../widgets/common.dart';

/// ──────────────────────────────────────────────────────────────
/// Rules Editor Widget — collapsible section for editing muhurta rules
/// ──────────────────────────────────────────────────────────────
class MuhurtaRulesEditor extends StatefulWidget {
  final MuhurtaEvent event;
  final VoidCallback? onRulesChanged;

  const MuhurtaRulesEditor({
    super.key,
    required this.event,
    this.onRulesChanged,
  });

  @override
  State<MuhurtaRulesEditor> createState() => _MuhurtaRulesEditorState();
}

class _MuhurtaRulesEditorState extends State<MuhurtaRulesEditor> {
  bool _isExpanded = false;
  late UserMuhurtaRules _rules;

  // All names localized via AppLocale.l() keys

  @override
  void initState() {
    super.initState();
    _rules = UserRulesManager.instance.getRules(widget.event);
  }

  @override
  void didUpdateWidget(MuhurtaRulesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event != widget.event) {
      _rules = UserRulesManager.instance.getRules(widget.event);
    }
  }

  void _onChanged() {
    UserRulesManager.instance.saveRules(widget.event, _rules);
    widget.onRulesChanged?.call();
  }

  Future<void> _resetToDefaults() async {
    await UserRulesManager.instance.resetToDefaults(widget.event);
    setState(() {
      _rules = UserRulesManager.instance.getRules(widget.event);
    });
    widget.onRulesChanged?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.l('mRulesReset')), backgroundColor: kTeal, duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header — tap to expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(_isExpanded ? Icons.tune : Icons.tune, color: kPurple1, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  AppLocale.l('mEditRules'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kPurple1),
                )),
                if (_isExpanded)
                  TextButton(
                    onPressed: _resetToDefaults,
                    child: Text(AppLocale.l('mDefault'), style: TextStyle(fontSize: 11, color: Colors.orange)),
                  ),
                Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: kMuted),
              ],
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── 1. Tithi ──
            _buildSectionTitle(AppLocale.l('mTithi'), Icons.calendar_today),
            const SizedBox(height: 6),
            _buildChipGroup(
              itemCount: 30,
              labelBuilder: (i) => '${AppLocale.l('bt${i % 15}')}${i < 15 ? " ${AppLocale.l('mShukla')}" : " ${AppLocale.l('mKrishna')}"}',
              shortLabelBuilder: (i) => '${(i % 15) + 1}${i < 15 ? AppLocale.l('mShukla') : AppLocale.l('mKrishna')}',
              selectedIndices: _rules.allowedTithis,
              onChanged: (selected) {
                setState(() => _rules.allowedTithis = selected.isEmpty ? null : selected);
                _onChanged();
              },
            ),
            const SizedBox(height: 14),

            // ── 2. Nakshatra ──
            _buildSectionTitle(AppLocale.l('mNakshatra'), Icons.star),
            const SizedBox(height: 6),
            _buildChipGroup(
              itemCount: 27,
              labelBuilder: (i) { final n = AppLocale.l('nak$i'); return n; },
              shortLabelBuilder: (i) { final n = AppLocale.l('nak$i'); return n.length > 4 ? n.substring(0, 4) : n; },
              selectedIndices: _rules.allowedNakshatras,
              onChanged: (selected) {
                setState(() => _rules.allowedNakshatras = selected.isEmpty ? null : selected);
                _onChanged();
              },
            ),
            const SizedBox(height: 14),

            // ── 3. Vara ──
            _buildSectionTitle(AppLocale.l('mVara'), Icons.today),
            const SizedBox(height: 6),
            _buildChipGroup(
              itemCount: 7,
              labelBuilder: (i) => AppLocale.l('varaS$i'),
              shortLabelBuilder: (i) => AppLocale.l('varaS$i'),
              selectedIndices: _rules.allowedVaras,
              onChanged: (selected) {
                setState(() => _rules.allowedVaras = selected.isEmpty ? null : selected);
                _onChanged();
              },
            ),
            const SizedBox(height: 14),

            // ── 4. Yoga (blocked) ──
            _buildSectionTitle(AppLocale.l('mBlockedYogas'), Icons.block),
            const SizedBox(height: 6),
            _buildChipGroup(
              itemCount: 27,
              labelBuilder: (i) { final y = AppLocale.l('yoga$i'); return y; },
              shortLabelBuilder: (i) { final y = AppLocale.l('yoga$i'); return y.length > 4 ? y.substring(0, 4) : y; },
              selectedIndices: _rules.blockedYogas,
              isBlockedMode: true,
              onChanged: (selected) {
                setState(() => _rules.blockedYogas = selected.isEmpty ? null : selected);
                _onChanged();
              },
            ),
            const SizedBox(height: 14),

            // ── 5. Toggle switches ──
            _buildSectionTitle(AppLocale.l('mOtherRules'), Icons.settings),
            const SizedBox(height: 6),

            _buildToggle(AppLocale.l('mAvoidVishti'), _rules.avoidVishti, (v) {
              setState(() => _rules.avoidVishti = v);
              _onChanged();
            }),
            _buildToggle(AppLocale.l('mShuklaOnly'), _rules.requireShukla, (v) {
              setState(() => _rules.requireShukla = v);
              _onChanged();
            }),
            _buildToggle(AppLocale.l('mNeedUttarayana'), _rules.requireUttarayana, (v) {
              setState(() => _rules.requireUttarayana = v);
              _onChanged();
            }),
            _buildToggle(AppLocale.l('mAvoidDagdha'), _rules.blockDagdhaYoga, (v) {
              setState(() => _rules.blockDagdhaYoga = v);
              _onChanged();
            }),
            _buildToggle(AppLocale.l('mAvoidGuruAsta'), _rules.blockGuruAsta, (v) {
              setState(() => _rules.blockGuruAsta = v);
              _onChanged();
            }),
            _buildToggle(AppLocale.l('mAvoidShukraAsta'), _rules.blockShukraAsta, (v) {
              setState(() => _rules.blockShukraAsta = v);
              _onChanged();
            }),
            _buildToggle(AppLocale.l('mConsiderAbhijit'), _rules.considerAbhijit, (v) {
              setState(() => _rules.considerAbhijit = v);
              _onChanged();
            }),
            _buildToggle(AppLocale.l('mNeedTaraBala'), _rules.requireTaraBala, (v) {
              setState(() => _rules.requireTaraBala = v);
              _onChanged();
            }),
            if (_rules.requireTaraBala) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(AppLocale.l('mAllowedTaras'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: List.generate(9, (i) {
                  final taraLabels = [
                    AppLocale.l('tJanma'), AppLocale.l('tSampat'), AppLocale.l('tVipat'),
                    AppLocale.l('tKshema'), AppLocale.l('tPratyak'), AppLocale.l('tSadhaka'),
                    AppLocale.l('tVadha'), AppLocale.l('tMitra'), AppLocale.l('tParaMitra'),
                  ];
                  const defaultGood = [1, 3, 5, 7, 8];
                  final selected = _rules.allowedTaras.contains(i);
                  final isDefault = defaultGood.contains(i);
                  return FilterChip(
                    label: Text(taraLabels[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? (isDefault ? Colors.green.shade700 : Colors.orange.shade700) : kText)),
                    selected: selected,
                    selectedColor: isDefault ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    checkmarkColor: isDefault ? Colors.green.shade700 : Colors.orange.shade700,
                    backgroundColor: kBg,
                    side: BorderSide(color: selected ? (isDefault ? Colors.green : Colors.orange) : kBorder, width: 0.5),
                    onSelected: (sel) {
                      setState(() {
                        final mutable = List<int>.from(_rules.allowedTaras);
                        if (sel) { mutable.add(i); } else { mutable.remove(i); }
                        _rules.allowedTaras = mutable;
                      });
                      _onChanged();
                    },
                  );
                }),
              ),
              const SizedBox(height: 4),
            ],
            _buildToggle(AppLocale.l('mNeedGuruBala'), _rules.requireGuruBala, (v) {
              setState(() => _rules.requireGuruBala = v);
              _onChanged();
            }),
            _buildToggle(AppLocale.l('mGuruFavorLagna'), _rules.requireGuruAnukoolaForLagna, (v) {
              setState(() => _rules.requireGuruAnukoolaForLagna = v);
              _onChanged();
            }),
            _buildToggle(AppLocale.l('mFullDayScan'), _rules.fullDayScan, (v) {
              setState(() => _rules.fullDayScan = v);
              _onChanged();
            }),
            const SizedBox(height: 14),

            // ── 6. Lagna Shuddhi ──
            _buildSectionTitle(AppLocale.l('mLagnaShuddhiReqs'), Icons.verified),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: ShuddhiType.values.map((s) {
                final labels = {
                  ShuddhiType.lagna: AppLocale.l('mLagna'),
                  ShuddhiType.saptama: AppLocale.l('mSaptama'),
                  ShuddhiType.ashtama: AppLocale.l('mAshtama'),
                  ShuddhiType.dashama: AppLocale.l('mDashama'),
                  ShuddhiType.chandraSaptama: AppLocale.l('mChandraSaptama'),
                };
                final selected = _rules.requiredShuddhis.contains(s);
                return FilterChip(
                  label: Text(labels[s] ?? s.name, style: TextStyle(fontSize: 11, color: selected ? Colors.white : kText)),
                  selected: selected,
                  selectedColor: kTeal,
                  backgroundColor: kBg,
                  checkmarkColor: Colors.white,
                  side: BorderSide(color: selected ? kTeal : kBorder),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _rules.requiredShuddhis.add(s);
                      } else {
                        _rules.requiredShuddhis.remove(s);
                      }
                    });
                    _onChanged();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Bhava Shuddhi toggle (advanced)
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocale.l('mUseBhavaShuddhi'), style: const TextStyle(fontSize: 12)),
              value: _rules.useBhavaShuddhi,
              activeColor: kTeal,
              onChanged: (v) {
                setState(() => _rules.useBhavaShuddhi = v);
                _onChanged();
              },
            ),
            const SizedBox(height: 14),

            // ── 7. Lagna Rashi ──
            _buildSectionTitle(AppLocale.l('mAllowedLagnaRashi'), Icons.grid_view),
            const SizedBox(height: 6),
            _buildChipGroup(
              itemCount: 12,
              labelBuilder: (i) => AppLocale.l('rashi$i'),
              shortLabelBuilder: (i) => AppLocale.l('rashi$i'),
              selectedIndices: _rules.allowedLagnas,
              onChanged: (selected) {
                setState(() => _rules.allowedLagnas = selected.isEmpty ? null : selected);
                _onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 14, color: kMuted),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
    ]);
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: kText))),
          SizedBox(
            height: 28,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: kTeal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipGroup({
    required int itemCount,
    required String Function(int) labelBuilder,
    required String Function(int) shortLabelBuilder,
    required List<int>? selectedIndices,
    required ValueChanged<List<int>> onChanged,
    bool isBlockedMode = false,
  }) {
    // If null, select all (or none for blocked mode)
    final selected = selectedIndices ?? (isBlockedMode ? <int>[] : List.generate(itemCount, (i) => i));

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(itemCount, (i) {
        final isSelected = selected.contains(i);
        final chipColor = isBlockedMode
            ? (isSelected ? Colors.red.shade700 : kBg)
            : (isSelected ? kPurple1 : kBg);
        final textColor = isSelected ? Colors.white : kMuted;

        return GestureDetector(
          onTap: () {
            final newSelected = List<int>.from(selected);
            if (isSelected) {
              newSelected.remove(i);
            } else {
              newSelected.add(i);
            }
            newSelected.sort();
            onChanged(newSelected);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? chipColor : kBorder, width: 1),
            ),
            child: Text(
              shortLabelBuilder(i),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        );
      }),
    );
  }
}
