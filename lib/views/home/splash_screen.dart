import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../auth/login_screen.dart';

// Feminine palette constants (shared across screens)
const Color kRose = Color(0xFFE91E8C);
const Color kLavender = Color(0xFF9C27B0);
const Color kPurpleDark = Color(0xFF1A0A2E);
const Color kPurpleMid = Color(0xFF150B22);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPurpleDark,
      body: Stack(
        children: [
          // ── Deep purple gradient background ─────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A0A2E),
                    Color(0xFF12071E),
                    Color(0xFF0D0D0D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
          ),

          // ── Soft glowing rose blob top-right ────────────────────────
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  kRose.withValues(alpha: 0.22),
                  Colors.transparent,
                ]),
              ),
            ),
          ).animate().fadeIn(duration: 1000.ms),

          // ── Soft glowing lavender blob bottom-left ──────────────────
          Positioned(
            bottom: -80, left: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  kLavender.withValues(alpha: 0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ).animate().fadeIn(duration: 1200.ms),

          // ── Decorative ring top-right ────────────────────────────────
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: kRose.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 900.ms).scale(
              begin: const Offset(0.7, 0.7), end: const Offset(1, 1),
              curve: Curves.easeOut, duration: 1200.ms),

          // ── Center content ───────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shield icon with rose-purple gradient
                Container(
                  width: 104, height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [kRose, kLavender],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kRose.withValues(alpha: 0.5),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: kLavender.withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 52),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 30),

                // App name with gradient shimmer
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFF48FB1), Colors.white, Color(0xFFCE93D8)],
                    stops: [0, 0.5, 1],
                  ).createShader(bounds),
                  child: Text(
                    AppConstants.appName,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 10),

                // Tagline
                Text(
                  AppConstants.appTagline,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCE93D8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 700.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 16),

                // Rose-lavender gradient divider
                Container(
                  width: 70, height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                        colors: [kRose, kLavender]),
                  ),
                )
                    .animate(delay: 900.ms)
                    .fadeIn(duration: 400.ms)
                    .scaleX(begin: 0, end: 1, curve: Curves.easeOut),

                const SizedBox(height: 72),

                // Loading indicator – rose color
                SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(kRose),
                    backgroundColor: kLavender.withValues(alpha: 0.2),
                    strokeWidth: 2,
                  ),
                ).animate(delay: 1200.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 14),

                Text(
                  'Initializing secure environment...',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8070A0),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ).animate(delay: 1400.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),

          // ── Bottom branding ──────────────────────────────────────────
          Positioned(
            bottom: 32, left: 0, right: 0,
            child: Column(
              children: [
                Text(
                  'AI-Powered Women Safety Platform',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8070A0),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v${AppConstants.appVersion}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5A4A72),
                    fontSize: 10,
                  ),
                ),
              ],
            ).animate(delay: 1600.ms).fadeIn(duration: 400.ms),
          ),
        ],
      ),
    );
  }
}
