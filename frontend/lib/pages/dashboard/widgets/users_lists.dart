// lib/pages/dashboard/widgets/users_lists.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/components/navbar.dart';
import 'package:frontend/components/responsive.dart';
import 'package:frontend/components/sidebar.dart';

class ListUsers extends StatefulWidget {
  const ListUsers({super.key});

  @override
  _ListUsersState createState() => _ListUsersState();
}

class _ListUsersState extends State<ListUsers> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final AuthService authService = AuthService();

  final TextEditingController _idUserController = TextEditingController();
  final TextEditingController _namaUserController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
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

      if (sessionData['admin'] != 1) {
        throw Exception('Access denied. Only admin users can view this page.');
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

  Future<void> _addUser() async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri = Uri.parse('http://127.0.0.1:8000/api/users/add_user/');

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_data': sessionData,
          'user_data': {
            'id_user': _idUserController.text,
            'nama_user': _namaUserController.text,
            'password': _passwordController.text.isEmpty
                ? '1234'
                : _passwordController.text,
          },
        }),
      );

      if (response.statusCode == 201) {
        _showPopupMessage('User added successfully', Colors.green);
        _fetchUsers();
        _clearForm();
      } else {
        throw Exception('Failed to add user');
      }
    } catch (e) {
      _showPopupMessage('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _updateUser() async {
    if (_selectedUserId == null) {
      _showPopupMessage('Please select a user to update', Colors.orange);
      return;
    }

    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri = Uri.parse('http://127.0.0.1:8000/api/users/update_user/');

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_data': sessionData,
          'user_id': _selectedUserId,
          'user_data': {
            'id_user': _idUserController.text,
            'nama_user': _namaUserController.text,
            'password': _passwordController.text.isEmpty
                ? null
                : _passwordController.text,
          },
        }),
      );

      if (response.statusCode == 200) {
        _showPopupMessage('User updated successfully', Colors.green);
        _fetchUsers();
        _clearForm();
      } else {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      _showPopupMessage('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _deleteUser() async {
    if (_selectedUserId == null) {
      _showPopupMessage('Please select a user to delete', Colors.orange);
      return;
    }

    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;
      final uri = Uri.parse('http://127.0.0.1:8000/api/users/delete_user/');

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_data': sessionData,
          'user_id': _selectedUserId,
        }),
      );

      if (response.statusCode == 200) {
        _showPopupMessage('User deleted successfully', Colors.green);
        _fetchUsers();
        _clearForm();
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      _showPopupMessage('Error: ${e.toString()}', Colors.red);
    }
  }

  void _clearForm() {
    setState(() {
      _selectedUserId = null;
      _idUserController.clear();
      _namaUserController.clear();
      _passwordController.clear();
    });
  }

  void _showPopupMessage(String message, Color backgroundColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    backgroundColor == Colors.green
                        ? Icons.check_circle_outline
                        : backgroundColor == Colors.red
                            ? Icons.error_outline
                            : Icons.info_outline,
                    color: backgroundColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: backgroundColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: backgroundColor,
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

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        TextFormField(
          controller: _idUserController,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: Responsive.getFontSize(context,
                desktop: 14, tablet: 12, mobile: 10),
          ),
          decoration: InputDecoration(
            labelText: 'ID User',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            labelStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: Responsive.getFontSize(context,
                  desktop: 14, tablet: 12, mobile: 10),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _namaUserController,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: Responsive.getFontSize(context,
                desktop: 14, tablet: 12, mobile: 10),
          ),
          decoration: InputDecoration(
            labelText: 'Nama User',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            labelStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: Responsive.getFontSize(context,
                  desktop: 14, tablet: 12, mobile: 10),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: Responsive.getFontSize(context,
                desktop: 14, tablet: 12, mobile: 10),
          ),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Default password 1234',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            labelStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: Responsive.getFontSize(context,
                  desktop: 14, tablet: 12, mobile: 10),
            ),
            hintStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: Responsive.getFontSize(context,
                  desktop: 12, tablet: 10, mobile: 8),
            ),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _addUser,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Tambah User',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: Responsive.getFontSize(context,
                        desktop: 14, tablet: 12, mobile: 10),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _updateUser,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Simpan Data',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: Responsive.getFontSize(context,
                        desktop: 14, tablet: 12, mobile: 10),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _deleteUser,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Hapus User',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: Responsive.getFontSize(context,
                        desktop: 14, tablet: 12, mobile: 10),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: Responsive.getWidth(context) -
                (2 * Responsive.getPadding(context).left),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dataTableTheme: DataTableThemeData(
                headingTextStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontSize: Responsive.getFontSize(context,
                      desktop: 16, tablet: 14, mobile: 12),
                ),
                dataTextStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.black87,
                  fontSize: Responsive.getFontSize(context,
                      desktop: 14, tablet: 12, mobile: 10),
                ),
              ),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.blue.shade50;
                  }
                  return null;
                },
              ),
              columnSpacing: 16.0,
              horizontalMargin: 16.0,
              columns: [
                DataColumn(
                  label: SizedBox(
                    width: Responsive.getWidth(context, percentage: 20),
                    child: Text('ID User'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: Responsive.getWidth(context, percentage: 30),
                    child: Text('Nama User'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: Responsive.getWidth(context, percentage: 30),
                    child: Text('Password'),
                  ),
                ),
              ],
              rows: _users.map((user) {
                final isSelected = _selectedUserId == user['id'].toString();
                return DataRow(
                  selected: isSelected,
                  cells: [
                    DataCell(
                      SizedBox(
                        width: Responsive.getWidth(context, percentage: 20),
                        child: Text(
                          user['id_user'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () => _selectUser(user),
                    ),
                    DataCell(
                      SizedBox(
                        width: Responsive.getWidth(context, percentage: 30),
                        child: Text(
                          user['nama_user'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () => _selectUser(user),
                    ),
                    DataCell(
                      SizedBox(
                        width: Responsive.getWidth(context, percentage: 30),
                        child: Text(
                          user['password'] ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () => _selectUser(user),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      if (_selectedUserId == user['id'].toString()) {
        _selectedUserId = null;
        _clearForm();
      } else {
        _selectedUserId = user['id'].toString();
        _idUserController.text = user['id_user'];
        _namaUserController.text = user['nama_user'];
        _passwordController.text = user['password'] ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(title: 'Manage Users'),
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
                maxWidth: Responsive.isMobile(context) ? double.infinity : 800,
              ),
              child: Padding(
                padding: Responsive.getPadding(context),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.red,
                                fontSize: Responsive.getFontSize(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildForm(),
                                const SizedBox(height: 24),
                                _buildUserList(),
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

  @override
  void dispose() {
    _idUserController.dispose();
    _namaUserController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
