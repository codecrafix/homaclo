import 'package:flutter/foundation.dart';

enum BookingMode { water, solar, repair }

/// Solar booking state (separate from the water-tank cart so the existing tank
/// flow stays untouched). Same rules as the website:
///  * Solar Panel Cleaning: 3-30 kW dropdown, panels x ₹100, minimum 5 panels,
///    up to 500 panels (can be typed)
///  * Solar Maintenance & Repair: problem type + description, flat ₹1,000
/// Both are saved with service_category 'solar'.
class SolarCart extends ChangeNotifier {
  SolarCart._();
  static final SolarCart instance = SolarCart._();

  static const int pricePerPanel = 100;
  static const int minPanels = 5;
  static const int maxPanels = 500;
  static const int repairPrice = 1000;
  static final List<int> kwOptions = List<int>.generate(28, (i) => i + 3); // 3..30

  static const List<String> repairCategories = [
    'Inverter not working / error',
    'ACDB problem',
    'DCDB problem',
    'Solar not working properly',
    'Low voltage',
    'Low output / less generation',
    'No output at all',
    'Wiring / loose connection / sparking',
    'Panel damaged / hot-spot',
    'Earthing / lightning arrestor',
    'Monitoring / WiFi issue',
    'General checkup & maintenance',
    'Other problem',
  ];

  BookingMode mode = BookingMode.water;
  int kw = 3;
  int panels = 0;
  String repairCategory = '';
  String repairNote = '';

  /// True for both solar services (they share the solar booking category).
  bool get isSolar => mode != BookingMode.water;
  bool get isRepair => mode == BookingMode.repair;

  bool get panelsReady => panels >= minPanels;
  bool get repairReady =>
      repairCategory.isNotEmpty && repairNote.trim().length >= 5;

  int get total => isRepair ? repairPrice : panels * pricePerPanel;

  String get serviceName {
    if (isRepair) {
      final note = repairNote.trim().replaceAll(RegExp(r'\s+'), ' ');
      final s = 'Solar Maintenance & Repair — $repairCategory: $note';
      return s.length > 300 ? s.substring(0, 300) : s;
    }
    return 'Solar Panel Cleaning (${kw}kW × $panels panel${panels == 1 ? '' : 's'})';
  }

  void setMode(BookingMode m) {
    if (mode == m) return;
    mode = m;
    if (m == BookingMode.solar && panels < minPanels) panels = minPanels;
    notifyListeners();
  }

  void setSolar(bool value) =>
      setMode(value ? BookingMode.solar : BookingMode.water);

  void setKw(int value) {
    kw = value;
    notifyListeners();
  }

  /// +/- buttons: never below the minimum (a decrement at the minimum stays).
  void changePanels(int delta) {
    var n = panels + delta;
    if (n < minPanels) n = (delta > 0 || panels > 0) ? minPanels : 0;
    panels = n.clamp(0, maxPanels);
    notifyListeners();
  }

  /// Typed value (0 allowed while typing; fewer than the minimum keeps Next off).
  void setPanels(int value) {
    panels = value.clamp(0, maxPanels);
    notifyListeners();
  }

  void ensureMinPanels() {
    if (panels < minPanels) {
      panels = minPanels;
      notifyListeners();
    }
  }

  void setRepairCategory(String v) {
    repairCategory = v;
    notifyListeners();
  }

  void setRepairNote(String v) {
    repairNote = v;
    notifyListeners();
  }

  void reset() {
    mode = BookingMode.water;
    kw = 3;
    panels = 0;
    repairCategory = '';
    repairNote = '';
    notifyListeners();
  }
}
