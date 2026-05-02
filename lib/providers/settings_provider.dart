// ============================================================
// providers/settings_provider.dart
// Manages shop settings state and syncs with SQLite
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/shop_settings.dart';
import '../services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  ShopSettings _settings = const ShopSettings();

  /// Current shop settings (read-only)
  ShopSettings get settings => _settings;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Whether shop info has been configured at least once
  bool get isConfigured => _settings.isConfigured;

  /// Load settings from the database (called on app start)
  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await DatabaseService.instance.loadShopSettings();
    } catch (e) {
      _error = 'Failed to load settings: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save settings to the database
  Future<bool> saveSettings(ShopSettings newSettings) async {
    try {
      await DatabaseService.instance.saveShopSettings(newSettings);
      _settings = newSettings;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save settings: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Update a single field and save
  Future<bool> updateField(String key, String value) async {
    try {
      await DatabaseService.instance.saveSetting(key, value);
      // Reload to get fresh state
      _settings = await DatabaseService.instance.loadShopSettings();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update setting: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }
}
