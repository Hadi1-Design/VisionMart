import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/design_system.dart';
import 'glass_widgets.dart';

class SurveillanceOverlay extends StatelessWidget {
  final String imageUrl;
  final String cameraName;
  final String resolution;
  final int fps;

  const SurveillanceOverlay({
    super.key,
    required this.imageUrl,
    this.cameraName = "CAM-01 · ENTRANCE",
    this.resolution = "1080p",
    this.fps = 30,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(
              image: ResizeImage(
                NetworkImage(imageUrl),
                width: 400, // Optimize image decode size
              ),
              fit: BoxFit.cover,
              opacity: 0.7,
            ),
          ),
          child: Stack(
            children: [
              // Scanning Lines Effect
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScanningLinesPainter(),
                ),
              ),

              // Scanning Beam
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .moveY(begin: -220, end: 220, duration: 3.seconds, curve: Curves.linear),
              ),

              // Camera UI Overlay (Static) - Wrapped in RepaintBoundary
              const RepaintBoundary(
                child: _StaticOverlayUI(),
              ),

              // Bottom Overlay Info
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cameraName,
                      style: AppTextStyles.body(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "FPS $fps",
                      style: AppTextStyles.mono(fontSize: 10, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),

              // Corner Decorations
              _cornerDecorator(true, true),
              _cornerDecorator(true, false),
              _cornerDecorator(false, true),
              _cornerDecorator(false, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cornerDecorator(bool top, bool left) {
    return Positioned(
      top: top ? 30 : null,
      bottom: !top ? 30 : null,
      left: left ? 30 : null,
      right: !left ? 30 : null,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
            bottom: !top ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
            left: left ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
            right: !left ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _StaticOverlayUI extends StatelessWidget {
  const _StaticOverlayUI();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top Overlay Info
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.destructive,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .fadeIn(duration: 800.ms)
                      .fadeOut(duration: 800.ms),
                  const SizedBox(width: 8),
                  Text(
                    "REC",
                    style: AppTextStyles.mono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                "DEEP_SENSE: ACTIVE",
                style: AppTextStyles.mono(
                  fontSize: 10,
                  color: AppColors.primaryGlow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Grid View Finder
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanningLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02) // Reduced alpha here instead of Opacity widget
      ..strokeWidth = 1.0;

    const lineSpacing = 6.0;
    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
