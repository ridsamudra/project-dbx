// lib/pages/dashboard/widgets/revenue_realtime_percentage.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:frontend/components/responsive.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/browser_client.dart';

class RevenueRealtimePercentage extends StatefulWidget {
  const RevenueRealtimePercentage({super.key});

  @override
  _RevenueRealtimePercentageState createState() =>
      _RevenueRealtimePercentageState();
}

class _RevenueRealtimePercentageState extends State<RevenueRealtimePercentage> {
  Map<String, double> _dataMap = {};
  Map<String, int> _totalTransactions = {};
  Map<String, double> _totalPendapatan = {};
  bool _isLoading = true;
  String _errorMessage = '';
  int _touchedIndex = -1;
  String? selectedLocation;
  List<String> locations = ['Semua (Akumulasi)'];
  AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    fetchRevenueRealtime();
  }

  Future<void> _fetchLocations() async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri =
          Uri.parse('http://127.0.0.1:8000/api/revenuerealtime/bylocations')
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
        _errorMessage = 'Failed to fetch locations: $e';
      });
    }
  }

  Future<void> fetchRevenueRealtime([String? location]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri = Uri.parse(
        location == null || location == 'Semua (Akumulasi)'
            ? 'http://127.0.0.1:8000/api/revenuerealtime/all'
            : 'http://127.0.0.1:8000/api/revenuerealtime/bylocations',
      ).replace(queryParameters: {
        'session_data': jsonEncode(sessionData),
        if (location != null && location != 'Semua (Akumulasi)')
          'location': location,
      });

      final response =
          await client.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        List<dynamic> data;

        if (decodedData is List) {
          data = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          data = decodedData[location] as List<dynamic>? ?? [];
        } else {
          throw Exception('Unexpected data format');
        }

        setState(() {
          _generateDataMap(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
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
                    fontWeight: FontWeight.w600,
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
      fetchRevenueRealtime(selected == 'Semua (Akumulasi)' ? null : selected);
    }
  }

  void _generateDataMap(List<dynamic> data) {
    double totalPendapatan = 0;

    for (var item in data) {
      double pendapatan = (item['jumlah_pendapatan'] as int).toDouble();
      totalPendapatan += pendapatan;
    }

    _dataMap = {};
    _totalTransactions = {};
    _totalPendapatan = {};

    if (totalPendapatan == 0) {
      for (var item in data) {
        String vehicleType = item['jenis_kendaraan'];
        int transactions = item['jumlah_transaksi'] as int;
        _dataMap[vehicleType] = 100.0 / data.length;
        _totalTransactions[vehicleType] = transactions;
        _totalPendapatan[vehicleType] = 0.0;
      }
    } else {
      for (var item in data) {
        String vehicleType = item['jenis_kendaraan'];
        int transactions = item['jumlah_transaksi'] as int;
        double pendapatan = (item['jumlah_pendapatan'] as int).toDouble();

        _dataMap[vehicleType] =
            pendapatan > 0 ? (pendapatan / totalPendapatan) * 100 : 0;
        _totalTransactions[vehicleType] = transactions;
        _totalPendapatan[vehicleType] = pendapatan;
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Hitung ukuran yang tersedia
          final availableHeight =
              constraints.maxHeight - 80; // 80 untuk header dan padding
          final chartSize =
              availableHeight.clamp(0.0, Responsive.getChartSize(context));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Persentase Pendapatan Realtime',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: const Color(0xFF757575),
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 10,
                            tablet: 16,
                            desktop: 16,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildFilterButton(),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage.isNotEmpty)
                  Center(child: Text(_errorMessage))
                else if (_dataMap.isEmpty)
                  _buildEmptyDataMessage()
                else
                  Flexible(
                    child: SizedBox(
                      height: chartSize,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Pie Chart
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: SizedBox(
                                width: chartSize * 0.8,
                                height: chartSize * 0.8,
                                child: _buildChart(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Legend
                          Expanded(
                            flex: 1,
                            child: SingleChildScrollView(
                              child: _buildLegend(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyDataMessage() {
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
              fontSize: Responsive.getFontSize(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Silakan pilih filter dengan titik lokasi yang lain.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.grey[500],
              fontSize: Responsive.getFontSize(context,
                  mobile: 12, tablet: 14, desktop: 16),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: Responsive.isMobile(context) ? 30 : 40,
        sections: _generatePieChartSections(),
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    return _dataMap.entries.map((entry) {
      final vehicleType = entry.key;
      final percentage = entry.value;
      final isTouch =
          _touchedIndex == _dataMap.keys.toList().indexOf(vehicleType);

      final radius = isTouch
          ? Responsive.getChartSize(context) * 0.12
          : Responsive.getChartSize(context) * 0.10;

      return PieChartSectionData(
        color: _getColorForVehicleType(vehicleType),
        value: percentage,
        title: '',
        radius: radius,
        badgeWidget: isTouch ? _buildBadgeWidget(vehicleType) : null,
        badgePositionPercentageOffset: 0.98,
        showTitle: false,
      );
    }).toList();
  }

  Widget _buildBadgeWidget(String vehicleType) {
    final percentage = _dataMap[vehicleType] ?? 0;
    final transactions = _totalTransactions[vehicleType] ?? 0;
    final pendapatan = _totalPendapatan[vehicleType] ?? 0.0;

    return Padding(
      padding: Responsive.getPadding(context,
          mobile: const EdgeInsets.all(2),
          tablet: const EdgeInsets.all(3),
          desktop: const EdgeInsets.all(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vehicleType,
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: Responsive.getFontSize(context,
                  mobile: 10, tablet: 12, desktop: 14),
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}% pendapatan',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: Responsive.getFontSize(context,
                  mobile: 10, tablet: 12, desktop: 14),
            ),
          ),
          Text(
            '$transactions transaksi',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: Responsive.getFontSize(context,
                  mobile: 10, tablet: 12, desktop: 14),
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(pendapatan),
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: Responsive.getFontSize(context,
                  mobile: 10, tablet: 12, desktop: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    List<MapEntry<String, double>> sortedEntries = _dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedEntries.map((entry) {
        final vehicleType = entry.key;
        final transactions = _totalTransactions[vehicleType] ?? 0;
        final pendapatan = _totalPendapatan[vehicleType] ?? 0.0;
        final isTouch =
            _touchedIndex == _dataMap.keys.toList().indexOf(vehicleType);

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: Responsive.isMobile(context) ? 8 : 12,
                height: Responsive.isMobile(context) ? 8 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getColorForVehicleType(vehicleType),
                ),
              ),
              SizedBox(width: Responsive.isMobile(context) ? 4 : 8),
              Expanded(
                child: Text(
                  '$vehicleType ($transactions - ${NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(pendapatan)})',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: isTouch ? Colors.black : const Color(0xFF757575),
                    fontWeight: isTouch ? FontWeight.w600 : FontWeight.w500,
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 10,
                      tablet: 12,
                      desktop: 14,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForVehicleType(String vehicleType) {
    final List<Color> colors = [
      const Color(0xD9322FC8),
      const Color(0xD9FF9F43),
      const Color(0xD9E73F76),
      const Color(0xD9B57C5A),
      const Color(0xD93FAF2A),
      const Color(0xD9E74C3C),
      const Color(0xD9F1C40F),
      const Color(0xD99398EC)
    ];
    return colors[_dataMap.keys.toList().indexOf(vehicleType) % colors.length];
  }
}
