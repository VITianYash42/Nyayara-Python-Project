import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../home/mode_selection_screen.dart';

const Color _rose = Color(0xFFE91E8C);
const Color _lavender = Color(0xFF9C27B0);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'user';
  bool _obscurePw = true;
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final vm = context.read<AuthViewModel>();
    final success = await vm.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(vm.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A2E), Color(0xFF140820), Color(0xFF0D0D0D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
          ),

          // Rose blob
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _rose.withValues(alpha: 0.18), Colors.transparent,
                ]),
              ),
            ),
          ),

          // Lavender blob
          Positioned(
            bottom: 60, left: -60,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _lavender.withValues(alpha: 0.12), Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E1330),
                            border: Border.all(color: const Color(0xFF3A2F5A)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Color(0xFFCE93D8), size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFF48FB1), Colors.white, Color(0xFFCE93D8)],
                        ).createShader(b),
                        child: Text('Nyayara',
                            style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Account',
                              style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic))
                              .animate().fadeIn().slideY(begin: 0.2),

                          const SizedBox(height: 6),

                          Text('Your privacy is our priority. All data is encrypted.',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFFB0A0CC), fontSize: 12))
                              .animate(delay: 100.ms).fadeIn(),

                          // Rose-lavender divider
                          const SizedBox(height: 10),
                          Container(
                            width: 50, height: 2.5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: const LinearGradient(
                                  colors: [_rose, _lavender]),
                            ),
                          ).animate(delay: 200.ms).fadeIn().scaleX(begin: 0),

                          const SizedBox(height: 28),

                          // Fields
                          _FemField(ctrl: _nameCtrl, label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (v) => v!.isEmpty ? 'Enter your name' : null),
                          const SizedBox(height: 14),
                          _FemField(ctrl: _emailCtrl, label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => !RegExp(r'\S+@\S+\.\S+').hasMatch(v ?? '')
                                  ? 'Enter valid email' : null),
                          const SizedBox(height: 14),
                          _FemField(ctrl: _phoneCtrl, label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 14),
                          _FemField(ctrl: _passwordCtrl, label: 'Password',
                              icon: Icons.lock_outlined,
                              obscure: _obscurePw,
                              onToggle: () => setState(() => _obscurePw = !_obscurePw),
                              validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null),

                          const SizedBox(height: 22),

                          // Role selection
                          Text('I am registering as:',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF9A8AB0), fontSize: 12)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _RoleChip(label: 'User / Survivor', roleKey: 'user',
                                  icon: Icons.person_rounded,
                                  selected: _selectedRole == 'user',
                                  onTap: () => setState(() => _selectedRole = 'user')),
                              const SizedBox(width: 10),
                              _RoleChip(label: 'HR / Admin', roleKey: 'hr',
                                  icon: Icons.business_center_rounded,
                                  selected: _selectedRole == 'hr',
                                  onTap: () => setState(() => _selectedRole = 'hr')),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Register button
                          GestureDetector(
                            onTap: _isLoading ? null : _register,
                            child: Container(
                              width: double.infinity, height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: _isLoading ? null : const LinearGradient(
                                  colors: [_rose, _lavender],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                color: _isLoading ? const Color(0xFF2A1545) : null,
                                boxShadow: _isLoading ? [] : [
                                  BoxShadow(
                                      color: _rose.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8)),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22, width: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                                    : Text('Create My Safe Account',
                                        style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                              ),
                            ),
                          ).animate(delay: 300.ms).fadeIn(),

                          const SizedBox(height: 20),

                          Center(
                            child: Text(
                              '🔒 End-to-end encrypted. We never share your information.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF6A5A82), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feminine text field ───────────────────────────────────────────────
class _FemField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggle;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FemField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.onToggle,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator ?? (_) => null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9A8AB0), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFFCE93D8), size: 20),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF7A6A9A), size: 18),
                onPressed: onToggle)
            : null,
        filled: true,
        fillColor: const Color(0xFF1E1330),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3A2F5A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _rose, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ── Role chip ─────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label, roleKey;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label, required this.roleKey, required this.icon,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? LinearGradient(
                    colors: [_rose.withValues(alpha: 0.2), _lavender.withValues(alpha: 0.2)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: selected ? null : const Color(0xFF1E1330),
            border: Border.all(
              color: selected ? _rose.withValues(alpha: 0.7) : const Color(0xFF3A2F5A),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? const Color(0xFFF48FB1) : const Color(0xFF7A6A9A),
                  size: 26),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: selected ? Colors.white : const Color(0xFF9A8AB0),
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}
