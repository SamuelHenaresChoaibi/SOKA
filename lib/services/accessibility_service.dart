import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService extends ChangeNotifier {
  static const _themeModeKey = 'accessibility_theme_mode';
  static const _textScaleFactorKey = 'accessibility_text_scale_factor';
  static const _highContrastKey = 'accessibility_high_contrast';
  static const _reduceMotionKey = 'accessibility_reduce_motion';
  static const _boldTextKey = 'accessibility_bold_text';

  ThemeMode _themeMode = ThemeMode.system;
  double _textScaleFactor = 1.0;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _boldText = false;
  bool _isReady = false;

  SharedPreferences? _prefs;

  AccessibilityService() {
    _load();
  }

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;
  bool get boldText => _boldText;
  bool get isReady => _isReady;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    final themeModeName = _prefs?.getString(_themeModeKey);
    _themeMode = _themeModeFromString(themeModeName);
    _textScaleFactor = (_prefs?.getDouble(_textScaleFactorKey) ?? 1.0).clamp(
      0.9,
      1.5,
    );
    _highContrast = _prefs?.getBool(_highContrastKey) ?? false;
    _reduceMotion = _prefs?.getBool(_reduceMotionKey) ?? false;
    _boldText = _prefs?.getBool(_boldTextKey) ?? false;
    _isReady = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) return;
    _themeMode = value;
    await _prefs?.setString(_themeModeKey, value.name);
    notifyListeners();
  }

  Future<void> setTextScaleFactor(double value) async {
    final normalized = value.clamp(0.9, 1.5);
    if ((_textScaleFactor - normalized).abs() < 0.001) return;
    _textScaleFactor = normalized;
    await _prefs?.setDouble(_textScaleFactorKey, normalized);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    if (_highContrast == value) return;
    _highContrast = value;
    await _prefs?.setBool(_highContrastKey, value);
    notifyListeners();
  }

  Future<void> setReduceMotion(bool value) async {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    await _prefs?.setBool(_reduceMotionKey, value);
    notifyListeners();
  }

  Future<void> setBoldText(bool value) async {
    if (_boldText == value) return;
    _boldText = value;
    await _prefs?.setBool(_boldTextKey, value);
    notifyListeners();
  }

  Future<void> resetDefaults() async {
    _themeMode = ThemeMode.system;
    _textScaleFactor = 1.0;
    _highContrast = false;
    _reduceMotion = false;
    _boldText = false;

    await _prefs?.setString(_themeModeKey, _themeMode.name);
    await _prefs?.setDouble(_textScaleFactorKey, _textScaleFactor);
    await _prefs?.setBool(_highContrastKey, _highContrast);
    await _prefs?.setBool(_reduceMotionKey, _reduceMotion);
    await _prefs?.setBool(_boldTextKey, _boldText);
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
