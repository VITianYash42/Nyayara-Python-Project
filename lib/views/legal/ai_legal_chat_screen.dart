import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/complaint_viewmodel.dart';
import '../../services/ai_service.dart';

/// Returns true if the case type is workplace-related
bool _isWorkplace(String caseType) {
  final lower = caseType.toLowerCase();
  return lower.contains('workplace') ||
      lower.contains('posh') ||
      lower.contains('sexual harassment of women at workplace') ||
      lower.contains('hr') ||
      lower.contains('office') ||
      lower.contains('colleague') ||
      lower.contains('manager') ||
      lower.contains('employer');
}

/// Returns true if the case type is cyber-related
bool _isCyber(String caseType) {
  final lower = caseType.toLowerCase();
  return lower.contains('cyber') ||
      lower.contains('online') ||
      lower.contains('stalking') ||
      lower.contains('deepfake') ||
      lower.contains('blackmail') ||
      lower.contains('revenge') ||
      lower.contains('social media');
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class AILegalChatScreen extends StatefulWidget {
  const AILegalChatScreen({super.key});

  @override
  State<AILegalChatScreen> createState() => _AILegalChatScreenState();
}

class _AILegalChatScreenState extends State<AILegalChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isAnalyzing = false;
  AIAnalysisResult? _currentAnalysis;

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      'Hello. I am Nyayara — your confidential legal assistant.\n\n'
      'Describe what happened to you. I will help you understand your rights, '
      'identify relevant laws, and draft your FIR or complaint letter.\n\n'
      '🔒 Everything you share is strictly confidential.',
    );
  }

  void _addBotMessage(String text, {bool isAnalysis = false, AIAnalysisResult? result}) {
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: false,
        isAnalysis: isAnalysis,
        result: result,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isAnalyzing) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isAnalyzing = true;
    });
    _scrollToBottom();

    final vm = context.read<ComplaintViewModel>();
    await vm.analyzeIncident(text);
    final result = vm.latestAnalysis;

    if (result != null && mounted) {
      _currentAnalysis = result;
      _addBotMessage(result.aiSummary, isAnalysis: true, result: result);
      await Future.delayed(const Duration(milliseconds: 400));
      _addBotMessage(
          '📋 **Next Step**: ${result.nextBestAction}\n\n'
          '⚖️ **Similar Cases**: ${result.similarCaseSummary}\n\n'
          'Type "generate FIR" or "generate HR complaint" to create your document.',
      );
    }

    if (mounted) setState(() => _isAnalyzing = false);
  }

  Future<void> _handleSpecialCommand(String cmd) async {
    print('DEBUG: _handleSpecialCommand called with: $cmd');
    final vm = context.read<ComplaintViewModel>();
    final user = context.read<AuthViewModel>().currentUser;

    try {
      if (cmd.contains('fir')) {
        if (_currentAnalysis == null) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the incident first.')));
           return;
        }

        // Show pre-FIR detail collection dialog first
        final details = await showDialog<Map<String, String>>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _FIRDetailsDialog(
            userName: user?.name ?? '',
            caseType: _currentAnalysis!.caseType,
          ),
        );

        if (details == null || !mounted) return;

        setState(() => _isAnalyzing = true);
        await vm.generateFIR(
          complainantName: details['name'] ?? user?.name ?? 'Complainant',
          incidentDate: details['date'] ?? DateTime.now().toString().substring(0, 10),
          incidentLocation: details['location'] ?? '[Location]',
          description: details['description'] ?? _messages.firstWhere((m) => m.isUser).text,
          caseType: _currentAnalysis!.caseType,
        );

        if (mounted) {
          setState(() => _isAnalyzing = false);
          _showDocumentDialog('FIR Draft', vm.generatedFIR ?? 'Error generating FIR');
        }
      } else if (cmd.contains('hr') || cmd.contains('complaint') || cmd.contains('shebox')) {
        setState(() => _isAnalyzing = true);
        await vm.generateHREmail(
          complainantName: user?.name ?? 'Employee',
          isAnonymous: user?.anonymousFlag ?? false,
          harasserName: '[Harasser Name — you will fill in the document]',
          department: '[Department]',
          incidentDate: DateTime.now().toString().substring(0, 10),
          description: _messages.firstWhere((m) => m.isUser).text,
        );
        if (mounted) {
          setState(() => _isAnalyzing = false);
          _showDocumentDialog('HR / SHe-Box Complaint', vm.generatedHREmail ?? 'Error');
        }
      }
    } catch (e, stack) {
      print('Critical Error in _handleSpecialCommand: $e\n$stack');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDocumentDialog(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DocumentBottomSheet(title: title, content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, gradient: AppColors.goldGradient),
              child: const Icon(Icons.psychology_rounded, size: 18, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Legal AI Assistant',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                Text('Powered by Nyayara',
                    style: GoogleFonts.inter(color: AppColors.textGold, fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.success.withOpacity(0.15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.successLight)),
                const SizedBox(width: 4),
                Text('Online',
                    style: GoogleFonts.inter(color: AppColors.successLight, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Prompts
          _QuickPromptsBar(onSelect: (p) {
            _inputCtrl.text = p;
            _sendMessage();
          }),

          // Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isAnalyzing ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isAnalyzing && i == _messages.length) {
                  return const _TypingIndicator();
                }
                return _messages[i].isAnalysis
                    ? _AnalysisCard(
                        result: _messages[i].result!,
                        message: _messages[i],
                        onGenerateFIR: () => _handleSpecialCommand('fir'),
                        onGenerateHR: () => _handleSpecialCommand('hr complaint'),
                      )
                    : _ChatBubble(message: _messages[i]);
              },
            ),
          ),

          // Input Area
          _ChatInputBar(
            controller: _inputCtrl,
            onSend: () {
              final lower = _inputCtrl.text.toLowerCase();
              if (lower.contains('fir') || lower.contains('hr complaint') || lower.contains('generate')) {
                final cmd = lower;
                _inputCtrl.clear();
                _handleSpecialCommand(cmd);
              } else {
                _sendMessage();
              }
            },
            isLoading: _isAnalyzing,
          ),
        ],
      ),
    );
  }
}

class _QuickPromptsBar extends StatelessWidget {
  final void Function(String) onSelect;
  const _QuickPromptsBar({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final prompts = [
      'My manager keeps making inappropriate jokes',
      'Someone is stalking me online',
      'My colleague sent me unwanted messages',
      'I faced domestic violence',
    ];
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: prompts.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            print('DEBUG: QuickPrompt tapped: ${prompts[i]}');
            onSelect(prompts[i]);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.backgroundCard,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(prompts[i],
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isAnalysis;
  final AIAnalysisResult? result;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isAnalysis = false,
    this.result,
    required this.timestamp,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, gradient: AppColors.goldGradient),
              child: const Icon(Icons.psychology_rounded, size: 16, color: Colors.black),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                color: message.isUser ? AppColors.goldPrimary : AppColors.backgroundCard,
                border: message.isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                    color: message.isUser ? Colors.black : AppColors.textPrimary,
                    fontSize: 13, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final AIAnalysisResult result;
  final _ChatMessage message;
  final VoidCallback onGenerateFIR;
  final VoidCallback onGenerateHR;

  const _AnalysisCard({
    required this.result,
    required this.message,
    required this.onGenerateFIR,
    required this.onGenerateHR,
  });

  @override
  Widget build(BuildContext context) {
    final isWorkplace = _isWorkplace(result.caseType);
    final isCyber = _isCyber(result.caseType);
    final severityColor = result.severityScore == 'High' || result.severityScore == 'Critical'
        ? AppColors.danger
        : result.severityScore == 'Medium'
            ? AppColors.warning
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.goldPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded, color: AppColors.goldLight, size: 20),
              const SizedBox(width: 8),
              Text('AI Analysis Complete',
                  style: GoogleFonts.inter(
                      color: AppColors.goldLight, fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: severityColor.withOpacity(0.15),
                ),
                child: Text(result.severityScore,
                    style: GoogleFonts.inter(
                        color: severityColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 20),
          Text(result.aiSummary,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, height: 1.6)),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _Stat(label: 'Case Type', value: result.caseType),
              const SizedBox(width: 8),
              _Stat(label: 'Severity', value: '${result.severityPercent}%', color: severityColor),
              const SizedBox(width: 8),
              _Stat(label: 'Case Strength', value: '${result.caseStrengthPercent}%', color: AppColors.goldLight),
            ],
          ),
          const SizedBox(height: 12),

          // Legal sections
          Text('Applicable Laws',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...result.legalSections.take(3).map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚖️ ', style: TextStyle(fontSize: 12)),
                Expanded(child: Text(s,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, height: 1.4))),
              ],
            ),
          )),

          const SizedBox(height: 14),

          // ── Next Steps Guidance ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: (isWorkplace
                      ? const Color(0xFF9C27B0)
                      : isCyber
                          ? const Color(0xFF2196F3)
                          : AppColors.danger)
                  .withOpacity(0.08),
              border: Border.all(
                color: (isWorkplace
                        ? const Color(0xFF9C27B0)
                        : isCyber
                            ? const Color(0xFF2196F3)
                            : AppColors.danger)
                    .withOpacity(0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWorkplace
                      ? '🏢 Workplace Harassment — Recommended Steps'
                      : isCyber
                          ? '💻 Cyber Crime — Recommended Steps'
                          : '👮 How to File Your FIR — Steps',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (isWorkplace) ...[
                  _Step('1', 'Document all incidents with dates, times & witnesses.'),
                  _Step('2', 'Report to Internal Complaints Committee (ICC) or HR dept.'),
                  _Step('3', 'File formally on SHe-Box (shebox.nic.in) — forwarded to ICC/LCC.'),
                  _Step('4', 'If unresolved in 60 days, approach Labour Commissioner.'),
                  _Step('5', 'For severe abuse, an FIR can also be filed under IPC 354.'),
                ] else if (isCyber) ...[
                  _Step('1', 'Screenshot and save ALL evidence before reporting.'),
                  _Step('2', 'Call 1930 (Cyber Crime Helpline) immediately.'),
                  _Step('3', 'File complaint on cybercrime.gov.in — police receive it directly.'),
                  _Step('4', 'For serious cases (deepfake, blackmail), also file physical FIR.'),
                ] else ...[
                  _Step('1', 'Ensure your safety first — call 112 if in immediate danger.'),
                  _Step('2', 'Collect evidence: messages, photos, medical reports, witnesses.'),
                  _Step('3', 'Draft your FIR below — review carefully before submitting.'),
                  _Step('4', 'Visit your nearest police station with the PDF printout.'),
                  _Step('5', 'You have the right to demand a copy of the FIR (free of charge).'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Action Buttons — context-aware ───────────────────────
          if (isWorkplace) ...[
            _ActionButton(
              label: 'Generate HR Complaint',
              icon: Icons.email_outlined,
              onTap: onGenerateHR,
            ),
            const SizedBox(height: 8),
            _PortalButton(
              label: 'File on SHe-Box (Workplace Portal)',
              url: 'https://shebox.nic.in',
              color: const Color(0xFF9C27B0),
              icon: Icons.open_in_new_rounded,
            ),
            const SizedBox(height: 6),
            _GuidanceChip('FIR can also be filed under IPC 354 for severe cases.',
                icon: Icons.info_outline),
          ] else if (isCyber) ...[
            _PortalButton(
              label: 'Submit to Cyber Crime Portal',
              url: 'https://cybercrime.gov.in',
              color: const Color(0xFF2196F3),
              icon: Icons.open_in_new_rounded,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Also Generate FIR Draft',
              icon: Icons.description_outlined,
              onTap: onGenerateFIR,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Generate FIR Draft',
                    icon: Icons.description_outlined,
                    onTap: onGenerateFIR,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PortalButton(
                    label: 'State e-FIR',
                    url: 'https://cybercrime.gov.in',
                    color: AppColors.danger,
                    icon: Icons.open_in_new_rounded,
                    compact: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String num, text;
  const _Step(this.num, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18, height: 18,
            margin: const EdgeInsets.only(right: 8, top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldPrimary.withOpacity(0.2),
            ),
            child: Center(
              child: Text(num,
                  style: GoogleFonts.inter(
                      color: AppColors.goldLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 11, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _GuidanceChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _GuidanceChip(this.text, {required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.backgroundElevated,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textHint, size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    color: AppColors.textHint, fontSize: 10, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _PortalButton extends StatelessWidget {
  final String label, url;
  final Color color;
  final IconData icon;
  final bool compact;
  const _PortalButton({
    required this.label, required this.url,
    required this.color, required this.icon,
    this.compact = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            print('DEBUG: PortalButton tapped: $label');
            _launchUrl(url);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 9 : 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: GoogleFonts.inter(
                        color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.backgroundElevated,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 9)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.inter(
                    color: color ?? AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: AppColors.goldGradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            print('DEBUG: ActionButton tapped: $label');
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: Colors.black),
                const SizedBox(width: 4),
                Text(label,
                    style: GoogleFonts.inter(
                        color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient),
            child: const Icon(Icons.psychology_rounded, size: 16, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: const Radius.circular(4)),
              color: AppColors.backgroundCard,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.goldPrimary),
              ).animate(onPlay: (c) => c.repeat()).fadeOut(
                      duration: 600.ms, delay: Duration(milliseconds: i * 200))),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                maxLines: 3,
                minLines: 1,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Describe what happened…',
                  hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.goldPrimary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: isLoading ? null : onSend,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isLoading ? null : AppColors.goldGradient,
                  color: isLoading ? AppColors.backgroundCard : null,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldLight))
                    : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentBottomSheet extends StatelessWidget {
  final String title;
  final String content;
  const _DocumentBottomSheet({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.description_rounded, color: AppColors.goldLight),
                const SizedBox(width: 10),
                Text(title,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppColors.goldLight),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textHint),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.backgroundCard,
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  content,
                  style: GoogleFonts.robotoMono(
                      color: AppColors.textPrimary, fontSize: 11, height: 1.6),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Save Document'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FIRDetailsDialog extends StatefulWidget {
  final String userName;
  final String caseType;

  const _FIRDetailsDialog({required this.userName, required this.caseType});

  @override
  State<_FIRDetailsDialog> createState() => _FIRDetailsDialogState();
}

class _FIRDetailsDialogState extends State<_FIRDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  final _dateCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.userName);
    _dateCtrl.text = DateTime.now().toString().substring(0, 10);
  }

  Future<void> _getCurrentLocation() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetching location...'), duration: Duration(seconds: 1)),
      );

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied')));
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
      
      // Use a custom User-Agent as per Nominatim policy
      final response = await http.get(url, headers: {'User-Agent': 'SaheliAI_Prototype/1.0'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Prioritize 'display_name'
        final address = data['display_name']; 
        if (mounted) {
            setState(() {
                _locationCtrl.text = address ?? "Lat: ${position.latitude}, Lng: ${position.longitude}";
            });
        }
      } else {
        if (mounted) {
            setState(() {
                _locationCtrl.text = "Lat: ${position.latitude}, Lng: ${position.longitude}";
            });
        }
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.description_rounded, color: AppColors.goldLight),
          const SizedBox(width: 12),
          Text('Draft FIR Details',
              style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please provide precise details for the official FIR draft.',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _DialogField(
                label: 'Complainant Name',
                controller: _nameCtrl,
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _DialogField(
                label: 'Incident Date',
                controller: _dateCtrl,
                icon: Icons.calendar_today_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _DialogField(
                label: 'Location',
                controller: _locationCtrl,
                icon: Icons.place_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: Text('Use Current Location', style: GoogleFonts.inter(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.goldLight,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _DialogField(
                label: 'Detailed Description',
                controller: _descCtrl,
                icon: Icons.subject,
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textHint)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameCtrl.text.trim(),
                'date': _dateCtrl.text.trim(),
                'location': _locationCtrl.text.trim(),
                'description': _descCtrl.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.goldPrimary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Generate Draft', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _DialogField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: AppColors.goldLight),
            filled: true,
            fillColor: AppColors.backgroundCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.goldPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
