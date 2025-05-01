import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import 'package:energenius/screens/login_screen.dart';
import '../utils/page_transition.dart';
import '../widgets/theme_toggle_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  
  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _selectedCountry;
  final List<String> _countries = ["Egypt", "USA", "UK", "Canada", "Germany", "France", "India"];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _animationController.forward();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match!", style: TextStyle(color: Colors.white)), 
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'dob': _dobController.text.trim(),
        'country': _selectedCountry,
      });

      if (!mounted) return;
      replaceWithFade(context, LoginScreen());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: TextStyle(color: Colors.white)), 
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkTheme = themeProvider.isDarkTheme;
    
    return Scaffold(
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
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
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            size: 24,
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        ThemeToggleButton(
                          width: 80.0,
                          height: 24.0,
                          iconSize: 18.0,
                          animationDuration: Duration(milliseconds: 350),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Sign Up",
                      style: GoogleFonts.poppins(
                        color: isDarkTheme ? Colors.white : Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: isDarkTheme ? 10 : 0, sigmaY: isDarkTheme ? 10 : 0),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: CustomTextFormField(
                                  controller: _firstNameController,
                                  labelText: "First Name",
                                  prefixIcon: Icons.person,
                                  isDarkTheme: isDarkTheme,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "First name is required";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: isDarkTheme ? 10 : 0, sigmaY: isDarkTheme ? 10 : 0),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: CustomTextFormField(
                                  controller: _lastNameController,
                                  labelText: "Last Name",
                                  prefixIcon: Icons.person,
                                  isDarkTheme: isDarkTheme,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Last name is required";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
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
                            isDarkTheme: isDarkTheme,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Email is required";
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return "Enter a valid email";
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: isDarkTheme ? 10 : 0, sigmaY: isDarkTheme ? 10 : 0),
                        child: CustomTextFormField(
                          controller: _passwordController,
                          labelText: "Password",
                          prefixIcon: Icons.lock,
                          isDarkTheme: isDarkTheme,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Password is required";
                            }
                            if (value.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: isDarkTheme ? 10 : 0, sigmaY: isDarkTheme ? 10 : 0),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: CustomTextFormField(
                            controller: _confirmPasswordController,
                            labelText: "Confirm Password",
                            prefixIcon: Icons.lock,
                            isDarkTheme: isDarkTheme,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Confirm your password";
                              }
                              if (value != _passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: isDarkTheme ? 10 : 0, sigmaY: isDarkTheme ? 10 : 0),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: CustomTextField(
                            controller: _dobController,
                            labelText: "Date of Birth",
                            prefixIcon: Icons.cake,
                            isDarkTheme: isDarkTheme,
                            isReadOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(primary: Colors.blue),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _dobController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: isDarkTheme ? 10 : 0, sigmaY: isDarkTheme ? 10 : 0),
                        child: CustomDropdown<String>(
                          labelText: "Country",
                          prefixIcon: Icons.public,
                          value: _selectedCountry ?? _countries.first,
                          items: _countries,
                          isDarkTheme: isDarkTheme,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCountry = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signup,
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
                            borderRadius: BorderRadius.circular(_isLoading ? 25 : 10),
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
                                    "SIGN UP",
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
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: GoogleFonts.poppins(color: isDarkTheme ? Colors.white70 : Colors.black.withAlpha(200)),
                        ),
                        TextButton(
                          onPressed: () => replaceWithFade(context, LoginScreen()),
                          child: Text(
                            "Login",
                            style: GoogleFonts.poppins(color: Colors.blueAccent),
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
    );
  }
}