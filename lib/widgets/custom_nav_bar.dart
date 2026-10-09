import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/design_system.dart';
import 'glass_widgets.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isStaff;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isStaff = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<NavEntry> adminItems = [
      NavEntry(icon: LucideIcons.layoutDashboard, label: "Dashboard"),
      NavEntry(icon: LucideIcons.shieldAlert, label: "Alerts"),
      NavEntry(icon: LucideIcons.barChart3, label: "Analytics"),
      NavEntry(icon: LucideIcons.settings, label: "Settings"),
    ];

    final List<NavEntry> staffItems = [
      NavEntry(icon: LucideIcons.layoutDashboard, label: "Dashboard"),
      NavEntry(icon: LucideIcons.shieldAlert, label: "Alerts"),
      NavEntry(icon: LucideIcons.settings, label: "Settings"),
    ];

    final items = isStaff ? staffItems : adminItems;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: AnimatedTouchable(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1) : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isSelected ? AppColors.primaryGlow : AppColors.mutedForeground,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTextStyles.body(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class NavEntry {
  final IconData icon;
  final String label;

  NavEntry({required this.icon, required this.label});
}
