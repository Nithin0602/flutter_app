// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://10.15.5.171/api/method';
  
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('Login API: $_baseUrl/wtt_module.customization.custom.test.user_login');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/wtt_module.customization.custom.test.user_login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'username': username, 'password': password}),
      );

      print('Login Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['message']?['success_key'] == 1) {
          // Save user data with raw token string
          await _saveUserData(data['message']);
          
          return {
            'success': true,
            'data': data['message'],
          };
        } else {
          return {
            'success': false,
            'message': data['message']?['message'] ?? 'Login failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Login Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Save raw token string (not as JSON object)
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save raw token string directly
    final rawToken = userData['token']?.toString() ?? '';
    await prefs.setString('token', rawToken);
    
    // Save other user data
    await prefs.setString('employee_id', userData['employee']?.toString() ?? '');
    await prefs.setString('full_name', userData['full_name']?.toString() ?? '');
    await prefs.setString('user_email', userData['email']?.toString() ?? '');
    await prefs.setString('user_permissions', json.encode(userData['permissions'] ?? {}));
    
    print('Raw token saved: $rawToken (length: ${rawToken.length})');
  }

  // Get raw token string
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Retrieved raw token: ${token?.substring(0, 20)}... (length: ${token?.length})');
    return token;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('employee_id');
    await prefs.remove('full_name');
    await prefs.remove('user_email');
    await prefs.remove('user_permissions');
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsJson = prefs.getString('user_permissions');
    Map<String, dynamic> permissions = {};
    
    if (permissionsJson != null) {
      try {
        permissions = json.decode(permissionsJson);
      } catch (e) {
        print('Error decoding permissions: $e');
      }
    }
    
    return {
      'employee_id': prefs.getString('employee_id'),
      'full_name': prefs.getString('full_name'),
      'user_email': prefs.getString('user_email'),
      'permissions': permissions,
    };
  }

  // Verify token is valid (not empty)
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}