import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../legal/ai_legal_chat_screen.dart';
import '../reporting/complaint_form_screen.dart';
import '../sos/sos_screen.dart';
import '../vault/evidence_vault_screen.dart';
import '../home/mode_selection_screen.dart';

// ── Feminine soft palette ──────────────────────────────────────────────
const Color _rose = Color(0xFFE91E8C);
const Color _roseSoft = Color(0xFFFCE4EC);
const Color _lavender = Color(0xFF9C27B0);
const Color _lavenderSoft = Color(0xFFEDE7F6);
const Color _peach = Color(0xFFFF7043);
const Color _teal = Color(0xFF00897B);
const Color _indigo = Color(0xFF3949AB);

class UserHomeScreen extends StatefulWidget {
  final int initialTab;
  const UserHomeScreen({super.key, this.initialTab = 0});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  final List<Widget> _screens = const [
    _HomeTab(),
    AILegalChatScreen(),
    ComplaintFormScreen(),
    EvidenceVaultScreen(),
    SOSScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.gavel_outlined, Icons.gavel_rounded, 'Legal AI'),
      (Icons.report_outlined, Icons.report_rounded, 'Report'),
      (Icons.lock_outlined, Icons.lock_rounded, 'Vault'),
      (Icons.sos_outlined, Icons.sos_rounded, 'SOS'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12101A),
        border: const Border(top: BorderSide(color: Color(0xFF2A2A3A), width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == currentIndex;
              final isSOS = i == 4;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: isSelected
                                ? (isSOS
                                    ? const LinearGradient(
                                        colors: [Color(0xFFB71C1C), Color(0xFFE53935)])
                                    : const LinearGradient(
                                        colors: [_rose, _lavender],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight))
                                : null,
                          ),
                          child: Icon(
                            isSelected ? item.$2 : item.$1,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF607080),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? (isSOS ? AppColors.danger : _rose)
                                : const Color(0xFF607080),
                            fontSize: 9.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Home Tab ─────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final firstName = user?.name.split(' ').first ?? 'there';

    return Stack(
      children: [
        // ── Gradient background ───────────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A0A2E), // deep purple-black at top
                  Color(0xFF150B22),
                  Color(0xFF0D0D0D), // near-black at bottom
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
        ),

        // ── Soft blobs ───────────────────────────────────────────────
        Positioned(
          top: -60, right: -60,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _rose.withValues(alpha: 0.18),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          top: 80, left: -80,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _lavender.withValues(alpha: 0.12),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        // ── Scrollable content ───────────────────────────────────────
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _Header(greeting: _greeting(), name: firstName)
                    .animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

                const SizedBox(height: 24),

                // Hero welcome card
                _WelcomeHero(name: firstName)
                    .animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // SOS Banner
                _SOSBanner()
                    .animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 28),

                // Section label
                _SectionLabel(label: 'What do you need?'),
                const SizedBox(height: 14),

                // Action Cards
                _ActionGrid(),

                const SizedBox(height: 28),

                _SectionLabel(label: 'Know Your Rights'),
                const SizedBox(height: 14),

                _RightsCards(),

                const SizedBox(height: 28),

                _SectionLabel(label: 'Safety Tips'),
                const SizedBox(height: 14),

                _SafetyTips(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                  colors: [_rose, _lavender],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
            )),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.inter(
                color: const Color(0xFFDDCCFF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4)),
      ],
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String greeting, name;
  const _Header({required this.greeting, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: GoogleFonts.inter(
                      color: const Color(0xFFB0A0CC), fontSize: 13)),
              Text(name,
                  style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        // Notification
        _HeaderIcon(icon: Icons.notifications_outlined, onTap: () {}),
        const SizedBox(width: 10),
        // Mode switch
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ModeSelectionScreen())),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_rose, _lavender],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: _rose.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E1830),
          border: Border.all(color: const Color(0xFF3A2F5A)),
        ),
        child: Icon(icon, color: const Color(0xFFB0A0CC), size: 20),
      ),
    );
  }
}

// ── Welcome Hero ─────────────────────────────────────────────────────
class _WelcomeHero extends StatelessWidget {
  final String name;
  const _WelcomeHero({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1155), Color(0xFF1A0A3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _rose.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
              color: _lavender.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFF48FB1), Color(0xFFCE93D8)],
                  ).createShader(bounds),
                  child: Text('Your shield,\nyour voice.',
                      style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.3)),
                ),
                const SizedBox(height: 8),
                Text('Nyayara is here for you — confidential,\nsafe, and always on your side.',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFB0A0CC),
                        fontSize: 11.5,
                        height: 1.6)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _rose.withValues(alpha: 0.3),
                _lavender.withValues(alpha: 0.15),
              ]),
              border: Border.all(color: _rose.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(Icons.balance_rounded, color: Color(0xFFF48FB1), size: 32),
          ),
        ],
      ),
    );
  }
}

// ── SOS Banner ───────────────────────────────────────────────────────
class _SOSBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SOSScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B0000), Color(0xFFB71C1C), Color(0xFFD32F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            // Pulsing icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.sos_rounded, color: Colors.white, size: 24),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.93, end: 1.07, duration: 1000.ms),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EMERGENCY SOS',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text('Tap to alert your trusted contacts',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 11.5)),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Alert',
                  style: GoogleFonts.inter(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Grid ───────────────────────────────────────────────────────
class _ActionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        icon: Icons.gavel_rounded,
        label: 'AI Legal Help',
        desc: 'FIR & complaint drafts',
        gradient: const LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        glow: _lavender,
        route: 1,
      ),
      _ActionData(
        icon: Icons.report_rounded,
        label: 'File Complaint',
        desc: 'POSH / HR report',
        gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        glow: _indigo,
        route: 2,
      ),
      _ActionData(
        icon: Icons.lock_rounded,
        label: 'Evidence Vault',
        desc: 'Secure your files',
        gradient: const LinearGradient(
            colors: [Color(0xFF004D40), Color(0xFF00897B)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        glow: _teal,
        route: 3,
      ),
      _ActionData(
        icon: Icons.favorite_rounded,
        label: 'My History',
        desc: 'Past complaints',
        gradient: const LinearGradient(
            colors: [Color(0xFF880E4F), Color(0xFFE91E8C)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        glow: _rose,
        route: 0,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) => _ActionCard(data: actions[i], index: i),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label, desc;
  final LinearGradient gradient;
  final Color glow;
  final int route;
  const _ActionData({
    required this.icon, required this.label, required this.desc,
    required this.gradient, required this.glow, required this.route,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionData data;
  final int index;
  const _ActionCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final homeState = context.findAncestorStateOfType<_UserHomeScreenState>();
        homeState?.setState(() => homeState._currentIndex = data.route);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: data.gradient,
          boxShadow: [
            BoxShadow(
                color: data.glow.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: Colors.white, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(data.desc,
                    style: GoogleFonts.inter(
                        color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 300 + index * 80))
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.15);
  }
}

// ── Rights Cards ──────────────────────────────────────────────────────
class _RightsCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rights = [
      (Icons.balance_rounded, 'POSH Act 2013',
          'Right to a safe workplace free from harassment', _lavender),
      (Icons.home_rounded, 'Domestic Violence Act',
          'Protection from all forms of domestic abuse', _rose),
      (Icons.gavel_rounded, 'IPC Section 354',
          'Assault or use of criminal force on women', _peach),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: rights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = rights[i];
          return Container(
            width: 200,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF1A1030),
              border: Border.all(color: r.$4.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(r.$1, color: r.$4, size: 16),
                    const SizedBox(width: 6),
                    Text(r.$2,
                        style: GoogleFonts.inter(
                            color: r.$4, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(r.$3,
                    style: GoogleFonts.inter(
                        color: const Color(0xFFB0A0CC), fontSize: 10.5, height: 1.5),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ).animate(delay: Duration(milliseconds: 400 + i * 100)).fadeIn().slideX(begin: 0.1);
        },
      ),
    );
  }
}

// ── Safety Tips ───────────────────────────────────────────────────────
class _SafetyTips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      ('📸', 'Document every incident with date, time & witnesses'),
      ('💬', 'Save screenshots and emails as evidence'),
      ('🕵️', 'You can report anonymously — identity protected'),
      ('⚖️', 'ICC must respond within 7 days by law'),
      ('🛡️', 'You are protected from retaliation under POSH'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF140E24),
        border: Border.all(color: const Color(0xFF2E2050)),
      ),
      child: Column(
        children: tips.asMap().entries.map((e) {
          final tip = e.value;
          return Padding(
            padding: EdgeInsets.only(bottom: e.key == tips.length - 1 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.$1, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(tip.$2,
                      style: GoogleFonts.inter(
                          color: const Color(0xFFB0A0CC),
                          fontSize: 12, height: 1.55)),
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: 500 + e.key * 60)).fadeIn().slideX(begin: 0.05);
        }).toList(),
      ),
    );
  }
}
