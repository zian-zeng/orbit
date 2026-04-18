import 'dart:async';
import 'dart:convert';
import 'dart:io';

class HttpJsonClient {
  HttpJsonClient({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  Future<dynamic> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final request = await _httpClient.getUrl(uri).timeout(timeout);
    headers.forEach(request.headers.set);
    final response = await request.close().timeout(timeout);
    return _decodeResponse(response);
  }

  Future<dynamic> postJson(
    Uri uri, {
    required Map<String, dynamic> body,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final request = await _httpClient.postUrl(uri).timeout(timeout);
    request.headers.contentType = ContentType.json;
    headers.forEach(request.headers.set);
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(timeout);
    return _decodeResponse(response);
  }

  Future<dynamic> _decodeResponse(HttpClientResponse response) async {
    final body = await response.transform(utf8.decoder).join();
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
