import 'settings_service.dart';

class LicenseService {
  LicenseService._();
  static final LicenseService instance = LicenseService._();

  bool isValidStored() {
    final key = SettingsService.instance.license;
    if (key.isEmpty) return false;
    return LicenseValidator.validateFormat(key).valid;
  }

  Future<bool> save(String key) async {
    final normalized = key.toUpperCase().trim();
    final result = LicenseValidator.validateFormat(normalized);
    if (!result.valid) return false;
    await SettingsService.instance.setLicense(normalized);
    return true;
  }

  Future<void> clear() async {
    await SettingsService.instance.setLicense('');
  }
}

class LicenseValidator {
  static const _pattern = r'^MPFH-(\d{8})-([A-Z0-9]{4})-([A-Z0-9]{4})$';

  static ({bool valid, String? error}) validateFormat(String key) {
    final normalized = key.toUpperCase().trim();
    final match = RegExp(_pattern).firstMatch(normalized);
    if (match == null) {
      return (
        valid: false,
        error: 'Неверный формат ключа. Используйте MPFH-YYYYMMDD-XXXX-XXXX'
      );
    }
    final datePart = match.group(1)!;
    final checksum = match.group(2)!;

    if (!_isValidDate(datePart)) {
      return (valid: false, error: 'Неверная дата в ключе');
    }
    if (_crcToChecksum(_crc16(datePart)) != checksum) {
      return (valid: false, error: 'Неверная контрольная сумма ключа');
    }
    return (valid: true, error: null);
  }

  static int _crc16(String data) {
    var crc = 0xFFFF;
    for (final unit in data.codeUnits) {
      crc ^= unit;
      for (var j = 0; j < 8; j++) {
        crc = (crc & 1) != 0 ? (0xA001 ^ (crc >> 1)) : (crc >> 1);
      }
    }
    return crc & 0xFFFF;
  }

  static String _crcToChecksum(int crc) {
    return crc.toRadixString(16).padLeft(4, '0').toUpperCase();
  }

  static bool _isValidDate(String dateStr) {
    if (!RegExp(r'^\d{8}$').hasMatch(dateStr)) return false;
    final year = int.tryParse(dateStr.substring(0, 4));
    final month = int.tryParse(dateStr.substring(4, 6));
    final day = int.tryParse(dateStr.substring(6, 8));
    if (month == null || day == null) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    final test = DateTime(year!, month, day);
    return test.year == year && test.month == month && test.day == day;
  }
}