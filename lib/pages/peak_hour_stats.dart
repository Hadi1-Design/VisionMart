import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';
import 'package:vision_app/services/peak_hour_service.dart';

class PeakHourStatsPage extends StatelessWidget {
  const PeakHourStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppGradients.mesh),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeakHourHighlight(),
                        const SizedBox(height: 24),
                        _buildHourlyChartSection(),
                        const SizedBox(height: 24),
                        _buildMetricsGrid(),
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Center(
          child: AnimatedTouchable(
            onTap: () => Navigator.pop(context),
            child: GlassCard(
              borderRadius: 12,
              padding: const EdgeInsets.all(8),
              child: const Icon(LucideIcons.chevronLeft, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
      title: Text(
        "Peak Hour Insights",
        style: AppTextStyles.heading(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      floating: true,
    );
  }

  Widget _buildPeakHourHighlight() {
    return StreamBuilder<PeakHourData>(
      stream: PeakHourService.instance.peakHourStream,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return GlassCard(
          padding: const EdgeInsets.all(24),
          showGlow: true,
          glowColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppGradients.purpleGlow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.crown, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PEAK VISITOR HOUR",
                        style: AppTextStyles.body(
                          fontSize: 10,
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.bold,
                        ).copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data?.timeRange ?? "Loading...",
                        style: AppTextStyles.heading(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoItem("Volume", "${data?.visitorCount ?? 0} people"),
                  _infoItem("Status", data?.status ?? "Normal"),
                  _infoItem("Trend", data?.trend ?? "0%"),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
      },
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.body(fontSize: 9, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHourlyChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "HOURLY DISTRIBUTION",
          style: AppTextStyles.body(
            fontSize: 11,
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.bold,
          ).copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Column(
            children: [
              SizedBox(
                height: 240,
                child: StreamBuilder<List<HourlyStat>>(
                  stream: PeakHourService.instance.hourlyStatsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final stats = snapshot.data!;
                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(stats),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${stats[group.x.toInt()].count} people',
                                AppTextStyles.body(fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final hour = value.toInt();
                                if (hour % 4 == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      stats[hour].label.split(' ')[0],
                                      style: AppTextStyles.body(
                                        fontSize: 9,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: AppTextStyles.body(
                                    fontSize: 9,
                                    color: AppColors.mutedForeground,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: stats.map((s) {
                          return BarChartGroupData(
                            x: s.hour,
                            barRods: [
                              BarChartRodData(
                                toY: s.count.toDouble(),
                                gradient: AppGradients.indigo,
                                width: 8,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: _getMaxY(stats),
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem("Visitor Volume", AppColors.primary),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  double _getMaxY(List<HourlyStat> stats) {
    if (stats.isEmpty) return 100;
    final max = stats.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    return (max * 1.2).clamp(10, double.infinity);
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.body(fontSize: 10, color: AppColors.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return StreamBuilder<PeakHourData>(
      stream: PeakHourService.instance.peakHourStream,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _miniMetricCard("AVG VISITORS", "${data?.avgVisitors.toInt() ?? 0}", LucideIcons.lineChart, AppGradients.electric),
            _miniMetricCard("PEAK CAPACITY", "${data?.peakCapacity.toInt() ?? 0}%", LucideIcons.pieChart, AppGradients.tealGlow),
          ],
        );
      },
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _miniMetricCard(String label, String value, IconData icon, Gradient gradient) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.body(
                  fontSize: 9,
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, size: 14, color: AppColors.mutedForeground),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.heading(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
