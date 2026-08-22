import 'package:shared_preferences/shared_preferences.dart';
import 'settings_keys.dart';

class SettingsService {
  static late final SettingsService instance;

  final SharedPreferences _prefs;

  SettingsService._(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    instance = SettingsService._(prefs);
    return instance;
  }

  double getAnalysisTolerance() {
    return _prefs.getDouble(SettingsKeys.analysisTolerance) ?? 10.0;
  }

  Future<void> setAnalysisTolerance(double value) async {
    await _prefs.setDouble(SettingsKeys.analysisTolerance, value);
  }

  double getAnalysisKL() {
    return _prefs.getDouble(SettingsKeys.analysisKL) ?? 1.0;
  }

  Future<void> setAnalysisKL(double value) async {
    await _prefs.setDouble(SettingsKeys.analysisKL, value);
  }

  bool getColorNormalization() {
    return _prefs.getBool(SettingsKeys.colorNormalization) ?? false;
  }

  Future<void> setColorNormalization(bool value) async {
    await _prefs.setBool(SettingsKeys.colorNormalization, value);
  }

  String getMatchingMode() {
    return _prefs.getString(SettingsKeys.matchingMode) ?? 'ciede2000';
  }

  Future<void> setMatchingMode(String value) async {
    await _prefs.setString(SettingsKeys.matchingMode, value);
  }
}
