import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:energenius/screens/signup_screen.dart';
import 'package:energenius/screens/forgot_password_screen.dart';
import 'package:energenius/screens/main_screen.dart';
import '../widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../utils/page_transition.dart';
import '../widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
  }

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('email') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('password', _passwordController.text.trim());
      await prefs.setBool('rememberMe', _rememberMe);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _saveCredentials();
      if (!mounted) return;
      replaceWithFade(context, MainScreen());
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "Login Failed",
            style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            e.toString().contains('user-not-found') || e.toString().contains('wrong-password')
                ? "Invalid email or password. Please try again."
                : "An error occurred. Please try again later.",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: GoogleFonts.poppins(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkTheme = themeProvider.isDarkTheme;

    return Scaffold(
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkTheme
                ? [Colors.blueAccent.withAlpha(77), Colors.black]
                : [Colors.white, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Theme toggle button at the top right
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: ThemeToggleButton(
                            width: 80.0,
                            height: 24.0,
                            iconSize: 18.0,
                            animationDuration: Duration(milliseconds: 350),
                          ),
                        ),
                      ),
                      
                      // App Logo
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: isDarkTheme ? Colors.white.withAlpha(26) : Colors.blue.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.energy_savings_leaf,
                          size: 60,
                          color: isDarkTheme ? Colors.white : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Text(
                        "Login to Energenius",
                        style: GoogleFonts.poppins(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      Text(
                        "Welcome back! Please sign in to continue",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: isDarkTheme ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Email Field
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: isDarkTheme ? 10 : 0, sigmaY: isDarkTheme ? 10 : 0),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: CustomTextFormField(
                              controller: _emailController,
                              labelText: "Email",
                              prefixIcon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              isDarkTheme: isDarkTheme,
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Email is required";
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return "Enter a valid email";
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Password Field with Toggle
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: isDarkTheme ? 10 : 0, sigmaY: isDarkTheme ? 10 : 0),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: CustomTextFormField(
                              controller: _passwordController,
                              labelText: "Password",
                              prefixIcon: Icons.lock,
                              obscureText: _obscurePassword,
                              isDarkTheme: isDarkTheme,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Password is required";
                                if (value.length < 6) return "Password must be at least 6 characters";
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Remember & Forgot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Theme(
                                data: ThemeData(
                                  checkboxTheme: CheckboxThemeData(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  checkColor: Colors.white,
                                  activeColor: Colors.blueAccent,
                                ),
                              ),
                              Text(
                                "Remember Me",
                                style: GoogleFonts.poppins(
                                  color: isDarkTheme ? Colors.white70 : Colors.black.withAlpha(200),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => navigateWithFade(
                              context,
                              ForgotPasswordScreen(),
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Colors.blueAccent, Colors.purpleAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "LOGIN",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Sign Up Redirect
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              color: isDarkTheme ? Colors.white70 : Colors.black.withAlpha(200),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (!_isLoading) {
                                navigateWithFade(
                                  context,
                                  SignupScreen(),
                                );
                              }
                            },
                            child: Text(
                              "Sign Up",
                              style: GoogleFonts.poppins(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}