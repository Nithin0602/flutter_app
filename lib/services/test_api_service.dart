// lib/services/test_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class TestApiService {
  static const String _baseUrl = 'http://10.15.5.171/api/method';
  
  // Test if API works with current token
  static Future<Map<String, dynamic>> testApiConnection() async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null || token.isEmpty) {
        return {
          'success': false, 
          'message': 'No token found',
        };
      }

      // Try a simple API that works (based on your example)
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token,
        'Accept': 'application/json',
      };

      // Try a test API that you know works
      final response = await http.get(
        Uri.parse('$_baseUrl/frappe.auth.get_logged_user'),
        headers: headers,
      );

      print('Test API Status: ${response.statusCode}');
      print('Test API Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'API connection successful',
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Test API failed with ${response.statusCode}',
          'status_code': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      print('Test API Error: $e');
      return {
        'success': false,
        'message': 'Test API error: ${e.toString()}',
      };
    }
  }
}