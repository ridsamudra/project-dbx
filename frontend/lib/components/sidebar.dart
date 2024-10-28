// lib/components/sidebar.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'package:frontend/services/auth_service.dart';
import '../pages/widgets/combined_widget_details.dart';
import '../pages/widgets/list_user.dart';
import '../pages/widgets/list_locations_user.dart';
import '../pages/widgets/change_password.dart';
import '../components/responsive.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final AuthService _authService = AuthService();
  List<String> locations = [];
  String? errorMessage;
  bool isLocationDropdownOpen = false;
  bool isAdminDropdownOpen = false;
  bool isUserDropdownOpen = false;
  String? selectedLocation;
  bool isAdmin = false;
  String userName = '';

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    _checkAdminStatus();
    _fetchUserName();
  }

  Future<void> _fetchLocations() async {
    try {
      final sessionData = await _authService.getSessionData();
      if (sessionData == null) {
        throw Exception('No session data available');
      }

      final client = BrowserClient()..withCredentials = true;

      final uri =
          Uri.parse('http://127.0.0.1:8000/api/revenuedetails/locations/')
              .replace(queryParameters: {
        'session_data': jsonEncode(sessionData),
      });

      final response =
          await client.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is Map<String, dynamic> && data['status'] == 'success') {
          setState(() {
            locations = List<String>.from(data['locations']);
          });
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch locations: $e';
      });
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final sessionData = await _authService.getSessionData();
      if (sessionData != null && sessionData['admin'] == 1) {
        setState(() {
          isAdmin = true;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> _fetchUserName() async {
    try {
      final sessionData = await _authService.getSessionData();
      if (sessionData != null && sessionData['id_user'] != null) {
        setState(() {
          userName = sessionData['id_user'];
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogo(context),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMenuItem(
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        onTap: () => Navigator.of(context)
                            .pushReplacementNamed('/dashboard'),
                      ),
                      const SizedBox(height: 10),
                      _buildLocationDropdownButton(),
                      if (isLocationDropdownOpen) _buildLocationDropdownList(),
                      if (isAdmin) ...[
                        const SizedBox(height: 10),
                        _buildAdminDropdownButton(),
                        if (isAdminDropdownOpen) _buildAdminDropdownList(),
                      ],
                    ],
                  ),
                ),
              ),
              _buildUserDropdown(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Padding(
      padding: Responsive.getPadding(context),
      child: Image.asset(
        'assets/best_parking_logo.png',
        height: Responsive.isMobile(context) ? 40 : 50,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: Colors.black87,
          size: Responsive.getFontSize(context,
              mobile: 16, tablet: 18, desktop: 20)),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.black87,
          fontSize: Responsive.getFontSize(context,
              mobile: 14, tablet: 16, desktop: 18),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildLocationDropdownButton() {
    return ListTile(
      leading: Icon(Icons.location_on,
          color: Colors.black87,
          size: Responsive.getFontSize(context,
              mobile: 16, tablet: 18, desktop: 20)),
      title: Text(
        'Detail Pendapatan',
        style: TextStyle(
          color: Colors.black87,
          fontSize: Responsive.getFontSize(context,
              mobile: 14, tablet: 16, desktop: 18),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        isLocationDropdownOpen
            ? Icons.keyboard_arrow_up
            : Icons.keyboard_arrow_down,
        color: Colors.black87,
      ),
      onTap: () {
        setState(() {
          isLocationDropdownOpen = !isLocationDropdownOpen;
        });
      },
    );
  }

  Widget _buildLocationDropdownList() {
    return Column(
      children: locations.map((location) {
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 56.0, right: 16.0),
          leading: Container(
            width: 24,
            alignment: Alignment.centerLeft,
            child: const Icon(
              Icons.circle,
              size: 8,
              color: Colors.black87,
            ),
          ),
          title: Text(
            location,
            style: TextStyle(
              color: Colors.black87,
              fontSize: Responsive.getFontSize(context,
                  mobile: 12, tablet: 14, desktop: 16),
            ),
          ),
          onTap: () {
            setState(() {
              selectedLocation = location;
              isLocationDropdownOpen = false;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CombinedWidgetDetails(location: location),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildAdminDropdownButton() {
    return ListTile(
      leading: Icon(Icons.admin_panel_settings,
          color: Colors.black87,
          size: Responsive.getFontSize(context,
              mobile: 16, tablet: 18, desktop: 20)),
      title: Text(
        'Admin',
        style: TextStyle(
          color: Colors.black87,
          fontSize: Responsive.getFontSize(context,
              mobile: 14, tablet: 16, desktop: 18),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        isAdminDropdownOpen
            ? Icons.keyboard_arrow_up
            : Icons.keyboard_arrow_down,
        color: Colors.black87,
      ),
      onTap: () {
        setState(() {
          isAdminDropdownOpen = !isAdminDropdownOpen;
        });
      },
    );
  }

  Widget _buildAdminDropdownList() {
    return Column(
      children: [
        _buildAdminMenuItem('Daftar User', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListUsers()),
          );
        }),
        _buildAdminMenuItem('Lokasi User', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UsersLocations()),
          );
        }),
      ],
    );
  }

  Widget _buildAdminMenuItem(String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56.0, right: 16.0),
      leading: Container(
        width: 24,
        alignment: Alignment.centerLeft,
        child: const Icon(
          Icons.circle,
          size: 8,
          color: Colors.black87,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.black87,
          fontSize: Responsive.getFontSize(context,
              mobile: 12, tablet: 14, desktop: 16),
        ),
      ),
      onTap: () {
        setState(() {
          isAdminDropdownOpen = false;
        });
        onTap();
      },
    );
  }

  Widget _buildUserDropdown(BuildContext context) {
    return Container(
      padding: Responsive.getPadding(context),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.black87,
              radius: 20, // Sesuaikan ukuran avatar
              child: Icon(Icons.person,
                  color: Colors.white,
                  size: Responsive.getFontSize(context,
                      mobile: 18, tablet: 20, desktop: 22)),
            ),
            title: Text(
              userName,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: Responsive.getFontSize(context,
                    mobile: 14, tablet: 16, desktop: 18),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(
                isUserDropdownOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  isUserDropdownOpen = !isUserDropdownOpen;
                });
              },
            ),
          ),
          if (isUserDropdownOpen) ...[
            _buildUserDropdownItem(
              icon: Icons.lock,
              title: 'Ubah Password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage()),
                );
              },
            ),
            _buildUserDropdownItem(
              icon: Icons.logout,
              title: 'Log out',
              onTap: () async {
                await _authService.logout();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserDropdownItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: Colors.black87,
          size: Responsive.getFontSize(context,
              mobile: 16, tablet: 18, desktop: 20)),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.black87,
          fontSize: Responsive.getFontSize(context,
              mobile: 13, tablet: 15, desktop: 17),
        ),
      ),
      onTap: () {
        setState(() {
          isUserDropdownOpen = false;
        });
        onTap();
      },
    );
  }
}
