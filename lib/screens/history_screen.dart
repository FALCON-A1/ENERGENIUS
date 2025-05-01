import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../utils/conversion_utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  String _selectedPeriod = 'daily';
  DateTime? _startDate;
  DateTime? _endDate;
  String _energyUnit = 'kWh';

  // Map to store export data
  Map<String, double> _exportData = {};

  @override
  void initState() {
    super.initState();
    _loadInitialDates();
    _loadSettings();
  }
  
  // Load user preferences for energy unit
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _energyUnit = prefs.getString('energyUnit') ?? 'kWh';
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _loadInitialDates() {
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
  }

  // Format energy values with current unit
  String _formatEnergyValue(double valueInKWh) {
    try {
      double convertedValue = ConversionUtilities.convertEnergy(
        valueInKWh, 
        'kWh', 
        _energyUnit
      );
      return "${convertedValue.toStringAsFixed(2)} $_energyUnit";
    } catch (e) {
      return "$valueInKWh kWh";
    }
  }

  Stream<QuerySnapshot> _getHistoryStream() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('consumption_history')
        .orderBy('date', descending: true)
        .where('date', isGreaterThanOrEqualTo: _startDate?.toIso8601String().split('T')[0] ?? '')
        .where('date', isLessThanOrEqualTo: _endDate?.toIso8601String().split('T')[0] ?? '')
        .limit(30)
        .snapshots();
  }

  Future<void> _selectDateRange() async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Colors.blueAccent),
          ),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Date range updated: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blueAccent,
          ),
        );
      });
    }
  }

  Future<void> _exportHistory() async {
    try {
      // Prepare export data
      _exportData = {};
      String userId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('consumption_history')
          .where('date', isGreaterThanOrEqualTo: _startDate?.toIso8601String().split('T')[0] ?? '')
          .where('date', isLessThanOrEqualTo: _endDate?.toIso8601String().split('T')[0] ?? '')
          .get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double rawConsumption = data['total_consumption']?.toDouble() ?? 0.0;
        // Convert to selected unit for export
        double convertedConsumption = ConversionUtilities.convertEnergy(
          rawConsumption, 
          'kWh', 
          _energyUnit
        );
        _exportData[data['date'] ?? ''] = convertedConsumption;
      }

      final directory = await getApplicationDocumentsDirectory();
      final csv = "Date,Consumption ($_energyUnit)\n${_exportData.entries.map((e) => "${e.key},${e.value}").join("\n")}";
      final file = File('${directory.path}/consumption_history.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'Consumption History Export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e', style: const TextStyle(color: Colors.white)),
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
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkTheme 
                ? [Color.fromRGBO(68, 138, 255, 0.2), Colors.black]
                : [Colors.white, Colors.grey[300]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _getHistoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading history: ${snapshot.error}",
                      style: GoogleFonts.poppins(
                        color: isDarkTheme ? Colors.white70 : Colors.black87, 
                        fontSize: 18
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                List<FlSpot> chartData = [];
                List<String> dates = [];
                double totalConsumption = 0.0;
                int index = 0;

                final docs = snapshot.data?.docs ?? [];
                if (_selectedPeriod == 'daily') {
                  for (var doc in docs) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    double consumption = data['total_consumption']?.toDouble() ?? 0.0;
                    String dateStr = data['date'] ?? doc.id;
                    chartData.add(FlSpot(index.toDouble(), consumption));
                    dates.add(dateStr);
                    totalConsumption += consumption;
                    index++;
                  }
                  chartData = chartData.reversed.toList();
                  dates = dates.reversed.toList();
                } else if (_selectedPeriod == 'weekly') {
                  Map<String, double> weeklyData = {};
                  for (var doc in docs) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    DateTime date = DateTime.parse(data['date'] ?? doc.id);
                    String weekKey = "${date.year}-W${date.weekOfYear}";
                    weeklyData[weekKey] = (weeklyData[weekKey] ?? 0.0) + (data['total_consumption']?.toDouble() ?? 0.0);
                  }
                  var sortedWeeks = weeklyData.keys.toList()
                    ..sort((a, b) {
                      final aParts = a.split('-W');
                      final bParts = b.split('-W');
                      final aYear = int.parse(aParts[0]);
                      final bYear = int.parse(bParts[0]);
                      final aWeek = int.parse(aParts[1]);
                      final bWeek = int.parse(bParts[1]);
                      return aYear.compareTo(bYear) != 0 ? aYear.compareTo(bYear) : aWeek.compareTo(bWeek);
                    });
                  for (var week in sortedWeeks) {
                    double consumption = weeklyData[week]!;
                    chartData.add(FlSpot(index.toDouble(), consumption));
                    dates.add(week);
                    totalConsumption += consumption;
                    index++;
                  }
                } else if (_selectedPeriod == 'monthly') {
                  Map<String, double> monthlyData = {};
                  for (var doc in docs) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    DateTime date = DateTime.parse(data['date'] ?? doc.id);
                    String monthKey = DateFormat('yyyy-MM').format(date);
                    monthlyData[monthKey] = (monthlyData[monthKey] ?? 0.0) + (data['total_consumption']?.toDouble() ?? 0.0);
                  }
                  var sortedMonths = monthlyData.keys.toList()..sort();
                  for (var month in sortedMonths) {
                    double consumption = monthlyData[month]!;
                    chartData.add(FlSpot(index.toDouble(), consumption));
                    dates.add(month);
                    totalConsumption += consumption;
                    index++;
                  }
                }

                if (chartData.isEmpty || chartData.every((spot) => spot.y == 0)) {
                  chartData = [FlSpot(0, 0)];
                  dates = [_startDate?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0]];
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "History",
                      style: GoogleFonts.poppins(
                        color: isDarkTheme ? Colors.white : Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Semantics(
                          label: "Select time period",
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            dropdownColor: isDarkTheme ? Colors.grey[900] : Colors.grey[100],
                            style: GoogleFonts.poppins(color: isDarkTheme ? Colors.white : Colors.black),
                            underline: Container(
                              height: 2,
                              color: Colors.blueAccent,
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedPeriod = newValue!;
                              });
                            },
                            items: <String>['daily', 'weekly', 'monthly']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase(), 
                                  style: GoogleFonts.poppins(color: isDarkTheme ? Colors.white : Colors.black)
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "Total: ${_formatEnergyValue(totalConsumption)}",
                              style: GoogleFonts.poppins(
                                color: isDarkTheme ? Colors.white70 : Colors.black87, 
                                fontSize: 18
                              ),
                            ),
                            const SizedBox(width: 10),
                            Semantics(
                              label: "Select date range",
                              child: Tooltip(
                                message: "Select date range",
                                child: IconButton(
                                  icon: Icon(Icons.calendar_today, 
                                    color: Colors.blueAccent
                                  ),
                                  onPressed: _selectDateRange,
                                ),
                              ),
                            ),
                            Semantics(
                              label: "Export history",
                              child: Tooltip(
                                message: "Export history",
                                child: IconButton(
                                  icon: Icon(Icons.share, 
                                    color: Colors.blueAccent
                                  ),
                                  onPressed: _exportHistory,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isDarkTheme ? Colors.white.withAlpha(200) : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: chartData.every((spot) => spot.y == 0)
                            ? Center(
                                child: Text(
                                  "No history data available for the selected range.",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 40.0),
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      drawHorizontalLine: true,
                                      verticalInterval: 1,
                                      horizontalInterval: totalConsumption > 0 ? totalConsumption / 5 : 1,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: isDarkTheme ? Colors.white.withAlpha(51) : Colors.black.withAlpha(30),
                                          strokeWidth: 1,
                                        );
                                      },
                                      getDrawingVerticalLine: (value) {
                                        return FlLine(
                                          color: isDarkTheme ? Colors.white.withAlpha(51) : Colors.black.withAlpha(30),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          interval: (chartData.length > 10) ? (chartData.length / 5).floorToDouble() : 1,
                                          getTitlesWidget: (value, meta) {
                                            int index = value.toInt();
                                            if (index >= 0 && index < dates.length) {
                                              String label;
                                              if (_selectedPeriod == 'daily') {
                                                label = DateFormat('dd/MM').format(DateTime.parse(dates[index]));
                                              } else if (_selectedPeriod == 'weekly') {
                                                label = 'W${dates[index].split('-W')[1]}';
                                              } else {
                                                DateTime monthDate = DateFormat('yyyy-MM').parse(dates[index]);
                                                label = DateFormat('MMM').format(monthDate);
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Transform.rotate(
                                                  angle: -45 * 0.0174533, // Rotate -45 degrees
                                                  child: Text(
                                                    label,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white70,
                                                      fontSize: 10,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          interval: totalConsumption > 0 ? totalConsumption / 5 : 1,
                                          getTitlesWidget: (value, meta) {
                                            // Convert value to the selected energy unit for display
                                            double convertedValue = ConversionUtilities.convertEnergy(
                                              value, 
                                              'kWh', 
                                              _energyUnit
                                            );
                                            return Text(
                                              convertedValue.toStringAsFixed(1),
                                              style: GoogleFonts.poppins(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: true, border: Border.all(color: Colors.blueAccent)),
                                    minX: 0,
                                    maxX: chartData.length.toDouble() - 1,
                                    minY: 0,
                                    maxY: chartData.isNotEmpty && totalConsumption > 0
                                        ? chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.1
                                        : 1.0,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: chartData,
                                        isCurved: true,
                                        gradient: const LinearGradient(
                                          colors: [Colors.blueAccent, Colors.cyanAccent],
                                        ),
                                        barWidth: 3,
                                        dotData: const FlDotData(show: true),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blueAccent.withAlpha(76),
                                              Colors.cyanAccent.withAlpha(25),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipBorder: const BorderSide(color: Colors.blueAccent),
                                        tooltipPadding: const EdgeInsets.all(8),
                                        tooltipRoundedRadius: 8,
                                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            // Convert the y-value to the selected energy unit for tooltip
                                            double convertedValue = ConversionUtilities.convertEnergy(
                                              spot.y, 
                                              'kWh', 
                                              _energyUnit
                                            );
                                            return LineTooltipItem(
                                              '${convertedValue.toStringAsFixed(2)} $_energyUnit\n${dates[spot.x.toInt()]}',
                                              const TextStyle(color: Colors.white, fontSize: 12),
                                            );
                                          }).toList();
                                        },
                                      ),
                                      handleBuiltInTouches: true,
                                      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                                        return spotIndexes.map((index) {
                                          return TouchedSpotIndicatorData(
                                            FlLine(
                                              color: Colors.blueAccent,
                                              strokeWidth: 2,
                                            ),
                                            FlDotData(show: true),
                                          );
                                        }).toList();
                                      },
                                    ),
                                    clipData: const FlClipData.all(),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to calculate week of year
extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysSinceFirstDay = difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }
}