import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:tech4girls/providers/sensor_data_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedPeriod = 'today'; // today, week, month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodButton('Aujourd\'hui', 'today'),
                _buildPeriodButton('Cette semaine', 'week'),
                _buildPeriodButton('Ce mois', 'month'),
              ],
            ),
          ),
          // Chart and statistics
          Expanded(
            child: Consumer<SensorDataProvider>(
              builder: (context, sensorProvider, _) {
                final data = _getDataByPeriod(sensorProvider);
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.show_chart,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Aucune donnée disponible'),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          // Statistics
                          _buildStatistics(sensorProvider, data),
                          const SizedBox(height: 24),
                          // Temperature Chart
                          Text(
                            'Évolution de la Température',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildTemperatureChart(data),
                          const SizedBox(height: 24),
                          // Data table
                          Text(
                            'Détails des Mesures',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildDataTable(data),
                          const SizedBox(height: 24),
                          // Movement events list
                          Text(
                            'Mouvements détectés',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildMotionList(data),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    bool isSelected = _selectedPeriod == period;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = period;
        });
      },
      selectedColor: Colors.deepPurple,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  List<dynamic> _getDataByPeriod(SensorDataProvider provider) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        return provider.sensorHistory
            .where(
              (d) =>
                  d.timestamp.year == now.year &&
                  d.timestamp.month == now.month &&
                  d.timestamp.day == now.day,
            )
            .toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return provider.sensorHistory
            .where((d) => d.timestamp.isAfter(weekAgo))
            .toList();
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        return provider.sensorHistory
            .where((d) => d.timestamp.isAfter(monthAgo))
            .toList();
      default:
        return provider.sensorHistory;
    }
  }

  Widget _buildStatistics(SensorDataProvider provider, List<dynamic> data) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    double minTemp = data[0].temperature;
    double maxTemp = data[0].temperature;
    double sum = 0;
    int emergencyCount = 0;

    for (var reading in data) {
      if (reading.temperature < minTemp) minTemp = reading.temperature;
      if (reading.temperature > maxTemp) maxTemp = reading.temperature;
      sum += reading.temperature;
      if (reading.emergencySignal) emergencyCount++;
    }

    double avgTemp = sum / data.length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Min', '${minTemp.toStringAsFixed(1)}°C'),
                _buildStatItem('Moyenne', '${avgTemp.toStringAsFixed(1)}°C'),
                _buildStatItem('Max', '${maxTemp.toStringAsFixed(1)}°C'),
                _buildStatItem('Urgences', '$emergencyCount'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMotionList(List<dynamic> data) {
    final motions = data.where((d) => d.motionDetected).toList();
    if (motions.isEmpty) {
      return const Text('Aucun mouvement enregistré.');
    }
    return Column(
      children:
          motions
              .map(
                (d) => ListTile(
                  leading: const Icon(
                    Icons.directions_walk,
                    color: Colors.blue,
                  ),
                  title: Text(DateFormat.Hms().format(d.timestamp)),
                  subtitle: Text('${d.temperature.toStringAsFixed(1)}°C'),
                ),
              )
              .toList(),
    );
  }

  Widget _buildTemperatureChart(List<dynamic> data) {
    if (data.isEmpty) {
      return const SizedBox(height: 200);
    }

    // Prepare data for chart
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].temperature));
    }

    // Find min and max for Y axis
    double minY = data
        .map((d) => d.temperature)
        .reduce((a, b) => a < b ? a : b);
    double maxY = data
        .map((d) => d.temperature)
        .reduce((a, b) => a > b ? a : b);

    // Add some padding
    minY = (minY - 2).clamp(30.0, 50.0);
    maxY = (maxY + 2).clamp(30.0, 50.0);

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Text(
                      DateFormat('HH:mm').format(data[index].timestamp),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
                interval: (data.length / 5).ceilToDouble(),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(0)}°',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.deepPurple,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
          ],
          minY: minY,
          maxY: maxY,
        ),
      ),
    );
  }

  Widget _buildDataTable(List<dynamic> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Heure')),
          DataColumn(label: Text('Température')),
          DataColumn(label: Text('Urgence')),
        ],
        rows:
            data.map((d) {
              return DataRow(
                cells: [
                  DataCell(Text(DateFormat('HH:mm:ss').format(d.timestamp))),
                  DataCell(
                    Text(
                      '${d.temperature.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        color:
                            d.temperature >= 38.0
                                ? Colors.orange
                                : Colors.black,
                        fontWeight:
                            d.temperature >= 38.0
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      d.emergencySignal ? 'OUI' : 'NON',
                      style: TextStyle(
                        color: d.emergencySignal ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
