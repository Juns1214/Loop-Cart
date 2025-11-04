import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'bar_data.dart';

class MyBarGraph extends StatelessWidget {
  final List<double> donationAmount;
  const MyBarGraph({super.key, required this.donationAmount});

  @override
  Widget build(BuildContext context) {
    BarData myBarData = BarData(
      lowIncome: donationAmount[0],
      orphanage: donationAmount[1],
      oldFolkHome: donationAmount[2],
      cancerNGO: donationAmount[3],
      wildlifeProtection: donationAmount[4],
      environmentProtection: donationAmount[5],
    );

    myBarData.initializeBarData();

    return BarChart(
      BarChartData(
        maxY: 450,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < myBarData.barData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      myBarData.barData[index].x,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  'RM${value.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: myBarData.barData.map((data) {
          return BarChartGroupData(
            x: myBarData.barData.indexOf(data),
            barRods: [
              BarChartRodData(
                toY: data.y,
                width: 24,
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 450,
                  color: Colors.grey[200],
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String category = myBarData.barData[groupIndex].x;
              return BarTooltipItem(
                '$category\nRM ${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}