import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../../models/complaint_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/complaint_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _harasserCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hrEmailCtrl = TextEditingController();

  String _selectedDept = AppConstants.departments.first;
  String _selectedCaseType = AppConstants.caseTypes.first;
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _complaintId;
  DateTime _incidentDate = DateTime.now();

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.goldLight),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _incidentDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final user = context.read<AuthViewModel>().currentUser;
    final vm = context.read<ComplaintViewModel>();

    // Generate AI email draft first
    await vm.generateHREmail(
      complainantName: user?.name ?? 'Complainant',
      isAnonymous: _isAnonymous,
      harasserName: _harasserCtrl.text.trim(),
      department: _selectedDept,
      incidentDate: _incidentDate.toString().substring(0, 10),
      description: _descCtrl.text.trim(),
    );

    final complaint = ComplaintModel(
      complaintId: '',
      userId: user?.userId ?? 'anonymous',
      userName: _isAnonymous ? null : user?.name,
      harasserName: _harasserCtrl.text.trim(),
      department: _selectedDept,
      description: _descCtrl.text.trim(),
      caseType: _selectedCaseType,
      hrEmail: _hrEmailCtrl.text.isNotEmpty ? _hrEmailCtrl.text.trim() : null,
      anonymous: _isAnonymous,
      timestamp: _incidentDate,
      hrComplaintDraft: vm.generatedHREmail ?? '',
      legalSections: AppConstants.legalSections[_selectedCaseType] ?? [],
    );

    debugPrint("Submitting complaint...");
    final id = await vm.submitComplaint(complaint);
    debugPrint("Submission result ID: $id");
    
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = id != null;
        _complaintId = id;
      });
      
      if (id == null) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Submission Failed: ${vm.errorMessage}'), backgroundColor: Colors.red),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('File Complaint',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          if (_isAnonymous)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.success.withOpacity(0.15),
                border: Border.all(color: AppColors.success.withOpacity(0.4)),
              ),
              child: Text('ANONYMOUS',
                  style: GoogleFonts.inter(
                      color: AppColors.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
        ],
      ),
      body: _submitted ? _SuccessScreen(complaintId: _complaintId!) : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Anonymous toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.backgroundCard,
                    border: Border.all(
                        color: _isAnonymous
                            ? AppColors.success.withOpacity(0.4)
                            : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_off_outlined,
                          color: AppColors.textSecondary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('File Anonymously',
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600)),
                            Text('Your name will be hidden from the HR report',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAnonymous,
                        onChanged: (v) => setState(() => _isAnonymous = v),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 20),
                _sectionLabel('Incident Details'),
                const SizedBox(height: 12),

                // Harasser Name
                TextFormField(
                  controller: _harasserCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Harasser\'s Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 16),

                // Department
                _DropdownField(
                  label: 'Department',
                  value: _selectedDept,
                  items: AppConstants.departments,
                  onChanged: (v) => setState(() => _selectedDept = v!),
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 16),

                // Case Type
                _DropdownField(
                  label: 'Incident Type',
                  value: _selectedCaseType,
                  items: AppConstants.caseTypes,
                  icon: Icons.gavel_outlined,
                  onChanged: (v) => setState(() => _selectedCaseType = v!),
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 16),

                // Incident Date
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.backgroundCard,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AppColors.goldLight, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date of Incident',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary, fontSize: 12)),
                            Text(_incidentDate.toString().substring(0, 10),
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 250.ms).fadeIn(),

                const SizedBox(height: 16),

                // Incident Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 6,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Describe the incident in detail *',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 90),
                      child: Icon(Icons.description_outlined),
                    ),
                  ),
                  validator: (v) => v!.length < 20 ? 'Please provide more detail' : null,
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 20),

                _sectionLabel('HR Notification (Optional)'),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _hrEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'HR / Manager Email',
                    hintText: 'your.hr@company.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ).animate(delay: 350.ms).fadeIn(),

                const SizedBox(height: 12),

                // AI notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.goldPrimary.withOpacity(0.08),
                    border: Border.all(color: AppColors.goldPrimary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.goldLight, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI will automatically generate a formal complaint email for HR on submission.',
                          style: GoogleFonts.inter(color: AppColors.textGold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn(),

                const SizedBox(height: 28),

                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.send_rounded, size: 18, color: Colors.black),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Complaint',
                    style: GoogleFonts.inter(
                        color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ).animate(delay: 500.ms).fadeIn(),

                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '🔒 Your complaint is encrypted and securely stored.',
                    style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Row(
    children: [
      Container(width: 4, height: 16,
          decoration: BoxDecoration(color: AppColors.goldPrimary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.inter(
          color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
    ],
  );
}

class _DropdownField extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final IconData? icon;
  final void Function(String?)? onChanged;

  const _DropdownField({
    required this.label, required this.value,
    required this.items, this.icon, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon ?? Icons.business_outlined),
      ),
      dropdownColor: AppColors.backgroundCard,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint),
      items: items.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
      onChanged: onChanged,
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final String complaintId;
  const _SuccessScreen({required this.complaintId});

  Future<void> _launchEmail(BuildContext context) async {
    final vm = context.read<ComplaintViewModel>();
    final draft = vm.generatedHREmail ?? '';
    if (draft.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email draft available')));
      return;
    }
    
    // Construct mailto
    // Note: We might need to escape content properly
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: '', // Optional: Fill HR email if known
      query: 'subject=Formal Complaint - $complaintId&body=${Uri.encodeComponent(draft)}',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch email app')));
      }
    } catch (e) {
      debugPrint("Email Launch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withOpacity(0.15),
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 52),
            ).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('Complaint Filed!', style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold))
                .animate(delay: 300.ms).fadeIn(),
            const SizedBox(height: 8),
            Text('Reference ID: $complaintId',
                style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 12))
                .animate(delay: 500.ms).fadeIn(),
            const SizedBox(height: 16),
            Text(
              'Your complaint has been securely stored.\nPlease send the generated email to HR to formalize it.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
            ).animate(delay: 600.ms).fadeIn(),
            const SizedBox(height: 24),

            // Email Button
            ElevatedButton.icon(
              onPressed: () => _launchEmail(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.email_outlined),
              label: const Text('📧 Open Email Draft for HR'),
            ).animate(delay: 700.ms).fadeIn(),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to Home',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ).animate(delay: 800.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
