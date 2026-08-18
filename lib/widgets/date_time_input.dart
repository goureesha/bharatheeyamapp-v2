import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ────────────────────────────────────────────────────────────────
// Shared date & time number-input widgets
// ────────────────────────────────────────────────────────────────

const Color _kBorder = Color(0xFFE0E0E0);
const Color _kCard   = Colors.white;
const Color _kText   = Color(0xFF1E293B);
const Color _kMuted  = Color(0xFF94A3B8);

/// Simple DD / MM / YYYY number input row
class DateInputRow extends StatefulWidget {
  final DateTime date;
  final Color color;
  final void Function(DateTime) onChanged;

  const DateInputRow({
    super.key,
    required this.date,
    required this.color,
    required this.onChanged,
  });

  @override
  State<DateInputRow> createState() => _DateInputRowState();
}

class _DateInputRowState extends State<DateInputRow> {
  late TextEditingController _ddCtrl, _mmCtrl, _yyyyCtrl;
  late FocusNode _ddFocus, _mmFocus, _yyyyFocus;
  bool _internalUpdate = false;

  @override
  void initState() {
    super.initState();
    _ddCtrl = TextEditingController(text: widget.date.day.toString().padLeft(2, '0'));
    _mmCtrl = TextEditingController(text: widget.date.month.toString().padLeft(2, '0'));
    _yyyyCtrl = TextEditingController(text: widget.date.year.toString());
    _ddFocus = FocusNode()..addListener(_onDdFocusChange);
    _mmFocus = FocusNode()..addListener(_onMmFocusChange);
    _yyyyFocus = FocusNode()..addListener(_onYyyyFocusChange);
  }

  @override
  void didUpdateWidget(covariant DateInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_internalUpdate) { _internalUpdate = false; return; }
    if (oldWidget.date != widget.date) {
      if (!_ddFocus.hasFocus) _ddCtrl.text = widget.date.day.toString().padLeft(2, '0');
      if (!_mmFocus.hasFocus) _mmCtrl.text = widget.date.month.toString().padLeft(2, '0');
      if (!_yyyyFocus.hasFocus) _yyyyCtrl.text = widget.date.year.toString();
    }
  }

  @override
  void dispose() {
    _ddCtrl.dispose(); _mmCtrl.dispose(); _yyyyCtrl.dispose();
    _ddFocus.removeListener(_onDdFocusChange);
    _mmFocus.removeListener(_onMmFocusChange);
    _yyyyFocus.removeListener(_onYyyyFocusChange);
    _ddFocus.dispose(); _mmFocus.dispose(); _yyyyFocus.dispose();
    super.dispose();
  }

  void _onDdFocusChange() {
    if (!_ddFocus.hasFocus) {
      _padField(_ddCtrl, 2);
      _tryUpdate();
    }
  }

  void _onMmFocusChange() {
    if (!_mmFocus.hasFocus) {
      _padField(_mmCtrl, 2);
      _tryUpdate();
    }
  }

  void _onYyyyFocusChange() {
    if (!_yyyyFocus.hasFocus) _tryUpdate();
  }

  void _padField(TextEditingController ctrl, int width) {
    final val = int.tryParse(ctrl.text);
    if (val != null && val > 0) {
      ctrl.text = val.toString().padLeft(width, '0');
    }
  }

  void _tryUpdate() {
    final dd = int.tryParse(_ddCtrl.text) ?? 0;
    final mm = int.tryParse(_mmCtrl.text) ?? 0;
    final yyyy = int.tryParse(_yyyyCtrl.text) ?? 0;
    if (dd >= 1 && dd <= 31 && mm >= 1 && mm <= 12 && yyyy >= 1800 && yyyy <= 2100) {
      try {
        final clamped = dd.clamp(1, _daysInMonth(mm, yyyy));
        _internalUpdate = true;
        widget.onChanged(DateTime(yyyy, mm, clamped));
      } catch (_) {}
    }
  }

  int _daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  void _onDdChanged(String v) {
    if (v.length >= 2) {
      _mmFocus.requestFocus();
      _mmCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _mmCtrl.text.length);
    }
  }

  void _onMmChanged(String v) {
    if (v.length >= 2) {
      _yyyyFocus.requestFocus();
      _yyyyCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _yyyyCtrl.text.length);
    }
  }

  void _onYyyyChanged(String v) {
    if (v.length >= 4) {
      _yyyyFocus.unfocus();
      _tryUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(Icons.calendar_today, color: _kMuted, size: 18),
        const SizedBox(width: 8),
        _numField(_ddCtrl, _ddFocus, 2, 'DD', _onDdChanged),
        _sep('/'),
        _numField(_mmCtrl, _mmFocus, 2, 'MM', _onMmChanged),
        _sep('/'),
        _numField(_yyyyCtrl, _yyyyFocus, 4, 'YYYY', _onYyyyChanged),
      ]),
    );
  }

  Widget _numField(TextEditingController ctrl, FocusNode focus, int maxLen, String hint, void Function(String) onChange) {
    return SizedBox(
      width: maxLen == 4 ? 52 : 34,
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: maxLen,
        style: TextStyle(fontSize: 14, color: _kText, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: _kMuted.withOpacity(0.5)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          border: UnderlineInputBorder(borderSide: BorderSide(color: widget.color.withOpacity(0.3))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.color, width: 2)),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _kBorder)),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChange,
        onTap: () => ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length),
      ),
    );
  }

  Widget _sep(String s) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Text(s, style: TextStyle(fontSize: 14, color: _kMuted, fontWeight: FontWeight.w600)),
  );
}

// ────────────────────────────────────────────────────────────────
// Simple HH : MM + AM/PM number input row
// ────────────────────────────────────────────────────────────────

class TimeInputRow extends StatefulWidget {
  final int hour;
  final int minute;
  final String ampm;
  final Color color;
  final void Function(int hour, int minute, String ampm) onChanged;

  const TimeInputRow({
    super.key,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.color,
    required this.onChanged,
  });

  @override
  State<TimeInputRow> createState() => _TimeInputRowState();
}

class _TimeInputRowState extends State<TimeInputRow> {
  late TextEditingController _hhCtrl, _minCtrl;
  late FocusNode _hhFocus, _minFocus;
  bool _internalUpdate = false;

  @override
  void initState() {
    super.initState();
    _hhCtrl = TextEditingController(text: widget.hour.toString().padLeft(2, '0'));
    _minCtrl = TextEditingController(text: widget.minute.toString().padLeft(2, '0'));
    _hhFocus = FocusNode()..addListener(_onHhFocusChange);
    _minFocus = FocusNode()..addListener(_onMinFocusChange);
  }

  @override
  void didUpdateWidget(covariant TimeInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_internalUpdate) { _internalUpdate = false; return; }
    if (oldWidget.hour != widget.hour && !_hhFocus.hasFocus) {
      _hhCtrl.text = widget.hour.toString().padLeft(2, '0');
    }
    if (oldWidget.minute != widget.minute && !_minFocus.hasFocus) {
      _minCtrl.text = widget.minute.toString().padLeft(2, '0');
    }
  }

  @override
  void dispose() {
    _hhCtrl.dispose(); _minCtrl.dispose();
    _hhFocus.removeListener(_onHhFocusChange);
    _minFocus.removeListener(_onMinFocusChange);
    _hhFocus.dispose(); _minFocus.dispose();
    super.dispose();
  }

  void _onHhFocusChange() {
    if (!_hhFocus.hasFocus) {
      _padField(_hhCtrl);
      _tryUpdate();
    }
  }

  void _onMinFocusChange() {
    if (!_minFocus.hasFocus) {
      _padField(_minCtrl);
      _tryUpdate();
    }
  }

  void _padField(TextEditingController ctrl) {
    final val = int.tryParse(ctrl.text);
    if (val != null) ctrl.text = val.toString().padLeft(2, '0');
  }

  void _tryUpdate() {
    final hh = int.tryParse(_hhCtrl.text) ?? 0;
    final mm = int.tryParse(_minCtrl.text) ?? 0;
    if (hh >= 1 && hh <= 12 && mm >= 0 && mm <= 59) {
      _internalUpdate = true;
      widget.onChanged(hh, mm, widget.ampm);
    }
  }

  void _onHhChanged(String v) {
    if (v.length >= 2) {
      _minFocus.requestFocus();
      _minCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _minCtrl.text.length);
    }
  }

  void _onMinChanged(String v) {
    if (v.length >= 2) {
      _minFocus.unfocus();
      _tryUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(Icons.access_time, color: _kMuted, size: 18),
        const SizedBox(width: 8),
        _numField(_hhCtrl, _hhFocus, 'HH', _onHhChanged),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(':', style: TextStyle(fontSize: 16, color: _kMuted, fontWeight: FontWeight.w700)),
        ),
        _numField(_minCtrl, _minFocus, 'MM', _onMinChanged),
        const SizedBox(width: 10),
        _ampmBtn('AM'),
        const SizedBox(width: 4),
        _ampmBtn('PM'),
      ]),
    );
  }

  Widget _numField(TextEditingController ctrl, FocusNode focus, String hint, void Function(String) onChange) {
    return SizedBox(
      width: 36,
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 2,
        style: TextStyle(fontSize: 14, color: _kText, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: _kMuted.withOpacity(0.5)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          border: UnderlineInputBorder(borderSide: BorderSide(color: widget.color.withOpacity(0.3))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.color, width: 2)),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _kBorder)),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChange,
        onTap: () => ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length),
      ),
    );
  }

  Widget _ampmBtn(String label) {
    final isActive = widget.ampm == label;
    return GestureDetector(
      onTap: () {
        _internalUpdate = true;
        final hh = int.tryParse(_hhCtrl.text) ?? widget.hour;
        final mm = int.tryParse(_minCtrl.text) ?? widget.minute;
        widget.onChanged(hh.clamp(1, 12), mm.clamp(0, 59), label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? widget.color : Colors.transparent,
          border: Border.all(color: isActive ? widget.color : _kBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : _kMuted,
          ),
        ),
      ),
    );
  }
}
