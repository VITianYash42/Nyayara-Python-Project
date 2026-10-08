import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../home/user_home_screen.dart';
import '../hr/hr_dashboard_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthViewModel>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Greeting
              Text(
                'Hello, ${user?.name.split(' ').first ?? 'there'} 👋',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16),
              ).animate().fadeIn(duration: 400.ms),

              Text(
                'How can I help\nyou today?',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),

              const SizedBox(height: 8),
              Container(width: 50, height: 3,
                  decoration: const BoxDecoration(gradient: AppColors.goldGradient))
                  .animate(delay: 200.ms).fadeIn().scaleX(begin: 0),

              const SizedBox(height: 40),

              // Mode Cards
              _ModeCard(
                icon: Icons.person_outline_rounded,
                title: 'Personal Safety',
                subtitle: 'Report incidents, get legal help, trigger SOS',
                badge: 'Individual Mode',
                badgeColor: AppColors.goldPrimary,
                features: const [
                  'AI Legal Assistance',
                  'Emergency SOS',
                  'Evidence Vault',
                  'FIR Draft Generator',
                ],
                delay: 300,
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                ),
              ),

              const SizedBox(height: 20),

              _ModeCard(
                icon: Icons.business_center_outlined,
                title: 'Workplace Mode',
                subtitle: 'File POSH complaints, HR dashboard, analytics',
                badge: user?.role == 'hr' || user?.role == 'admin' ? 'HR/Admin Mode' : 'Employee Mode',
                badgeColor: user?.role == 'hr' ? AppColors.info : AppColors.success,
                features: user?.role == 'hr'
                    ? const ['HR Dashboard', 'Complaint Analytics', 'Repeat Offender Alerts', 'Compliance Tracker']
                    : const ['File HR Complaint', 'Department Reporting', 'Anonymous Mode', 'AI Complaint Drafting'],
                delay: 450,
                onTap: () {
                  if (user?.role == 'hr' || user?.role == 'admin') {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HRDashboardScreen()),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const UserHomeScreen(initialTab: 2)),
                    );
                  }
                },
              ),

              const Spacer(),

              // Hotline Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.danger.withOpacity(0.08),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.danger.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.phone_in_talk, color: AppColors.danger, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Women Helpline: 181',
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text('Police: 100 | Cyber Crime: 1930',
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: AppColors.danger),
                  ],
                ),
              ).animate(delay: 700.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final List<String> features;
  final int delay;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.features,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.backgroundCard,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.goldGradient,
                  ),
                  child: Icon(icon, color: Colors.black, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: badgeColor.withOpacity(0.15),
                    border: Border.all(color: badgeColor.withOpacity(0.4)),
                  ),
                  child: Text(badge,
                      style: GoogleFonts.inter(
                          color: badgeColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.playfairDisplay(
                    color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((f) => _feature(f)).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Get started',
                    style: GoogleFonts.inter(
                        color: AppColors.goldLight, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.goldLight, size: 16),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideY(begin: 0.2);
  }

  Widget _feature(String f) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.goldPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Text(f, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
