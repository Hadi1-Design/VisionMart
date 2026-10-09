import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';
import 'dart:convert';
import 'package:vision_app/pages/alert_service.dart';

class WeaponAlertsPage extends StatefulWidget {
  const WeaponAlertsPage({super.key});

  @override
  State<WeaponAlertsPage> createState() => _WeaponAlertsPageState();
}

class _WeaponAlertsPageState extends State<WeaponAlertsPage> {
  int _filterIndex = 0;
  final List<String> _filters = ['All', 'Grenade', 'Knife', 'Missile', 'Pistol', 'Rifle'];

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(gradient: AppGradients.mesh)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      AnimatedTouchable(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text("Weapon Alerts", style: AppTextStyles.heading(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                // --- WEAPON FILTERS ---
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filterName = _filters[index];
                      final isSelected = _filterIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: AnimatedTouchable(
                          onTap: () => setState(() => _filterIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppGradients.indigo : null,
                              color: isSelected
                                  ? null
                                  : AppColors.card.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.5)
                                    : Colors.white10,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                filterName,
                                style: AppTextStyles.body(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.mutedForeground,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    backgroundColor: AppColors.card,
                    color: AppColors.primary,
                    child: ValueListenableBuilder<List<AlertItem>>(
                      valueListenable: AlertService.instance.alerts,
                      builder: (context, alerts, _) {
                        var weaponAlerts = clipsWithWeapons(alerts);

                        if (_filterIndex > 0) {
                          final selectedFilter = _filters[_filterIndex].toLowerCase();
                          weaponAlerts = weaponAlerts.where((alert) {
                            final title = alert.title.toLowerCase();
                            final description = alert.description.toLowerCase();
                            return title.contains(selectedFilter) || description.contains(selectedFilter);
                          }).toList();
                        }

                        if (weaponAlerts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.shieldCheck, size: 64, color: AppColors.success.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  _filterIndex == 0
                                      ? "No weapon threats detected"
                                      : "No ${_filters[_filterIndex].toLowerCase()} threats detected",
                                  style: AppTextStyles.body(color: AppColors.mutedForeground),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: weaponAlerts.length,
                          itemBuilder: (context, index) {
                            final alert = weaponAlerts[index];
                            return _WeaponAlertCard(
                              title: alert.title,
                              description: alert.description,
                              createdAt: alert.createdAt,
                              imageBase64: alert.imageBase64,
                            ).animate().fadeIn(delay: (index * 25).ms).slideY(begin: 0.1, end: 0);
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

  List<AlertItem> clipsWithWeapons(List<AlertItem> all) {
    return all.where((a) => a.source == 'weapon').toList();
  }
}

class _WeaponAlertCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime createdAt;
  final String? imageBase64;

  const _WeaponAlertCard({
    required this.title,
    required this.description,
    required this.createdAt,
    this.imageBase64,
  });

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
    dynamic imageBytes;
    if (imageBase64 != null) {
      try {
        imageBytes = base64Decode(imageBase64!);
      } catch (e) {
        imageBytes = null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        severityColor: AppColors.destructive,
        showGlow: true,
        glowColor: AppColors.destructive,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.swords, color: AppColors.destructive, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text("CRITICAL THREAT", style: AppTextStyles.mono(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.destructive)),
                  ],
                ),
                Text(_relativeTime(createdAt), style: AppTextStyles.mono(fontSize: 10, color: AppColors.mutedForeground)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                    )
                  : Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(LucideIcons.imageOff, size: 40, color: Colors.white12),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.heading(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(description, style: AppTextStyles.body(fontSize: 13, color: AppColors.mutedForeground)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.chevronRight, color: Colors.white, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
