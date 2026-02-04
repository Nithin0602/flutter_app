// home_screen.dart - CORRECTED VERSION
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math; // Add 'as math' to avoid conflict
import 'dart:convert';
import 'package:http/http.dart' as http;

// Import services and models
import '../services/dashboard_service.dart';
import '../models/dashboard_model.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final bool initialDarkMode;
  final Function(bool) onThemeChanged;
  
  HomeScreen({
    required this.initialDarkMode,
    required this.onThemeChanged,
  });
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Welcome animation state
  bool _showWelcomeAnimation = true;
  bool _animationComplete = false;
  bool _isLoadingQuote = false;
  bool _typingComplete = false;
  late AnimationController _welcomeController;
  late Animation<double> _smileyScale;
  late Animation<double> _smileyOpacity;
  late Animation<Offset> _smileyPosition;
  late Animation<double> _greetingOpacity;
  late Animation<double> _quoteOpacity;
  late Animation<double> _dashboardFade;
  
  // Typing animation
  String _quote = '';
  String _typedQuote = '';
  int _currentIndex = 0;
  Timer? _typingTimer;
  Timer? _autoNavigateTimer;
  
  // Original home screen state
  bool _isDarkMode = false, _showSideMenu = false, _showProfileMenu = false;
  String _userName = 'John Doe';
  String _employeeId = 'EMP00123';
  String _userEmail = 'loading...';
  Map<String, dynamic> _permissions = {};
  
  // Dashboard data state
  bool _isLoadingDashboard = false;
  TodayStatus? _todayStatus;
  MonthlyAttendance? _monthlyAttendance;
  MonthlyLate? _monthlyLate;
  JoiningDetails? _joiningDetails;
  
  // Quote APIs - Multiple fallback options
  final List<Map<String, String>> _quoteApis = [
    {
      'url': 'https://api.quotable.io/random',
      'contentPath': 'content',
      'authorPath': 'author'
    },
    {
      'url': 'https://api.fisenko.net/quotes/en/random',
      'contentPath': 'text',
      'authorPath': 'author'
    },
    {
      'url': 'https://type.fit/api/quotes',
      'contentPath': 'text',
      'authorPath': 'author'
    },
  ];
  
  // Default quotes for fallback
  final List<String> _defaultQuotes = [
    "The only way to do great work is to love what you do. — Steve Jobs",
    "Innovation distinguishes between a leader and a follower. — Steve Jobs",
    "Your time is limited, so don't waste it living someone else's life. — Steve Jobs",
    "The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt",
    "The way to get started is to quit talking and begin doing. — Walt Disney",
    "Don't watch the clock; do what it does. Keep going. — Sam Levenson",
    "Believe you can and you're halfway there. — Theodore Roosevelt",
    "The only limit to our realization of tomorrow is our doubts of today. — Franklin D. Roosevelt",
  ];
  
  // Day names
  final List<String> _days = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 
    'Thursday', 'Friday', 'Saturday'
  ];
  
  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
    _loadUserData();
    _checkTokenFormat(); // Check token format
    _initWelcomeAnimation();
  }
  
  void _initWelcomeAnimation() {
    // Initialize welcome animations
    _welcomeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationComplete = true;
        });
      }
    });
    
    // Animation setup (keep your existing animations)
    _smileyScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    
    _smileyOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );
    
    _smileyPosition = Tween<Offset>(
      begin: Offset(0, -0.5),
      end: Offset(0, -0.1),
    ).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    
    _greetingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Interval(0.5, 0.7, curve: Curves.easeInOut),
      ),
    );
    
    _quoteOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Interval(0.7, 0.9, curve: Curves.easeInOut),
      ),
    );
    
    _dashboardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Interval(0.9, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    // Load quote from API and start animation
    _loadQuoteFromAPI().then((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        _welcomeController.forward();
        _startTypingAnimation();
      });
    });
  }
  
  Future<void> _loadQuoteFromAPI() async {
    setState(() {
      _isLoadingQuote = true;
    });
    
    try {
      // Try each API until one works
      for (var api in _quoteApis) {
        try {
          final quote = await _fetchQuoteFromAPI(api);
          if (quote.isNotEmpty) {
            setState(() {
              _quote = quote;
              _isLoadingQuote = false;
            });
            return;
          }
        } catch (e) {
          print("API ${api['url']} failed: $e");
          continue;
        }
      }
      
      // If all APIs fail, use default quote
      _useDefaultQuote();
    } catch (e) {
      print("All quote APIs failed: $e");
      _useDefaultQuote();
    }
  }
  
  Future<String> _fetchQuoteFromAPI(Map<String, String> api) async {
    try {
      final response = await http.get(
        Uri.parse(api['url']!),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different API response formats
        if (api['url']!.contains('type.fit')) {
          // This API returns an array of quotes
          final quotes = json.decode(response.body) as List;
          if (quotes.isNotEmpty) {
            final random = math.Random();
            final randomQuote = quotes[random.nextInt(quotes.length)];
            return '${randomQuote[api['contentPath']!]} — ${randomQuote[api['authorPath']!] ?? "Unknown"}';
          }
        } else {
          // Single quote APIs
          final content = data[api['contentPath']!] ?? '';
          final author = data[api['authorPath']!] ?? 'Unknown';
          return '$content — $author';
        }
      }
    } catch (e) {
      print("Error fetching from ${api['url']}: $e");
    }
    
    return '';
  }
  
  void _useDefaultQuote() {
    final random = math.Random();
    setState(() {
      _quote = _defaultQuotes[random.nextInt(_defaultQuotes.length)];
      _isLoadingQuote = false;
    });
  }
  
  void _startTypingAnimation() {
    if (_quote.isEmpty) {
      // If quote is still empty, use default
      _useDefaultQuote();
    }
    
    Future.delayed(Duration(milliseconds: 800), () {
      const typingSpeed = 40; // milliseconds per character
      
      _typingTimer = Timer.periodic(Duration(milliseconds: typingSpeed), (timer) {
        if (_currentIndex < _quote.length) {
          setState(() {
            _typedQuote += _quote[_currentIndex];
            _currentIndex++;
          });
        } else {
          timer.cancel();
          _onTypingComplete();
        }
      });
    });
  }
  
  void _onTypingComplete() {
    setState(() {
      _typingComplete = true;
    });
    
    // Start auto-navigate timer (5 seconds after typing completes)
    _autoNavigateTimer = Timer(Duration(seconds: 5), () {
      if (_showWelcomeAnimation) {
        setState(() {
          _showWelcomeAnimation = false;
        });
      }
    });
    _loadDashboardData();
  }
  
  void _skipWelcomeAnimation() {
    // Cancel any active timers
    _typingTimer?.cancel();
    _autoNavigateTimer?.cancel();
    
    // Stop animation controller
    _welcomeController.stop();
    
    // Show full quote immediately
    setState(() {
      _showWelcomeAnimation = false;
      _typedQuote = _quote;
      _typingComplete = true;
      _animationComplete = true;
    });
     _loadDashboardData();
  }
  
  // ====== SINGLE _loadDashboardData METHOD ======
  // In home_screen.dart, update _loadDashboardData method:

Future<void> _loadDashboardData() async {
  if (!_showWelcomeAnimation) {
    setState(() {
      _isLoadingDashboard = true;
    });
  }
  
  try {
    print('Loading dashboard data...');
    
    // First try the simple method (matching your working sample)
    var result = await DashboardService.getDashboardDataSimple();
    
    // If that fails, try the original method
    if (result['success'] != true) {
      print('Simple method failed, trying original method...');
      result = await DashboardService.getDashboardData();
    }
    
    if (result['success'] == true && mounted) {
      final data = result['data'];
      print('Dashboard data received successfully');
      
      // Debug: Print what we received
      print('Today status data: ${data['today_status']}');
      print('Monthly attendance data: ${data['monthly_attendance']}');
      print('Monthly late data: ${data['monthly_late']}');
      print('Joining details data: ${data['joining_details']}');
      
      setState(() {
        _todayStatus = TodayStatus.fromJson(data['today_status'] ?? {});
        _monthlyAttendance = MonthlyAttendance.fromJson(data['monthly_attendance'] ?? {});
        _monthlyLate = MonthlyLate.fromJson(data['monthly_late'] ?? {});
        _joiningDetails = JoiningDetails.fromJson(data['joining_details'] ?? {});
      });
      
      print('Dashboard data loaded into state');
      print('Checkin time: ${_todayStatus?.checkinTime}');
      print('Present: ${_monthlyAttendance?.totalPresent}');
      print('Absent: ${_monthlyAttendance?.totalAbsents}');
      print('Late: ${_monthlyLate?.totalLate}');
      print('Total days: ${_joiningDetails?.totalDays}');
      
    } else if (mounted) {
      // Log detailed error
      print('Dashboard error: ${result['message']}');
      print('Error code: ${result['error_code']}');
      
      if (result['error_code'] == 'NOT_WHITELISTED') {
        // Show whitelist warning
        _showApiWhitelistWarning(result['details'] ?? '');
        
        // Use demo data
        _useMockDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Failed to load dashboard data'),
            backgroundColor: _redColor,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Use demo data as fallback
        _useMockDashboardData();
      }
    }
  } catch (e) {
    print("Error loading dashboard data: $e");
    print('Stack trace: ${e.toString()}');
    
    // Use demo data on error
    _useMockDashboardData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: _redColor,
          duration: Duration(seconds: 3),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingDashboard = false;
      });
    }
  }
}
  // ====== END OF SINGLE METHOD ======
  
  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getUserData();
      setState(() {
        _userName = userData['full_name'] ?? 'John Doe';
        _employeeId = userData['employee_id'] ?? 'EMP00123';
        _userEmail = userData['user_email'] ?? 'loading...';
        
        final permissionsJson = userData['permissions'];
        if (permissionsJson != null) {
          _permissions = json.decode(permissionsJson);
        }
      });
    } catch (e) {
      print("Error loading user data: $e");
    }
  }
  
   @override
  void dispose() {
    _welcomeController.dispose();
    _typingTimer?.cancel();
    _autoNavigateTimer?.cancel();
    super.dispose();
  }
  
  // Theme colors
  Color get _primaryColor => _isDarkMode ? Color(0xFF64B5F6) : Color(0xFF2196F3);
  Color get _secondaryColor => _isDarkMode ? Color(0xFF4DB6AC) : Color(0xFF00BCD4);
  Color get _backgroundColor => _isDarkMode ? Color(0xFF121212) : Color(0xFFF5F7FA);
  Color get _surfaceColor => _isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFFFFFFF);
  Color get _textColor => _isDarkMode ? Color(0xFFE0E0E0) : Color(0xFF263238);
  Color get _textSecondaryColor => _isDarkMode ? Color(0xFF9E9E9E) : Color(0xFF78909C);
  Color get _cardColor => _isDarkMode ? Color(0xFF242424) : Color(0xFFFFFFFF);
  Color get _greenColor => _isDarkMode ? Color(0xFF4CAF50) : Color(0xFF4CAF50);
  Color get _redColor => _isDarkMode ? Color(0xFFF44336) : Color(0xFFF44336);
  Color get _yellowColor => _isDarkMode ? Color(0xFFFFC107) : Color(0xFFFFC107);
  Color get _blueColor => _isDarkMode ? Color(0xFF64B5F6) : Color(0xFF2196F3);
  Color get _orangeColor => _isDarkMode ? Color(0xFFFF9800) : Color(0xFFFF9800);
  
  Future<void> _toggleTheme() async {
    final newMode = !_isDarkMode;
    setState(() => _isDarkMode = newMode);
    widget.onThemeChanged(newMode);
  }
  
  void _toggleSideMenu() => setState(() => _showSideMenu = !_showSideMenu);
  void _toggleProfileMenu() => setState(() => _showProfileMenu = !_showProfileMenu);
  
  Future<void> _clearUserData() async {
    await AuthService.logout();
  }
  
  // Check token format method
  Future<void> _checkTokenFormat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token != null) {
      print('Current token format check:');
      print('Token: ${token.substring(0, math.min(30, token.length))}...');
      print('Token length: ${token.length}');
      print('Is JSON?: ${_isJson(token)}');
    } else {
      print('No token found');
    }
  }

  bool _isJson(String str) {
    try {
      json.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mock dashboard data method
  void _useMockDashboardData() {
  print('Loading mock dashboard data...');
  
  // Create mock data based on your Postman response
  setState(() {
    _todayStatus = TodayStatus(
      successKey: 1,
      employee: "WTT1199",
      logType: "OUT",
      checkinTime: "09:03 AM",
      coming: "Late",
      checkOut: "-",
      date: DateTime.now().toString().substring(0, 10)
    );
    
    _monthlyAttendance = MonthlyAttendance(
      present: 1,
      halfDay: 0.5,
      absent: 3,
      totalPresent: 1.5,
      totalAbsents: 3.5
    );
    
    _monthlyLate = MonthlyLate(
      totalLate: 1,
      lateDays: [DateTime.now().toString().substring(0, 10)],
      fromDate: "2025-12-01",
      toDate: DateTime.now().toString().substring(0, 10)
    );
    
    _joiningDetails = JoiningDetails(
      name: "WTT1199",
      employeeName: "GOKUL R",
      dateOfJoining: "2020-10-09",
      department: "ERP - WTT",
      totalDays: 1908
    );
  });
  
  print('Mock data loaded:');
  print('Checkin: ${_todayStatus?.checkinTime}');
  print('Checkout: ${_todayStatus?.checkOut}');
  print('Present: ${_monthlyAttendance?.totalPresent}');
  print('Absent: ${_monthlyAttendance?.totalAbsents}');
  print('Late: ${_monthlyLate?.totalLate}');
  print('Total days: ${_joiningDetails?.totalDays}');
}

  void _showApiWhitelistWarning(String details) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('API Access Required', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The dashboard API needs to be whitelisted on the server.', style: TextStyle(color: _textColor)),
              SizedBox(height: 10),
              Text('Error Details:', style: TextStyle(color: _textSecondaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  details.isNotEmpty ? details : 'Method not whitelisted',
                  style: TextStyle(color: _textColor, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
              SizedBox(height: 10),
              Text('Solution:', style: TextStyle(color: _textSecondaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text('Contact your ERPNext administrator to whitelist this method:', style: TextStyle(color: _textColor, fontSize: 12)),
              SizedBox(height: 5),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'wtt_module.customization.custom.test.get_employee_dashboard',
                  style: TextStyle(color: _primaryColor, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _primaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _useMockDashboardData(); // Use demo data
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Using demo data. Contact admin to whitelist API.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: Text('Use Demo Data', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutConfirmation() {
    _toggleSideMenu();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?', style: TextStyle(color: _textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _textSecondaryColor))
          ),
          TextButton(
            onPressed: () async {
              await _clearUserData();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
            },
            child: Text('Logout', style: TextStyle(color: _redColor)),
          ),
        ],
      ),
    );
  }
  
  bool _hasPermission(String permission) {
    return _permissions[permission] == 1;
  }

  void _navigateTo(String route) {
    _toggleSideMenu();
    
    final permissionMap = {
      'Employee Check-in': 'checkin',
      'Attendance': 'attendance',
      'Leave Request': 'leave',
      'Claim Request': 'claim',
      'On Duty': 'on_duty',
      'OT Request': 'ot_req',
      'Project Task': 'project_task',
      'Incident': 'operator',
      'Site Ticket': 'site_in',
    };
    
    final permissionKey = permissionMap[route];
    
    if (permissionKey != null && !_hasPermission(permissionKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You don\'t have permission to access $route'),
          backgroundColor: _redColor,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$route screen is coming soon!'),
        backgroundColor: _primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
  
  String get _currentDay {
    return _days[DateTime.now().weekday % 7];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Main Dashboard Content
          AnimatedOpacity(
            opacity: _showWelcomeAnimation ? 0.0 : 1.0,
            duration: Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            child: _buildDashboardContent(),
          ),
          
          // Welcome Overlay Animation
          if (_showWelcomeAnimation) _buildWelcomeOverlay(),
          
          // Side Menu & Profile Menu (always on top)
          if (_showSideMenu) _buildSideMenuBackdrop(),
          if (_showSideMenu) _buildSideMenu(),
          
          if (_showProfileMenu && !_showSideMenu) _buildProfileMenu(),
          if (_showProfileMenu && !_showSideMenu) _buildProfileMenuBackdrop(),
        ],
      ),
    );
  }
  
  // ... Rest of your UI methods remain the same (keep all _build methods)
  
  Widget _buildWelcomeOverlay() {
    return AnimatedBuilder(
      animation: _welcomeController,
      builder: (context, child) {
        return Container(
          color: _backgroundColor,
          child: Stack(
            children: [
              // Animated gradient background
              _buildAnimatedBackground(),
              
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Modern smiley icon with floating animation
                    Transform.translate(
                      offset: _smileyPosition.value * 200,
                      child: Opacity(
                        opacity: _smileyOpacity.value,
                        child: Transform.scale(
                          scale: _smileyScale.value * 1.8,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _primaryColor.withOpacity(0.9),
                                  _primaryColor.withOpacity(0.1),
                                ],
                                stops: [0.1, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.4),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                  offset: Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _surfaceColor,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, -5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => RadialGradient(
                                      center: Alignment.center,
                                      radius: 0.5,
                                      colors: [
                                        _primaryColor,
                                        _primaryColor.withOpacity(0.7),
                                        _secondaryColor,
                                      ],
                                      stops: [0.0, 0.5, 1.0],
                                    ).createShader(bounds),
                                    child: Icon(
                                      Icons.emoji_emotions_rounded,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 60),
                    
                    // Greeting text
                    Opacity(
                      opacity: _greetingOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            '$_greeting,',
                            style: TextStyle(
                              fontSize: 24,
                              color: _textSecondaryColor,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _userName.split(' ').first,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: _primaryColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: _primaryColor.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '$_currentDay • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 60),
                    
                    // Motivational quote (typing animation)
                    Opacity(
                      opacity: _quoteOpacity.value,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          children: [
                            Text(
                              '✨ Daily Inspiration ✨',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: _isLoadingQuote
                                  ? SizedBox(
                                      height: 30,
                                      child: Center(
                                        child: SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  : _typedQuote.isNotEmpty
                                      ? Text(
                                          _typedQuote,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _textColor,
                                            fontSize: 20,
                                            height: 1.6,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          key: ValueKey(_typedQuote.length),
                                        )
                                      : Text(
                                          'Loading today\'s inspiration...',
                                          style: TextStyle(
                                            color: _textSecondaryColor,
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                            ),
                            SizedBox(height: 20),
                            // Typing indicator or auto-navigate countdown
                            if (_typedQuote.isNotEmpty)
                              _buildStatusIndicator(),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Skip button (visible during typing AND after typing completes)
                    if (_typedQuote.isNotEmpty)
                      _buildSkipButton(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatusIndicator() {
    if (!_typingComplete) {
      // Show typing indicator during typing
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'typing...',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      );
    } else {
      // Show countdown timer after typing completes
      return Column(
        children: [
          Text(
            'Dashboard will appear in 5 seconds...',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            width: 100,
            height: 4,
            child: LinearProgressIndicator(
              backgroundColor: _textSecondaryColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
        ],
      );
    }
  }
  
  Widget _buildSkipButton() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextButton(
            onPressed: _skipWelcomeAnimation,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Skip to Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _typingComplete 
                ? 'Click to go directly to dashboard'
                : 'Skip typing animation',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return IgnorePointer(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: _BackgroundPainter(
            animationValue: _welcomeController.value,
            isDarkMode: _isDarkMode,
            primaryColor: _primaryColor,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu_rounded, color: _textColor, size: 28),
                      onPressed: _toggleSideMenu,
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,', style: TextStyle(fontSize: 14, color: _textSecondaryColor)),
                        SizedBox(height: 4),
                        Text(_userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textColor)),
                        SizedBox(height: 4),
                        Text(_employeeId, style: TextStyle(fontSize: 12, color: _textSecondaryColor)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: _textColor, size: 24),
                      onPressed: _toggleTheme,
                    ),
                    GestureDetector(
                      onTap: _toggleProfileMenu,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [_primaryColor, _blueColor]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 10)],
                        ),
                        child: Center(
                          child: Text(
                            _userName.split(' ').map((n) => n[0]).join(),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 30),
            
            // Dashboard Cards with API Data
            if (_isLoadingDashboard && !_showWelcomeAnimation)
              _buildLoadingIndicator()
            else
              // In _buildDashboardContent() method, update the GridView:

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  // 1. Today Check-in
                  _buildAttendanceCard(
                    title: 'Today Check-in', 
                    value: _todayStatus?.checkinTime ?? '--:--', 
                    icon: Icons.login_rounded, 
                    color: _greenColor,
                    isLoading: _todayStatus == null,
                  ),
                  
                  // 2. Today Check-out
                  _buildAttendanceCard(
                    title: 'Today Check-out', 
                    value: _todayStatus?.checkOut ?? '--:--', 
                    icon: Icons.logout_rounded, 
                    color: _redColor,
                    isLoading: _todayStatus == null,
                  ),
                  
                  // 3. Present (This month)
                  _buildAttendanceCard(
                    title: 'Present', 
                    value: '${_monthlyAttendance?.totalPresent.toString() ?? '0'} days', 
                    icon: Icons.check_circle_rounded, 
                    color: _greenColor, 
                    badgeText: 'This month',
                    isLoading: _monthlyAttendance == null,
                  ),
                  
                  // 4. Absent (This month)
                  _buildAttendanceCard(
                    title: 'Absent', 
                    value: '${_monthlyAttendance?.totalAbsents.toString() ?? '0'} days', 
                    icon: Icons.cancel_rounded, 
                    color: _redColor, 
                    badgeText: 'This month',
                    isLoading: _monthlyAttendance == null,
                  ),
                  
                  // 5. Late (This month)
                  _buildAttendanceCard(
                    title: 'Late', 
                    value: '${_monthlyLate?.totalLate.toString() ?? '0'} days', 
                    icon: Icons.watch_later_rounded, 
                    color: _orangeColor, 
                    badgeText: 'This month',
                    isLoading: _monthlyLate == null,
                  ),
                  
                  // 6. Total Days in Company
                  _buildAttendanceCard(
                    title: 'Total Days', 
                    value: _joiningDetails?.totalDays.toString() ?? '0', 
                    icon: Icons.calendar_today_rounded, 
                    color: _blueColor,
                    badgeText: 'In company',
                    isLoading: _joiningDetails == null,
                  ),
                ],
              ),
            
            SizedBox(height: 30),
            
            // Refresh button
            if (!_isLoadingDashboard && !_showWelcomeAnimation)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _loadDashboardData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    foregroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: Icon(Icons.refresh_rounded, size: 20),
                  label: Text('Refresh Data'),
                ),
              ),
            
            SizedBox(height: 30),
            Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor)),
            SizedBox(height: 16),
            
            // Activity items based on API data
            if (_todayStatus?.checkinTime != null && _todayStatus!.checkinTime != '-')
              _buildActivityItem(
                title: 'Checked in today', 
                subtitle: _todayStatus!.checkinTime, 
                icon: Icons.login_rounded, 
                iconColor: _greenColor
              ),
            
            _buildActivityItem(
              title: 'Today Status', 
              subtitle: _todayStatus?.coming ?? 'Not checked in', 
              icon: Icons.info_rounded, 
              iconColor: _blueColor
            ),
            
            if (_monthlyLate?.totalLate != null && _monthlyLate!.totalLate > 0)
              _buildActivityItem(
                title: 'Late Days', 
                subtitle: '${_monthlyLate!.totalLate} late day(s) this month', 
                icon: Icons.warning_rounded, 
                iconColor: _orangeColor
              ),
            
            if (_joiningDetails?.department != null)
              _buildActivityItem(
                title: 'Department', 
                subtitle: _joiningDetails!.department, 
                icon: Icons.business_rounded, 
                iconColor: _primaryColor
              ),
            
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryColor),
            SizedBox(height: 16),
            Text('Loading dashboard data...', style: TextStyle(color: _textSecondaryColor)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttendanceCard({
    required String title, 
    required String value, 
    required IconData icon, 
    required Color color, 
    String? badgeText,
    bool isLoading = false,
  }) => Container(
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.15 : 0.05), blurRadius: 15, offset: Offset(0, 5))],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Center(
                  child: isLoading 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: 22),
                ),
              ),
              if (badgeText != null && !isLoading)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(badgeText, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
          SizedBox(height: 16),
          if (isLoading)
            Container(
              height: 24,
              width: 80,
              child: LinearProgressIndicator(
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textColor)),
          SizedBox(height: 4),
          Text(title, style: TextStyle(color: _textSecondaryColor, fontSize: 14)),
        ],
      ),
    ),
  );

  Widget _buildActivityItem({required String title, required String subtitle, required IconData icon, required Color iconColor}) => Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(12)
    ),
    child: Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Icon(icon, color: iconColor, size: 20)),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: _textColor, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: _textSecondaryColor, fontSize: 12)),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: _textSecondaryColor),
      ],
    ),
  );
  
  Widget _buildSideMenuBackdrop() => GestureDetector(
    onTap: () {
      if (_showProfileMenu) _toggleProfileMenu();
      _toggleSideMenu();
    },
    child: Container(color: Colors.black.withOpacity(0.5)),
  );
  
  Widget _buildSideMenu() => AnimatedPositioned(
    duration: Duration(milliseconds: 300),
    left: _showSideMenu ? 0 : -280,
    top: 0, bottom: 0,
    child: Container(
      width: 280,
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)]
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 20),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primaryColor, _blueColor]),
                    shape: BoxShape.circle
                  ),
                  child: Center(
                    child: Text(
                      _userName.split(' ').map((n) => n[0]).join(),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userName, style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 4),
                      Text(_employeeId, style: TextStyle(color: _textSecondaryColor, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: _textColor),
                  onPressed: _toggleSideMenu,
                ),
              ],
            ),
          ),
          Divider(color: _textSecondaryColor.withOpacity(0.3), height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    if (_hasPermission('checkin'))
                      _buildMenuItem(icon: Icons.login_rounded, title: 'Employee Check-in', onTap: () => _navigateTo('Employee Check-in')),
                    if (_hasPermission('attendance'))
                      _buildMenuItem(icon: Icons.calendar_today_rounded, title: 'Attendance', onTap: () => _navigateTo('Attendance')),
                    if (_hasPermission('leave'))
                      _buildMenuItem(icon: Icons.beach_access_rounded, title: 'Leave Request', onTap: () => _navigateTo('Leave Request')),
                    if (_hasPermission('claim'))
                      _buildMenuItem(icon: Icons.receipt_long_rounded, title: 'Claim Request', onTap: () => _navigateTo('Claim Request')),
                    if (_hasPermission('on_duty'))
                      _buildMenuItem(icon: Icons.work_outline_rounded, title: 'On Duty', onTap: () => _navigateTo('On Duty')),
                    if (_hasPermission('ot_req'))
                      _buildMenuItem(icon: Icons.timelapse_rounded, title: 'OT Request', onTap: () => _navigateTo('OT Request')),
                    if (_hasPermission('project_task'))
                      _buildMenuItem(icon: Icons.task_rounded, title: 'Project Task', onTap: () => _navigateTo('Project Task')),
                    if (_hasPermission('operator'))
                      _buildMenuItem(icon: Icons.warning_amber_rounded, title: 'Incident', onTap: () => _navigateTo('Incident')),
                    if (_hasPermission('site_in'))
                      _buildMenuItem(icon: Icons.confirmation_number_rounded, title: 'Site Ticket', onTap: () => _navigateTo('Site Ticket')),
                    
                    Divider(color: _textSecondaryColor.withOpacity(0.3), height: 20, indent: 20, endIndent: 20),
                    _buildMenuItem(icon: Icons.logout_rounded, title: 'Logout', color: _redColor, onTap: _showLogoutConfirmation),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    ),
  );
  
  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap, Color? color}) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (color ?? _primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Icon(icon, color: color ?? _primaryColor, size: 20)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(color: _textColor, fontSize: 15, fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_right_rounded, color: _textSecondaryColor, size: 20),
          ],
        ),
      ),
    ),
  );
  
  Widget _buildProfileMenu() => Positioned(
    top: MediaQuery.of(context).padding.top + 70,
    right: 20,
    child: Material(
      color: Colors.transparent,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 5))],
          border: Border.all(color: Colors.white.withOpacity(_isDarkMode ? 0.1 : 0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _showProfile,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Icon(Icons.person_rounded, color: _primaryColor, size: 20)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profile', style: TextStyle(color: _textColor, fontWeight: FontWeight.w500)),
                          SizedBox(height: 2),
                          Text('View your profile', style: TextStyle(color: _textSecondaryColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: Colors.white.withOpacity(_isDarkMode ? 0.1 : 0.2)),
            InkWell(
              onTap: () {
                _toggleProfileMenu();
                _navigateTo('Settings');
              },
              child: Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: _blueColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Icon(Icons.settings_rounded, color: _blueColor, size: 20)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Settings', style: TextStyle(color: _textColor, fontWeight: FontWeight.w500)),
                          SizedBox(height: 2),
                          Text('App settings', style: TextStyle(color: _textSecondaryColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  
  Widget _buildProfileMenuBackdrop() => GestureDetector(
    onTap: _toggleProfileMenu,
    child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
  );
  
  void _showProfile() {
    setState(() => _showProfileMenu = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Profile', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _primaryColor,
                child: Text(
                  _userName.split(' ').map((n) => n[0]).join(),
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                ),
              ),
              SizedBox(height: 16),
              Text(_userName, style: TextStyle(color: _textColor, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(_employeeId, style: TextStyle(color: _textSecondaryColor, fontSize: 14)),
              SizedBox(height: 16),
              Divider(color: _textSecondaryColor.withOpacity(0.3)),
              SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Email:', style: TextStyle(color: _textColor)), Text(_userEmail, style: TextStyle(color: _textSecondaryColor))]),
              SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Department:', style: TextStyle(color: _textColor)), Text(_joiningDetails?.department ?? 'Not available', style: TextStyle(color: _textSecondaryColor))]),
              SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Join Date:', style: TextStyle(color: _textColor)), Text(_joiningDetails?.dateOfJoining ?? 'Not available', style: TextStyle(color: _textSecondaryColor))]),
              SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Days:', style: TextStyle(color: _textColor)), Text(_joiningDetails?.totalDays.toString() ?? '0', style: TextStyle(color: _textSecondaryColor))]),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: _primaryColor)))],
      ),
    );
  }
}

// Background painter for animated background
class _BackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDarkMode;
  final Color primaryColor;
  
  _BackgroundPainter({
    required this.animationValue,
    required this.isDarkMode,
    required this.primaryColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode ? Color(0xFF121212) : Color(0xFFF5F7FA);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw animated gradient circles
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    for (int i = 0; i < 3; i++) {
      final radius = (100 + i * 150) * (animationValue.clamp(0.0, 1.0));
      final alpha = (1.0 - i * 0.3) * (1 - animationValue.clamp(0.0, 1.0)) * 0.1;
      
      final gradientPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withOpacity(alpha),
            Colors.transparent,
          ],
          stops: [0.0, 0.8],
        ).createShader(
          Rect.fromCircle(
            center: Offset(centerX, centerY),
            radius: radius,
          ),
        );
      
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        gradientPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
           isDarkMode != oldDelegate.isDarkMode;
  }
}