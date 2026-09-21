import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  String _baseUrl(String url) {
    var clean = url.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  Future<String?> sendReplies({
    required String instruction,
    required List<String> replies,
  }) async {
    final settings = SettingsService.instance;
    final base = _baseUrl(settings.apiUrl);
    final uri = Uri.parse('$base/save');

    final body = {
      'instruction': instruction,
      'replies': replies,
      'license': settings.license,
      'deviceId': settings.deviceId,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'ok') {
          return settings.license.isEmpty
              ? '$base/'
              : '$base/?license=${Uri.encodeQueryComponent(settings.license)}';
        }
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}