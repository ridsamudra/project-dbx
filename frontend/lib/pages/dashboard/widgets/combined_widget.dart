// lib/pages/dashboard/widgets/combined_widget.dart

import 'package:flutter/material.dart';
import 'trends_revenue.dart';
import 'trends_revenue_by_locations.dart';
import 'trends_trouble_transactions.dart';
import '../../../components/responsive.dart';

class CombinedRevenueWidget extends StatefulWidget {
  const CombinedRevenueWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CombinedRevenueWidgetState createState() => _CombinedRevenueWidgetState();
}

class _CombinedRevenueWidgetState extends State<CombinedRevenueWidget> {
  String? selectedWidget;

  final List<String> widgetOptions = [
    'Trend Pendapatan',
    'Trend Pendapatan Tiap Lokasi',
    'Trend Tiket Bermasalah',
  ];

  Widget _getSelectedWidget() {
    switch (selectedWidget) {
      case 'Trend Pendapatan':
        return const RevenueTrends();
      case 'Trend Pendapatan Tiap Lokasi':
        return const RevenueTrendsByLocations();
      case 'Trend Tiket Bermasalah':
        return const TroubleTransactions();
      default:
        return const RevenueTrends();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: Responsive.getPadding(
        context,
        mobile: const EdgeInsets.symmetric(vertical: 4.0),
        tablet: const EdgeInsets.symmetric(vertical: 6.0),
        desktop: const EdgeInsets.symmetric(vertical: 8.0),
      ),
      color: Colors.white,
      child: Padding(
        padding: Responsive.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedWidget == null)
              Text(
                'Silakan pilih widget',
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
            SizedBox(height: Responsive.isMobile(context) ? 8.0 : 16.0),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.grey[50],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.isMobile(context) ? 8 : 12,
                vertical: Responsive.isMobile(context) ? 4 : 8,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedWidget,
                  hint: Text(
                    'Pilih widget:',
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
                  isExpanded: true,
                  icon:
                      const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  iconSize: Responsive.isMobile(context) ? 20 : 24,
                  elevation: 16,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: const Color(0xFF757575),
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 10,
                      tablet: 16,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedWidget = newValue;
                    });
                  },
                  items: widgetOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: Responsive.isMobile(context) ? 8.0 : 16.0),
            if (selectedWidget != null) _getSelectedWidget(),
          ],
        ),
      ),
    );
  }
}
