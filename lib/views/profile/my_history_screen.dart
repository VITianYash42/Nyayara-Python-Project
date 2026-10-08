import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/complaint_viewmodel.dart';
import '../../models/complaint_model.dart';
import '../legal/official_links_screen.dart';

class MyHistoryScreen extends StatefulWidget {
  const MyHistoryScreen({super.key});

  @override
  State<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends State<MyHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (auth.isAnonymous) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          title: Text('My History',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.backgroundPrimary,
          iconTheme: const IconThemeData(color: AppColors.goldLight),
        ),
        body: _AnonymousGuard(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('My History',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.backgroundPrimary,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.goldPrimary,
          labelColor: AppColors.goldLight,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Complaints'),
            Tab(text: 'Saved FIRs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ComplaintsTab(userId: auth.userId),
          _SavedFIRsTab(),
        ],
      ),
    );
  }
}

// ── Anonymous Guard ─────────────────────────────────────────────────────
class _AnonymousGuard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundCard,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.history_rounded,
                color: AppColors.textHint, size: 48),
          ),
          const SizedBox(height: 20),
          Text('Login to View History',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            'Create an account to save your complaints,\nFIR drafts, and case history securely.',
            style: GoogleFonts.inter(
                color: AppColors.textHint, fontSize: 13, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.login_rounded, color: Colors.black),
            label: Text('Go Back & Login',
                style:
                    GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }
}

// ── Complaints Tab ──────────────────────────────────────────────────────
class _ComplaintsTab extends StatelessWidget {
  final String userId;
  const _ComplaintsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ComplaintViewModel>();
    return StreamBuilder<List<ComplaintModel>>(
      stream: vm.userComplaintStream(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.goldLight));
        }
        final complaints = snap.data ?? [];
        if (complaints.isEmpty) {
          return _EmptyState(
            icon: Icons.inbox_rounded,
            message: 'No complaints filed yet',
            subtitle: 'Your submitted complaints will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (_, i) =>
              _ComplaintHistoryCard(complaint: complaints[i], index: i),
        );
      },
    );
  }
}

class _ComplaintHistoryCard extends StatelessWidget {
  final ComplaintModel complaint;
  final int index;
  const _ComplaintHistoryCard({required this.complaint, required this.index});

  Color get _statusColor {
    switch (complaint.status) {
      case 'Resolved': return AppColors.success;
      case 'Under Investigation': return AppColors.warning;
      case 'Under Review': return AppColors.info;
      default: return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.backgroundCard,
        border: Border.all(
          color: complaint.escalated ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  complaint.caseType,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _statusColor.withValues(alpha: 0.1),
                ),
                child: Text(complaint.status,
                    style: GoogleFonts.inter(
                        color: _statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (complaint.harasserName.isNotEmpty)
            Row(children: [
              const Icon(Icons.person_outline, size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('Reported: ${complaint.harasserName}',
                  style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 12)),
            ]),
          const SizedBox(height: 4),
          Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                complaint.timestamp.toString().substring(0, 10),
                style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 11),
              ),
              const Spacer(),
              if (complaint.escalated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.danger.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger, size: 10),
                      const SizedBox(width: 3),
                      Text('Escalated',
                          style: GoogleFonts.inter(
                              color: AppColors.danger,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OfficialLinksScreen())),
                child: Text('View Links →',
                    style: GoogleFonts.inter(
                        color: AppColors.goldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideX(begin: 0.1);
  }
}

// ── Saved FIRs Tab ──────────────────────────────────────────────────────
class _SavedFIRsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.description_rounded,
      message: 'No FIR Drafts Saved',
      subtitle: 'Generate an FIR from the AI Legal Chat and it will appear here.',
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message, subtitle;
  const _EmptyState(
      {required this.icon, required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textHint, size: 52),
          const SizedBox(height: 16),
          Text(message,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: GoogleFonts.inter(
                  color: AppColors.textHint, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }
}
