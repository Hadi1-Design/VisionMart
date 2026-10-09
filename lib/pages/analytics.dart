import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';
import 'package:vision_app/pages/alert_service.dart';
import 'package:vision_app/services/analytics_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _selectedTab = 0;

  // ── Daily streams — cached once in initState so StreamBuilder never
  //    receives a new stream reference on rebuild (prevents flicker).
  late final Stream<int> _dailyVisitorStream;
  late final Stream<List<FlSpot>> _dailyVisitorSpotsStream;

  // Weekly/Monthly futures — lazily created when tab is first selected,
  // and refreshed on pull-to-refresh. Never opened for Daily tab.
  Future<AnalyticsSummary>? _weeklyFuture;
  Future<AnalyticsSummary>? _monthlyFuture;

  // ── Daily label lists (used for chart x-axis) ──────────────────────────
  // Shows only every 4th hour for readability (0, 4, 8, 12, 16, 20)
  static List<String> get _dailyHourLabels =>
      List.generate(24, (i) => (i % 4 == 0) ? '${i}h' : '');

  static const List<String> _weeklyLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const List<String> _monthlyLabels = ['W1', 'W2', 'W3', 'W4'];

  @override
  void initState() {
    super.initState();
    // Cache streams once — stable references prevent StreamBuilder flicker
    _dailyVisitorStream = AnalyticsService.instance.dailyVisitorsStream;
    _dailyVisitorSpotsStream = AnalyticsService.instance.dailyVisitorSpotsStream;
  }

  // ── Tab selection ──────────────────────────────────────────────────────
  void _onTabSelect(int index) {
    setState(() {
      _selectedTab = index;
      if (index == 1) _weeklyFuture ??= AnalyticsService.instance.fetchWeeklySummary();
      if (index == 2) _monthlyFuture ??= AnalyticsService.instance.fetchMonthlySummary();
    });
  }

  // ── Pull-to-refresh ────────────────────────────────────────────────────
  Future<void> _onRefresh() async {
    setState(() {
      if (_selectedTab == 1) {
        _weeklyFuture = AnalyticsService.instance.fetchWeeklySummary();
      } else if (_selectedTab == 2) {
        _monthlyFuture = AnalyticsService.instance.fetchMonthlySummary();
      }
    });
    await Future.delayed(const Duration(milliseconds: 600));
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  DateTime get _todayMidnight {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }


  /// Build hourly FlSpots for today's alert chart from in-memory AlertService.
  List<FlSpot> get _todayAlertSpots {
    final midnight = _todayMidnight;
    final Map<int, int> hourBuckets = {};
    for (final a in AlertService.instance.alerts.value) {
      if (a.createdAt.isAfter(midnight)) {
        final h = a.createdAt.hour;
        hourBuckets[h] = (hourBuckets[h] ?? 0) + 1;
      }
    }
    return List.generate(
      24,
      (i) => FlSpot(i.toDouble(), (hourBuckets[i] ?? 0).toDouble()),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          backgroundColor: AppColors.card,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATA · INSIGHTS',
                          style: AppTextStyles.body(
                            fontSize: 10,
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.bold,
                          ).copyWith(letterSpacing: 2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Analytics',
                          style: AppTextStyles.heading(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _headerIconButton(LucideIcons.download),
                  ],
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 24),

                // ── STAT CARDS ───────────────────────────────────────────
                _buildStatCards()
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // ── PERIOD SELECTOR ──────────────────────────────────────
                Center(
                  child: GlassCard(
                    padding: const EdgeInsets.all(4),
                    borderRadius: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _selectorItem('Daily', 0),
                        _selectorItem('Weekly', 1),
                        _selectorItem('Monthly', 2),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 24),

                // ── VISITOR TREND ────────────────────────────────────────
                _sectionTitle('VISITOR TREND', LucideIcons.trendingUp),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(10, 24, 24, 16),
                  child: SizedBox(
                    height: 220,
                    child: _buildVisitorChart(),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // ── ALERT TREND ──────────────────────────────────────────
                _sectionTitle('ALERT FREQUENCY', LucideIcons.alertCircle),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(10, 24, 24, 16),
                  child: SizedBox(
                    height: 220,
                    child: _buildAlertChart(),
                  ),
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── STAT CARDS BUILDER ──────────────────────────────────────────────────
  Widget _buildStatCards() {
    // DAILY — live streams / in-memory data
    if (_selectedTab == 0) {
      return Row(
        children: [
          Expanded(
            child: StreamBuilder<int>(
              stream: _dailyVisitorStream,
              builder: (_, snap) {
                final count = snap.data ?? 0;
                return _statCard(
                  'Total Visitors',
                  _formatCount(count),
                  LucideIcons.users,
                  AppGradients.indigo,
                  isLoading: snap.connectionState == ConnectionState.waiting,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ValueListenableBuilder<List<AlertItem>>(
              valueListenable: AlertService.instance.alerts,
              builder: (_, alerts, __) {
                final midnight = _todayMidnight;
                final count = alerts.where((a) => a.createdAt.isAfter(midnight)).length;
                return _statCard(
                  'Total Alerts',
                  count.toString(),
                  LucideIcons.shieldAlert,
                  AppGradients.warning,
                );
              },
            ),
          ),
        ],
      );
    }

    // WEEKLY / MONTHLY — FutureBuilder
    final future =
        _selectedTab == 1 ? _weeklyFuture : _monthlyFuture;

    return FutureBuilder<AnalyticsSummary>(
      future: future,
      builder: (_, snap) {
        final isLoading = snap.connectionState == ConnectionState.waiting ||
            snap.connectionState == ConnectionState.none;
        final data = snap.data;
        return Row(
          children: [
            Expanded(
              child: _statCard(
                'Total Visitors',
                isLoading ? '...' : _formatCount(data?.totalVisitors ?? 0),
                LucideIcons.users,
                AppGradients.indigo,
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                'Total Alerts',
                isLoading ? '...' : (data?.totalAlerts ?? 0).toString(),
                LucideIcons.shieldAlert,
                AppGradients.warning,
                isLoading: isLoading,
              ),
            ),
          ],
        );
      },
    );
  }

  // ── VISITOR CHART BUILDER ───────────────────────────────────────────────
  Widget _buildVisitorChart() {
    if (_selectedTab == 0) {
      // Daily — live stream from 2minlogic (cached stream ref)
      return StreamBuilder<List<FlSpot>>(
        stream: _dailyVisitorSpotsStream,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _chartLoading();
          }
          final spots = snap.data ??
              List.generate(24, (i) => FlSpot(i.toDouble(), 0));
          return VisitorTrendChart(
            data: spots,
            labels: _dailyHourLabels,
            isVisitorChart: true,
          );
        },
      );
    }

    final future = _selectedTab == 1 ? _weeklyFuture : _monthlyFuture;
    final labels = _selectedTab == 1 ? _weeklyLabels : _monthlyLabels;

    return FutureBuilder<AnalyticsSummary>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting ||
            snap.connectionState == ConnectionState.none) {
          return _chartLoading();
        }
        final spots = snap.data?.visitorSpots ??
            List.generate(labels.length, (i) => FlSpot(i.toDouble(), 0));
        return VisitorTrendChart(
          data: spots,
          labels: labels,
          isVisitorChart: true,
        );
      },
    );
  }

  // ── ALERT CHART BUILDER ────────────────────────────────────────────────
  Widget _buildAlertChart() {
    if (_selectedTab == 0) {
      // Daily — derived from in-memory AlertService (no new listener)
      return ValueListenableBuilder<List<AlertItem>>(
        valueListenable: AlertService.instance.alerts,
        builder: (_, __, ___) {
          return VisitorTrendChart(
            data: _todayAlertSpots,
            labels: _dailyHourLabels,
            isVisitorChart: false,
          );
        },
      );
    }

    final future = _selectedTab == 1 ? _weeklyFuture : _monthlyFuture;
    final labels = _selectedTab == 1 ? _weeklyLabels : _monthlyLabels;

    return FutureBuilder<AnalyticsSummary>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting ||
            snap.connectionState == ConnectionState.none) {
          return _chartLoading();
        }
        final spots = snap.data?.alertSpots ??
            List.generate(labels.length, (i) => FlSpot(i.toDouble(), 0));
        return VisitorTrendChart(
          data: spots,
          labels: labels,
          isVisitorChart: false,
        );
      },
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────

  /// Formats a number: e.g. 9800 → "9.8K", 150 → "150"
  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _chartLoading() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.primary,
      ),
    );
  }

  Widget _headerIconButton(IconData icon) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(10),
      child: Icon(icon, size: 20, color: Colors.white),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Gradient gradient, {
    bool isLoading = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isLoading
                  ? SizedBox(
                      width: 40,
                      height: 16,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white10,
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : Text(
                      value,
                      style: AppTextStyles.heading(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              Text(
                title,
                style: AppTextStyles.body(
                  fontSize: 9,
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selectorItem(String label, int index) {
    final isSelected = _selectedTab == index;
    return AnimatedTouchable(
      onTap: () => _onTabSelect(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTextStyles.body(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedForeground),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.body(
            fontSize: 10,
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.bold,
          ).copyWith(letterSpacing: 2),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CHART WIDGET (unchanged logic, same as before)
// ─────────────────────────────────────────────

class VisitorTrendChart extends StatelessWidget {
  final List<FlSpot> data;
  final List<String> labels;
  final bool isVisitorChart;

  const VisitorTrendChart({
    super.key,
    required this.data,
    required this.labels,
    required this.isVisitorChart,
  });

  @override
  Widget build(BuildContext context) {
    // If all values are 0, show a flat line and prevent division-by-zero
    final maxY = data.map((e) => e.y).fold<double>(0, (a, b) => a > b ? a : b);
    final double gridInterval = maxY > 0 ? maxY / 4 : 1.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: gridInterval,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: gridInterval,
              getTitlesWidget: (value, _) => Text(
                isVisitorChart
                    ? (value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toInt().toString())
                    : value.toInt().toString(),
                style: AppTextStyles.body(
                  fontSize: 9,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) return const Text('');
                return Text(
                  labels[index],
                  style: AppTextStyles.body(
                    fontSize: 9,
                    color: AppColors.mutedForeground,
                  ),
                );
              },
            ),
          ),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            barWidth: 3,
            gradient:
                isVisitorChart ? AppGradients.indigo : AppGradients.warning,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: isVisitorChart
                    ? AppColors.primary
                    : AppColors.warning,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isVisitorChart ? AppColors.primary : AppColors.warning)
                      .withValues(alpha: 0.2),
                  (isVisitorChart ? AppColors.primary : AppColors.warning)
                      .withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      s.y.toInt().toString(),
                      AppTextStyles.body(fontWeight: FontWeight.bold),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
