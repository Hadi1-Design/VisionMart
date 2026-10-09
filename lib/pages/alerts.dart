import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';
import 'package:vision_app/pages/alert_service.dart';
import 'suspicious_activity.dart';
import 'weapon_alerts.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

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
    return Scaffold(
      backgroundColor: Colors.transparent, // Parent provides background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "SYSTEM · STATUS",
                        style: AppTextStyles.body(
                          fontSize: 10,
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.bold,
                        ).copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 4,
                        width: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Security Alerts",
                    style: AppTextStyles.heading(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- ALERTS LIST ---
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                backgroundColor: AppColors.card,
                color: AppColors.primary,
                child: ValueListenableBuilder<List<AlertItem>>(
                  valueListenable: AlertService.instance.alerts,
                  builder: (context, allAlerts, _) {
                    final currentAlerts = allAlerts;

                    if (currentAlerts.isEmpty) {
                      return ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                const Icon(
                                  LucideIcons.shieldCheck,
                                  size: 48,
                                  color: AppColors.success,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No alerts found",
                                  style: AppTextStyles.body(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: currentAlerts.length,
                      itemBuilder: (context, index) {
                        final alert = currentAlerts[index];
                        final Color severityColor = alert.color == Colors.red
                            ? AppColors.destructive
                            : alert.color == Colors.orange
                            ? AppColors.warning
                            : AppColors.primary;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child:
                              GlassCard(
                                    padding: const EdgeInsets.all(16),
                                    severityColor: severityColor,
                                    showGlow: alert.color == Colors.red,
                                    glowColor: AppColors.destructive,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: severityColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                alert.icon,
                                                color: severityColor,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          alert.title,
                                                          style:
                                                              AppTextStyles.body(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      _statusTag(
                                                        alert.color ==
                                                                Colors.red
                                                            ? "CRITICAL"
                                                            : alert.color ==
                                                                  Colors.orange
                                                            ? "HIGH"
                                                            : "MEDIUM",
                                                        severityColor,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    alert.description,
                                                    style: AppTextStyles.body(
                                                      fontSize: 13,
                                                      color: AppColors
                                                          .mutedForeground,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  LucideIcons.mapPin,
                                                  size: 10,
                                                  color:
                                                      AppColors.mutedForeground,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Zone B-3",
                                                  style: AppTextStyles.body(
                                                    fontSize: 10,
                                                    color: AppColors
                                                        .mutedForeground,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(
                                                  LucideIcons.clock,
                                                  size: 10,
                                                  color:
                                                      AppColors.mutedForeground,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _relativeTime(
                                                    alert.createdAt,
                                                  ),
                                                  style: AppTextStyles.body(
                                                    fontSize: 10,
                                                    color: AppColors
                                                        .mutedForeground,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            AnimatedTouchable(
                                              onTap: () {
                                                if (alert.source == 'weapon') {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => const WeaponAlertsPage(),
                                                    ),
                                                  );
                                                } else {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          SuspiciousActivityPage(
                                                            focusAlert: alert,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "Details",
                                                      style: AppTextStyles.body(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      LucideIcons.chevronRight,
                                                      size: 12,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: (index * 25).ms)
                                  .slideX(begin: 0.1, end: 0),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.body(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
