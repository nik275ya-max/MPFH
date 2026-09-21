import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _instKey = 'mpfh-instruction';
  static const _countKey = 'mpfh-replies-count';
  static const _licenseKey = 'mpfh-license-key';
  static const _deviceIdKey = 'mpfh-device-id';
  static const _apiUrlKey = 'mpfh-api-url';
  static const _sensitivityKey = 'mpfh-sensitivity';
  static const _tiltAngleKey = 'mpfh-tilt-angle';

  String instruction = 'Инструкция к фокусу:';
  int repliesCount = 4;
  String license = '';
  String deviceId = '';
  String apiUrl = 'https://d5dn894hrib988v7pucu.kr8f6hld.apigw.yandexcloud.net';

  double sensitivity = 50;
  double tiltAngle = 25;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    instruction = _prefs.getString(_instKey) ?? instruction;
    repliesCount = _prefs.getInt(_countKey) ?? repliesCount;
    license = _prefs.getString(_licenseKey) ?? license;
    deviceId = _prefs.getString(_deviceIdKey) ?? _generateDeviceId();
    apiUrl = _prefs.getString(_apiUrlKey) ?? apiUrl;
    sensitivity = _prefs.getDouble(_sensitivityKey) ?? sensitivity;
    tiltAngle = _prefs.getDouble(_tiltAngleKey) ?? tiltAngle;
    if (_prefs.getString(_deviceIdKey) == null) {
      await _prefs.setString(_deviceIdKey, deviceId);
    }
  }

  Future<void> setInstruction(String value) async {
    instruction = value;
    await _prefs.setString(_instKey, value);
  }

  Future<void> setRepliesCount(int value) async {
    repliesCount = value;
    await _prefs.setInt(_countKey, value);
  }

  Future<void> setLicense(String value) async {
    license = value;
    await _prefs.setString(_licenseKey, value);
  }

  Future<void> setApiUrl(String value) async {
    apiUrl = value;
    await _prefs.setString(_apiUrlKey, value);
  }

  Future<void> setSensitivity(double value) async {
    sensitivity = value;
    await _prefs.setDouble(_sensitivityKey, value);
  }

  Future<void> setTiltAngle(double value) async {
    tiltAngle = value;
    await _prefs.setDouble(_tiltAngleKey, value);
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}