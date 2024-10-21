// lib/pages/dashboard/widges/revenue_realtime.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/browser_client.dart';
import 'package:intl/intl.dart';

class RevenueRealtime extends StatefulWidget {
  const RevenueRealtime({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RevenueRealtimeState createState() => _RevenueRealtimeState();
}

class _RevenueRealtimeState extends State<RevenueRealtime> {
  late Future<dynamic> _dataFuture;
  final AuthService authService = AuthService();
  String? selectedLocation;
  String? errorMessage;
  List<String> locations = [];

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchRevenueRealtime();
    _fetchLocations(); // Fetch locations on init
  }

  Future<dynamic> fetchRevenueRealtime([String? location]) async {
    final sessionData = await authService.getSessionData();
    if (sessionData == null) {
      throw Exception('No session data available');
    }

    final client = BrowserClient()..withCredentials = true;

    try {
      final uri = Uri.parse(
        location == null
            ? 'http://127.0.0.1:8000/api/revenuerealtime/all'
            : 'http://127.0.0.1:8000/api/revenuerealtime/bylocations',
      ).replace(queryParameters: {
        'session_data': jsonEncode(sessionData),
        if (location != null) 'location': location,
      });

      final response =
          await client.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to load data: ${response.statusCode}\nBody: ${response.body}');
      }
    } catch (e) {
      print('Error in fetchRevenueRealtime: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> _fetchLocations() async {
    try {
      // Fetch from specific URL for locations
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
            // Take the keys (location names) for dropdown
            locations = ['Default', ...data.keys];
          });
        }
      } else {
        throw Exception(
            'Failed to load locations: ${response.statusCode}\nBody: ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error in _fetchLocations: $e');
      setState(() {
        errorMessage = 'Failed to fetch locations: $e';
      });
    }
  }

  void _openFilterDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Lokasi'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                return ListTile(
                  title: Text(location),
                  onTap: () => Navigator.pop(context, location),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null && selected != selectedLocation) {
      setState(() {
        selectedLocation = selected == 'Default' ? null : selected;
        errorMessage = null;
        _dataFuture = fetchRevenueRealtime(selectedLocation);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Pendapatan Realtime',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Color(0xFF757575),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  label: Text(selectedLocation ?? 'Default'),
                  onPressed: _openFilterDialog,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            FutureBuilder<dynamic>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('No data available'));
                }

                final data = snapshot.data;
                if (data is List) {
                  return _buildTable(data);
                } else if (data is Map<String, dynamic>) {
                  if (selectedLocation != null) {
                    // Show data for the selected location
                    return _buildTable(data[selectedLocation] ?? []);
                  } else {
                    // Show data for all locations
                    return Column(
                      children: data.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                color: Color(0xFF757575),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTable(entry.value),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    );
                  }
                }

                return const Center(child: Text('Invalid data format'));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<dynamic> data) {
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        _buildTableHeader(),
        ..._buildTableRows(data),
      ],
    );
  }

  TableRow _buildTableHeader() {
    return const TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Waktu',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Color(0xFF757575),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Jenis Kendaraan',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Color(0xFF757575),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Total Transaksi',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Color(0xFF757575),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Total Pendapatan',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Color(0xFF757575),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<TableRow> _buildTableRows(List<dynamic> data) {
    return data.map((row) {
      final mapRow = row as Map<String, dynamic>;
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              DateFormat('dd-MM-yyyy HH:mm:ss')
                  .format(DateTime.parse(mapRow['waktu'])),
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              mapRow['jenis_kendaraan'].toString(),
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              mapRow['jumlah_transaksi'].toString(),
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(mapRow['jumlah_pendapatan']),
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}
