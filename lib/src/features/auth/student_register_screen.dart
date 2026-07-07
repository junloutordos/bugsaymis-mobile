import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class StudentRegisterScreen extends ConsumerStatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  ConsumerState<StudentRegisterScreen> createState() =>
      _StudentRegisterScreenState();
}

class _StudentRegisterScreenState
    extends ConsumerState<StudentRegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConf = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/student/register', data: {
        'student_email':          _emailCtrl.text.trim(),
        'password':               _passCtrl.text,
        'password_confirmation':  _confCtrl.text,
      });
      if (mounted) {
        context.push('/verify-email',
            extra: {'email': _emailCtrl.text.trim()});
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('422') || e.toString().contains('No student')
          ? 'No student found with that email. Use your school-issued email address.'
          : 'Registration failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: Stack(
        children: [
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () =>
                            context.canPop() ? context.pop() : context.go('/login'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Student Account',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Register with your school email',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white60, fontSize: 13)),
                  ),
                  const SizedBox(height: 28),
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
                          _FieldLabel('School Email'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary, fontSize: 14),
                            decoration: _dec(
                                hint: 'your-id@pshs.edu.ph',
                                icon: Icons.email_outlined),
                            validator: (v) =>
                                v == null || !v.contains('@')
                                    ? 'Enter your school email'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary, fontSize: 14),
                            decoration: _dec(
                                    hint: '8+ characters',
                                    icon: Icons.lock_outline_rounded)
                                .copyWith(
                              suffixIcon: _eyeBtn(
                                  _obscurePass,
                                  () => setState(
                                      () => _obscurePass = !_obscurePass)),
                            ),
                            validator: (v) =>
                                v == null || v.length < 8
                                    ? 'At least 8 characters'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel('Confirm Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confCtrl,
                            obscureText: _obscureConf,
                            style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary, fontSize: 14),
                            decoration: _dec(
                                    hint: '••••••••',
                                    icon: Icons.lock_outline_rounded)
                                .copyWith(
                              suffixIcon: _eyeBtn(
                                  _obscureConf,
                                  () => setState(
                                      () => _obscureConf = !_obscureConf)),
                            ),
                            validator: (v) =>
                                v != _passCtrl.text ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 28),
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
                                onTap: () => context.go('/login'),
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
  }

  InputDecoration _dec({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _eyeBtn(bool obscure, VoidCallback toggle) => IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: toggle,
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
