import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';
import 'package:vision_app/services/presence_service.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isAdmin;

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
    required this.isAdmin,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, bool> notifications = {"security": true, "analytics": true};

  bool _isLoading = true;
  bool _isSaving = false;

  final _settingsDocRef = FirebaseFirestore.instance
      .collection('app_settings')
      .doc('notification_settings');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _settingsDocRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          notifications["security"] = (data["security"] as bool?) ?? true;
          notifications["analytics"] = (data["analytics"] as bool?) ?? true;
          _isLoading = false;
        });
      } else {
        await _settingsDocRef.set(notifications);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showSnackBar("Failed to load settings: $e");
    }
  }

  Future<void> handleToggle(String key) async {
    if (!widget.isAdmin) {
      _showSnackBar("Only admins can change alert settings.");
      return;
    }

    final newValue = !notifications[key]!;
    setState(() {
      notifications[key] = newValue;
      _isSaving = true;
    });

    try {
      await _settingsDocRef.update({key: newValue});
      if (!mounted) return;
      _showSnackBar(
        "${key[0].toUpperCase()}${key.substring(1)} alerts updated",
      );
    } catch (e) {
      setState(() => notifications[key] = !newValue);
      if (!mounted) return;
      _showSnackBar("Failed to update setting: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  void handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      _showSnackBar("Logged Out Successfully");
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Logout Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    Text(
                      "PROFILE · PREFERENCES",
                      style: AppTextStyles.body(
                        fontSize: 10,
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.bold,
                      ).copyWith(letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Settings",
                      style: AppTextStyles.heading(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- PROFILE CARD ---
                    GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                height: 64,
                                width: 64,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.indigo,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Icon(
                                  LucideIcons.user,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isAdmin
                                          ? "Vision Admin"
                                          : "Staff User",
                                      style: AppTextStyles.heading(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "visionmart",
                                      style: AppTextStyles.body(
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _headerIconButton(LucideIcons.edit3),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 32),

                    // --- NOTIFICATION SETTINGS ---
                    _sectionTitle("SYSTEM NOTIFICATIONS", LucideIcons.bell),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          if (!widget.isAdmin)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "Notifications are managed by the administrator.",
                                style: AppTextStyles.body(
                                  fontSize: 11,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ),
                          ...notifications.keys.map(
                            (key) => _buildSwitchTile(
                              label:
                                  "${key[0].toUpperCase()}${key.substring(1)} Alerts",
                              value: notifications[key]!,
                              icon: _getIconForKey(key),
                              onChanged: widget.isAdmin
                                  ? (_) => handleToggle(key)
                                  : null,
                            ),
                          ),
                          if (_isSaving)
                            const LinearProgressIndicator(
                              color: AppColors.primary,
                              backgroundColor: Colors.transparent,
                            ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 32),

                    const SizedBox(height: 32),

                    // --- LOGIN INFO ---
                    _sectionTitle("SYSTEM INFORMATION", LucideIcons.cpu),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _infoRow("App Version", "1.0"),
                          const Divider(color: Colors.white12, height: 24),
                          _infoRow("Last Update", "May 2026"),
                          const Divider(color: Colors.white12, height: 24),
                          StreamBuilder<int>(
                            stream: PresenceService.instance.activeNodesStream,
                            initialData: 1,
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 1;
                              return _infoRow("Device Nodes", "$count Active");
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 48),

                    // --- LOGOUT BUTTON ---
                    AnimatedTouchable(
                      onTap: handleLogout,
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.destructive.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.logOut,
                              color: AppColors.destructive,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Logout System",
                              style: AppTextStyles.body(
                                fontWeight: FontWeight.bold,
                                color: AppColors.destructive,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _headerIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Icon(icon, size: 18, color: Colors.white70),
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

  Widget _buildSwitchTile({
    required String label,
    required bool value,
    required IconData icon,
    Function(bool)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body(color: AppColors.mutedForeground),
        ),
        Text(value, style: AppTextStyles.body(fontWeight: FontWeight.bold)),
      ],
    );
  }

  IconData _getIconForKey(String key) {
    switch (key) {
      case "security":
        return LucideIcons.shield;
      case "analytics":
        return LucideIcons.barChart;
      default:
        return LucideIcons.bell;
    }
  }
}
