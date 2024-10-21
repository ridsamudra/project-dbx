// lib/pages/dashboard/widgets/summary_cards.dart

import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:frontend/services/auth_service.dart';
import '../../../components/responsive.dart';

class SummaryCards extends StatefulWidget {
  final String title;
  final String apiUrl;
  final Color color;

  const SummaryCards({
    super.key,
    required this.title,
    required this.apiUrl,
    this.color = Colors.black,
  });

  @override
  _SummaryCardsState createState() => _SummaryCardsState();
}

class _SummaryCardsState extends State<SummaryCards> {
  late Future<Map<String, String>> _futureData;
  DateTime? _lastUpdated;
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _futureData = _fetchData();
  }

  Future<Map<String, String>> _fetchData() async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient();
      final uri = Uri.parse(widget.apiUrl)
          .replace(queryParameters: {'session_data': jsonEncode(sessionData)});
      final response = await client.get(uri, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apiUpdateTime = DateTime.parse(data['waktu']);

        if (_lastUpdated == null || apiUpdateTime.isAfter(_lastUpdated!)) {
          _lastUpdated = apiUpdateTime;
        }

        String value;
        switch (widget.title) {
          case 'Pendapatan 7 Hari Terakhir':
          case 'Pendapatan Hari Ini':
            value = NumberFormat.currency(
                    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                .format((data[widget.title == 'Pendapatan 7 Hari Terakhir'
                        ? 'total_pendapatan'
                        : 'pendapatan_hari_ini'] as num)
                    .toDouble());
            break;
          case 'Transaksi 7 Hari Terakhir':
          case 'Transaksi Hari Ini':
            value = NumberFormat().format(data[
                widget.title == 'Transaksi 7 Hari Terakhir'
                    ? 'total_transaksi'
                    : 'transaksi_hari_ini'] as int);
            break;
          default:
            value = 'N/A';
        }

        return {
          'value': value,
          'lastUpdated': _lastUpdated != null
              ? '${DateFormat('dd-MM-yyyy').format(_lastUpdated!)} ${DateFormat('HH:mm:ss').format(_lastUpdated!)}'
              : 'N/A'
        };
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching summary data: $e');
      return {'value': 'Error', 'lastUpdated': 'N/A'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          return Card(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.grey[700],
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.isMobile(context) ? 8 : 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data['value']!,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.black,
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 14,
                          tablet: 20,
                          desktop: 24,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.isMobile(context) ? 8 : 12),
                  Text(
                    'Last updated: ${data['lastUpdated']}',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontStyle: FontStyle.italic,
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 8,
                        tablet: 11,
                        desktop: 12,
                      ),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: Text('No Data'));
        }
      },
    );
  }
}
