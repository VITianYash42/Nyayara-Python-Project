import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/app_theme.dart';
import '../../core/app_constants.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'trusted_contacts_screen.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  bool _sosSent = false;
  bool _isCounting = false;
  int _countdown = 3;
  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  bool _isSafe = false;
  int _safeTimer = 30 * 60;
  Timer? _safeTimerTick;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _rippleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _countdownTimer?.cancel();
    _safeTimerTick?.cancel();
    super.dispose();
  }

  void _startSOS() {
    if (_isCounting || _sosSent) return;
    setState(() {
      _isCounting = true;
      _countdown = 3;
    });
    try { Vibration.vibrate(duration: 200); } catch (_) {}

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        _triggerSOS();
      } else {
        setState(() => _countdown--);
        try { Vibration.vibrate(duration: 100); } catch (_) {}
      }
    });
  }

  void _cancelSOS() {
    _countdownTimer?.cancel();
    setState(() {
      _isCounting = false;
      _countdown = 3;
    });
  }

  Future<void> _triggerSOS() async {
    if (!kIsWeb) {
      try { Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500], amplitude: 255); } catch (_) {}
    }
    setState(() {
      _sosSent = true;
      _isCounting = false;
    });

    final auth = context.read<AuthViewModel>();
    final contacts = auth.trustedContacts;
    final userName = auth.isSignedIn
        ? (auth.currentUser?.name ?? 'A Nyayara User')
        : 'A Nyayara User';

    // 1. Get Location
    Position? position;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      }
    } catch (e) {
      debugPrint("Location Error: $e");
    }

    final locationLink = position != null 
        ? 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}' 
        : 'Unknown Location';

    // 2. Auto-Trigger SMS & Call to Trusted Contacts
    final phones = contacts.map((c) => c['phone'].toString()).toList();
    debugPrint("SOS: Contacts found: ${phones.length}");

    if (phones.isNotEmpty) {
      // Send SMS
      final message = _emergencyMessage(userName, locationLink);
      final smsUri = Uri.parse('sms:${phones.join(',')}?body=$message');
      
      try {
        debugPrint("SOS: Launching SMS: $smsUri");
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        } else {
            debugPrint("SOS: Could not launch SMS intent");
        }
      } catch (e) {
        debugPrint("SOS SMS Error: $e");
      }

      // Wait slightly
      await Future.delayed(const Duration(seconds: 2));

      // Call the FIRST contact
      debugPrint("SOS: Calling: ${phones.first}");
      _callNumber(phones.first);
    } else {
        debugPrint("SOS: No trusted contacts to notify!");
    }
    
    // 3. Save to Firestore
    try {
      await FirebaseFirestore.instance.collection('sos_alerts').add({
        'userId': auth.userId,
        'userName': userName,
        'location': locationLink,
        'contactsNotified': phones,
        'timestamp': FieldValue.serverTimestamp(),
        'resolved': false,
      });
    } catch (_) {}

    // 4. Show dispatch dialog
    if (mounted) {
      _showDispatchDialog(contacts, userName, locationLink);
    }
  }

  /// Emergency message to share via WhatsApp / SMS
  String _emergencyMessage(String name, [String? locationLink]) {
    final time = DateTime.now();
    return Uri.encodeComponent(
      '🚨 EMERGENCY ALERT from $name via Nyayara\n\n'
      'I need immediate help! This is an automated SOS.\n'
      'Time: ${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}\n'
      'Location: ${locationLink ?? "Tracking..."}\n\n'
      'Please call me or contact police at 112 immediately.',
    );
  }

  Future<void> _callNumber(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsAppAlert(String phone, String message) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Prepend 91 for India if not there
    final intlPhone = clean.startsWith('91') ? clean : '91$clean';
    final uri = Uri.parse('https://wa.me/$intlPhone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDispatchDialog(
      List<Map<String, dynamic>> contacts, String senderName, String? locationLink) {
    final message = _emergencyMessage(senderName, locationLink);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.sos_rounded, color: AppColors.danger, size: 32),
            ),
            const SizedBox(height: 12),
            Text('🚨 SOS Triggered!',
                style: GoogleFonts.inter(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(height: 4),
            Text('Tap to call or WhatsApp each contact',
                style: GoogleFonts.inter(
                    color: AppColors.textHint, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (contacts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.warning.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 28),
                      const SizedBox(height: 8),
                      Text('No trusted contacts added yet.',
                          style: GoogleFonts.inter(
                              color: AppColors.warning, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Call 112 (Police) immediately!',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                )
              else
                ...contacts.map((c) {
                  final phone = c['phone'] as String? ?? '';
                  final name = c['name'] as String? ?? 'Contact';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.backgroundCard,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppColors.goldPrimary.withValues(alpha: 0.15),
                              child: Text(
                                name[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: GoogleFonts.inter(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700)),
                                  Text('+91 $phone',
                                      style: GoogleFonts.inter(
                                          color: AppColors.textHint,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Call button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _callNumber(phone),
                                icon: const Icon(Icons.call_rounded,
                                    color: Colors.white, size: 14),
                                label: Text('Call Now',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // WhatsApp button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _whatsAppAlert(phone, message),
                                icon: const Icon(Icons.message_rounded,
                                    color: Colors.white, size: 14),
                                label: Text('WhatsApp',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 8),
              const Divider(color: AppColors.border),
              const SizedBox(height: 4),

              // Emergency 112 always visible
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _callNumber('112'),
                      icon: const Icon(Icons.local_police_rounded,
                          color: Colors.white, size: 16),
                      label: Text('Call 112 — Police',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _markSafe();
            },
            child: Text("I'm Safe — Cancel SOS",
                style: GoogleFonts.inter(
                    color: AppColors.success, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.inter(color: AppColors.textHint)),
          ),
        ],
      ),
    );
  }

  void _markSafe() {
    setState(() {
      _sosSent = false;
      _isSafe = true;
    });
    _safeTimerTick?.cancel();
    _safeTimerTick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_safeTimer <= 0) {
        t.cancel();
        setState(() => _isSafe = false);
      } else {
        setState(() => _safeTimer--);
      }
    });
  }

  String get _safeTimerDisplay {
    final m = _safeTimer ~/ 60;
    final s = _safeTimer % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Text('SOS Shield',
                      style: GoogleFonts.playfairDisplay(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _sosSent
                          ? AppColors.danger.withOpacity(0.15)
                          : AppColors.success.withOpacity(0.15),
                      border: Border.all(
                          color: _sosSent ? AppColors.danger : AppColors.success,
                          width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _sosSent ? AppColors.danger : AppColors.success,
                          ),
                        ).animate(onPlay: (c) => c.repeat())
                            .fadeOut(duration: 800.ms),
                        const SizedBox(width: 6),
                        Text(_sosSent ? 'ALERT ACTIVE' : 'READY',
                            style: GoogleFonts.inter(
                                color: _sosSent ? AppColors.danger : AppColors.success,
                                fontSize: 11, fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // SOS Button (Large)
              _BuildSOSButton(
                isCounting: _isCounting,
                countdown: _countdown,
                sosSent: _sosSent,
                isSafe: _isSafe,
                pulseAnim: _pulseController,
                rippleAnim: _rippleController,
                onPress: _startSOS,
                onCancel: _cancelSOS,
                onSafe: _markSafe,
              ),

              const SizedBox(height: 32),

              if (_sosSent) ...[
                _AlertSentBanner().animate().fadeIn().slideY(begin: 0.3),
                const SizedBox(height: 20),
              ],

              if (_isSafe)
                _SafeCheckInBanner(timer: _safeTimerDisplay).animate().fadeIn(),

              // Location Info
              _LocationCard(),
              const SizedBox(height: 16),

          // Trusted Contacts (real from Firestore)
              _TrustedContactsList(
                contacts: context.watch<AuthViewModel>().trustedContacts,
                alerted: _sosSent,
              ),
              const SizedBox(height: 16),

              // Emergency Numbers
              _EmergencyNumbers(),
              const SizedBox(height: 16),

              // Instructions
              _SOSInstructions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildSOSButton extends StatelessWidget {
  final bool isCounting, sosSent, isSafe;
  final int countdown;
  final AnimationController pulseAnim, rippleAnim;
  final VoidCallback onPress, onCancel, onSafe;

  const _BuildSOSButton({
    required this.isCounting, required this.countdown,
    required this.sosSent, required this.isSafe,
    required this.pulseAnim, required this.rippleAnim,
    required this.onPress, required this.onCancel, required this.onSafe,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple rings
        if (sosSent) ...[
          for (int i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: rippleAnim,
              builder: (_, __) {
                final delay = i * 0.33;
                final value = ((rippleAnim.value + delay) % 1.0);
                return Container(
                  width: 120 + (value * 100),
                  height: 120 + (value * 100),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.danger.withOpacity((1 - value) * 0.5),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
        ],

        // Main SOS Circle
        GestureDetector(
          onTap: sosSent ? null : (isCounting ? onCancel : onPress),
          child: AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: sosSent ? 1.0 + (pulseAnim.value * 0.05) : 1.0,
              child: child,
            ),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCounting
                    ? const LinearGradient(
                        colors: [Color(0xFFF57C00), Color(0xFFFF9800)])
                    : sosSent
                        ? AppColors.dangerGradient
                        : const LinearGradient(
                            colors: [AppColors.danger, Color(0xFFB71C1C)]),
                boxShadow: [
                  BoxShadow(
                    color: (isCounting ? AppColors.warning : AppColors.danger)
                        .withOpacity(sosSent ? 0.6 : 0.4),
                    blurRadius: sosSent ? 40 : 25,
                    spreadRadius: sosSent ? 10 : 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCounting) ...[
                    Text('$countdown',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 60,
                            fontWeight: FontWeight.w900)),
                    Text('tap to cancel',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                  ] else if (sosSent) ...[
                    const Icon(Icons.sos_rounded, color: Colors.white, size: 52),
                    Text('ALERT SENT',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2)),
                  ] else ...[
                    const Icon(Icons.sos_rounded, color: Colors.white, size: 52),
                    Text('SOS',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3)),
                    Text('press & hold',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertSentBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.danger.withOpacity(0.08),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.danger, size: 20),
              const SizedBox(width: 8),
              Text('SOS Alert Sent!',
                  style: GoogleFonts.inter(
                      color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your live location has been sent to 3 trusted contacts. They have been notified via SMS and call.',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () =>
                (context.findAncestorStateOfType<_SOSScreenState>())?.._markSafe(),
            icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.black),
            label: Text("I'm Safe Now",
                style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeCheckInBanner extends StatelessWidget {
  final String timer;
  const _SafeCheckInBanner({required this.timer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.success.withOpacity(0.08),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safe Check-in Active',
                    style: GoogleFonts.inter(
                        color: AppColors.success, fontWeight: FontWeight.w700)),
                Text('Contacts notified. Timer: $timer',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.goldPrimary.withOpacity(0.15),
            ),
            child: const Icon(Icons.location_on, color: AppColors.goldLight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Location',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                Text('GPS Active • Tracking enabled',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.successLight),
          ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms),
        ],
      ),
    );
  }
}

class _TrustedContactsList extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;
  final bool alerted;
  const _TrustedContactsList({required this.contacts, required this.alerted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Trusted Contacts',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const TrustedContactsScreen())),
              icon: const Icon(Icons.manage_accounts_outlined,
                  size: 14, color: AppColors.goldLight),
              label: Text('Manage',
                  style:
                      GoogleFonts.inter(color: AppColors.goldLight, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (contacts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.backgroundCard,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.group_add_outlined,
                    color: AppColors.textHint, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No trusted contacts yet. Add family & friends who will be alerted.',
                    style: GoogleFonts.inter(
                        color: AppColors.textHint, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          ...contacts.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.backgroundCard,
                  border: Border.all(
                      color: alerted
                          ? AppColors.danger.withValues(alpha: 0.3)
                          : AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.goldPrimary.withValues(alpha: 0.15),
                      child: Text(
                          (c['name'] as String? ?? 'U')[0].toUpperCase(),
                          style: GoogleFonts.inter(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['name'] ?? 'Contact',
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(
                              '+91 ${c['phone']} • ${c['relation'] ?? ''}',
                              style: GoogleFonts.inter(
                                  color: AppColors.textHint, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (alerted)
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                  ],
                ),
              )),
      ],
    );
  }
}

class _EmergencyNumbers extends StatelessWidget {
  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final numbers = [
      {'number': AppConstants.helplinePolice, 'label': 'Police Emergency', 'color': AppColors.danger},
      {'number': AppConstants.helplineWomen, 'label': 'Women Helpline', 'color': const Color(0xFFE91E63)},
      {'number': AppConstants.helplineWomenPolice, 'label': 'Women Police', 'color': AppColors.warning},
      {'number': AppConstants.helplineCyberCrime, 'label': 'Cyber Crime', 'color': AppColors.info},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Emergency Helplines',
            style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: numbers.map((n) {
            final color = n['color'] as Color;
            return GestureDetector(
              onTap: () => _call(n['number'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.08),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.call_rounded, color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['number'] as String,
                              style: GoogleFonts.inter(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          Text(n['label'] as String,
                              style: GoogleFonts.inter(
                                  color: AppColors.textHint, fontSize: 9),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SOSInstructions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How SOS Works',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...['Tap SOS button to start 3-second countdown',
            'Shake device 3× to trigger instant SOS',
            'Live location shared with all trusted contacts',
            'Auto-recording begins (audio simulation)',
            'Tap "I\'m Safe" to cancel and notify contacts'].asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Text('${e.key + 1}. ', style: GoogleFonts.inter(color: AppColors.goldPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                Expanded(child: Text(e.value, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12))),
              ]),
            )),
        ],
      ),
    );
  }
}
