import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class ApiService {
  final String _baseUrl = 'http://127.0.0.1:8080/api';

  // 401错误回调函数
  static void Function()? _onUnauthorized;

  // 设置401错误处理回调
  static void setUnauthorizedCallback(void Function() callback) {
    _onUnauthorized = callback;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _request(String method, String endpoint,
      {dynamic body, Map<String, String>? queryParams}) async {
    var uri = Uri.parse('$_baseUrl$endpoint');
    if (queryParams != null) uri = uri.replace(queryParameters: queryParams);
    final headers = await _getHeaders();

    // 记录请求信息
    AppLogger.httpRequest(
      method: method,
      url: uri.toString(),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'POST':
          response =
              await http.post(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        case 'PUT':
          response =
              await http.put(uri, headers: headers, body: jsonEncode(body));
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // 记录响应信息
      AppLogger.httpResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
        contentLength: response.contentLength,
      );

      // 检查是否为401未授权错误
      if (response.statusCode == 401 && _onUnauthorized != null) {
        _onUnauthorized!();
      }

      return response;
    } catch (e, stackTrace) {
      // 记录异常信息
      AppLogger.httpError(
        message: 'HTTP 请求失败',
        error: e,
        stackTrace: stackTrace,
        url: uri.toString(),
        method: method,
      );
      rethrow;
    }
  }

  // Auth
  Future<http.Response> login(String u, String p) =>
      _request('POST', '/auth/login', body: {'username': u, 'password': p});
  Future<http.Response> register(String u, String p, String e) =>
      _request('POST', '/auth/register',
          body: {'username': u, 'password': p, 'email': e});

  // User Profile
  Future<http.Response> getUserProfile() => _request('GET', '/user/profile');
  Future<http.Response> updateUserAvatar(String avatarData) =>
      _request('PUT', '/user/avatar', body: {'avatar': avatarData});
  Future<http.Response> updateUserPassword(
          String currentPassword, String newPassword) =>
      _request('PUT', '/user/password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword
      });
  Future<http.Response> updateUserEmail(String email, String password) =>
      _request('PUT', '/user/email',
          body: {'email': email, 'password': password});

  // Categories
  Future<http.Response> getCategories() => _request('GET', '/categories');

  // Transactions
  Future<http.Response> getTransactions({String? m, String? d}) {
    Map<String, String>? queryParams;
    if (m != null || d != null) {
      queryParams = <String, String>{};
      if (m != null) queryParams['month'] = m;
      if (d != null) queryParams['date'] = d;
    }
    return _request('GET', '/transactions', queryParams: queryParams);
  }

  Future<http.Response> createTransaction(Map<String, dynamic> data) =>
      _request('POST', '/transactions', body: data);
  Future<http.Response> deleteTransaction(String id) =>
      _request('DELETE', '/transactions/$id');

  // Statistics
  Future<http.Response> getStatistics({required int y, required int m}) =>
      _request('GET', '/statistics',
          queryParams: {'year': y.toString(), 'month': m.toString()});

  // Assets
  Future<http.Response> getAssets() => _request('GET', '/assets');
  Future<http.Response> createAsset(String n, String cId) =>
      _request('POST', '/assets',
          body: {'name': n, 'categoryId': int.parse(cId)});
  Future<http.Response> deleteAsset(String id) =>
      _request('DELETE', '/assets/$id');
  Future<http.Response> createAssetRecord(String id, String d, double a) =>
      _request('POST', '/assets/$id/records', body: {'date': d, 'amount': a});

  // Asset Categories
  Future<http.Response> getAssetCategories() =>
      _request('GET', '/asset-categories');
  Future<http.Response> createAssetCategory(String n, String i, String t) =>
      _request('POST', '/asset-categories',
          body: {'name': n, 'icon': i, 'type': t});
  Future<http.Response> deleteAssetCategory(String id) =>
      _request('DELETE', '/asset-categories/$id');
}
