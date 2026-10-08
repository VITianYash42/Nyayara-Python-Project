import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'signup_screen.dart';
import '../home/mode_selection_screen.dart';

const Color _rose = Color(0xFFE91E8C);
const Color _lavender = Color(0xFF9C27B0);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final vm = context.read<AuthViewModel>();
    final success = await vm.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
        );
      } else {
        _showError(vm.errorMessage ?? 'Login failed');
      }
    }
  }

  Future<void> _anonymousLogin() async {
    setState(() => _isLoading = true);
    final vm = context.read<AuthViewModel>();
    final success = await vm.signInAnonymously();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
        );
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: const Color(0xFF1A0A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: Stack(
        children: [
          // ── Gradient background ─────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A0A2E),
                    Color(0xFF140820),
                    Color(0xFF0D0D0D),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
          ),

          // ── Rose glow blob top-right ─────────────────────────────────
          Positioned(
            top: -70, right: -70,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _rose.withValues(alpha: 0.2),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Lavender glow blob bottom-left ───────────────────────────
          Positioned(
            bottom: 100, left: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _lavender.withValues(alpha: 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Logo row
                    Row(
                      children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [_rose, _lavender],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _rose.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shield_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFFF48FB1), Colors.white, Color(0xFFCE93D8)],
                          ).createShader(b),
                          child: Text(
                            'Nyayara',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),

                    const SizedBox(height: 52),

                    // Welcome
                    Text('Welcome back,',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB0A0CC), fontSize: 15),
                    ).animate(delay: 100.ms).fadeIn(),

                    Text('Your safe space awaits.',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

                    const SizedBox(height: 10),

                    // Rose gradient divider
                    Container(
                      width: 56, height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(colors: [_rose, _lavender]),
                      ),
                    ).animate(delay: 300.ms).fadeIn().scaleX(begin: 0),

                    const SizedBox(height: 36),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          _FemField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter your email';
                              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v))
                                return 'Enter a valid email';
                              return null;
                            },
                          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),

                          const SizedBox(height: 16),

                          // Password
                          _FemField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outlined,
                            obscureText: _obscurePassword,
                            onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter your password';
                              if (v.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2),

                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text('Forgot Password?',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFFCE93D8),
                                      fontSize: 12)),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Sign In button — rose-lavender gradient
                          GestureDetector(
                            onTap: _isLoading ? null : _login,
                            child: Container(
                              width: double.infinity, height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: _isLoading
                                    ? null
                                    : const LinearGradient(
                                        colors: [_rose, _lavender],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight),
                                color: _isLoading
                                    ? const Color(0xFF2A1545)
                                    : null,
                                boxShadow: _isLoading
                                    ? []
                                    : [
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
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ))
                                    : Text('Sign In Securely',
                                        style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5)),
                              ),
                            ),
                          ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),

                          const SizedBox(height: 22),

                          // OR divider
                          Row(children: [
                            Expanded(
                                child: Divider(
                                    color: const Color(0xFF3A2F5A))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text('OR',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF7A6A9A),
                                      fontSize: 12)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: const Color(0xFF3A2F5A))),
                          ]).animate(delay: 700.ms).fadeIn(),

                          const SizedBox(height: 20),

                          // Anonymous Button
                          GestureDetector(
                            onTap: _isLoading ? null : _anonymousLogin,
                            child: Container(
                              width: double.infinity, height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: const Color(0xFF1E1330),
                                border: Border.all(
                                    color: _lavender.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off_outlined,
                                      size: 18,
                                      color: const Color(0xFFCE93D8)),
                                  const SizedBox(width: 8),
                                  Text('Continue Anonymously',
                                      style: GoogleFonts.inter(
                                          color: const Color(0xFFCE93D8),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ).animate(delay: 800.ms).fadeIn(),

                          const SizedBox(height: 36),

                          // Sign up link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ",
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF8070A0))),
                              GestureDetector(
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) => const SignupScreen())),
                                child: Text('Sign Up',
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFFF48FB1),
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ).animate(delay: 900.ms).fadeIn(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable feminine text field ──────────────────────────────────────
class _FemField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FemField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9A8AB0)),
        prefixIcon: Icon(icon, color: const Color(0xFFCE93D8), size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF7A6A9A),
                    size: 18),
                onPressed: onToggleObscure)
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
