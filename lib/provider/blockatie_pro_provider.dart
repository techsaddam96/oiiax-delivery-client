import 'package:blockatie/models/blockatie_pro_package.dart';
import 'package:blockatie/services/blockatie_pro_service.dart';
import 'package:flutter/material.dart';

class BlockatieProProvider extends ChangeNotifier {
  List<BlockatieProPackage> _packages = [];
  bool _isLoading = false;
  String? _error;

  List<BlockatieProPackage> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPackages() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BlockatieProService.getPackages();

      if (response != null && response.success) {
        _packages = response.packages;
        _error = null;
      } else {
        _error =
            'Failed to load packages. Please check your connection and try again.';
        _packages = [];
      }
    } catch (_) {
      _error = 'Network error: Unable to connect to server. Please try again.';
      _packages = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
