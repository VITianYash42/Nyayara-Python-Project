import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/app_theme.dart';

class OfficialLinksScreen extends StatelessWidget {
  const OfficialLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Official Reporting Channels',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.backgroundPrimary,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _HeaderCard(),
            const SizedBox(height: 24),

            // 1. National Cyber Crime Portal
            _SectionHeader(title: '🟣 1️⃣ National Cyber Crime Portal', subtitle: 'For Online Harassment, Deepfake, Blackmail'),
            const SizedBox(height: 12),
            _LinkCard(
              icon: Icons.security_rounded,
              iconColor: const Color(0xFF2196F3),
              title: 'cybercrime.gov.in',
              subtitle: 'Report: Cyber harassment, Deepfakes, Morphing, Online Blackmail, Revenge Porn.',
              badge: 'GOVT OFFICIAL',
              badgeColor: AppColors.success,
              onTap: () => _launch('https://cybercrime.gov.in'),
            ),

            const SizedBox(height: 24),

            // 2. SHe-Box
            _SectionHeader(title: '🟣 2️⃣ SHe-Box (Workplace Harassment)', subtitle: 'Ministry of Women & Child Development'),
            const SizedBox(height: 12),
            _LinkCard(
              icon: Icons.business_center_rounded,
              iconColor: const Color(0xFF9C27B0),
              title: 'shebox.nic.in',
              subtitle: 'Report: Workplace sexual harassment & POSH Act complaints. Forwards to ICC/LCC.',
              badge: 'WORKPLACE',
              badgeColor: const Color(0xFF9C27B0),
              onTap: () => _launch('https://shebox.nic.in'),
            ),

            const SizedBox(height: 24),

            // 3. State Police Portals
            _SectionHeader(title: '🟣 3️⃣ State Police e-FIR Portals', subtitle: 'File e-complaints & Lost Article FIRs'),
            const SizedBox(height: 12),
            _LinkCard(
              icon: Icons.local_police_outlined,
              iconColor: AppColors.goldLight,
              title: 'Delhi Police',
              subtitle: 'delhipolice.gov.in',
              badge: 'DELHI',
              badgeColor: AppColors.textHint,
              onTap: () => _launch('https://delhipolice.gov.in'),
              compact: true,
            ),
             _LinkCard(
              icon: Icons.local_police_outlined,
              iconColor: AppColors.goldLight,
              title: 'Karnataka Police',
              subtitle: 'ksp.karnataka.gov.in',
              badge: 'KARNATAKA',
              badgeColor: AppColors.textHint,
              onTap: () => _launch('https://ksp.karnataka.gov.in'),
              compact: true,
            ),
             _LinkCard(
              icon: Icons.local_police_outlined,
              iconColor: AppColors.goldLight,
              title: 'Telangana Police',
              subtitle: 'tspolice.gov.in',
              badge: 'TELANGANA',
              badgeColor: AppColors.textHint,
              onTap: () => _launch('https://tspolice.gov.in'),
              compact: true,
            ),
             _LinkCard(
              icon: Icons.local_police_outlined,
              iconColor: AppColors.goldLight,
              title: 'Maharashtra Police',
              subtitle: 'citizen.mahapolice.gov.in',
              badge: 'MAHARASHTRA',
              badgeColor: AppColors.textHint,
              onTap: () => _launch('https://citizen.mahapolice.gov.in'),
              compact: true,
            ),

            const SizedBox(height: 24),

            // 4. Emergency Numbers
            _SectionHeader(title: '🟣 4️⃣ Emergency Numbers', subtitle: 'Tap to call immediately'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _EmergencyBtn(
                    number: '112',
                    label: 'National Emergency',
                    color: AppColors.danger,
                    icon: Icons.notifications_active,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EmergencyBtn(
                    number: '181',
                    label: 'Women Helpline',
                    color: const Color(0xFFE91E63),
                    icon: Icons.female,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _EmergencyBtn(
              number: '1091',
              label: 'Women Police Helpline (Direct Line)',
              color: AppColors.warning,
              icon: Icons.local_police,
              fullWidth: true,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    if (await canLaunchUrlString(url)) await launchUrlString(url, mode: LaunchMode.externalApplication);
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A00), Color(0xFF2A1500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.goldLight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'For serious crimes, verify details here and visit the nearest police station if physical FIR is required.',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        const SizedBox(height: 4),
        Text(subtitle,
            style:
                GoogleFonts.inter(color: AppColors.textHint, fontSize: 12)),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, badge;
  final Color badgeColor;
  final VoidCallback onTap;
  final bool compact;

  const _LinkCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.backgroundCard,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 36 : 44, height: compact ? 36 : 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: iconColor.withOpacity(0.15),
              ),
              child: Icon(icon, color: iconColor, size: compact ? 18 : 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            color: AppColors.textHint,
                            fontSize: 11,
                            height: 1.3)),
                  ] else ...[
                     const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            color: AppColors.textHint,
                            fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: badgeColor.withOpacity(0.15),
                  ),
                  child: Text(badge,
                      style: GoogleFonts.inter(
                          color: badgeColor, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 6),
                Icon(Icons.open_in_new_rounded, color: AppColors.textHint, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyBtn extends StatelessWidget {
  final String number, label;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _EmergencyBtn({
    required this.number, required this.label,
    required this.color, required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrlString('tel:$number'),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Call $number',
                    style: GoogleFonts.inter(
                        color: color, fontWeight: FontWeight.w800, fontSize: 15)),
                Text(label,
                    style: GoogleFonts.inter(
                        color: color.withOpacity(0.8), fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
