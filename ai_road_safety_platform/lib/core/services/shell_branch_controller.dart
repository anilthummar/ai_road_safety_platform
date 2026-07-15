import 'package:flutter/foundation.dart';

/// Tracks which shell tab is visible so IndexedStack children can pause work.
class ShellBranchController extends ChangeNotifier {
  int _index = 0;

  /// Current shell branch index (0 = dashboard).
  int get index => _index;

  /// Whether the driver dashboard branch is selected.
  bool get isDashboardVisible => _index == 0;

  /// Updates the active branch and notifies listeners.
  void setIndex(int index) {
    if (_index == index) return;
    _index = index;
    notifyListeners();
  }
}
