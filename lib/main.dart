// main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;
  
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      });
    } catch (e) {
      print("Error loading theme: $e");
    }
  }

  Future<void> _toggleTheme(bool newValue) async {
    try {
      setState(() {
        _isDarkMode = newValue;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', newValue);
    } catch (e) {
      print("Error saving theme: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WTT App',
      theme: ThemeData.light().copyWith(
        primaryColor: Color(0xFF2196F3),
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF263238),
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF64B5F6),
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        cardColor: Color(0xFF1E1E1E), dialogTheme: DialogThemeData(backgroundColor: Color(0xFF1E1E1E)),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(
          initialDarkMode: _isDarkMode,
          onThemeChanged: _toggleTheme,
        ),
        '/home': (context) => HomeScreen(
          initialDarkMode: _isDarkMode,
          onThemeChanged: _toggleTheme,
        ),
      },
    );
  }
}