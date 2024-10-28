// lib/pages/widgets/post_status.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/components/responsive.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/browser_client.dart';

class PostStatus extends StatefulWidget {
  const PostStatus({super.key});

  @override
  _PostStatusState createState() => _PostStatusState();
}

class _PostStatusState extends State<PostStatus> {
  Map<String, dynamic> _postStatusData = {};
  Map<String, List<dynamic>> _locationData = {};
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
    fetchPostStatus();
  }

  Future<void> _fetchLocations() async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri = Uri.parse('http://127.0.0.1:8000/api/poststatus/bylocations')
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

  Future<void> fetchPostStatus([String? location]) async {
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
            ? 'http://127.0.0.1:8000/api/poststatus/all'
            : 'http://127.0.0.1:8000/api/poststatus/bylocations',
      ).replace(queryParameters: {
        'session_data': jsonEncode(sessionData),
        if (location != null && location != 'Semua (Akumulasi)')
          'location': location,
      });

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        if (location == null || location == 'Semua (Akumulasi)') {
          setState(() {
            _postStatusData = decodedData;
            _locationData = {};
            _isLoading = false;
          });
        } else {
          setState(() {
            _locationData = {location: decodedData[location]};
            _isLoading = false;
          });
        }
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

  Widget _buildLocationCard(Map<String, dynamic> posData) {
    final bool isOnline = posData['status_pos'] == 'Online';

    return Card(
      color: isOnline ? const Color(0xCC28C76F) : const Color(0xCCC72828),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        width: double.infinity, // Ensures full width
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              posData['nama_pos'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 10,
                  tablet: 14,
                  desktop: 16,
                ),
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              posData['status_pos'],
              textAlign: TextAlign.center, // Added center alignment
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 10,
                  tablet: 12,
                  desktop: 14,
                ),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${posData['total_transaksi']} Trx',
              textAlign: TextAlign.center, // Added center alignment
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 10,
                  tablet: 12,
                  desktop: 14,
                ),
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationGrid(List<dynamic> posDataList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: Responsive.isMobile(context) ? 1.2 : 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: posDataList.length,
      itemBuilder: (context, index) {
        return _buildLocationCard(posDataList[index]);
      },
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, Color color,
      String count, String transactionSum) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: Responsive.getFontSize(context,
                    mobile: 12, tablet: 14, desktop: 14),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'TRANSAKSI $transactionSum',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: Responsive.getFontSize(context,
                    mobile: 11, tablet: 13, desktop: 13),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count Pos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: Responsive.getFontSize(context,
                    mobile: 11, tablet: 13, desktop: 13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterDialog() async {
    final selected = await showDialog<String>(
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
                        mobile: 14, tablet: 16, desktop: 16),
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
        fetchPostStatus(selected);
      });
    }
  }

  Widget _buildPieChart(Map<String, dynamic> data) {
    var activeCount = data['jumlah_pos_online'] as int;
    var inactiveCount = data['jumlah_pos_offline'] as int;

    Map<String, double> postData = {
      'POS ONLINE': activeCount.toDouble(),
      'POS OFFLINE': inactiveCount.toDouble(),
    };

    final total = activeCount + inactiveCount;

    return AspectRatio(
      aspectRatio: Responsive.isMobile(context) ? 0.8 : 1,
      child: Padding(
        padding: Responsive.getPadding(context),
        child: PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: Responsive.isMobile(context) ? 30 : 40,
            sections: postData.entries.map((entry) {
              final vehicleType = entry.key;
              final percentage = (entry.value / total * 100).toDouble();
              final isTouch =
                  _touchedIndex == postData.keys.toList().indexOf(vehicleType);

              final radius = isTouch
                  ? Responsive.getChartSize(context) * 0.12
                  : Responsive.getChartSize(context) * 0.10;

              return PieChartSectionData(
                color: vehicleType == 'POS ONLINE'
                    ? const Color(0xCC28C76F)
                    : const Color(0xCCC72828),
                value: entry.value,
                title: '',
                radius: radius,
                badgeWidget: isTouch
                    ? Padding(
                        padding: Responsive.getPadding(context),
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
                                    mobile: 12, tablet: 13, desktop: 14),
                              ),
                            ),
                            Text(
                              '${entry.value.toInt()} pos',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: Responsive.getFontSize(context,
                                    mobile: 12, tablet: 13, desktop: 14),
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: Responsive.getFontSize(context,
                                    mobile: 12, tablet: 13, desktop: 14),
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
                badgePositionPercentageOffset: 0.9,
              );
            }).toList(),
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(
          Responsive.isMobile(context) ? 8.0 : 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Status Pos',
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
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.location_on,
                    size: Responsive.getFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 14,
                    ),
                  ),
                  label: Text(
                    selectedLocation ?? 'Pilih Lokasi',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 10,
                        tablet: 14,
                        desktop: 14,
                      ),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  onPressed: _openFilterDialog,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage))
                      : SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.all(
                              Responsive.isMobile(context) ? 8.0 : 16.0,
                            ),
                            child: _locationData.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: _locationData.entries
                                        .map(
                                          (entry) => _buildLocationGrid(
                                            entry.value,
                                          ),
                                        )
                                        .toList(),
                                  )
                                : Responsive.isMobile(context)
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                _buildStatusCard(
                                                  context,
                                                  'POS ONLINE',
                                                  const Color(0xCC28C76F),
                                                  _postStatusData[
                                                          'jumlah_pos_online']
                                                      .toString(),
                                                  _postStatusData[
                                                          'total_transaksi_pos_online']
                                                      .toString(),
                                                ),
                                                const SizedBox(height: 8),
                                                _buildStatusCard(
                                                  context,
                                                  'POS OFFLINE',
                                                  const Color(0xCCC72828),
                                                  _postStatusData[
                                                          'jumlah_pos_offline']
                                                      .toString(),
                                                  _postStatusData[
                                                          'total_transaksi_pos_offline']
                                                      .toString(),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child:
                                                _buildPieChart(_postStatusData),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _buildStatusCard(
                                                    context,
                                                    'POS ONLINE',
                                                    const Color(0xCC28C76F),
                                                    _postStatusData[
                                                            'jumlah_pos_online']
                                                        .toString(),
                                                    _postStatusData[
                                                            'total_transaksi_pos_online']
                                                        .toString(),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: _buildStatusCard(
                                                    context,
                                                    'POS OFFLINE',
                                                    const Color(0xCCC72828),
                                                    _postStatusData[
                                                            'jumlah_pos_offline']
                                                        .toString(),
                                                    _postStatusData[
                                                            'total_transaksi_pos_offline']
                                                        .toString(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child:
                                                _buildPieChart(_postStatusData),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
