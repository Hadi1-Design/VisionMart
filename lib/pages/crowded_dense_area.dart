import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';

class CrowdedDenseAreaPage extends StatefulWidget {
  const CrowdedDenseAreaPage({super.key});

  @override
  State<CrowdedDenseAreaPage> createState() => _CrowdedDenseAreaPageState();
}

class _CrowdedDenseAreaPageState extends State<CrowdedDenseAreaPage> {
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
                          Text("SYSTEM · HEATMAP",
                              style: AppTextStyles.body(fontSize: 10, color: AppColors.mutedForeground, fontWeight: FontWeight.bold)
                                  .copyWith(letterSpacing: 2)),
                          Text("Crowded Density", style: AppTextStyles.heading(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      _pulsingIcon(),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('RegionCount').doc('counter_1').snapshots(),
                    builder: (context, countSnapshot) {
                      if (countSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      
                      final countData = countSnapshot.data?.data() as Map<String, dynamic>? ?? {};

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('RegionSetup').snapshots(),
                        builder: (context, setupSnapshot) {
                          if (setupSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          }

                          final List<Map<String, dynamic>> regions = setupSnapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final id = doc.id;
                            final count = countData['${id}_count'] ?? 0;
                            return {
                              'id': id,
                              'name': data['region_name'] ?? id,
                              'image_base64': data['image_base64'] ?? '',
                              'count': count,
                            };
                          }).toList();

                          regions.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

                          if (regions.isEmpty) {
                            return Center(child: Text("No monitored zones available", style: AppTextStyles.body(color: AppColors.mutedForeground)));
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            itemCount: regions.length,
                            itemBuilder: (context, index) {
                              return _buildDensityCard(regions[index], index);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDensityCard(Map<String, dynamic> region, int index) {
    final isTop = index == 0;
    final count = region['count'] as int;
    Uint8List? imageBytes;
    String base64str = region['image_base64'] as String;
    if (base64str.isNotEmpty) {
      try {
        base64str = base64str.contains(',') ? base64str.split(',').last : base64str;
        imageBytes = base64Decode(base64str);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        showGlow: isTop,
        glowColor: AppColors.destructive,
        child: Column(
          children: [
            if (isTop)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.2),
                  border: const Border(bottom: BorderSide(color: AppColors.destructive, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.flame, color: AppColors.destructive, size: 14),
                    const SizedBox(width: 8),
                    Text("CRITICAL DENSITY", style: AppTextStyles.body(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.destructive).copyWith(letterSpacing: 2)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageBytes != null ? Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                        cacheWidth: 200, // Optimize decode size
                      ) : const Icon(LucideIcons.imageOff, size: 20, color: Colors.white24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(region['name'], style: AppTextStyles.body(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isTop ? AppColors.destructive : AppColors.primary).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: (isTop ? AppColors.destructive : AppColors.primary).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            "Occupancy: $count",
                            style: AppTextStyles.body(fontSize: 11, fontWeight: FontWeight.bold, color: isTop ? AppColors.destructive : AppColors.primaryGlow),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _rankIndicator(index + 1, isTop),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _rankIndicator(int rank, bool isTop) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: isTop ? AppColors.destructive.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(color: isTop ? AppColors.destructive.withValues(alpha: 0.5) : Colors.white12),
      ),
      child: Center(
        child: Text("#$rank", style: AppTextStyles.mono(fontSize: 12, fontWeight: FontWeight.bold, color: isTop ? AppColors.destructive : Colors.white70)),
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

  Widget _pulsingIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: const Icon(LucideIcons.scan, color: AppColors.primaryGlow, size: 16),
    ).animate(onPlay: (controller) => controller.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 500.ms).then().scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 500.ms);
  }
}
