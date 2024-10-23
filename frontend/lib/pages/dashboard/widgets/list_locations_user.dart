// lib/pages/dashboard/widgets/users_locations.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/components/navbar.dart';
import 'package:frontend/components/responsive.dart';
import 'package:frontend/components/sidebar.dart';

class UsersLocations extends StatefulWidget {
  const UsersLocations({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UsersLocationsState createState() => _UsersLocationsState();
}

class _UsersLocationsState extends State<UsersLocations> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _allLocations = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final AuthService authService = AuthService();

  String? _selectedUserId;
  Map<String, dynamic>? _selectedUser;
  List<Map<String, dynamic>> _selectedUserLocations = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchAllLocations();
  }

  Future<void> _fetchUsers() async {
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
      final uri = Uri.parse('http://127.0.0.1:8000/api/users/list_user/');

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_data': sessionData}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchAllLocations() async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri = Uri.parse('http://127.0.0.1:8000/api/users/list_locations/');

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_data': sessionData}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _allLocations = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchUserLocations(String userId) async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri =
          Uri.parse('http://127.0.0.1:8000/api/users/get_user_locations/');

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_data': sessionData,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _selectedUserLocations =
              List<Map<String, dynamic>>.from(data['locations']);
        });
      } else {
        throw Exception('Failed to load user locations');
      }
    } catch (e) {
      _showPopupMessage('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _manageUserLocations(String operation, String locationId) async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri =
          Uri.parse('http://127.0.0.1:8000/api/users/manage_user_locations/');

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_data': sessionData,
          'operation': operation,
          'user_id': _selectedUserId,
          'location_id': locationId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showPopupMessage(
          operation == 'add'
              ? 'Akses lokasi berhasil ditambahkan!'
              : 'Akses lokasi berhasil dihapus!',
          Colors.green,
        );
        _fetchUserLocations(_selectedUserId!);
      } else {
        throw Exception('Failed to update user location access');
      }
    } catch (e) {
      _showPopupMessage('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showPopupMessage(String message, Color backgroundColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                backgroundColor == Colors.green
                    ? Icons.check_circle
                    : Icons.error,
                color: backgroundColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
            ),
            children: [
              _buildTableCell('ID User', isHeader: true),
              _buildTableCell('Nama User', isHeader: true),
            ],
          ),
          ..._users.map((user) {
            final isSelected = _selectedUserId == user['id'].toString();
            return TableRow(
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.transparent,
              ),
              children: [
                _buildTableCell(user['id_user'],
                    onTap: () => _selectUser(user)),
                _buildTableCell(user['nama_user'],
                    onTap: () => _selectUser(user)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text,
      {bool isHeader = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            fontSize: Responsive.isMobile(context) ? 12 : 14,
          ),
        ),
      ),
    );
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      if (_selectedUserId == user['id'].toString()) {
        _selectedUserId = null;
        _selectedUser = null;
        _selectedUserLocations.clear();
      } else {
        _selectedUserId = user['id'].toString();
        _selectedUser = user;
        _fetchUserLocations(_selectedUserId!);
      }
    });
  }

  Widget _buildLocationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedUserId != null
              ? 'Pilih akses lokasi untuk user: ${_selectedUser?['nama_user']}'
              : 'Pilih akses lokasi untuk user: ',
          style: TextStyle(
            fontSize: Responsive.isMobile(context) ? 16 : 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: _allLocations.map((location) {
            final isSelected = _selectedUserLocations
                .any((userLocation) => userLocation['id'] == location['id']);
            return SizedBox(
              width: Responsive.isMobile(context) ? double.infinity : 200,
              child: CheckboxListTile(
                title: Text(
                  location['site'],
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: Responsive.isMobile(context) ? 12 : 14,
                  ),
                ),
                value: isSelected,
                onChanged: _selectedUserId != null
                    ? (bool? value) {
                        if (value != null) {
                          _manageUserLocations(value ? 'add' : 'remove',
                              location['id'].toString());
                        }
                      }
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(title: 'Pengaturan Lokasi User'),
      drawer: const Sidebar(),
      body: SafeArea(
        child: Center(
          child: Card(
            margin: EdgeInsets.all(Responsive.getPadding(context).left),
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.isMobile(context) ? double.infinity : 600,
              ),
              child: Padding(
                padding: Responsive.getPadding(context),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildUserList(),
                                const SizedBox(height: 24),
                                _buildLocationList(),
                              ],
                            ),
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
