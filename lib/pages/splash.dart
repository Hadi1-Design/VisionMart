import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vision_app/theme/design_system.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final uid = user.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] as String?;

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (role == 'staff') {
        Navigator.pushReplacementNamed(context, '/staff_dashboard');
      } else {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Mesh Gradient Background Effect
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppGradients.mesh),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        gradient: AppGradients.indigo,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      delay: 200.ms,
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 24),

                // Brand Name
                Text(
                      "VisionMart",
                      style: AppTextStyles.heading(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 60),

                // Loading Indicator
                const SizedBox(
                  width: 40,
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.muted,
                    color: AppColors.primary,
                  ),
                ).animate().fadeIn(delay: 1200.ms),
              ],
            ),
          ),

          // Bottom Version/Status Info
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                      height: 8,
                      width: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 1.seconds)
                    .fadeOut(delay: 1.seconds, duration: 1.seconds),
                const SizedBox(width: 8),
                Text(
                  "SYSTEMS · OK",
                  style: AppTextStyles.mono(
                    fontSize: 10,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ).copyWith(letterSpacing: 2),
                ),
              ],
            ).animate().fadeIn(delay: 1500.ms),
          ),
        ],
      ),
    );
  }
}
