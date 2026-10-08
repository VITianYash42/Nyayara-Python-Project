import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../../models/complaint_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/complaint_viewmodel.dart';
import '../home/mode_selection_screen.dart';
import '../timeline/legal_timeline_screen.dart';

class HRDashboardScreen extends StatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  State<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends State<HRDashboardScreen> {
  List<ComplaintModel> _complaints = [];
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    // Listen to real Firestore stream for all complaints
    context.read<ComplaintViewModel>().allComplaintsStream().listen((list) {
      if (mounted) setState(() => _complaints = list);
    });
  }

  List<ComplaintModel> get _filtered => _statusFilter == 'All'
      ? _complaints
      : _complaints.where((c) => c.status == _statusFilter).toList();

  int get _highCount => _complaints.where((c) => c.severityScore == 'High').length;
  int get _escalatedCount => _complaints.where((c) => c.escalated).length;
  int get _resolvedCount => _complaints.where((c) => c.status == 'Resolved').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HR Dashboard',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
            Text(AppConstants.demoOrgName,
                style: GoogleFonts.inter(color: AppColors.textGold, fontSize: 10)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.goldLight),
          onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const ModeSelectionScreen())),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textHint),
            onPressed: () async {
              await context.read<AuthViewModel>().signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                _StatCard(label: 'Total', value: '${_complaints.length}',
                    icon: Icons.folder_copy, color: AppColors.info),
                const SizedBox(width: 12),
                _StatCard(label: 'High Risk', value: '$_highCount',
                    icon: Icons.warning_rounded, color: AppColors.danger),
                const SizedBox(width: 12),
                _StatCard(label: 'Escalated', value: '$_escalatedCount',
                    icon: Icons.trending_up, color: AppColors.warning),
                const SizedBox(width: 12),
                _StatCard(label: 'Resolved', value: '$_resolvedCount',
                    icon: Icons.check_circle, color: AppColors.success),
              ],
            ).animate().fadeIn(),

            const SizedBox(height: 20),

            // Escalation Alert
            if (_escalatedCount > 0)
              _EscalationAlert(count: _escalatedCount)
                  .animate().fadeIn().slideY(begin: -0.2),

            const SizedBox(height: 20),

            // Severity Chart
            _SeverityChart(complaints: _complaints).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 20),

            // Department Heatmap
            _DepartmentHeatmap(complaints: _complaints).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 20),

            // Complaints List
            Row(
              children: [
                Text('All Complaints',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const Spacer(),
                // Filter
                DropdownButton<String>(
                  value: _statusFilter,
                  dropdownColor: AppColors.backgroundCard,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint, size: 16),
                  items: ['All', ...AppConstants.departments.take(0),
                    AppConstants.statusPending,
                    AppConstants.statusUnderReview,
                    AppConstants.statusInvestigating,
                    AppConstants.statusResolved,
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _statusFilter = v!),
                ),
              ],
            ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: 12),

            ..._filtered.asMap().entries.map((e) =>
                _ComplaintCard(
                    complaint: e.value,
                    index: e.key,
                    onStatusChange: (s) => setState(() {
                      final idx = _complaints.indexOf(e.value);
                      _complaints[idx] = e.value.copyWith(status: s);
                    }))),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.backgroundCard,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
            Text(label, style: GoogleFonts.inter(
                color: AppColors.textHint, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _EscalationAlert extends StatelessWidget {
  final int count;
  const _EscalationAlert({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.danger.withOpacity(0.08),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: AppColors.danger.withOpacity(0.15)),
            child: const Icon(Icons.warning_rounded, color: AppColors.danger, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count Complaints Escalated!',
                    style: GoogleFonts.inter(
                        color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Repeat offenders detected. Immediate action required per POSH Act.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.danger),
        ],
      ),
    );
  }
}

class _SeverityChart extends StatelessWidget {
  final List<ComplaintModel> complaints;
  const _SeverityChart({required this.complaints});

  @override
  Widget build(BuildContext context) {
    final high = complaints.where((c) => c.severityScore == 'High').length.toDouble();
    final medium = complaints.where((c) => c.severityScore == 'Medium').length.toDouble();
    final low = complaints.where((c) => c.severityScore == 'Low').length.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Severity Distribution',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                            value: high, color: AppColors.danger,
                            title: '${high.toInt()}', titleStyle: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        PieChartSectionData(
                            value: medium, color: AppColors.warning,
                            title: '${medium.toInt()}', titleStyle: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        PieChartSectionData(
                            value: low == 0 ? 0.001 : low, color: AppColors.success,
                            title: low == 0 ? '' : '${low.toInt()}', titleStyle: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                      sectionsSpace: 3,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Legend(color: AppColors.danger, label: 'High', count: high.toInt()),
                    const SizedBox(height: 8),
                    _Legend(color: AppColors.warning, label: 'Medium', count: medium.toInt()),
                    const SizedBox(height: 8),
                    _Legend(color: AppColors.success, label: 'Low', count: low.toInt()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _Legend({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(
            shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text('$label ($count)', style: GoogleFonts.inter(
            color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _DepartmentHeatmap extends StatelessWidget {
  final List<ComplaintModel> complaints;
  const _DepartmentHeatmap({required this.complaints});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> deptCount = {};
    for (final c in complaints) {
      deptCount[c.department] = (deptCount[c.department] ?? 0) + 1;
    }
    final sorted = deptCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.isNotEmpty ? sorted.first.value : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Department Heatmap',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          ...sorted.map((entry) {
            final intensity = entry.value / maxCount;
            final color = Color.lerp(
                AppColors.goldPrimary.withOpacity(0.3), AppColors.danger, intensity)!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(entry.key,
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12))),
                      Text('${entry.value} case${entry.value > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: intensity,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final int index;
  final void Function(String) onStatusChange;

  const _ComplaintCard({
    required this.complaint, required this.index, required this.onStatusChange});

  Color get _severityColor {
    switch (complaint.severityScore) {
      case 'High': return AppColors.danger;
      case 'Medium': return AppColors.warning;
      default: return AppColors.success;
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
          color: complaint.escalated ? AppColors.danger.withOpacity(0.4) : AppColors.border,
          width: complaint.escalated ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (complaint.escalated)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.danger.withOpacity(0.15),
                  ),
                  child: Text('ESCALATED',
                      style: GoogleFonts.inter(
                          color: AppColors.danger, fontSize: 8, fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ),
              Expanded(
                child: Text(
                  complaint.anonymous ? 'Anonymous Report' : (complaint.userName ?? 'Unknown'),
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _severityColor.withOpacity(0.15),
                ),
                child: Text(complaint.severityScore,
                    style: GoogleFonts.inter(
                        color: _severityColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('vs. ${complaint.harasserName}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 10),
              const Icon(Icons.business_outlined, size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(complaint.department,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(complaint.description,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(complaint.timestamp.toString().substring(0, 10),
                  style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 10)),
              const Spacer(),
              // Status Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.backgroundElevated,
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButton<String>(
                  value: complaint.status,
                  isDense: true,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.backgroundCard,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                  items: [
                    AppConstants.statusPending,
                    AppConstants.statusUnderReview,
                    AppConstants.statusInvestigating,
                    AppConstants.statusResolved,
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (s) => onStatusChange(s!),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LegalTimelineScreen())),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.goldPrimary.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.timeline_rounded, color: AppColors.goldLight, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideY(begin: 0.1);
  }
}
