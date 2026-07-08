import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final ApiClient apiClient;

  String? _token;
  User? _user;
  bool _isLoading = true;

  AuthService(this.apiClient);

  String? get token => _token;
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);
    final storedUser = prefs.getString(_userKey);
    if (storedToken != null && storedUser != null) {
      _token = storedToken;
      _user = User.fromJson(jsonDecode(storedUser) as Map<String, dynamic>);
      apiClient.setToken(_token);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> requestOtp(String mobile) async {
    final response = await apiClient.post('/auth/otp/request', {'mobile': mobile});
    return (response as Map<String, dynamic>)['devOtp'] as String?;
  }

  Future<bool> verifyOtp(String mobile, String otp) async {
    final response = await apiClient.post('/auth/otp/verify', {
      'mobile': mobile,
      'otp': otp,
    });
    await _saveSession(response);
    return response['isNewUser'] as bool;
  }

  Future<void> _saveSession(dynamic response) async {
    final token = response['token'] as String;
    final user = User.fromJson(response['user'] as Map<String, dynamic>);

    _token = token;
    _user = user;
    apiClient.setToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));

    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? photoBase64,
  }) async {
    final response = await apiClient.patch('/auth/me', {
      'name': name,
      'address': ?address,
      'city': ?city,
      'state': ?state,
      'pincode': ?pincode,
      'photoBase64': ?photoBase64,
    });
    _user = User.fromJson(response as Map<String, dynamic>);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_user!.toJson()));

    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    apiClient.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    notifyListeners();
  }
}
