import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';
import 'package:vision_app/pages/alert_service.dart';
import 'dart:convert';

class SuspiciousActivityPage extends StatefulWidget {
  final AlertItem? focusAlert;

  const SuspiciousActivityPage({super.key, this.focusAlert});

  @override
  State<SuspiciousActivityPage> createState() => _SuspiciousActivityPageState();
}

class _SuspiciousActivityPageState extends State<SuspiciousActivityPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _cardKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusAlert != null) {
        _scrollToAlert(widget.focusAlert!);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToAlert(AlertItem focus) {
    final activities = AlertService.instance.alerts.value
        .where((a) => a.source == 'shoplifting')
        .toList();
    final idx = activities.indexWhere(
      (a) =>
          a.title == focus.title &&
          a.createdAt.millisecondsSinceEpoch ==
              focus.createdAt.millisecondsSinceEpoch,
    );
    if (idx == -1) return;
    final targetKey = _cardKeys[idx];
    if (targetKey == null) return;
    final ctx = targetKey.currentContext;
    if (ctx == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToAlert(focus),
      );
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppGradients.mesh),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // --- CUSTOM HEADER ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    children: [
                      _headerIconButton(
                        LucideIcons.chevronLeft,
                        () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SECURITY · MONITOR",
                            style: AppTextStyles.body(
                              fontSize: 10,
                              color: AppColors.mutedForeground,
                              fontWeight: FontWeight.bold,
                            ).copyWith(letterSpacing: 2),
                          ),
                          Text(
                            "Suspicious Activity",
                            style: AppTextStyles.heading(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    backgroundColor: AppColors.card,
                    color: AppColors.primary,
                    child: ValueListenableBuilder<List<AlertItem>>(
                      valueListenable: AlertService.instance.alerts,
                      builder: (context, allAlerts, _) {
                        final activities = allAlerts
                            .where((a) => a.source == 'shoplifting')
                            .toList();

                        if (activities.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.shieldCheck,
                                  size: 48,
                                  color: AppColors.success,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No suspicious activity detected",
                                  style: AppTextStyles.body(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            final activity = activities[index];
                            return _buildActivityCard(context, activity, index)
                                .animate()
                                .fadeIn(delay: (index * 50).ms)
                                .slideY(begin: 0.1, end: 0);
                          },
                        );
                      },
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

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return AnimatedTouchable(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, AlertItem item, int index) {
    _cardKeys[index] = GlobalKey();
    final relTime = _relativeTime(item.createdAt);

    dynamic imageWidget;
    if (item.imageBase64 != null) {
      try {
        final bytes = base64Decode(item.imageBase64!);
        imageWidget = Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          cacheWidth: 600,
        );
      } catch (e) {
        imageWidget = _placeholderImage();
      }
    } else {
      imageWidget = _placeholderImage();
    }

    return Container(
      key: _cardKeys[index],
      margin: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        showGlow: index == 0,
        glowColor: AppColors.destructive,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTextStyles.body(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  relTime,
                  style: AppTextStyles.mono(
                    fontSize: 10,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageWidget,
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              style: AppTextStyles.body(
                fontSize: 13,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: "Mark Reviewed",
                    icon: LucideIcons.checkCircle2,
                    isSecondary: true,
                    onTap: () {
                      AlertService.instance.removeAlert(item);
                      _showSnackBar("Marked as Reviewed");
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: "Notify Staff",
                    icon: LucideIcons.bell,
                    onTap: () => _showSnackBar("Staff Notified"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    bool isSecondary = false,
    required VoidCallback onTap,
  }) {
    return AnimatedTouchable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSecondary
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSecondary
                ? Colors.white10
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSecondary ? Colors.white70 : AppColors.primaryGlow,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSecondary ? Colors.white70 : AppColors.primaryGlow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.05),
      child: const Icon(LucideIcons.imageOff, size: 40, color: Colors.white12),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.body(fontSize: 12)),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
