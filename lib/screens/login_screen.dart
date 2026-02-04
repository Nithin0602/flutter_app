import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class LoginScreen extends StatefulWidget {
  final bool initialDarkMode;
  final Function(bool) onThemeChanged;
  const LoginScreen({super.key, 
    required this.initialDarkMode,
    required this.onThemeChanged,
  });
  
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true, _rememberMe = false, _isLoading = false, _isDarkMode = true;
  late AnimationController _animationController;
  late Animation<double> _logoFade, _logoScale, _formFade, _formSlide;
  
  // API Configuration
  final String _apiUrl = 'http://10.15.5.171/api/method/wtt_module.customization.custom.test.user_login';
  
  // User data storage keys
  final String _userNameKey = 'user_name';
  final String _employeeIdKey = 'employee_id';
  final String _fullNameKey = 'full_name';
  final String _emailKey = 'user_email';
  final String _tokenKey = 'auth_token';
  final String _permissionsKey = 'user_permissions';
  final String _passwordKey = 'user_password';


  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Interval(0.0, 0.5, curve: Curves.easeOutCubic))
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Interval(0.0, 0.5, curve: Curves.elasticOut))
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Interval(0.5, 1.0, curve: Curves.easeOutCubic))
    );

    _formSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Interval(0.5, 1.0, curve: Curves.easeOutBack))
    );

    Future.delayed(Duration(seconds: 13), () => _animationController.forward());
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedUsername = prefs.getString(_userNameKey);
      final savedPassword = prefs.getString(_passwordKey);
      final savedRememberMe = prefs.getBool('remember_me') ?? false;

      if (savedRememberMe) {
        setState(() {
          _rememberMe = true;
          _usernameController.text = savedUsername ?? '';
          _passwordController.text = savedPassword ?? '';
        });
      }
    } catch (e) {
      print("Error loading saved credentials: $e");
    }
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _primaryColor => _isDarkMode ? Color(0xFF4DB6AC) : Color(0xFF4DB6AC);
  Color get _secondaryColor => _isDarkMode ? Color(0xFF4DB6AC) : Color(0xFF4DB6AC);
  Color get _backgroundColor => _isDarkMode ? Color(0xFF4DB6AC) : Color(0xFF4DB6AC);
  Color get _surfaceColor => _isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFFFFFFF);
  Color get _textColor => _isDarkMode ? Color(0xFFE0E0E0) : Color(0xFF263238);
  Color get _hintColor => _isDarkMode ? Color(0xFF9E9E9E) : Color(0xFF78909C);

  Future<void> _toggleDarkMode() async {
    final newMode = !_isDarkMode;
    setState(() => _isDarkMode = newMode);
    widget.onThemeChanged(newMode);
  }

  // In login_screen.dart - Update the _login() method
Future<void> _login() async {
  if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
    _showSnackBar('Please fill in all fields');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (responseData['message']?['success_key'] == 1) {
        // Save user data to SharedPreferences
        await _saveUserData(responseData['message']);
        
        // Save credentials if remember me is checked
        await _saveCredentials();
        
        // Navigate to welcome screen first
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: responseData['message']['full_name'] ?? _usernameController.text.trim(),
        );
      } else {
        _showSnackBar(responseData['message']?['message'] ?? 'Login failed');
      }
    } else {
      _showSnackBar('Server error: ${response.statusCode}');
    }
  } catch (e) {
    setState(() => _isLoading = false);
    _showSnackBar('Network error: ${e.toString()}');
  }
}

// In login_screen.dart, update the _saveUserData method:

Future<void> _saveUserData(Map<String, dynamic> userData) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Save raw token string directly
    final rawToken = userData['token']?.toString() ?? '';
    await prefs.setString('token', rawToken);
    
    // Save other data
    await prefs.setString('employee_id', userData['employee'] ?? '');
    await prefs.setString('full_name', userData['full_name'] ?? '');
    await prefs.setString('user_email', userData['email'] ?? '');
    await prefs.setString('user_permissions', json.encode(userData['permissions'] ?? {}));
    
    print('Saved raw token: $rawToken');
  } catch (e) {
    print("Error saving user data: $e");
  }
}

// Remove _saveCredentials method or update it:
Future<void> _saveCredentials() async {
  final prefs = await SharedPreferences.getInstance();

  if (_rememberMe) {
    await prefs.setString('username', _usernameController.text.trim());
    await prefs.setBool('remember_me', true);
  } else {
    await prefs.remove('username');
    await prefs.setBool('remember_me', false);
  }
}

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _forgotPassword() => showDialog(
    context: context,
    builder: (context) => _buildForgotPasswordDialog(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: IconButton(
                        key: ValueKey(_isDarkMode),
                        onPressed: _toggleDarkMode,
                        icon: Icon(
                          _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: _textColor.withOpacity(0.7),
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                  _buildAnimatedLogo(),
                  SizedBox(height: 50),
                  _buildAnimatedLoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() => AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) => Opacity(
      opacity: _logoFade.value,
      child: Transform.scale(
        scale: _logoScale.value,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                _primaryColor.withOpacity(0.9),
                _secondaryColor.withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 4,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 158,
              height: 158,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _surfaceColor,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.8,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, color: Colors.white, size: 40),
                            SizedBox(height: 8),
                            Text('SECURE LOGIN', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildAnimatedLoginForm() => AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) => Opacity(
      opacity: _formFade.value,
      child: Transform.translate(
        offset: Offset(0, _formSlide.value),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1), blurRadius: 40, offset: Offset(0, 20)),
              BoxShadow(color: Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.3), blurRadius: 2, offset: Offset(-2, -2)),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _textColor, letterSpacing: 0.5)),
                      SizedBox(height: 4),
                      Text('Sign in to your account', style: TextStyle(color: _hintColor, fontSize: 14)),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_primaryColor.withOpacity(0.1), _secondaryColor.withOpacity(0.05)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('v1.0.0', style: TextStyle(color: _primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              SizedBox(height: 32),
              _buildGlossyTextField(controller: _usernameController, label: 'Username', prefixIcon: Icons.person_outline_rounded),
              SizedBox(height: 24),
              _buildGlossyPasswordField(),
              SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: _rememberMe ? _primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _rememberMe ? _primaryColor : _hintColor, width: 2),
                            ),
                            child: _rememberMe ? Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                          ),
                          SizedBox(width: 12),
                          Text('Remember me', style: TextStyle(color: _textColor)),
                        ],
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _forgotPassword,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [_primaryColor.withOpacity(0.1), _secondaryColor.withOpacity(0.05)]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1.5),
                        ),
                        child: Text('Forgot Password?', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildGlossyTextField({required TextEditingController controller, required String label, required IconData prefixIcon}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: _textColor.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 14)),
      SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_surfaceColor.withOpacity(0.95), _surfaceColor.withOpacity(0.85)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05), blurRadius: 15, offset: Offset(5, 5)),
            BoxShadow(color: Colors.white.withOpacity(_isDarkMode ? 0.02 : 0.3), blurRadius: 0, offset: Offset(-2, -2)),
          ],
        ),
        child: TextField(
          controller: controller,
          style: TextStyle(color: _textColor, fontSize: 16),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            prefixIcon: Container(margin: EdgeInsets.only(left: 4, right: 12), child: Icon(prefixIcon, color: _primaryColor, size: 22)),
            border: InputBorder.none,
          ),
        ),
      ),
    ],
  );

  Widget _buildGlossyPasswordField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Password', style: TextStyle(color: _textColor.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 14)),
      SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_surfaceColor.withOpacity(0.95), _surfaceColor.withOpacity(0.85)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05), blurRadius: 15, offset: Offset(5, 5)),
            BoxShadow(color: Colors.white.withOpacity(_isDarkMode ? 0.02 : 0.3), blurRadius: 0, offset: Offset(-2, -2)),
          ],
        ),
        child: TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: _textColor, fontSize: 16),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            prefixIcon: Container(margin: EdgeInsets.only(left: 4, right: 12), child: Icon(Icons.lock_outline_rounded, color: _primaryColor, size: 22)),
            suffixIcon: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: _primaryColor.withOpacity(0.7), size: 22,
                      key: ValueKey(_obscurePassword),
                    ),
                  ),
                ),
              ),
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    ],
  );

  Widget _buildLoginButton() => Container(
    width: double.infinity, height: 58,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 10))],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isLoading ? null : _login,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: _isLoading ? 0 : 1,
              duration: Duration(milliseconds: 300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Login', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                ],
              ),
            ),
            if (_isLoading) SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
          ],
        ),
      ),
    ),
  );

  Widget _buildForgotPasswordDialog() => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: EdgeInsets.all(24),
    child: Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.4 : 0.2), blurRadius: 50, offset: Offset(0, 30))],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reset Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _textColor)),
              IconButton(icon: Icon(Icons.close_rounded, color: _hintColor, size: 28), onPressed: () => Navigator.pop(context)),
            ],
          ),
          SizedBox(height: 16),
          Text('Enter your email and we\'ll send you a secure link to reset your password.', style: TextStyle(color: _hintColor, fontSize: 15, height: 1.5)),
          SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_surfaceColor.withOpacity(0.95), _surfaceColor.withOpacity(0.85)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.15 : 0.05), blurRadius: 15, offset: Offset(5, 5))],
            ),
            child: TextField(
              style: TextStyle(color: _textColor),
              decoration: InputDecoration(
                hintText: 'Enter your email', hintStyle: TextStyle(color: _hintColor),
                prefixIcon: Container(margin: EdgeInsets.only(left: 4, right: 12), child: Icon(Icons.email_outlined, color: _primaryColor, size: 24)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          SizedBox(height: 30),
          Container(
            width: double.infinity, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Reset link sent to your email');
                },
                child: Center(
                  child: Text('Send Reset Link', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}