import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vision_app/theme/design_system.dart';
import 'package:vision_app/widgets/glass_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, [Color color = Colors.green]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> handleResetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Please enter your email", AppColors.destructive);
      return;
    }

    try {
      setState(() => _isLoading = true);

      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      _showSnackBar(
        "Password reset link sent! Please check your email.",
        AppColors.success,
      );
      setState(() => _isLoading = false);
      
      // Navigate back after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
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
          // Background Glows (consistent with LoginPage)
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
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Icon / Branding
                          Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              gradient: AppGradients.indigo,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.keyRound,
                              color: Colors.white,
                              size: 32,
                            ),
                          ).animate().fadeIn(duration: 800.ms).scale(),

                          const SizedBox(height: 32),

                          GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(
                                  "Reset Password",
                                  style: AppTextStyles.heading(fontSize: 22),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Enter your registered email to receive a password reset link.",
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Email Field
                                _buildField(
                                  "EMAIL ADDRESS",
                                  emailController,
                                  LucideIcons.mail,
                                ),

                                const SizedBox(height: 24),

                                // Action Button
                                AnimatedTouchable(
                                  onTap: _isLoading ? null : handleResetPassword,
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.indigo,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.5),
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
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Send Reset Link",
                                                  style: AppTextStyles.body(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  LucideIcons.send,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "Back to Login",
                                    style: AppTextStyles.body(
                                      color: AppColors.primaryGlow,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                        ],
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

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
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
            style: AppTextStyles.body(),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "you@store.com",
              hintStyle: AppTextStyles.body(
                color: AppColors.mutedForeground.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: AppColors.mutedForeground,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
