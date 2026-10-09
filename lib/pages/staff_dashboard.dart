import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';
import 'package:vision_app/widgets/custom_nav_bar.dart';
import 'package:vision_app/pages/roi.dart';
import 'package:vision_app/pages/suspicious_activity.dart';
import 'alerts.dart';
import 'settings.dart';
import 'package:vision_app/pages/alert_service.dart';
import 'package:vision_app/pages/weapon_alerts.dart';
import 'package:vision_app/services/people_count_service.dart';
import 'package:vision_app/services/presence_service.dart';
import 'package:vision_app/services/connectivity_service.dart';
import 'package:vision_app/services/peak_hour_service.dart';
import 'package:vision_app/pages/peak_hour_stats.dart';

class StaffDashboardPage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const StaffDashboardPage({super.key, required this.onThemeChanged});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Staff pages: Home, Alerts, Settings
    final List<Widget> pages = [
      const _StaffDashboardHome(),
      const AlertsPage(),
      SettingsPage(onThemeChanged: widget.onThemeChanged, isAdmin: false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppGradients.mesh),
            ),
          ),
          IndexedStack(index: _currentIndex, children: pages),
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomNavBar(
              currentIndex: _currentIndex,
              isStaff: true,
              onTap: _onTabTapped,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffDashboardHome extends StatefulWidget {
  const _StaffDashboardHome();

  @override
  State<_StaffDashboardHome> createState() => _StaffDashboardHomeState();
}

class _StaffDashboardHomeState extends State<_StaffDashboardHome> {
  @override
  void initState() {
    super.initState();
    AlertService.instance.startListeningToWeapons();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      backgroundColor: AppColors.card,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: ConnectivityService.instance.isOnline,
                      builder: (context, isOnline, _) {
                        return Row(
                          children: [
                            Text(
                              isOnline
                                  ? "VisionMart · Live"
                                  : "VisionMart · Offline",
                              style: AppTextStyles.body(
                                fontSize: 10,
                                color: AppColors.mutedForeground,
                                fontWeight: FontWeight.bold,
                              ).copyWith(letterSpacing: 2),
                            ),
                            const SizedBox(width: 6),
                            Container(
                                  height: 6,
                                  width: 6,
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? AppColors.destructive
                                        : AppColors.mutedForeground,
                                    shape: BoxShape.circle,
                                  ),
                                )
                                .animate(
                                  onPlay: (c) {
                                    if (isOnline) c.repeat();
                                  },
                                )
                                .fadeIn(duration: 400.ms)
                                .fadeOut(duration: 400.ms),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Staff Dashboard",
                      style: AppTextStyles.heading(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

              ],
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // --- BENTO STATS GRID ---
            const RepaintBoundary(
              child: _StatsGrid(),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            // --- QUICK ACTIONS (NOW ABOVE PRIMARY FEED) ---
            Text(
              "QUICK ACTIONS",
              style: AppTextStyles.body(
                fontSize: 11,
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.bold,
              ).copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            RepaintBoundary(child: _buildQuickActions(context)),

            const SizedBox(height: 24),

            // --- RECENT ALERTS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "RECENT ALERTS",
                  style: AppTextStyles.body(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.bold,
                  ).copyWith(letterSpacing: 2),
                ),
                AnimatedTouchable(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const AlertsPage()),
                  ),
                  child: Text(
                    "VIEW ALL",
                    style: AppTextStyles.body(
                      fontSize: 10,
                      color: AppColors.primaryGlow,
                      fontWeight: FontWeight.bold,
                    ).copyWith(letterSpacing: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const RepaintBoundary(child: _RecentAlertList()),
          ],
        ),
      ),
    );
  }


  Widget _buildQuickActions(BuildContext context) {
    return ValueListenableBuilder<List<AlertItem>>(
      valueListenable: AlertService.instance.alerts,
      builder: (context, alerts, _) {
        final suspiciousCount = alerts
            .where((a) => a.source == 'shoplifting')
            .length;
        final weaponCount = alerts.where((a) => a.source == 'weapon').length;

        return Column(
          children: [
            _bigActionCard(
              context,
              "Suspicious Activity",
              "AI-flagged behaviour patterns.",
              LucideIcons.shieldAlert,
              AppGradients.orangeGlow,
              const SuspiciousActivityPage(),
              suspiciousCount.toString(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _smallActionCard(
                    context,
                    "ROI Mgmt.",
                    "Zone scanning.",
                    LucideIcons.focus,
                    AppGradients.purpleGlow,
                    const ROIPage(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _smallActionCard(
                    context,
                    "Weapon Alerts",
                    "Threat scan.",
                    LucideIcons.swords,
                    AppGradients.warning,
                    const WeaponAlertsPage(),
                    weaponCount.toString(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _bigActionCard(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    Gradient gradient,
    Widget page,
    String badge,
  ) {
    return AnimatedTouchable(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (c) => page)),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: AppTextStyles.body(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: AppTextStyles.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallActionCard(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    Gradient gradient,
    Widget page, [
    String? badge,
  ]) {
    return AnimatedTouchable(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (c) => page)),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: AppTextStyles.body(
                fontSize: 10,
                color: AppColors.mutedForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// --- REPAINT-ISOLATED WIDGETS ---

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        AnimatedTouchable(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const PeakHourStatsPage()),
          ),
          child: _buildStatCard(
            "LIVE COUNT",
            stream: PeopleCountService.instance.peopleCountStream,
            icon: LucideIcons.users,
            gradient: AppGradients.purpleGlow,
            detail: "+12.4%",
            subDetail: "vs last hour",
            showHint: true,
          ),
        ),
        ValueListenableBuilder<List<AlertItem>>(
          valueListenable: AlertService.instance.alerts,
          builder: (context, alerts, _) {
            final bool isSecure = alerts.isEmpty;
            return _buildStatCard(
              "PRIORITY ALERTS",
              value: isSecure ? "00" : alerts.length.toString().padLeft(2, '0'),
              icon: LucideIcons.shieldAlert,
              gradient: isSecure ? AppGradients.success : AppGradients.warning,
              detail: isSecure ? "0 new" : "+${alerts.length} new",
              subDetail: "vs last hour",
              isGlowing: !isSecure,
            );
          },
        ),
        StreamBuilder<int>(
          stream: PresenceService.instance.activeNodesStream,
          initialData: 1,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 1;
            return _buildStatCard(
              "ACTIVE NODES",
              value: count.toString().padLeft(2, '0'),
              icon: LucideIcons.wifi,
              gradient: AppGradients.electric,
              detail: count > 0 ? "System Nom." : "Check Conn.",
              subDetail: "Live status",
            );
          },
        ),
        StreamBuilder<PeakHourData>(
          stream: PeakHourService.instance.peakHourStream,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return _buildStatCard(
              "FOOTFALL TODAY",
              value: data != null ? data.totalVisitors.toString() : "...",
              icon: LucideIcons.trendingUp,
              gradient: AppGradients.tealGlow,
              detail: data?.trend.split(' ')[0] ?? "0%",
              subDetail: data?.trend.contains('yesterday') ?? false
                  ? "vs yesterday"
                  : "vs last hour",
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label, {
    Stream<int>? stream,
    String? value,
    required IconData icon,
    required Gradient gradient,
    required String detail,
    required String subDetail,
    bool isGlowing = false,
    bool showHint = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      showGlow: isGlowing,
      glowColor: AppColors.destructive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (showHint)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        LucideIcons.barChart2,
                        size: 10,
                        color: AppColors.mutedForeground.withValues(alpha: 0.5),
                      ),
                    ),
                  Text(
                    label,
                    style: AppTextStyles.body(
                      fontSize: 10,
                      color: AppColors.mutedForeground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
            ],
          ),
          const Spacer(),
          stream != null
              ? StreamBuilder<int>(
                  stream: stream,
                  builder: (context, snapshot) {
                    return Text(
                      "${snapshot.data ?? 0}",
                      style: AppTextStyles.heading(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                )
              : Text(
                  value ?? "N/A",
                  style: AppTextStyles.heading(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  detail,
                  style: AppTextStyles.body(
                    fontSize: 9,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subDetail,
                  style: AppTextStyles.body(
                    fontSize: 8,
                    color: AppColors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentAlertList extends StatelessWidget {
  const _RecentAlertList();

  String _relativeTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AlertItem>>(
      valueListenable: AlertService.instance.alerts,
      builder: (context, alerts, _) {
        if (alerts.isEmpty) {
          return GlassCard(
            child: Center(
              child: Text(
                "No recent alerts",
                style: AppTextStyles.body(color: AppColors.mutedForeground),
              ),
            ),
          );
        }
        return Column(
          children: alerts.take(3).map((alert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.alertTriangle,
                        color: AppColors.destructive,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: AppTextStyles.body(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            alert.description,
                            style: AppTextStyles.body(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _relativeTime(alert.createdAt),
                      style: AppTextStyles.mono(
                        fontSize: 10,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
