import 'dart:convert';
import 'package:http/http.dart' as http;

// Backend is deployed on Render, backed by a Neon Postgres database — see
// backend/README.md for the deployment setup. The free Render tier spins
// down after 15 minutes of inactivity, so the first request after idle can
// take 30-60s to wake back up; that's expected, not a bug.
const String apiBaseUrl = 'https://the-shoolins.onrender.com/api';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers,
    );
    return _decode(response);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers,
    );
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) {
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, 'Request failed');
      }
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = decoded is Map<String, dynamic>
          ? (decoded['error']?.toString() ?? 'Request failed')
          : 'Request failed';
      throw ApiException(response.statusCode, message);
    }
    return decoded;
  }
}

String productAssetPath(String imageFilename) => 'assets/products/$imageFilename';
