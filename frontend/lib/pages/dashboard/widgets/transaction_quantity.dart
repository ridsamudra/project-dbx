import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TransactionQuantity extends StatefulWidget {
  const TransactionQuantity({super.key});

  @override
  _TransactionQuantityState createState() => _TransactionQuantityState();
}

class _TransactionQuantityState extends State<TransactionQuantity>
    with SingleTickerProviderStateMixin {
  late Future<List<TransactionQty>> _transactionQuantities;
  final NumberFormat numberFormat = NumberFormat('#,##0', 'id_ID');
  late AnimationController _animationController;
  late Animation<double> _animation;

  // State for sorting
  String _sortOrder = 'asc'; // 'asc' for ascending, 'desc' for descending

  @override
  void initState() {
    super.initState();
    _transactionQuantities = fetchTransactionQuantities();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<TransactionQty>> fetchTransactionQuantities() async {
    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/transactionquantity/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // Sort data based on the current sort order
        data.sort((a, b) => _sortOrder == 'asc'
            ? a['total_qty'].compareTo(b['total_qty'])
            : b['total_qty'].compareTo(a['total_qty']));
        return data.map((item) => TransactionQty.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load transaction quantities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load transaction quantities: $e');
    }
  }

  String _formatYLabel(double value) {
    return numberFormat.format(value);
  }

  Widget _bottomTitleWidgets(
      double value, TitleMeta meta, List<TransactionQty> data) {
    const style = TextStyle(fontSize: 12);
    final index = value.toInt();
    if (index >= 0 && index < data.length) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(DateFormat('MMM yyyy').format(data[index].month),
              style: style),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(
        _formatYLabel(value),
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.right,
      ),
    );
  }

  double _calculateMaxY(List<TransactionQty> data) {
    final maxQty = data.map((e) => e.totalQty).reduce((a, b) => a > b ? a : b);
    return (maxQty * 1.1).ceilToDouble();
  }

  void _toggleSortOrder() {
    setState(() {
      _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
      _transactionQuantities =
          fetchTransactionQuantities(); // Fetch sorted data
    });
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction Quantity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF757575),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _sortOrder == 'asc'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: Colors.blue,
                  ),
                  onPressed: _toggleSortOrder,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 300,
              child: FutureBuilder<List<TransactionQty>>(
                future: _transactionQuantities,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }

                  final data = snapshot.data!;
                  return AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey[300],
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) =>
                                    _bottomTitleWidgets(value, meta, data),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) =>
                                    _leftTitleWidgets(value, meta),
                                interval: _calculateMaxY(data) / 5,
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: data.asMap().entries.map((entry) {
                                return FlSpot(
                                  entry.key.toDouble(),
                                  entry.value.totalQty.toDouble() *
                                      _animation.value,
                                );
                              }).toList(),
                              isCurved: true,
                              color: Colors.blue,
                              dotData: FlDotData(show: _animation.value == 1.0),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withOpacity(0.1),
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                            ),
                          ],
                          minY: 0,
                          maxY: _calculateMaxY(data),
                          lineTouchData: const LineTouchData(
                            handleBuiltInTouches: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionQty {
  final DateTime month;
  final int totalQty;

  TransactionQty({required this.month, required this.totalQty});

  factory TransactionQty.fromJson(Map<String, dynamic> json) {
    return TransactionQty(
      month: DateTime.parse(json['month'] + '-01'),
      totalQty: json['total_qty'],
    );
  }
}
