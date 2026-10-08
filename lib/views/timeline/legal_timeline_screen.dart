import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../core/app_theme.dart';

class LegalTimelineScreen extends StatefulWidget {
  final int currentStage; // 0-4
  const LegalTimelineScreen({super.key, this.currentStage = 1});

  @override
  State<LegalTimelineScreen> createState() => _LegalTimelineScreenState();
}

class _LegalTimelineScreenState extends State<LegalTimelineScreen> {
  final List<_TimelineStage> _stages = [
    _TimelineStage(
      title: 'Complaint Filed',
      subtitle: 'Internal ICC / HR Report',
      details: 'Complaint submitted to ICC. ICC must respond within 7 days per POSH Act.',
      icon: Icons.description_outlined,
      estimatedDays: '0-7 days',
      legalRef: 'POSH Act S.9',
    ),
    _TimelineStage(
      title: 'FIR / Police Report',
      subtitle: 'First Information Report',
      details: 'File FIR with the nearest police station. Police must begin investigation within 24 hours.',
      icon: Icons.local_police_outlined,
      estimatedDays: '1-3 days',
      legalRef: 'CrPC Section 154',
    ),
    _TimelineStage(
      title: 'Investigation',
      subtitle: 'Police & ICC Inquiry',
      details: 'ICC conducts inquiry within 60 days. Police investigation runs parallel.',
      icon: Icons.search_rounded,
      estimatedDays: '30-90 days',
      legalRef: 'POSH Act S.11',
    ),
    _TimelineStage(
      title: 'Chargesheet / ICC Report',
      subtitle: 'Findings & Recommendations',
      details: 'ICC submits report to employer. Police files chargesheet in court.',
      icon: Icons.article_outlined,
      estimatedDays: '90-120 days',
      legalRef: 'POSH Act S.13',
    ),
    _TimelineStage(
      title: 'Court Proceedings',
      subtitle: 'Trial & Judgment',
      details: 'Court hearings begin. Both sides present evidence. Timeline varies by court.',
      icon: Icons.balance_rounded,
      estimatedDays: '6-24 months',
      legalRef: 'IPC / Special Acts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Legal Timeline',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.goldLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [AppColors.goldPrimary.withOpacity(0.15), Colors.transparent],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.goldPrimary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline_rounded, color: AppColors.goldLight, size: 20),
                    const SizedBox(width: 8),
                    Text('Case Progress',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    const Spacer(),
                    Text('Stage ${widget.currentStage + 1} of ${_stages.length}',
                        style: GoogleFonts.inter(color: AppColors.goldLight, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (widget.currentStage + 1) / _stages.length,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.goldPrimary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _stages.length,
              itemBuilder: (_, i) {
                final stage = _stages[i];
                final isDone = i < widget.currentStage;
                final isCurrent = i == widget.currentStage;
                final isPending = i > widget.currentStage;

                return TimelineTile(
                  alignment: TimelineAlign.manual,
                  lineXY: 0.08,
                  isFirst: i == 0,
                  isLast: i == _stages.length - 1,
                  indicatorStyle: IndicatorStyle(
                    width: 36,
                    height: 36,
                    indicator: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.success
                            : isCurrent
                                ? AppColors.goldPrimary
                                : AppColors.backgroundCard,
                        border: Border.all(
                          color: isDone
                              ? AppColors.success
                              : isCurrent
                                  ? AppColors.goldPrimary
                                  : AppColors.border,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : stage.icon,
                        size: 16,
                        color: isDone
                            ? Colors.white
                            : isCurrent
                                ? Colors.black
                                : AppColors.textHint,
                      ),
                    ),
                  ),
                  beforeLineStyle: LineStyle(
                    color: isDone ? AppColors.success : AppColors.border,
                    thickness: 2,
                  ),
                  afterLineStyle: LineStyle(
                    color: i < widget.currentStage - 1 ? AppColors.success : AppColors.border,
                    thickness: 2,
                  ),
                  endChild: Container(
                    margin: const EdgeInsets.fromLTRB(12, 8, 0, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isCurrent
                          ? AppColors.goldPrimary.withOpacity(0.08)
                          : AppColors.backgroundCard,
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.goldPrimary.withOpacity(0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(stage.title,
                                  style: GoogleFonts.inter(
                                      color: isDone
                                          ? AppColors.success
                                          : isCurrent
                                              ? AppColors.goldLight
                                              : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppColors.goldPrimary.withOpacity(0.2),
                                ),
                                child: Text('CURRENT',
                                    style: GoogleFonts.inter(
                                        color: AppColors.goldLight,
                                        fontSize: 8, fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5)),
                              ),
                          ],
                        ),
                        Text(stage.subtitle,
                            style: GoogleFonts.inter(
                                color: AppColors.textHint, fontSize: 11)),
                        const SizedBox(height: 6),
                        if (!isPending) Text(stage.details,
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 11, height: 1.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule_outlined, size: 12, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(stage.estimatedDays,
                                style: GoogleFonts.inter(
                                    color: AppColors.textHint, fontSize: 10)),
                            const SizedBox(width: 12),
                            const Icon(Icons.balance_outlined, size: 12, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(stage.legalRef,
                                style: GoogleFonts.inter(
                                    color: AppColors.textHint, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().slideX(begin: 0.2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStage {
  final String title, subtitle, details, estimatedDays, legalRef;
  final IconData icon;
  const _TimelineStage({
    required this.title, required this.subtitle, required this.details,
    required this.estimatedDays, required this.legalRef, required this.icon,
  });
}
