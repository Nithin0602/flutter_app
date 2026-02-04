// lib/services/dashboard_service.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class DashboardService {
  static const String _baseUrl = 'http://10.15.5.171/api/method';
  
  // Method 1: Using AuthService (your current approach)
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      // Get raw token string
      final token = await AuthService.getToken();
      
      print('Dashboard Token: ${token?.substring(0, math.min(20, token?.length ?? 0))}...');
      
      if (token == null || token.isEmpty) {
        return {
          'success': false, 
          'message': 'No authentication token found. Please login again.',
          'error_code': 'NO_TOKEN'
        };
      }

      // Build headers EXACTLY like your working sample
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Cookie': 'sid=$token',  // Add Cookie header
        'Authorization': 'Token $token', // Add "Token " prefix
      };

      print('Dashboard API URL: $_baseUrl/wtt_module.customization.custom.test.get_employee_dashboard');
      print('Dashboard API Headers: $headers');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/wtt_module.customization.custom.test.get_employee_dashboard'),
        headers: headers,
      );

      print('Dashboard Response Status: ${response.statusCode}');
      
      // Log first 300 characters of response for debugging
      if (response.body.isNotEmpty) {
        final preview = response.body.substring(0, math.min(300, response.body.length));
        print('Dashboard Response Preview: $preview...');
      }
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Debug: Print the structure
        print('Response has message key: ${data.containsKey('message')}');
        if (data.containsKey('message')) {
          final message = data['message'];
          print('Message keys: ${message.keys}');
          print('Message success_key: ${message['success_key']}');
        }
        
        if (data['message']?['success_key'] == 1) {
          return {
            'success': true,
            'data': data['message'],
          };
        } else {
          return {
            'success': false,
            'message': data['message']?['message'] ?? 'Failed to fetch dashboard data',
            'error_code': 'API_ERROR'
          };
        }
      } else if (response.statusCode == 403) {
        // Handle whitelisting error
        final errorBody = response.body;
        print('403 Error Body: $errorBody');
        
        return {
          'success': false,
          'message': 'API method needs to be whitelisted on server.',
          'error_code': 'NOT_WHITELISTED',
          'status_code': 403,
          'details': errorBody
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'error_code': 'SERVER_ERROR',
          'status_code': response.statusCode,
          'details': response.body
        };
      }
    } catch (e) {
      print('Dashboard Service Error: $e');
      print('Stack trace: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_code': 'NETWORK_ERROR'
      };
    }
  }
  
  // Method 2: Direct approach matching your working sample
  static Future<Map<String, dynamic>> getDashboardDataSimple() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No token found in SharedPreferences'};
      }
      
      const url = 'http://10.15.5.171/api/method/wtt_module.customization.custom.test.get_employee_dashboard';
      
      print('=== SIMPLE API CALL ===');
      print('URL: $url');
      print('Token length: ${token.length}');
      print('Token: $token');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$token',
          'Authorization': 'Token $token',
        },
      );
      
      print('Simple API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Debug: Print the entire response structure
        print('=== RESPONSE STRUCTURE ===');
        print('Root keys: ${data.keys}');
        
        if (data.containsKey('message')) {
          final message = data['message'];
          print('Message type: ${message.runtimeType}');
          print('Message keys: ${message.keys}');
          
          if (message is Map) {
            // Check for success_key
            print('Success key: ${message['success_key']}');
            
            // Check for today_status
            if (message.containsKey('today_status')) {
              final todayStatus = message['today_status'];
              print('Today status type: ${todayStatus.runtimeType}');
              print('Today status keys: ${todayStatus.keys}');
              print('Checkin time: ${todayStatus['checkin_time']}');
              print('Check out: ${todayStatus['check_out']}');
            }
            
            // Check for monthly_attendance
            if (message.containsKey('monthly_attendance')) {
              final monthlyAttendance = message['monthly_attendance'];
              print('Monthly attendance type: ${monthlyAttendance.runtimeType}');
              if (monthlyAttendance is Map) {
                print('Monthly attendance keys: ${monthlyAttendance.keys}');
                print('Present: ${monthlyAttendance['present']}');
                print('Absent: ${monthlyAttendance['absent']}');
                print('Total Present: ${monthlyAttendance['Total Presnet']}');
                print('Total Absents: ${monthlyAttendance['Total Absents']}');
              }
            }
            
            // Check for monthly_late
            if (message.containsKey('monthly_late')) {
              final monthlyLate = message['monthly_late'];
              print('Monthly late type: ${monthlyLate.runtimeType}');
              if (monthlyLate is Map) {
                print('Monthly late keys: ${monthlyLate.keys}');
                print('Total late: ${monthlyLate['total_late']}');
              }
            }
            
            // Check for joining_details
            if (message.containsKey('joining_details')) {
              final joiningDetails = message['joining_details'];
              print('Joining details type: ${joiningDetails.runtimeType}');
              if (joiningDetails is Map) {
                print('Joining details keys: ${joiningDetails.keys}');
                print('Total days: ${joiningDetails['total_days']}');
              }
            }
          }
        }
        
        if (data['message']?['success_key'] == 1) {
          return {
            'success': true,
            'data': data['message'],
          };
        } else {
          return {
            'success': false,
            'message': 'API returned success_key != 1',
            'data': data
          };
        }
      } else {
        print('Response body: ${response.body}');
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}',
          'status_code': response.statusCode,
          'body': response.body
        };
      }
    } catch (e) {
      print('Simple API Error: $e');
      print('Error type: ${e.runtimeType}');
      return {
        'success': false, 
        'message': 'Exception: ${e.toString()}'
      };
    }
  }
  
  // Method 3: Try alternative header formats
  static Future<Map<String, dynamic>> getDashboardDataAlternative() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No token'};
      }
      
      const url = 'http://10.15.5.171/api/method/wtt_module.customization.custom.test.get_employee_dashboard';
      
      // Try different header combinations
      final List<Map<String, String>> headerOptions = [
        {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$token',
          'Authorization': 'Token $token',
        },
        {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$token',
          'Authorization': 'Bearer $token',
        },
        {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$token',
        },
        {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        {
          'Content-Type': 'application/json',
          'Authorization': '$token', // Raw token
        },
      ];
      
      for (int i = 0; i < headerOptions.length; i++) {
        try {
          print('Trying header option ${i + 1}: ${headerOptions[i]}');
          
          final response = await http.get(
            Uri.parse(url),
            headers: headerOptions[i],
          ).timeout(Duration(seconds: 10));
          
          print('Option ${i + 1} status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['message']?['success_key'] == 1) {
              print('Success with option ${i + 1}');
              return {
                'success': true,
                'data': data['message'],
                'header_option': i + 1,
              };
            }
          }
        } catch (e) {
          print('Option ${i + 1} failed: $e');
          continue;
        }
      }
      
      return {
        'success': false,
        'message': 'All header options failed',
      };
    } catch (e) {
      print('Alternative API Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Helper method to get dashboard data with fallback
  static Future<Map<String, dynamic>> getDashboardDataWithFallback() async {
    print('=== GETTING DASHBOARD DATA ===');
    
    // First try the simple method (matches your working sample)
    print('\n1. Trying simple method...');
    var result = await getDashboardDataSimple();
    
    if (result['success'] == true) {
      print('✅ Simple method succeeded');
      return result;
    }
    
    print('❌ Simple method failed: ${result['message']}');
    
    // Try alternative headers
    print('\n2. Trying alternative headers...');
    result = await getDashboardDataAlternative();
    
    if (result['success'] == true) {
      print('✅ Alternative headers succeeded with option ${result['header_option']}');
      return result;
    }
    
    print('❌ Alternative headers failed: ${result['message']}');
    
    // Try original method
    print('\n3. Trying original method...');
    result = await getDashboardData();
    
    if (result['success'] == true) {
      print('✅ Original method succeeded');
      return result;
    }
    
    print('❌ All methods failed');
    return result;
  }
  
  // Parse data for specific cards
  static Map<String, dynamic> parseDashboardForCards(Map<String, dynamic> dashboardData) {
    try {
      final todayStatus = dashboardData['today_status'] ?? {};
      final monthlyAttendance = dashboardData['monthly_attendance'] ?? {};
      final monthlyLate = dashboardData['monthly_late'] ?? {};
      final joiningDetails = dashboardData['joining_details'] ?? {};
      
      return {
        'checkin_time': todayStatus['checkin_time']?.toString() ?? '--:--',
        'check_out': todayStatus['check_out']?.toString() ?? '--:--',
        'present': _getPresentValue(monthlyAttendance),
        'absent': _getAbsentValue(monthlyAttendance),
        'late': monthlyLate['total_late']?.toString() ?? '0',
        'total_days': joiningDetails['total_days']?.toString() ?? '0',
      };
    } catch (e) {
      print('Error parsing dashboard for cards: $e');
      return {
        'checkin_time': '--:--',
        'check_out': '--:--',
        'present': '0',
        'absent': '0',
        'late': '0',
        'total_days': '0',
      };
    }
  }
  
  static String _getPresentValue(Map<String, dynamic> monthlyAttendance) {
    try {
      // Try different possible keys
      if (monthlyAttendance.containsKey('Total Presnet')) {
        return monthlyAttendance['Total Presnet']?.toString() ?? '0';
      }
      if (monthlyAttendance.containsKey('total_present')) {
        return monthlyAttendance['total_present']?.toString() ?? '0';
      }
      if (monthlyAttendance.containsKey('present')) {
        final present = (monthlyAttendance['present'] ?? 0).toDouble();
        final halfDay = (monthlyAttendance['half_day'] ?? 0).toDouble();
        return (present + halfDay * 0.5).toString();
      }
      return '0';
    } catch (e) {
      return '0';
    }
  }
  
  static String _getAbsentValue(Map<String, dynamic> monthlyAttendance) {
    try {
      // Try different possible keys
      if (monthlyAttendance.containsKey('Total Absents')) {
        return monthlyAttendance['Total Absents']?.toString() ?? '0';
      }
      if (monthlyAttendance.containsKey('total_absents')) {
        return monthlyAttendance['total_absents']?.toString() ?? '0';
      }
      if (monthlyAttendance.containsKey('absent')) {
        return monthlyAttendance['absent']?.toString() ?? '0';
      }
      return '0';
    } catch (e) {
      return '0';
    }
  }
  
  // Get only the 6 values needed for cards
  static Future<Map<String, dynamic>> getDashboardCardsData() async {
    try {
      final result = await getDashboardDataWithFallback();
      
      if (result['success'] == true) {
        final cardsData = parseDashboardForCards(result['data']);
        return {
          'success': true,
          'cards': cardsData,
          'full_data': result['data'],
        };
      } else {
        // Return mock data for demo
        return {
          'success': false,
          'message': result['message'],
          'cards': {
            'checkin_time': '09:03 AM',
            'check_out': '-',
            'present': '1.5',
            'absent': '3.5',
            'late': '1',
            'total_days': '1908',
          },
          'is_mock': true,
        };
      }
    } catch (e) {
      print('Error getting dashboard cards: $e');
      return {
        'success': false,
        'message': e.toString(),
        'cards': {
          'checkin_time': '09:03 AM',
          'check_out': '-',
          'present': '1.5',
          'absent': '3.5',
          'late': '1',
          'total_days': '1908',
        },
        'is_mock': true,
      };
    }
  }
}