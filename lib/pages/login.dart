import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String role = "admin";
  final TextEditingController adminEmailController = TextEditingController();
  final TextEditingController adminPasswordController = TextEditingController();
  final TextEditingController staffEmailController = TextEditingController();
  final TextEditingController staffPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    adminEmailController.dispose();
    adminPasswordController.dispose();
    staffEmailController.dispose();
    staffPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, [Color color = Colors.green]) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> handleLogin() async {
    final email =
        (role == 'admin' ? adminEmailController : staffEmailController).text
            .trim();
    final password =
        (role == 'admin' ? adminPasswordController : staffPasswordController)
            .text
            .trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter email and password", AppColors.destructive);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        setState(() => _isLoading = false);
        _showSnackBar("Login failed: user is null", AppColors.destructive);
        return;
      }

      final uid = user.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        await _auth.signOut();
        setState(() => _isLoading = false);
        _showSnackBar(
          "No role info found. Contact admin.",
          AppColors.destructive,
        );
        return;
      }

      final data = doc.data();
      final firestoreRole = data?['role'] as String?;

      if (firestoreRole != role) {
        await _auth.signOut();
        setState(() => _isLoading = false);
        _showSnackBar(
          "Access denied. Logged-in role ($firestoreRole) does not match selection ($role).",
          AppColors.destructive,
        );
        return;
      }

      if (!mounted) return;
      _showSnackBar("Welcome To Dashboard!", AppColors.success);
      setState(() => _isLoading = false);

      if (firestoreRole == 'admin') {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/staff_dashboard');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("${e.message}", AppColors.destructive);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Unexpected error: $e", AppColors.destructive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              height: 400,
              width: 400,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ).animate().fadeIn(duration: 2.seconds),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ).animate().fadeIn(duration: 2.seconds),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Logo
                  Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: AppGradients.indigo,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.scanFace,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "VisionMart",
                                style: AppTextStyles.heading(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "AI Powered Surveillance System",
                                style: AppTextStyles.body(
                                  fontSize: 10,
                                  color: AppColors.mutedForeground,
                                  fontWeight: FontWeight.w600,
                                ).copyWith(letterSpacing: 3),
                              ),
                            ],
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .slideY(begin: -0.2, end: 0),

                  const SizedBox(height: 32),

                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          "Welcome back",
                          style: AppTextStyles.heading(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Sign in to your AI surveillance hub",
                          style: AppTextStyles.body(
                            color: AppColors.mutedForeground,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Role Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _roleButton("admin", LucideIcons.shield, "Admin"),
                              _roleButton("staff", LucideIcons.user, "Staff"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Form Fields
                        _buildField(
                          "EMAIL",
                          role == 'admin'
                              ? adminEmailController
                              : staffEmailController,
                          LucideIcons.mail,
                          false,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          "PASSWORD",
                          role == 'admin'
                              ? adminPasswordController
                              : staffPasswordController,
                          LucideIcons.lock,
                          true,
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: true,
                                  onChanged: (_) {},
                                  activeColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Text(
                                  "Keep me signed in",
                                  style: AppTextStyles.body(
                                    fontSize: 12,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/forgot-password',
                                );
                              },
                              child: Text(
                                "Forgot password?",
                                style: AppTextStyles.body(
                                  fontSize: 12,
                                  color: AppColors.primaryGlow,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Login Button
                        AnimatedTouchable(
                          onTap: _isLoading ? null : handleLogin,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppGradients.indigo,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Sign In",
                                          style: AppTextStyles.body(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          LucideIcons.arrowRight,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ).animate().scale(
                          delay: 400.ms,
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
                        ),

                        const SizedBox(height: 24),

                        RichText(
                          text: TextSpan(
                            style: AppTextStyles.body(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: "Create one",
                                style: TextStyle(
                                  color: AppColors.primaryGlow,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border, thickness: 0.5),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                      height: 6,
                                      width: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                    .animate(onPlay: (c) => c.repeat())
                                    .fadeIn(duration: 1.seconds)
                                    .fadeOut(delay: 1.seconds),
                                const SizedBox(width: 8),
                                Text(
                                  "Systems · OK",
                                  style: AppTextStyles.mono(
                                    fontSize: 10,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "v1.0",
                              style: AppTextStyles.mono(
                                fontSize: 10,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleButton(String r, IconData icon, String label) {
    bool isSelected = role == r;
    return Expanded(
      child: AnimatedTouchable(
        onTap: () => setState(() => role = r),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.indigo : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.mutedForeground,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.body(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isPassword,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body(
            fontSize: 10,
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.bold,
          ).copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            style: AppTextStyles.body(),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: isPassword ? "••••••••" : "you@store.com",
              hintStyle: AppTextStyles.body(
                color: AppColors.mutedForeground.withValues(alpha: 0.5),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 18,
                        color: AppColors.mutedForeground,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
