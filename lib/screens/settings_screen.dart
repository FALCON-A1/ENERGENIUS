import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../utils/conversion_utilities.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _realTimeSync = true;
  String _energyUnit = 'kWh';
  String _currency = 'EGP';
  bool _notificationsEnabled = true;
  String _exportFrequency = 'weekly';
  String _language = 'en';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _realTimeSync = prefs.getBool('realTimeSync') ?? true;
        _energyUnit = prefs.getString('energyUnit') ?? 'kWh';
        _currency = prefs.getString('currency') ?? 'EGP';
        _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
        _exportFrequency = prefs.getString('exportFrequency') ?? 'weekly';
        _language = prefs.getString('language') ?? 'en';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading settings: $e", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('realTimeSync', _realTimeSync);
      await prefs.setString('energyUnit', _energyUnit);
      await prefs.setString('currency', _currency);
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setString('exportFrequency', _exportFrequency);
      await prefs.setString('language', _language);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Settings saved!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving settings: $e", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error logging out: $e", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      await FirebaseAuth.instance.currentUser!.delete();
      await _clearCache();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting account: $e", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cache cleared!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 1),
        ),
      );
      _loadSettings(); // Reload default settings
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error clearing cache: $e", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkTheme = themeProvider.isDarkTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkTheme
                ? [Colors.blueAccent.withAlpha(77), Colors.black]
                : [Colors.white, Colors.grey[300]!],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Settings
                Text(
                  "Theme",
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SwitchListTile(
                  title: Text(
                    "Dark Theme",
                    style: GoogleFonts.poppins(
                      color: isDarkTheme ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  value: isDarkTheme,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                    _saveSettings();
                  },
                  activeColor: Colors.blueAccent,
                ),
                const SizedBox(height: 20),

                // Data Sync Settings
                Text(
                  "Data Sync",
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SwitchListTile(
                  title: Text(
                    "Real-Time Sync",
                    style: GoogleFonts.poppins(
                      color: isDarkTheme ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "Enable to get live updates on energy consumption.",
                    style: GoogleFonts.poppins(
                      color: isDarkTheme ? Colors.white54 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  value: _realTimeSync,
                  onChanged: (value) {
                    setState(() {
                      _realTimeSync = value;
                      _saveSettings();
                    });
                  },
                  activeColor: Colors.blueAccent,
                ),
                const SizedBox(height: 20),

                // Energy Unit Settings
                Text(
                  "Energy Unit",
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Card(
                  color: isDarkTheme ? Colors.white.withAlpha(26) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select your preferred energy unit",
                          style: GoogleFonts.poppins(
                            color: isDarkTheme ? Colors.white70 : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _energyUnit,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDarkTheme ? Colors.white.withAlpha(26) : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: isDarkTheme ? Colors.grey[900] : Colors.white,
                          style: GoogleFonts.poppins(
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                          items: ConversionUtilities.energyConversions.keys
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _energyUnit = newValue!;
                              _saveSettings();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Energy unit updated to $_energyUnit", style: const TextStyle(color: Colors.white)),
                                backgroundColor: Colors.blueAccent,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Changes will apply throughout the app",
                          style: GoogleFonts.poppins(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // Currency Settings
                Text(
                  "Currency",
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Card(
                  color: isDarkTheme ? Colors.white.withAlpha(26) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select your preferred currency",
                          style: GoogleFonts.poppins(
                            color: isDarkTheme ? Colors.white70 : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDarkTheme ? Colors.white.withAlpha(26) : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: isDarkTheme ? Colors.grey[900] : Colors.white,
                          style: GoogleFonts.poppins(
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                          items: ConversionUtilities.currencyRates.keys
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text("$value (${ConversionUtilities.currencySymbols[value] ?? value})"),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _currency = newValue!;
                              _saveSettings();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Currency updated to $_currency", style: const TextStyle(color: Colors.white)),
                                backgroundColor: Colors.blueAccent,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Changes will apply throughout the app",
                          style: GoogleFonts.poppins(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // Notification Settings
                Text(
                  "Notifications",
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SwitchListTile(
                  title: Text(
                    "Enable Notifications",
                    style: GoogleFonts.poppins(
                      color: isDarkTheme ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "Get alerts for high consumption or daily summaries.",
                    style: GoogleFonts.poppins(
                      color: isDarkTheme ? Colors.white54 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                      _saveSettings();
                    });
                  },
                  activeColor: Colors.blueAccent,
                ),
                const SizedBox(height: 20),

                // Data Export Frequency
                Text(
                  "Data Export",
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: _exportFrequency,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkTheme ? Colors.white.withAlpha(26) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: isDarkTheme ? Colors.grey[900] : Colors.white,
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  items: <String>['daily', 'weekly', 'monthly']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _exportFrequency = newValue!;
                      _saveSettings();
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Language Selection
                Text(
                  "Language",
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkTheme ? Colors.white.withAlpha(26) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: isDarkTheme ? Colors.grey[900] : Colors.white,
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  items: <String>['en', 'ar', 'fr']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _language = newValue!;
                      _saveSettings();
                    });
                    // Add localization logic here if implemented
                  },
                ),
                const SizedBox(height: 20),

                // Account Management
                Text(
                  "Account",
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: Text(
                    "View Profile",
                    style: GoogleFonts.poppins(
                      color: Colors.blueAccent,
                    ),
                  ),
                  trailing: const Icon(Icons.person, color: Colors.blueAccent),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: Text(
                    "Logout",
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                    ),
                  ),
                  trailing: const Icon(Icons.logout, color: Colors.redAccent),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDarkTheme ? Colors.grey[900] : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        title: Text(
                          "Logout",
                          style: GoogleFonts.poppins(
                            color: isDarkTheme ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          "Are you sure you want to logout?",
                          style: GoogleFonts.poppins(
                            color: isDarkTheme ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(color: Colors.blueAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _logout();
                            },
                            child: Text(
                              "Logout",
                              style: GoogleFonts.poppins(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListTile(
                  title: Text(
                    "Delete Account",
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                    ),
                  ),
                  trailing: const Icon(Icons.delete, color: Colors.redAccent),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDarkTheme ? Colors.grey[900] : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        title: Text(
                          "Delete Account",
                          style: GoogleFonts.poppins(
                            color: isDarkTheme ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          "This will permanently delete your account and data. Are you sure?",
                          style: GoogleFonts.poppins(
                            color: isDarkTheme ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(color: Colors.blueAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteAccount();
                            },
                            child: Text(
                              "Delete",
                              style: GoogleFonts.poppins(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Clear Cache/Data
                Text(
                  "Maintenance",
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ListTile(
                  title: Text(
                    "Clear Cache",
                    style: GoogleFonts.poppins(
                      color: isDarkTheme ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  trailing: const Icon(Icons.delete_sweep, color: Colors.blueAccent),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDarkTheme ? Colors.grey[900] : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        title: Text(
                          "Clear Cache",
                          style: GoogleFonts.poppins(
                            color: isDarkTheme ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          "Are you sure you want to clear all cached data?",
                          style: GoogleFonts.poppins(
                            color: isDarkTheme ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(color: Colors.blueAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _clearCache();
                            },
                            child: Text(
                              "Clear",
                              style: GoogleFonts.poppins(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Add bottom padding for navigation bar
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}