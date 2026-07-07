import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _loading        = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final client = ref.read(apiClientProvider);
      await client.post('/register', data: {
        'name'                 : _nameCtrl.text.trim(),
        'email'                : _emailCtrl.text.trim(),
        'password'             : _passCtrl.text,
        'password_confirmation': _confirmCtrl.text,
      });

      if (mounted) {
        context.pushReplacement('/verify-email',
            extra: {'email': _emailCtrl.text.trim()});
      }
    } catch (e) {
      if (!mounted) return;
      final err = e.toString();
      String msg = 'Registration failed. Please try again.';
      if (err.contains('email') && err.contains('taken') ||
          err.contains('unique')) {
        msg = 'That email is already registered. Try signing in instead.';
      } else if (err.contains('422')) {
        msg = 'Please check your details and try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.authBg,
        body: Stack(
          children: [
            // ── Top arc decoration ────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 240,
                decoration: const BoxDecoration(
                  gradient: AppGradients.authDecoration,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
            ),

            // ── Scrollable content ────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button on the arc
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            shape: const CircleBorder(),
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Brand block ───────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                'assets/images/pshs_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(
                                    Icons.shield_rounded,
                                    color: Colors.white,
                                    size: 40),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Create Account',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text('AtlasGo',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white60, fontSize: 13)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Form card ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: kFormShadow,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your details',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2)),
                            const SizedBox(height: 4),
                            Text('Fill in your information to get started',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),

                            const SizedBox(height: 24),

                            // ── Full name ─────────────────────────────
                            _FieldLabel('Full Name'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textPrimary, fontSize: 14),
                              decoration: _dec(hint: 'Juan Dela Cruz',
                                  icon: Icons.person_outline_rounded),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Enter your full name'
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            // ── Email ─────────────────────────────────
                            _FieldLabel('Email Address'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textPrimary, fontSize: 14),
                              decoration: _dec(hint: 'you@email.com',
                                  icon: Icons.email_outlined),
                              validator: (v) =>
                                  v == null || !v.contains('@')
                                      ? 'Enter a valid email'
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            // ── Password ──────────────────────────────
                            _FieldLabel('Password'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePass,
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textPrimary, fontSize: 14),
                              decoration: _dec(
                                      hint: 'At least 8 characters',
                                      icon: Icons.lock_outline_rounded)
                                  .copyWith(
                                suffixIcon: _visToggle(
                                    _obscurePass,
                                    () => setState(
                                        () => _obscurePass = !_obscurePass)),
                              ),
                              validator: (v) =>
                                  v == null || v.length < 8
                                      ? 'Minimum 8 characters'
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            // ── Confirm password ──────────────────────
                            _FieldLabel('Confirm Password'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscureConfirm,
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textPrimary, fontSize: 14),
                              decoration: _dec(
                                      hint: 'Re-enter password',
                                      icon: Icons.lock_outline_rounded)
                                  .copyWith(
                                suffixIcon: _visToggle(
                                    _obscureConfirm,
                                    () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm)),
                              ),
                              validator: (v) => v != _passCtrl.text
                                  ? 'Passwords do not match'
                                  : null,
                              onFieldSubmitted: (_) => _submit(),
                            ),

                            const SizedBox(height: 28),

                            // ── Register button ───────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: GradientButton(
                                text: 'Create Account',
                                isLoading: _loading,
                                onPressed: _loading ? null : _submit,
                              ),
                            ),

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Already have an account? ',
                                    style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Text('Sign in',
                                      style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.accent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  InputDecoration _dec({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _visToggle(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: onTap,
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));
}
