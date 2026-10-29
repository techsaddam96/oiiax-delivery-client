import 'package:blockatie/services/user_session_state.dart';

class WalletProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _selectedTabIndex = -1;
  }

  int _selectedTabIndex = -1; // -1 means no tab selected (show wallet content)

  int get selectedTabIndex => _selectedTabIndex;

  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void resetTab() {
    _selectedTabIndex = -1;
    notifyListeners();
  }

  void resetToWallet() {
    _selectedTabIndex = -1;
    notifyListeners();
  }
}
