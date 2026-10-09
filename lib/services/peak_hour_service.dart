import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Model class to represent a 60-minute window for stats
class HourlyStat {
  final int hour; // 0-23
  final int count;

  HourlyStat({required this.hour, required this.count});

  String get label {
    final dt = DateTime(2024, 1, 1, hour);
    return DateFormat('h a').format(dt);
  }
}

/// Model class to represent peak hour data
class PeakHourData {
  final String timeRange; // e.g., "5:00-6:00 PM"
  final int visitorCount; // Total people who entered in this hour
  final DateTime startTime;
  final int totalVisitors;
  final double avgVisitors;
  final double peakCapacity; // Percentage 0-100
  final String status;
  final String trend;

  PeakHourData({
    required this.timeRange,
    required this.visitorCount,
    required this.startTime,
    required this.totalVisitors,
    required this.avgVisitors,
    required this.peakCapacity,
    required this.status,
    required this.trend,
  });
}

/// Service to fetch and calculate peak hour and hourly trends
class PeakHourService {
  PeakHourService._();
  static final PeakHourService instance = PeakHourService._();

  /// Group 2-minute intervals into date-wise hourly buckets
  Map<String, Map<int, int>> _aggregateByDate(QuerySnapshot snapshot) {
    final Map<String, Map<int, int>> dateWiseBuckets = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final intervalIn = (data['interval_in'] as num?)?.toInt() ?? 0;
      final docId = doc.id; // e.g., "2026-02-05_17-30-00"

      try {
        final parts = docId.split('_');
        if (parts.length == 2) {
          final dateStr = parts[0]; // "2026-02-05"
          final timeParts = parts[1].split('-');
          final hour = int.parse(timeParts[0]);

          dateWiseBuckets.putIfAbsent(dateStr, () => {});
          dateWiseBuckets[dateStr]![hour] = (dateWiseBuckets[dateStr]![hour] ?? 0) + intervalIn;
        }
      } catch (e) {
        debugPrint('Error parsing docId $docId: $e');
      }
    }
    return dateWiseBuckets;
  }

  /// Stream of hourly statistics for the bar chart (based on latest available date)
  late final Stream<List<HourlyStat>> hourlyStatsStream = () {
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    return FirebaseFirestore.instance
        .collection('2minlogic')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: "${yesterdayStr}_00-00-00")
        .snapshots()
        .map((snapshot) {
      final dateWise = _aggregateByDate(snapshot);
      if (dateWise.isEmpty) return List.generate(24, (i) => HourlyStat(hour: i, count: 0));

      final sortedDates = dateWise.keys.toList()..sort((a, b) => b.compareTo(a));
      final latestDate = sortedDates.first;
      final aggregated = dateWise[latestDate]!;

      final List<HourlyStat> stats = [];
      for (int i = 0; i < 24; i++) {
        stats.add(HourlyStat(hour: i, count: aggregated[i] ?? 0));
      }
      return stats;
    });
  }().asBroadcastStream();

  /// Stream that emits the current peak hour data and comparisons
  late final Stream<PeakHourData> peakHourStream = () {
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    return FirebaseFirestore.instance
        .collection('2minlogic')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: "${yesterdayStr}_00-00-00")
        .snapshots()
        .map((snapshot) {
      final dateWise = _aggregateByDate(snapshot);
      
      if (dateWise.isEmpty) {
        return PeakHourData(
          timeRange: "--:--",
          visitorCount: 0,
          startTime: DateTime.now(),
          totalVisitors: 0,
          avgVisitors: 0,
          peakCapacity: 0,
          status: "No Data",
          trend: "0%",
        );
      }

      final sortedDates = dateWise.keys.toList()..sort((a, b) => b.compareTo(a));
      final latestDateStr = sortedDates.first;
      final currentData = dateWise[latestDateStr]!;
      
      // Calculate current stats
      int currentTotal = 0;
      int activeHours = 0;
      int peakHour = 0;
      int maxVisitors = 0;

      currentData.forEach((hour, count) {
        currentTotal += count;
        if (count > 0) activeHours++;
        if (count > maxVisitors) {
          maxVisitors = count;
          peakHour = hour;
        }
      });

      // Comparison with previous day
      String trend = "0%";
      if (sortedDates.length > 1) {
        final prevDateStr = sortedDates[1];
        final prevData = dateWise[prevDateStr]!;
        int prevTotal = 0;
        prevData.forEach((_, count) => prevTotal += count);
        
        if (prevTotal > 0) {
          final diff = ((currentTotal - prevTotal) / prevTotal) * 100;
          trend = "${diff > 0 ? '+' : ''}${diff.toInt()}% vs yesterday";
        }
      }

      final avgVisitors = currentTotal / (activeHours > 0 ? activeHours : 1);
      const maxCapacity = 200; 
      final peakCapacity = (maxVisitors / maxCapacity) * 100;
      
      String status = "Normal";
      if (peakCapacity > 80) status = "Critical";
      else if (peakCapacity > 50) status = "High Traffic";

      // Parse the latest date for startTime
      final dateParts = latestDateStr.split('-');
      final startTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        peakHour,
      );
      final endTime = startTime.add(const Duration(hours: 1));
      final formatter = DateFormat('h:mm a');

      return PeakHourData(
        timeRange: '${formatter.format(startTime)} - ${formatter.format(endTime)}',
        visitorCount: maxVisitors,
        startTime: startTime,
        totalVisitors: currentTotal,
        avgVisitors: avgVisitors,
        peakCapacity: peakCapacity > 100 ? 100 : peakCapacity,
        status: status,
        trend: trend,
      );
    });
  }().asBroadcastStream();
}
