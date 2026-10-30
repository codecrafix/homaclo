import 'package:flutter/foundation.dart';

/// Solar Panel Cleaning booking state (separate from the water-tank cart so
/// the existing tank flow stays untouched).
/// Price = panels x ₹100.  System size 3kW - 30kW is chosen from a dropdown.
class SolarCart extends ChangeNotifier {
  SolarCart._();
  static final SolarCart instance = SolarCart._();

  static const int pricePerPanel = 100;
  static const int maxPanels = 100;
  static final List<int> kwOptions = List<int>.generate(28, (i) => i + 3); // 3..30

  bool isSolar = false;
  int kw = 3;
  int panels = 0;

  int get total => panels * pricePerPanel;

  String get serviceName =>
      'Solar Panel Cleaning (${kw}kW × $panels panel${panels == 1 ? '' : 's'})';

  void setSolar(bool value) {
    if (isSolar == value) return;
    isSolar = value;
    notifyListeners();
  }

  void setKw(int value) {
    kw = value;
    notifyListeners();
  }

  void changePanels(int delta) {
    panels = (panels + delta).clamp(0, maxPanels);
    notifyListeners();
  }

  void reset() {
    isSolar = false;
    kw = 3;
    panels = 0;
    notifyListeners();
  }
}
