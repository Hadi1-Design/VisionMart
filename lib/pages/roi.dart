import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';

class ROIPage extends StatefulWidget {
  const ROIPage({super.key});

  @override
  State<ROIPage> createState() => _ROIPageState();
}

class _ROIPageState extends State<ROIPage> {
  String _formatDate(DateTime t) {
    return "${t.day}/${t.month}/${t.year} ${t.hour}:${t.minute.toString().padLeft(2, '0')}";
  }

  void _showRegionDetails(BuildContext context, String regionId, String regionName) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 32,
              showGlow: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(regionName, style: AppTextStyles.heading(fontSize: 24, fontWeight: FontWeight.bold)),
                      AnimatedTouchable(
                        onTap: () => Navigator.pop(context),
                        child: Icon(LucideIcons.x, size: 20, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('RegionCount').doc('counter_1').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text("No telemetry available", style: AppTextStyles.body(color: AppColors.mutedForeground));
                      }

                      final countData = snapshot.data!.data() as Map<String, dynamic>;
                      final int regionCount = countData['${regionId}_count'] ?? 0;
                      final String status = countData['status'] ?? 'Offline';
                      final isOnline = status.toLowerCase() == 'online';
                      final Timestamp? lastUpdatedTs = countData['last_updated'] as Timestamp?;
                      final String lastUpdatedStr = lastUpdatedTs != null ? _formatDate(lastUpdatedTs.toDate()) : 'Never';

                      return Column(
                        children: [
                          _detailItem(LucideIcons.users, "Occupancy", "$regionCount", AppColors.primaryGlow),
                          const SizedBox(height: 16),
                          _detailItem(LucideIcons.activity, "Status", status, isOnline ? AppColors.success : AppColors.destructive),
                          const SizedBox(height: 16),
                          _detailItem(LucideIcons.clock, "Last Sync", lastUpdatedStr, AppColors.mutedForeground),
                        ],
                      ).animate().fadeIn(duration: 200.ms); // Snappier
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Acknowledge", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack, duration: 300.ms), // Snappier
        );
      },
    );
  }

  Widget _detailItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 16),
        Text(label, style: AppTextStyles.body(color: AppColors.mutedForeground, fontSize: 13)),
        const Spacer(),
        Text(value, style: AppTextStyles.body(fontWeight: FontWeight.bold, fontSize: 13, color: color == AppColors.mutedForeground ? Colors.white : color)),
      ],
    );
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
                          Text("SYSTEM · ZONES",
                              style: AppTextStyles.body(fontSize: 10, color: AppColors.mutedForeground, fontWeight: FontWeight.bold)
                                  .copyWith(letterSpacing: 2)),
                          Text("Region of Interest", style: AppTextStyles.heading(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('RegionSetup').snapshots(),
                      builder: (context, setupSnapshot) {
                        if (setupSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                        }
                        
                        final docs = setupSnapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(child: Text("No monitored zones active", style: AppTextStyles.body(color: AppColors.mutedForeground)));
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("MONITORED ZONES",
                                style: AppTextStyles.body(fontSize: 10, color: AppColors.mutedForeground, fontWeight: FontWeight.bold)
                                    .copyWith(letterSpacing: 2)),
                            const SizedBox(height: 16),
                            
                            // Dynamic Grid (2 items per row)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final regionId = doc.id;
                                final regionName = data['region_name'] ?? regionId;
                                final imageBase64 = data['image_base64'] ?? '';
                                Uint8List? imageBytes;
                                if (imageBase64.isNotEmpty) {
                                  try {
                                    String base64str = imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;
                                    imageBytes = base64Decode(base64str);
                                  } catch (_) {}
                                }

                                return _buildRegionCard(context, regionId, regionName, imageBytes)
                                    .animate()
                                    .fadeIn(delay: (index * 50).ms)
                                    .scale(begin: const Offset(0.9, 0.9));
                              },
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // --- MOST CROWDED AREA SECTION ---
                            Text("MOST CROWDED AREA",
                                style: AppTextStyles.body(fontSize: 10, color: AppColors.mutedForeground, fontWeight: FontWeight.bold)
                                    .copyWith(letterSpacing: 2)),
                            const SizedBox(height: 16),
                            
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('RegionCount').doc('counter_1').snapshots(),
                              builder: (context, countSnapshot) {
                                if (countSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                                }
                                
                                final countData = countSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                                
                                // Map setup docs to regions with counts
                                final List<Map<String, dynamic>> regionsWithCount = docs.map((doc) {
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

                                // Sort by count Descending
                                regionsWithCount.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

                                return Column(
                                  children: regionsWithCount.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final region = entry.value;
                                    return _buildCrowdedAreaItem(region, index);
                                  }).toList(),
                                );
                              },
                            ),
                          ],
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

  Widget _buildCrowdedAreaItem(Map<String, dynamic> region, int index) {
    final count = region['count'] as int;
    final isTop = index == 0;
    Uint8List? imageBytes;
    String base64str = region['image_base64'] as String;
    if (base64str.isNotEmpty) {
      try {
        base64str = base64str.contains(',') ? base64str.split(',').last : base64str;
        imageBytes = base64Decode(base64str);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        showGlow: isTop && count > 0,
        glowColor: AppColors.destructive,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageBytes != null
                    ? Image.memory(imageBytes, fit: BoxFit.cover)
                    : const Icon(LucideIcons.image, size: 20, color: Colors.white24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(region['name'], style: AppTextStyles.body(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    "Occupancy: $count",
                    style: AppTextStyles.body(
                      fontSize: 11,
                      color: isTop && count > 0 ? AppColors.destructive : AppColors.mutedForeground,
                      fontWeight: isTop && count > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isTop && count > 0)
              const Icon(LucideIcons.flame, color: AppColors.destructive, size: 16)
                  .animate(onPlay: (c) => c.repeat())
                  .scale(duration: 500.ms)
                  .then()
                  .scale(duration: 500.ms),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
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

  Widget _buildRegionCard(BuildContext context, String id, String name, Uint8List? imageBytes) {
    return AnimatedTouchable(
      onTap: () => _showRegionDetails(context, id, name),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 20,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          cacheWidth: 400,
                        )
                      : const Icon(LucideIcons.image, size: 30, color: Colors.white24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(name,
                  style: AppTextStyles.body(fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
