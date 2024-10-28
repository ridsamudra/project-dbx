// lib/pages/widgets/change_password.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/components/navbar.dart';
import 'package:frontend/components/responsive.dart';
import 'package:frontend/components/sidebar.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final AuthService authService = AuthService();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        final sessionData = await authService.getSessionData();
        if (sessionData == null) {
          throw Exception('No session data available');
        }

        final client = BrowserClient()..withCredentials = true;
        final uri =
            Uri.parse('http://127.0.0.1:8000/api/users/change_password/');

        final response = await client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'session_data': sessionData,
            'old_password': _oldPasswordController.text,
            'new_password': _newPasswordController.text,
          }),
        );

        final responseBody = json.decode(response.body);

        if (response.statusCode == 200) {
          _showPopupMessage(
              'Password berhasil diganti, silahkan login ulang', Colors.green);
          await Future.delayed(const Duration(seconds: 2));
          await authService.logout();
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/login', (Route<dynamic> route) => false);
        } else {
          throw Exception(responseBody['error'] ?? 'Failed to change password');
        }
      } catch (e) {
        _showPopupMessage('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showPopupMessage(String message, Color backgroundColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                        : Icons.error_outline,
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
                      fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(title: 'Change Password'),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _oldPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Old Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your old password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
