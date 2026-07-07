import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    if (mounted && ref.read(authStateProvider).value != null) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    ref.listen(authStateProvider, (_, next) {
      if (!next.hasError) return;
      final err = next.error.toString();

      if (err.contains('requires_verification') || err.contains('verify your email')) {
        context.push('/verify-email', extra: {'email': _emailCtrl.text.trim()});
        return;
      }

      final msg = (err.contains('401') || err.contains('credentials') || err.contains('422'))
          ? 'Incorrect email or password.'
          : 'Login failed. Check your connection and try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: Stack(
        children: [
          // ── Top arc decoration ────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: AppGradients.authDecoration,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),

                  // ── Brand block ───────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 88,
                          height: 88,
                          child: Image.asset(
                            'assets/images/pshs_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                                Icons.shield_rounded,
                                color: Colors.white,
                                size: 50),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('AtlasGo',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Parent & Student Portal',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Form card ─────────────────────────────────────────
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
                          Text('Welcome back',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          Text('Sign in to your account',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),

                          const SizedBox(height: 24),

                          // ── Email ─────────────────────────────────────
                          _FieldLabel('Email address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary, fontSize: 14),
                            decoration: _fieldDec(
                                hint: 'you@email.com',
                                icon: Icons.email_outlined),
                            validator: (v) =>
                                v == null || !v.contains('@')
                                    ? 'Enter a valid email'
                                    : null,
                          ),

                          const SizedBox(height: 16),

                          // ── Password ──────────────────────────────────
                          _FieldLabel('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary, fontSize: 14),
                            decoration:
                                _fieldDec(hint: '••••••••',
                                    icon: Icons.lock_outline_rounded)
                                    .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Enter your password'
                                    : null,
                            onFieldSubmitted: (_) => _submit(),
                          ),

                          const SizedBox(height: 28),

                          // ── Sign In button ────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: GradientButton(
                              text: 'Sign In',
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _submit,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Register links ────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Parent? ',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                              GestureDetector(
                                onTap: () => context.push('/register'),
                                child: Text('Create account',
                                    style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Student? ',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                              GestureDetector(
                                onTap: () => context.push('/student/register'),
                                child: Text('Register here',
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
  }

  InputDecoration _fieldDec({required String hint, required IconData icon}) =>
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
