// lib/pages/dashboard/widgets/combined_widget_details.dart

import 'package:flutter/material.dart';
import 'daily_income_details.dart';
import 'monthly_income_details.dart';
import 'yearly_income_details.dart';
import '../../../components/sidebar.dart';
import '../../../components/navbar.dart';
import '../../../components/responsive.dart';

class CombinedWidgetDetails extends StatefulWidget {
  final String location;

  const CombinedWidgetDetails({super.key, required this.location});

  @override
  // ignore: library_private_types_in_public_api
  _CombinedWidgetDetailsState createState() => _CombinedWidgetDetailsState();
}

class _CombinedWidgetDetailsState extends State<CombinedWidgetDetails> {
  String? selectedWidget;

  final List<String> widgetOptions = [
    'Pendapatan Harian',
    'Pendapatan Bulanan',
    'Pendapatan Tahunan',
  ];

  Widget _getSelectedWidget() {
    switch (selectedWidget) {
      case 'Pendapatan Harian':
        return DailyIncomeDetails(location: widget.location);
      case 'Pendapatan Bulanan':
        return MonthlyIncomeDetails(location: widget.location);
      case 'Pendapatan Tahunan':
        return YearlyIncomeDetails(location: widget.location);
      default:
        return Container(); // Empty container when nothing is selected
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(title: 'Pendapatan Detail - ${widget.location}'),
      drawer: const Sidebar(),
      body: Card(
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
                  'Silakan pilih pendapatan detail',
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
                      'Pilih rentang waktu:',
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
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.black54),
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
              if (selectedWidget != null) Expanded(child: _getSelectedWidget()),
            ],
          ),
        ),
      ),
    );
  }
}
