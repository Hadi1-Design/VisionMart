import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';

class HeatmapPage extends StatelessWidget {
  const HeatmapPage({super.key});

  final List<List<int>> heatmapData = const [
    [0, 1, 2, 3, 1],
    [1, 2, 3, 4, 2],
    [0, 1, 2, 3, 1],
    [1, 3, 4, 4, 2],
    [0, 1, 2, 3, 0],
  ];

  Color getColor(int value) {
    switch (value) {
      case 0:
        return Colors.white.withValues(alpha: 0.05);
      case 1:
        return AppColors.primary.withValues(alpha: 0.3);
      case 2:
        return AppColors.accent.withValues(alpha: 0.5);
      case 3:
        return AppColors.warning.withValues(alpha: 0.7);
      case 4:
        return AppColors.destructive.withValues(alpha: 0.9);
      default:
        return Colors.transparent;
    }
  }

  Color getGlowColor(int value) {
    switch (value) {
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.destructive;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: AppGradients.mesh))),
          SafeArea(
            child: Column(
              children: [
                // --- HEADER ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    children: [
                      _headerIconButton(LucideIcons.chevronLeft, () => Navigator.pop(context)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("SPATIAL · ANALYTICS",
                              style: AppTextStyles.body(fontSize: 10, color: AppColors.mutedForeground, fontWeight: FontWeight.bold)
                                  .copyWith(letterSpacing: 2)),
                          Text("Density Heatmap", style: AppTextStyles.heading(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      _pulsingStatus(),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        showGlow: true,
                        glowColor: AppColors.primary,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Real-time occupancy gradients", style: AppTextStyles.body(fontSize: 12, color: AppColors.mutedForeground)),
                            const SizedBox(height: 32),
                            ...heatmapData.asMap().entries.map((entry) {
                              final rowIndex = entry.key;
                              final row = entry.value;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: row.asMap().entries.map((cellEntry) {
                                  final colIndex = cellEntry.key;
                                  final value = cellEntry.value;
                                  return _buildHeatCell(value, rowIndex, colIndex);
                                }).toList(),
                              );
                            }), // Removed .toList() to fix spread warning
                            const SizedBox(height: 32),
                            _buildLegend(),
                          ],
                        ),
                      ),
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

  Widget _buildHeatCell(int value, int r, int c) {
    final color = getColor(value);
    final glowColor = getGlowColor(value);
    final isHot = value >= 3;

    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHot ? glowColor.withValues(alpha: 0.5) : Colors.white10, width: 1),
        boxShadow: isHot
            ? [
                BoxShadow(color: glowColor.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1),
              ]
            : null,
      ),
      child: isHot
          ? Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ).animate(onPlay: (controller) => controller.repeat()).scale(begin: const Offset(1, 1), end: const Offset(2, 2), duration: 1.seconds).then().scale(begin: const Offset(2, 2), end: const Offset(1, 1), duration: 1.seconds),
            )
          : null,
    ).animate().fadeIn(delay: ((r + c) * 50).ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem("Low", Colors.white.withValues(alpha: 0.1)),
          const SizedBox(width: 16),
          _legendItem("Med", AppColors.accent.withValues(alpha: 0.5)),
          const SizedBox(width: 16),
          _legendItem("Critical", AppColors.destructive.withValues(alpha: 0.8)),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.body(fontSize: 10, color: AppColors.mutedForeground)),
      ],
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

  Widget _pulsingStatus() {
    return Row(
      children: [
        Text("LIVE SCAN", style: AppTextStyles.mono(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppColors.primaryGlow, shape: BoxShape.circle),
        ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 800.ms).fadeOut(duration: 800.ms),
      ],
    );
  }
}
