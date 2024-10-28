// lib/pages/widgets/revenue_trends.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/browser_client.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/components/responsive.dart';

class RevenueTrends extends StatefulWidget {
  const RevenueTrends({super.key});

  @override
  _RevenueTrendsState createState() => _RevenueTrendsState();
}

class _RevenueTrendsState extends State<RevenueTrends> {
  final AuthService authService = AuthService();
  String selectedTimeFilter = '7 Hari';
  String selectedLocationFilter = 'Semua';
  List<BarChartGroupData> barGroups = [];
  List<String> dateLabels = [];
  bool isLoading = true;
  double maxY = 0;
  String? highlightedBar;
  List<String> locations = ['Semua'];
  Map<String, bool> visibleBars = {
    'cash': true,
    'prepaid': true,
    'member': true,
    'manual': true,
    'masalah': true,
    'total': true,
  };

  final Map<String, Color> barColors = {
    'cash': Colors.blue.shade300,
    'prepaid': Colors.green.shade300,
    'member': Colors.orange.shade300,
    'manual': Colors.purple.shade300,
    'masalah': Colors.red.shade300,
    'total': Colors.grey.shade300,
  };

  @override
  void initState() {
    super.initState();
    fetchLocations();
    fetchRevenueData();
  }

  Future<void> fetchLocations() async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;

      final uri = Uri.parse(
              'http://127.0.0.1:8000/api/revenue/filterbydays/bylocations')
          .replace(queryParameters: {
        'session_data': jsonEncode(sessionData),
      });

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          locations = ['Semua', ...data.keys.toList()];
        });
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching locations: $e');
      setState(() {
        locations = ['Semua'];
      });
    }
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
    String baseUrl = 'http://127.0.0.1:8000/api/revenue/';
    String endpoint;

    if (selectedTimeFilter == '7 Hari') {
      endpoint = 'filterbydays';
    } else if (selectedTimeFilter == '6 Bulan') {
      endpoint = 'filterbymonths';
    } else {
      endpoint = 'filterbyyears';
    }

    endpoint += selectedLocationFilter == 'Semua' ? '/all' : '/bylocations';

    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: {
        'session_data': jsonEncode(sessionData),
        if (selectedLocationFilter != 'Semua')
          'location': selectedLocationFilter,
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

  void processData(dynamic jsonData) {
    List<BarChartGroupData> tempBarGroups = [];
    List<String> tempDateLabels = [];
    maxY = 0;

    if (selectedLocationFilter == 'Semua') {
      processAllLocationsData(jsonData, tempBarGroups, tempDateLabels);
    } else {
      processSingleLocationData(
          jsonData[selectedLocationFilter], tempBarGroups, tempDateLabels);
    }

    setState(() {
      barGroups = tempBarGroups;
      dateLabels = tempDateLabels;
      isLoading = false;
      adjustMaxY();
    });
  }

  void processAllLocationsData(List<dynamic> data,
      List<BarChartGroupData> tempBarGroups, List<String> tempDateLabels) {
    for (int i = 0; i < data.length; i++) {
      tempDateLabels.add(formatDate(data[i]['tanggal']));
      addBarGroup(data[i], i, tempBarGroups);
    }
  }

  void processSingleLocationData(List<dynamic> data,
      List<BarChartGroupData> tempBarGroups, List<String> tempDateLabels) {
    for (int i = 0; i < data.length; i++) {
      tempDateLabels.add(formatDate(data[i]['tanggal']));
      addBarGroup(data[i], i, tempBarGroups);
    }
  }

  String formatDate(dynamic dateValue) {
    if (dateValue is int) {
      return dateValue.toString();
    } else if (dateValue is String) {
      if (selectedTimeFilter == '7 Hari') {
        try {
          final date = DateTime.parse(dateValue);
          return DateFormat('dd MMM').format(date);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing date: $e');
          }
          return dateValue;
        }
      } else if (selectedTimeFilter == '6 Bulan') {
        return _formatMonthYear(dateValue);
      } else {
        return dateValue;
      }
    }
    return dateValue.toString();
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

  void addBarGroup(Map<String, dynamic> data, int index,
      List<BarChartGroupData> tempBarGroups) {
    List<BarChartRodData> rods = [];
    visibleBars.forEach((key, isVisible) {
      if (isVisible) {
        double value = _parseAndFormatNumber(data[key]);
        rods.add(_createBarRod(value, barColors[key]!));
        maxY = [maxY, value].reduce((a, b) => a > b ? a : b);
      }
    });

    tempBarGroups.add(BarChartGroupData(
      x: index,
      barRods: rods,
    ));
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

  double _parseAndFormatNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0;
    return 0;
  }

  BarChartRodData _createBarRod(double value, Color color) {
    return BarChartRodData(
      toY: value,
      color: color,
      width: Responsive.isMobile(context) ? 8 : 16, // Adjusted for mobile
      borderRadius: BorderRadius.circular(4),
    );
  }

  String formatNumber(double number) {
    return NumberFormat('#,##0', 'en_US').format(number);
  }

  Widget getTitles(double value, TitleMeta meta) {
    int index = value.toInt();
    if (index < dateLabels.length) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          dateLabels[index],
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
    }
    return const Text('');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopView = Responsive.isDesktop(context);
    final double chartHeight = isDesktopView
        ? Responsive.getHeight(context, percentage: 50)
        : Responsive.getHeight(context, percentage: 40);

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
                      'Trend Pendapatan',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: const Color(0xFF757575),
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 12,
                          tablet: 16,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Single Filter Button
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
                    width: isDesktopView
                        ? Responsive.getWidth(context, percentage: 95)
                        : Responsive.getWidth(context, percentage: 200),
                    height: chartHeight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: Responsive.getPadding(context).right,
                        top: isDesktopView
                            ? 40.0
                            : 20.0, // Extra padding for y-axis labels
                      ),
                      child: BarChart(
                        BarChartData(
                          maxY: maxY,
                          barGroups: barGroups,
                          alignment: isDesktopView
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
                                String barType =
                                    getLabelForRodIndex(rodIndex).capitalize();
                                String date = dateLabels[groupIndex];
                                return BarTooltipItem(
                                  '$barType\n',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: Responsive.getFontSize(
                                      context,
                                      mobile: 10,
                                      tablet: 12,
                                      desktop: 14,
                                    ),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$date\n',
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
                                  highlightedBar = null;
                                } else {
                                  highlightedBar = getLabelForRodIndex(
                                    response.spot!.touchedRodDataIndex,
                                  );
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24.0),
              Container(
                alignment: Alignment.center,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: visibleBars.entries
                      .where((entry) => entry.value)
                      .map((entry) => _legendItem(context,
                          barColors[entry.key]!, entry.key.capitalize()))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Single Filter Button with Icon and Text
  Widget _buildFilterButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(
        Icons.filter_list,
        size: Responsive.getFontSize(context,
            mobile: 12, tablet: 14, desktop: 14),
      ),
      label: Text(
        'Filter',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: Responsive.getFontSize(context,
              mobile: 12, tablet: 14, desktop: 14),
        ),
      ),
      onPressed: () {
        _showFilterOptions(context); // Menggunakan modal pop-up
      },
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

// Ubah tampilan modal filter
  void _showFilterOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.2,
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
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
                  icon: Icons.location_on,
                  label: 'Filter Lokasi',
                  onTap: _showLocationFilterDialog,
                ),
                _buildFilterOption(
                  context,
                  icon: Icons.visibility,
                  label: 'Filter Visibilitas',
                  onTap: _showVisibilityDialog,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Tutup",
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context,
                          mobile: 12, tablet: 16, desktop: 16),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper method untuk membangun opsi filter (tidak diubah)
  Widget _buildFilterOption(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(label,
          style: TextStyle(
            fontSize: Responsive.getFontSize(context,
                mobile: 12, tablet: 16, desktop: 16),
            fontFamily: 'Montserrat',
          )),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showTimeFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.2,
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih Rentang Waktu',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context,
                        mobile: 12, tablet: 16, desktop: 16),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 16),
                ...['7 Hari', '6 Bulan', '6 Tahun'].map((String filter) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedTimeFilter = filter;
                      });
                      Navigator.pop(context);
                      fetchRevenueData();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context,
                              mobile: 12, tablet: 16, desktop: 16),
                          // fontWeight: FontWeight.w400,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocationFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.2,
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih Lokasi',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context,
                        mobile: 12, tablet: 16, desktop: 16),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 16),
                ...locations.map((String location) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedLocationFilter = location;
                      });
                      Navigator.pop(context);
                      fetchRevenueData();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context,
                              mobile: 12, tablet: 16, desktop: 16),
                          // fontWeight: FontWeight.w400,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVisibilityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.2,
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tombol Visibilitas',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context,
                        mobile: 12, tablet: 16, desktop: 16),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: visibleBars.keys.map((String key) {
                          return CheckboxListTile(
                            title: Text(
                              key.capitalize(),
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(context,
                                    mobile: 12, tablet: 16, desktop: 16),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            value: visibleBars[key],
                            onChanged: (bool? value) {
                              setState(() {
                                visibleBars[key] = value!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  child: Text(
                    'Tutup',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context,
                          mobile: 12, tablet: 16, desktop: 16),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    fetchRevenueData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    bool isHighlighted = label.toLowerCase() == highlightedBar;
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
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            color: isHighlighted ? Colors.black : Colors.black54,
          ),
          child: Text(label),
        ),
      ],
    );
  }

  String getLabelForRodIndex(int index) {
    List<String> visibleKeys = visibleBars.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    return index < visibleKeys.length ? visibleKeys[index] : '';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
