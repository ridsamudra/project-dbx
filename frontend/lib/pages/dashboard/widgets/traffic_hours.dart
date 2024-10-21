// lib/pages/dashboard/widgets/traffic_hours.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/components/responsive.dart';
import 'package:http/browser_client.dart';

class TrafficHours extends StatefulWidget {
  const TrafficHours({super.key});

  @override
  _TrafficHoursState createState() => _TrafficHoursState();
}

class _TrafficHoursState extends State<TrafficHours> {
  List<BarChartGroupData> barGroups = [];
  bool isLoading = true;
  String errorMessage = '';
  double maxTransaction = 0;
  final NumberFormat numberFormat = NumberFormat('#,###');
  final NumberFormat currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  AuthService authService = AuthService();
  String? selectedLocation;
  List<String> locations = ['Semua (Akumulasi)'];
  Map<int, double> revenueData = {};
  bool hasData = false;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    fetchTrafficData();
  }

  Future<void> _fetchLocations() async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri =
          Uri.parse('http://127.0.0.1:8000/api/traffichours/bylocations')
              .replace(queryParameters: {
        'session_data': jsonEncode(sessionData),
      });

      final response =
          await client.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          setState(() {
            locations = ['Semua (Akumulasi)', ...data.keys];
          });
        }
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch locations: $e';
      });
    }
  }

  Future<void> fetchTrafficData([String? location]) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      hasData = false;
    });

    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri = Uri.parse(
        location == null || location == 'Semua (Akumulasi)'
            ? 'http://127.0.0.1:8000/api/traffichours/all'
            : 'http://127.0.0.1:8000/api/traffichours/bylocations',
      ).replace(queryParameters: {
        'session_data': jsonEncode(sessionData),
        if (location != null && location != 'Semua (Akumulasi)')
          'location': location,
      });

      final response =
          await client.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        Map<String, dynamic> data;

        if (decodedData is Map<String, dynamic>) {
          data = location == null || location == 'Semua (Akumulasi)'
              ? decodedData
              : decodedData[location];
        } else {
          throw Exception('Unexpected data format');
        }

        _processTrafficData(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${error.toString()}';
      });
    }
  }

  void _processTrafficData(Map<String, dynamic> data) {
    List<BarChartGroupData> tempBarGroups = [];
    maxTransaction = 0;
    revenueData.clear();
    hasData = false;

    for (int i = 0; i < 24; i++) {
      double transaksi = data['transaksi']['jam_$i'].toDouble();
      double pendapatan = data['pendapatan']['jam_$i'].toDouble();

      if (transaksi > 0 || pendapatan > 0) {
        hasData = true;
      }

      maxTransaction = maxTransaction > transaksi ? maxTransaction : transaksi;
      revenueData[i] = pendapatan;

      tempBarGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: transaksi,
            color: Colors.blue,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
    }

    if (maxTransaction == 0) {
      maxTransaction = 1;
    }

    setState(() {
      barGroups = tempBarGroups;
      isLoading = false;
    });
  }

  void _openFilterDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: Responsive.isMobile(context) ? double.infinity : 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih Lokasi',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context,
                        mobile: 18, tablet: 20, desktop: 22),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      return ListTile(
                        title: Text(
                          location,
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context,
                                mobile: 14, tablet: 16, desktop: 16),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(location),
                        selected: location == selectedLocation,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        tileColor: location == selectedLocation
                            ? Colors.blue.shade50
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != selectedLocation) {
      setState(() {
        selectedLocation = selected;
      });
      fetchTrafficData(selected == 'Semua (Akumulasi)' ? null : selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: Padding(
        padding: Responsive.getPadding(
          context,
          mobile: const EdgeInsets.all(12),
          tablet: const EdgeInsets.all(16),
          desktop: const EdgeInsets.all(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trafik Tiap Jam',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: const Color(0xFF757575),
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 10,
                      tablet: 16,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildFilterButton(),
              ],
            ),
            const SizedBox(height: 16),
            _buildChartContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.location_on,
          size: Responsive.getFontSize(context,
              mobile: 12, tablet: 16, desktop: 18)),
      label: Text(
        selectedLocation ?? 'Pilih Lokasi',
        style: TextStyle(
          fontSize: Responsive.getFontSize(context,
              mobile: 10, tablet: 14, desktop: 14),
          fontFamily: 'Montserrat',
        ),
      ),
      onPressed: _openFilterDialog,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        elevation: 2,
        padding: Responsive.getPadding(
          context,
          mobile: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tablet: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          desktop: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }

  Widget _buildChartContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    } else if (!hasData) {
      return _buildNoDataWidget();
    } else {
      return _buildResponsiveChart();
    }
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey[500],
            size: 50,
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada data yang tersedia',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.grey[600],
              fontSize: Responsive.getFontSize(
                context,
                mobile: 16,
                tablet: 17,
                desktop: 18,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Silakan pilih filter dengan titik lokasi yang lain.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.grey[500],
              fontSize: Responsive.getFontSize(
                context,
                mobile: 12,
                tablet: 13,
                desktop: 14,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = Responsive.isMobile(context)
            ? 300.0
            : constraints.maxHeight > 300
                ? 300.0
                : constraints.maxHeight;

        if (Responsive.isMobile(context)) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 800,
                height: height,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                  child: _buildChart(),
                ),
              ),
            ),
          );
        } else {
          return SizedBox(
            height: height,
            child: _buildChart(),
          );
        }
      },
    );
  }

  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0), // Tambahin padding atas
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: _getTitlesData(),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          maxY: maxTransaction,
          minY: 0,
          barTouchData: _getBarTouchData(),
        ),
      ),
    );
  }

  FlTitlesData _getTitlesData() {
    final fontSize = Responsive.getFontSize(
      context,
      mobile: 10,
      tablet: 11,
      desktop: 12,
    );

    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: 'Montserrat',
                  color: const Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                numberFormat.format(value.toInt()),
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: 'Montserrat',
                  color: const Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          interval: maxTransaction > 0 ? maxTransaction / 5 : 1,
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  BarTouchData _getBarTouchData() {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (BarChartGroupData group) => Colors.blueGrey,
        // tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tooltipMargin: 0,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          int hour = group.x;
          double transactions = rod.toY;
          double revenue = revenueData[hour] ?? 0;
          return BarTooltipItem(
            'Jam $hour\n'
            'Transaksi: ${numberFormat.format(transactions.round())}\n'
            'Pendapatan: ${currencyFormat.format(revenue)}',
            const TextStyle(color: Colors.white),
          );
        },
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        direction: TooltipDirection.top,
      ),
    );
  }
}
