// lib/pages/dashboard/widgets/revenue_trends_by_locations.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/browser_client.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/components/responsive.dart';

class RevenueTrendsByLocations extends StatefulWidget {
  const RevenueTrendsByLocations({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RevenueTrendsByLocationsState createState() =>
      _RevenueTrendsByLocationsState();
}

class _RevenueTrendsByLocationsState extends State<RevenueTrendsByLocations> {
  final AuthService authService = AuthService();
  String selectedTimeFilter = '7 Hari';
  List<BarChartGroupData> barGroups = [];
  List<String> dateLabels = [];
  bool isLoading = true;
  double maxY = 0;
  List<String> locationNames = [];
  Map<String, Color> locationColorMap = {};
  Map<String, bool> visibleLocations = {};
  String? highlightedLocation;

  // Updated color palette to match TroubleTransactions
  final List<Color> locationColors = [
    Colors.blue.shade300,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.red.shade300,
    Colors.teal.shade300,
    Colors.pink.shade300,
    Colors.indigo.shade300,
    Colors.yellow.shade700,
    Colors.cyan.shade300,
    Colors.lime.shade300,
    Colors.amber.shade300,
    Colors.brown.shade300,
  ];

  @override
  void initState() {
    super.initState();
    fetchRevenueData();
  }

  Future<void> fetchRevenueData() async {
    setState(() {
      isLoading = true;
    });

    final sessionData = await authService.getSessionData();
    if (sessionData == null) {
      throw Exception('No session data available');
    }

    final client = BrowserClient()..withCredentials = true;
    String baseUrl = 'http://127.0.0.1:8000/api/revenuebylocations/';
    String endpoint;

    if (selectedTimeFilter == '7 Hari') {
      endpoint = 'filterbydays';
    } else if (selectedTimeFilter == '6 Bulan') {
      endpoint = 'filterbymonths';
    } else {
      endpoint = 'filterbyyears';
    }

    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: {
        'session_data': jsonEncode(sessionData),
      });

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        processData(jsonData);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching data: $error');
      }
      setState(() {
        barGroups = [];
        dateLabels = [];
        isLoading = false;
      });
    } finally {
      client.close();
    }
  }

  void processData(Map<String, dynamic> jsonData) {
    List<BarChartGroupData> tempBarGroups = [];
    List<String> tempDateLabels = [];
    Set<String> tempLocationNames = {};
    Map<String, Color> tempLocationColorMap = {};
    maxY = 0;

    jsonData.forEach((date, locations) {
      tempDateLabels.add(formatDate(date));
      List<BarChartRodData> rods = [];

      for (var location in locations) {
        double total = double.parse(location['total'].toString());
        String locationName = location['nama_lokasi'];
        tempLocationNames.add(locationName);

        if (!tempLocationColorMap.containsKey(locationName)) {
          tempLocationColorMap[locationName] = locationColors[
              tempLocationColorMap.length % locationColors.length];
        }

        if (visibleLocations[locationName] ?? true) {
          rods.add(BarChartRodData(
            toY: total,
            color: tempLocationColorMap[locationName],
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ));
          maxY = [maxY, total].reduce((a, b) => a > b ? a : b);
        }
      }

      tempBarGroups.add(BarChartGroupData(
        x: tempDateLabels.length - 1,
        barRods: rods,
      ));
    });

    setState(() {
      barGroups = tempBarGroups;
      dateLabels = tempDateLabels;
      locationNames = tempLocationNames.toList();
      locationColorMap = tempLocationColorMap;
      isLoading = false;
      adjustMaxY();

      if (visibleLocations.isEmpty) {
        for (var location in locationNames) {
          visibleLocations[location] = true;
        }
      }
    });
  }

  void adjustMaxY() {
    if (selectedTimeFilter == '6 Tahun') {
      maxY = (maxY / 1000000000).ceil() * 1000000000;
    } else if (selectedTimeFilter == '6 Bulan') {
      maxY = (maxY / 100000000).ceil() * 100000000;
    } else {
      maxY = (maxY / 10000000).ceil() * 10000000;
    }
    maxY = maxY == 0 ? 1 : maxY;
  }

  String formatDate(String dateString) {
    if (selectedTimeFilter == '7 Hari') {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM').format(date);
    } else if (selectedTimeFilter == '6 Bulan') {
      return _formatMonthYear(dateString);
    } else {
      return dateString;
    }
  }

  String _formatMonthYear(String dateString) {
    try {
      final date = DateTime.parse('$dateString-01');
      return DateFormat('MMM yyyy').format(date);
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting month/year: $e');
      }
      return dateString;
    }
  }

  String formatNumber(double number) {
    return NumberFormat('#,##0', 'en_US').format(number);
  }

  Widget getTitles(double value, TitleMeta meta) {
    int index = value.toInt();
    if (index < dateLabels.length) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(dateLabels[index],
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
      );
    }
    return const Text('');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: Responsive.getPadding(
        context,
        mobile: const EdgeInsets.symmetric(vertical: 8.0),
        tablet: const EdgeInsets.symmetric(vertical: 12.0),
        desktop: const EdgeInsets.symmetric(vertical: 16.0),
      ),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: Responsive.getPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Trend Pendapatan Tiap Lokasi',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: const Color(0xFF757575),
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 12,
                          tablet: 16,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildFilterButton(context),
                ],
              ),
              const SizedBox(height: 24.0),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (barGroups.isEmpty)
                const Center(child: Text('No data available'))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: Responsive.isDesktop(context)
                        ? Responsive.getWidth(context, percentage: 95)
                        : Responsive.getWidth(context, percentage: 200),
                    height: Responsive.isDesktop(context)
                        ? Responsive.getHeight(context, percentage: 50)
                        : Responsive.getHeight(context, percentage: 40),
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: Responsive.getPadding(context).right,
                        top: Responsive.isDesktop(context) ? 40.0 : 20.0,
                      ),
                      child: BarChart(
                        BarChartData(
                          maxY: maxY,
                          barGroups: barGroups,
                          alignment: Responsive.isDesktop(context)
                              ? BarChartAlignment.spaceAround
                              : BarChartAlignment.spaceBetween,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: getTitles,
                                reservedSize:
                                    Responsive.isMobile(context) ? 40 : 50,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize:
                                    Responsive.isMobile(context) ? 80 : 120,
                                interval: maxY > 0 ? maxY / 5 : 1,
                                getTitlesWidget: (value, meta) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      formatNumber(value),
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: Responsive.getFontSize(
                                          context,
                                          mobile: 8,
                                          tablet: 10,
                                          desktop: 12,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                String locationName = locationNames[rodIndex];
                                return BarTooltipItem(
                                  '$locationName\n',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${dateLabels[groupIndex]}\n',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Rp ${formatNumber(rod.toY)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            touchCallback: (FlTouchEvent event,
                                BarTouchResponse? response) {
                              setState(() {
                                if (response == null || response.spot == null) {
                                  highlightedLocation = null;
                                } else {
                                  int touchedRodIndex =
                                      response.spot!.touchedRodDataIndex;
                                  highlightedLocation =
                                      locationNames[touchedRodIndex];
                                }
                              });
                            },
                          ),
                        ), // Ini kurung tutup BarChartData
                      ), // Ini kurung tutup BarChart
                    ),
                  ),
                ),
              const SizedBox(height: 24.0),
              Container(
                alignment: Alignment.center,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: locationNames
                      .where((location) => visibleLocations[location] ?? false)
                      .map((location) => _legendItem(
                          context, locationColorMap[location]!, location))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(
        Icons.filter_list,
        size: Responsive.getFontSize(context,
            mobile: 12, tablet: 16, desktop: 18),
      ),
      label: Text(
        'Filter',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: Responsive.getFontSize(context,
              mobile: 12, tablet: 14, desktop: 14),
        ),
      ),
      onPressed: () => _showFilterOptions(context),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        elevation: 2,
        padding: Responsive.getPadding(
          context,
          mobile: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          desktop: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildFilterOption(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Filter Waktu',
                  onTap: _showTimeFilterDialog,
                ),
                _buildFilterOption(
                  context,
                  icon: Icons.visibility,
                  label: 'Filter Visibilitas',
                  onTap: _showVisibilityDialog,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // The following methods need to be updated with responsive dialog styles:
  void _showTimeFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title:
              const Text('Pilih Rentang Waktu', style: TextStyle(fontSize: 18)),
          children: ['7 Hari', '6 Bulan', '6 Tahun'].map((String filter) {
            return SimpleDialogOption(
              child: Text(filter),
              onPressed: () {
                setState(() {
                  selectedTimeFilter = filter;
                });
                Navigator.pop(context);
                fetchRevenueData();
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showVisibilityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              const Text('Tombol Visibilitas', style: TextStyle(fontSize: 18)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: locationNames.map((location) {
                    return CheckboxListTile(
                      title: Text(location, style: TextStyle(fontSize: 16)),
                      value: visibleLocations[location] ?? true,
                      onChanged: (bool? value) {
                        setState(() {
                          visibleLocations[location] = value!;
                        });
                        this.setState(() {});
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tutup', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
                fetchRevenueData();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _legendItem(BuildContext context, Color color, String text) {
    bool isHighlighted = text == highlightedLocation;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: Responsive.isMobile(context) ? 8 : 12,
          height: Responsive.isMobile(context) ? 8 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 100),
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: Responsive.getFontSize(
              context,
              mobile: 10,
              tablet: 12,
              desktop: 16,
            ),
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? Colors.black : Colors.black54,
          ),
          child: Text(text),
        ),
      ],
    );
  }
}
