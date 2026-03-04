import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:tech4girls/providers/sensor_data_provider.dart';
import 'package:tech4girls/services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedPeriod = 'today'; // today, week, month
  final _databaseService = DatabaseService();
  List<Map<String, dynamic>> _emergencyLogs = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencyLogs();
  }

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
                final displayData = data.isEmpty ? _defaultSensorSamples() : data;
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.isEmpty)
                          _buildDemoBanner(),
                        _buildMedicalSummary(displayData),
                        const SizedBox(height: 16),
                        // Statistics
                        _buildStatistics(displayData),
                        const SizedBox(height: 24),
                        // Temperature Chart
                        _buildSectionTitle(
                          'Évolution de la Température',
                          Icons.show_chart,
                        ),
                        const SizedBox(height: 16),
                        _buildTemperatureChart(displayData),
                        const SizedBox(height: 24),
                        // Data table
                        _buildSectionTitle(
                          'Détails des Mesures',
                          Icons.table_chart,
                        ),
                        const SizedBox(height: 16),
                        _buildDataTable(displayData),
                        const SizedBox(height: 24),
                        // Movement events list
                        _buildSectionTitle(
                          'Mouvements détectés',
                          Icons.directions_walk,
                        ),
                        const SizedBox(height: 16),
                        _buildMotionList(displayData),
                        const SizedBox(height: 24),
                        _buildRecommendationsCard(displayData),
                        const SizedBox(height: 24),
                        _buildAlertLogsCard(),
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

  Widget _buildStatistics(List<dynamic> data) {
    final stats = _computeStats(data);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Statistiques', Icons.monitor_heart_outlined),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatItem('Min', '${stats.min.toStringAsFixed(1)}°C'),
                _buildStatItem(
                  'Moyenne',
                  '${stats.average.toStringAsFixed(1)}°C',
                ),
                _buildStatItem('Max', '${stats.max.toStringAsFixed(1)}°C'),
                _buildStatItem('Urgences', '${stats.emergencyCount}'),
                _buildStatItem('Mesures', '${data.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }

  Widget _buildMedicalSummary(List<dynamic> data) {
    final stats = _computeStats(data);
    final riskLevel =
        stats.max >= 38.5
            ? 'Élevé'
            : stats.max >= 38.0
            ? 'Modéré'
            : 'Faible';
    final riskColor =
        riskLevel == 'Élevé'
            ? Colors.red
            : riskLevel == 'Modéré'
            ? Colors.orange
            : Colors.green;

    return Card(
      color: Colors.deepPurple.shade50,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Rapport du ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip('Risque: $riskLevel', riskColor),
                _buildStatusChip(
                  'Pic: ${stats.max.toStringAsFixed(1)}°C',
                  Colors.deepPurple,
                ),
                _buildStatusChip(
                  'Urgences: ${stats.emergencyCount}',
                  stats.emergencyCount > 0 ? Colors.red : Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  Widget _buildDemoBanner() {
    return Card(
      color: Colors.amber.shade50,
      elevation: 1,
      child: const Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aucune mesure réelle détectée. Affichage de données statiques de démonstration.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(List<dynamic> data) {
    final latest = data.last;
    final hasHighTemp = data.any((d) => d.temperature >= 38.0);
    final hasEmergency = data.any((d) => d.emergencySignal);
    final recommendations = <Map<String, String>>[
      if (hasHighTemp)
        {
          'level': 'Priorité',
          'text':
              'Hydratez-vous régulièrement et surveillez votre température toutes les 30 minutes.',
        },
      if (hasEmergency)
        {
          'level': 'Urgent',
          'text':
              'Prévenez immédiatement un proche et préparez les informations médicales essentielles.',
        },
      if (!hasHighTemp && !hasEmergency)
        {
          'level': 'Routine',
          'text':
              'Continuez la surveillance quotidienne et maintenez un repos suffisant.',
        },
      {
        'level': 'Routine',
        'text': 'Gardez le bracelet chargé et connecté pour des alertes fiables.',
      },
      {
        'level': 'Conseil',
        'text':
            'Consultez un professionnel de santé si la fièvre persiste au-delà de 24h.',
      },
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommandations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Dernière température: ${latest.temperature.toStringAsFixed(1)}°C',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ...recommendations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _recommendationLevelColor(
                          item['level']!,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['level']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _recommendationLevelColor(item['level']!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item['text']!)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _recommendationLevelColor(String level) {
    switch (level) {
      case 'Urgent':
        return Colors.red;
      case 'Priorité':
        return Colors.orange;
      case 'Conseil':
        return Colors.blue;
      default:
        return Colors.green;
    }
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

  // --- Alert logs UI and helpers (migrated from Settings) ---
  Widget _buildAlertLogsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alertes envoyées: ${_emergencyLogs.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_emergencyLogs.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearEmergencyLogs,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Effacer'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_emergencyLogs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune alerte enregistrée',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _emergencyLogs.length,
                itemBuilder: (context, index) {
                  final log = _emergencyLogs[index];
                  final timestamp = log['timestamp'] as DateTime;
                  final alertType = log['messageType'] as String;
                  final contactName = log['contactName'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: _getAlertColor(alertType),
                          width: 4,
                        ),
                      ),
                      color: _getAlertColor(alertType).withValues(alpha: 0.05),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _formatMessageType(alertType),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getAlertColor(alertType),
                                  ),
                                ),
                              ),
                              Text(
                                '${timestamp.day}/${timestamp.month}/${timestamp.year}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'À: $contactName',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadEmergencyLogs() async {
    var logs = await _databaseService.getEmergencyLogs();
    if (logs.isEmpty) {
      logs = _defaultEmergencyLogs();
    }
    if (mounted) setState(() => _emergencyLogs = logs);
  }

  List<Map<String, dynamic>> _defaultEmergencyLogs() {
    final now = DateTime.now();
    return [
      {
        'contactId': 'demo_contact_1',
        'contactName': 'Maman',
        'messageType': 'temperature',
        'timestamp': now.subtract(const Duration(hours: 2)),
      },
      {
        'contactId': 'demo_contact_2',
        'contactName': 'Papa',
        'messageType': 'emergency',
        'timestamp': now.subtract(const Duration(hours: 6)),
      },
      {
        'contactId': 'demo_contact_1',
        'contactName': 'Maman',
        'messageType': 'movement',
        'timestamp': now.subtract(const Duration(days: 1, hours: 1)),
      },
    ];
  }

  List<_SampleReading> _defaultSensorSamples() {
    final now = DateTime.now();
    return [
      _SampleReading(
        timestamp: now.subtract(const Duration(hours: 5)),
        temperature: 37.2,
        emergencySignal: false,
        motionDetected: true,
      ),
      _SampleReading(
        timestamp: now.subtract(const Duration(hours: 4)),
        temperature: 37.6,
        emergencySignal: false,
        motionDetected: false,
      ),
      _SampleReading(
        timestamp: now.subtract(const Duration(hours: 3)),
        temperature: 38.1,
        emergencySignal: false,
        motionDetected: true,
      ),
      _SampleReading(
        timestamp: now.subtract(const Duration(hours: 2)),
        temperature: 38.4,
        emergencySignal: true,
        motionDetected: true,
      ),
      _SampleReading(
        timestamp: now.subtract(const Duration(hours: 1)),
        temperature: 37.9,
        emergencySignal: false,
        motionDetected: false,
      ),
    ];
  }

  String _formatMessageType(String type) {
    switch (type) {
      case 'temperature':
        return 'Alerte Température';
      case 'emergency':
        return 'Signal d\'Urgence';
      case 'movement':
        return 'Anomalie Mouvement';
      default:
        return type;
    }
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'temperature':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      case 'movement':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _clearEmergencyLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Effacer l\'historique'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer tous les enregistrements d\'alertes ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirm ?? false) {
      await _databaseService.clearEmergencyLogs();
      await _loadEmergencyLogs();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Historique supprimé')));
      }
    }
  }
}

_HistoryStats _computeStats(List<dynamic> data) {
  var minTemp = data[0].temperature as double;
  var maxTemp = data[0].temperature as double;
  var sum = 0.0;
  var emergencyCount = 0;

  for (final reading in data) {
    if (reading.temperature < minTemp) minTemp = reading.temperature;
    if (reading.temperature > maxTemp) maxTemp = reading.temperature;
    sum += reading.temperature as double;
    if (reading.emergencySignal) emergencyCount++;
  }

  return _HistoryStats(
    min: minTemp,
    max: maxTemp,
    average: sum / data.length,
    emergencyCount: emergencyCount,
  );
}

class _HistoryStats {
  final double min;
  final double max;
  final double average;
  final int emergencyCount;

  _HistoryStats({
    required this.min,
    required this.max,
    required this.average,
    required this.emergencyCount,
  });
}

class _SampleReading {
  final DateTime timestamp;
  final double temperature;
  final bool emergencySignal;
  final bool motionDetected;

  _SampleReading({
    required this.timestamp,
    required this.temperature,
    required this.emergencySignal,
    required this.motionDetected,
  });
}
