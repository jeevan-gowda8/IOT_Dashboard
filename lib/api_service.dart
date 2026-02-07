// api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ Headers required for Thingsay in APK release
  static const Map<String, String> _headers = {
    "User-Agent": "Mozilla/5.0",
    "Accept": "*/*",
    "Connection": "keep-alive",
  };

  /// Timeout for all requests (adjust as needed)
  static const Duration _timeout = Duration(seconds: 10);

  /// ✅ GET that can return JSON OR plain text
  static Future<dynamic> fetchData(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = res.body.trim();

        // Try to parse as JSON if it looks like one
        if (body.startsWith('{') || body.startsWith('[')) {
          try {
            return jsonDecode(body);
          } catch (e) {
            // Not valid JSON → treat as plain text
            assert(() {
              debugPrint('[ApiService] Invalid JSON, falling back to plain text: $e');
              return true;
            }());
          }
        }

        // Return plain text (remove surrounding quotes if present)
        return body.replaceAll('"', '');
      } else {
        final msg = 'GET failed: ${res.statusCode} ${res.reasonPhrase}';
        assert(() {
          debugPrint('[ApiService] $msg | URL: $url');
          return true;
        }());
        throw HttpException(msg);
      }
    } catch (e) {
      assert(() {
        debugPrint('[ApiService] fetchData error for $url: $e');
        return true;
      }());
      rethrow; // Let caller handle it
    }
  }

  /// ✅ POST → ON/OFF (fire-and-forget or confirmed)
  static Future<void> postTrigger(String url) async {
    try {
      final res = await http
          .post(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      // Consider 2xx as success
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = 'POST failed: ${res.statusCode} ${res.reasonPhrase}';
        assert(() {
          debugPrint('[ApiService] $msg | URL: $url');
          return true;
        }());
        throw HttpException(msg);
      }

      // Optional: log success in debug
      assert(() {
        debugPrint('[ApiService] POST succeeded: $url');
        return true;
      }());
    } catch (e) {
      assert(() {
        debugPrint('[ApiService] postTrigger error for $url: $e');
        return true;
      }());
      rethrow; // Important: propagate error so UI can react
    }
  }
}

// Custom exception for clarity
class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}