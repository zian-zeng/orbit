import 'dart:async';
import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class HttpJsonClient {
  HttpJsonClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<dynamic> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final response = await _httpClient.get(
      uri,
      headers: headers,
    ).timeout(timeout);
    return _decodeResponse(response);
  }

  Future<dynamic> postJson(
    Uri uri, {
    required Map<String, dynamic> body,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final response = await _httpClient
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ...headers,
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Future<dynamic> _decodeResponse(http.Response response) async {
    final body = response.body;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpJsonException(
        'HTTP ${response.statusCode}: ${_shorten(body)}',
      );
    }
    if (body.trim().isEmpty) {
      return null;
    }
    return jsonDecode(body);
  }

  String _shorten(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 180) {
      return normalized;
    }
    return '${normalized.substring(0, 180)}...';
  }
}

class HttpJsonException implements Exception {
  const HttpJsonException(this.message);

  final String message;

  @override
  String toString() => message;
}
