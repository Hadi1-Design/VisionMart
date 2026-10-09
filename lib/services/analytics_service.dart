import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────

class AnalyticsSummary {
  final int totalVisitors;
  final int totalAlerts;
  final List<FlSpot> visitorSpots;
  final List<FlSpot> alertSpots;
  final List<String> labels;

  const AnalyticsSummary({
    required this.totalVisitors,
    required this.totalAlerts,
    required this.visitorSpots,
    required this.alertSpots,
    required this.labels,
  });

  /// Empty/fallback summary for a given tab (0=daily,1=weekly,2=monthly)
  factory AnalyticsSummary.empty(int tab) {
    if (tab == 1) {
      return AnalyticsSummary(
        totalVisitors: 0,
        totalAlerts: 0,
        visitorSpots: List.generate(7, (i) => FlSpot(i.toDouble(), 0)),
        alertSpots: List.generate(7, (i) => FlSpot(i.toDouble(), 0)),
        labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      );
    } else {
      return AnalyticsSummary(
        totalVisitors: 0,
        totalAlerts: 0,
        visitorSpots: List.generate(4, (i) => FlSpot(i.toDouble(), 0)),
        alertSpots: List.generate(4, (i) => FlSpot(i.toDouble(), 0)),
        labels: const ['W1', 'W2', 'W3', 'W4'],
      );
    }
  }
}

// ─────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final _db = FirebaseFirestore.instance;

  // ── helpers ──────────────────────────────────
  String get _todayStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ── DAILY: live stream of today's in_count ────
  /// Live stream of today's total in_count from VirtualLineCount/counter_1.
  /// Reuses the same collection already listened to by PeopleCountService,
  /// so no extra listener cost — Firestore deduplicates identical listeners.
  Stream<int> get dailyVisitorsStream {
    return _db
        .collection('VirtualLineCount')
        .doc('counter_1')
        .snapshots()
        .map((snap) {
      final data = snap.data();
      return (data?['in_count'] as num?)?.toInt() ?? 0;
    }).handleError((e) {
      debugPrint('AnalyticsService dailyVisitorsStream error: $e');
      return 0;
    });
  }

  // ── DAILY: hourly visitor spots from 2minlogic ─
  /// Returns hourly visitor FlSpots for today (24 points, one per hour).
  /// Uses 2minlogic collection which is already queried by PeakHourService.
  Stream<List<FlSpot>> get dailyVisitorSpotsStream {
    final todayStr = _todayStr;
    return _db
        .collection('2minlogic')
        .where(
          FieldPath.documentId,
          isGreaterThanOrEqualTo: '${todayStr}_00-00-00',
        )
        .where(
          FieldPath.documentId,
          isLessThanOrEqualTo: '${todayStr}_23-59-59',
        )
        .snapshots()
        .map((snap) {
      final Map<int, int> hourBuckets = {};
      for (var doc in snap.docs) {
        final parts = doc.id.split('_');
        if (parts.length == 2) {
          final timeParts = parts[1].split('-');
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final intervalIn =
              (doc.data()['interval_in'] as num?)?.toInt() ?? 0;
          hourBuckets[hour] = (hourBuckets[hour] ?? 0) + intervalIn;
        }
      }
      // Build 24 spots; hours with no data get 0
      return List.generate(
        24,
        (i) => FlSpot(i.toDouble(), (hourBuckets[i] ?? 0).toDouble()),
      );
    }).handleError((e) {
      debugPrint('AnalyticsService dailyVisitorSpotsStream error: $e');
      return List.generate(24, (i) => FlSpot(i.toDouble(), 0));
    });
  }

  // ── WEEKLY: one-time Future ───────────────────
  /// Fetches visitor + alert data for the current week (Mon–today).
  /// Uses Count_History (archived days) + VirtualLineCount (today live).
  Future<AnalyticsSummary> fetchWeeklySummary() async {
    try {
      final now = DateTime.now();
      final weekday = now.weekday; // 1=Mon … 7=Sun
      final weekStart = DateTime(now.year, now.month, now.day - (weekday - 1));
      final weekStartStr = DateFormat('yyyy-MM-dd').format(weekStart);
      final todayStr = _todayStr;

      // ── 1. Count_History for Mon → yesterday ──
      final historySnap = await _db
          .collection('Count_History')
          .where(
            FieldPath.documentId,
            isGreaterThanOrEqualTo: weekStartStr,
          )
          .where(
            FieldPath.documentId,
            isLessThan: todayStr, // exclude today (it's in VirtualLineCount)
          )
          .get();

      // ── 2. Today's live in_count ───────────────
      final todaySnap =
          await _db.collection('VirtualLineCount').doc('counter_1').get();
      final todayIn = (todaySnap.data()?['in_count'] as num?)?.toInt() ?? 0;

      // ── 3. Build visitor spots (0=Mon … 6=Sun) ─
      final visitorBuckets = <int, int>{};
      int totalVisitors = todayIn;
      visitorBuckets[weekday - 1] = todayIn; // today's slot

      for (var doc in historySnap.docs) {
        try {
          final parts = doc.id.split('-');
          final docDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          final dayIndex = docDate.weekday - 1;
          final totalIn = (doc.data()['total_in'] as num?)?.toInt() ?? 0;
          visitorBuckets[dayIndex] = totalIn;
          totalVisitors += totalIn;
        } catch (e) {
          debugPrint('AnalyticsService: error parsing Count_History doc: $e');
        }
      }

      final visitorSpots = List.generate(
        7,
        (i) => FlSpot(i.toDouble(), (visitorBuckets[i] ?? 0).toDouble()),
      );

      // ── 4. Alerts for this week ────────────────
      final weekStartTs = Timestamp.fromDate(weekStart);
      final List<String> weaponTypes = ['Grenade', 'Knife', 'Missile', 'Pistol', 'Rifle'];

      final results = await Future.wait([
        _db
            .collection('WeaponDetections')
            .where('timestamp', isGreaterThanOrEqualTo: weekStartTs)
            .get(),
        ...weaponTypes.map((type) => _db
            .collection('WeaponDetections')
            .doc(type)
            .collection('alerts')
            .where('timestamp', isGreaterThanOrEqualTo: weekStartTs)
            .get()),
        _db
            .collection('shoplifting_incidents')
            .where('timestamp', isGreaterThanOrEqualTo: weekStartTs)
            .get(),
      ]);

      final alertBuckets = <int, int>{};
      for (var snap in results) {
        for (var doc in snap.docs) {
          final ts = doc.data()['timestamp'];
          if (ts is Timestamp) {
            final dayIndex = ts.toDate().weekday - 1;
            alertBuckets[dayIndex] = (alertBuckets[dayIndex] ?? 0) + 1;
          }
        }
      }

      final totalAlerts = results.fold<int>(0, (sum, snap) => sum + snap.docs.length);

      final alertSpots = List.generate(
        7,
        (i) => FlSpot(i.toDouble(), (alertBuckets[i] ?? 0).toDouble()),
      );

      return AnalyticsSummary(
        totalVisitors: totalVisitors,
        totalAlerts: totalAlerts,
        visitorSpots: visitorSpots,
        alertSpots: alertSpots,
        labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      );
    } catch (e) {
      debugPrint('AnalyticsService fetchWeeklySummary error: $e');
      return AnalyticsSummary.empty(1);
    }
  }

  // ── MONTHLY: one-time Future ──────────────────
  /// Fetches visitor + alert data for the current month, grouped into 4 weekly buckets.
  Future<AnalyticsSummary> fetchMonthlySummary() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthStartStr = DateFormat('yyyy-MM-dd').format(monthStart);
      final todayStr = _todayStr;

      // ── 1. Count_History for this month → yesterday ──
      final historySnap = await _db
          .collection('Count_History')
          .where(
            FieldPath.documentId,
            isGreaterThanOrEqualTo: monthStartStr,
          )
          .where(
            FieldPath.documentId,
            isLessThan: todayStr,
          )
          .get();

      // ── 2. Today's live count ─────────────────
      final todaySnap =
          await _db.collection('VirtualLineCount').doc('counter_1').get();
      final todayIn = (todaySnap.data()?['in_count'] as num?)?.toInt() ?? 0;

      // ── 3. Group into W1-W4 (day 1-7 = W1, 8-14 = W2, 15-21 = W3, 22+ = W4)
      int weekIndex(int day) {
        if (day <= 7) return 0;
        if (day <= 14) return 1;
        if (day <= 21) return 2;
        return 3;
      }

      final visitorBuckets = <int, int>{};
      int totalVisitors = todayIn;
      visitorBuckets[weekIndex(now.day)] =
          (visitorBuckets[weekIndex(now.day)] ?? 0) + todayIn;

      for (var doc in historySnap.docs) {
        try {
          final parts = doc.id.split('-');
          final day = int.parse(parts[2]);
          final totalIn = (doc.data()['total_in'] as num?)?.toInt() ?? 0;
          final wi = weekIndex(day);
          visitorBuckets[wi] = (visitorBuckets[wi] ?? 0) + totalIn;
          totalVisitors += totalIn;
        } catch (e) {
          debugPrint('AnalyticsService: error parsing monthly doc: $e');
        }
      }

      final visitorSpots = List.generate(
        4,
        (i) => FlSpot(i.toDouble(), (visitorBuckets[i] ?? 0).toDouble()),
      );

      // ── 4. Alerts for this month ──────────────
      final monthStartTs = Timestamp.fromDate(monthStart);
      final List<String> weaponTypes = ['Grenade', 'Knife', 'Missile', 'Pistol', 'Rifle'];

      final results = await Future.wait([
        _db
            .collection('WeaponDetections')
            .where('timestamp', isGreaterThanOrEqualTo: monthStartTs)
            .get(),
        ...weaponTypes.map((type) => _db
            .collection('WeaponDetections')
            .doc(type)
            .collection('alerts')
            .where('timestamp', isGreaterThanOrEqualTo: monthStartTs)
            .get()),
        _db
            .collection('shoplifting_incidents')
            .where('timestamp', isGreaterThanOrEqualTo: monthStartTs)
            .get(),
      ]);

      final alertBuckets = <int, int>{};
      for (var snap in results) {
        for (var doc in snap.docs) {
          final ts = doc.data()['timestamp'];
          if (ts is Timestamp) {
            final wi = weekIndex(ts.toDate().day);
            alertBuckets[wi] = (alertBuckets[wi] ?? 0) + 1;
          }
        }
      }

      final totalAlerts = results.fold<int>(0, (sum, snap) => sum + snap.docs.length);

      final alertSpots = List.generate(
        4,
        (i) => FlSpot(i.toDouble(), (alertBuckets[i] ?? 0).toDouble()),
      );

      return AnalyticsSummary(
        totalVisitors: totalVisitors,
        totalAlerts: totalAlerts,
        visitorSpots: visitorSpots,
        alertSpots: alertSpots,
        labels: const ['W1', 'W2', 'W3', 'W4'],
      );
    } catch (e) {
      debugPrint('AnalyticsService fetchMonthlySummary error: $e');
      return AnalyticsSummary.empty(2);
    }
  }
}
