import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        TextInput.finishAutofillContext();
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
                                'assets/images/atlas_arrow.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(
                                    Icons.navigation_rounded,
                                    color: Colors.white,
                                    size: 40),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Create Account',
                              style: AppTextStyles.screenTitle.copyWith(
                                  color: Colors.white, fontSize: 24)),
                          const SizedBox(height: 2),
                          Text('AtlasGo',
                              style: AppTextStyles.cardSubtitle
                                  .copyWith(color: Colors.white60)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Form card ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.all(Radius.circular(AppRadius.sheet)),
                        boxShadow: kFormShadow,
                      ),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your details',
                                  style: AppTextStyles.sectionHeader),
                              const SizedBox(height: 4),
                              Text('Fill in your information to get started',
                                  style: AppTextStyles.cardSubtitle),

                              const SizedBox(height: 24),

                              // ── Full name ─────────────────────────────
                              LabelledField(
                                label: 'Full Name',
                                child: TextFormField(
                                  controller: _nameCtrl,
                                  enabled: !_loading,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  style: AppTextStyles.bodyMedium,
                                  decoration: const InputDecoration(
                                    hintText: 'Juan Dela Cruz',
                                    prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                        color: AppColors.textSecondary,
                                        size: 18),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Enter your full name'
                                          : null,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Email ─────────────────────────────────
                              LabelledField(
                                label: 'Email Address',
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  enabled: !_loading,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.username,
                                    AutofillHints.email,
                                  ],
                                  style: AppTextStyles.bodyMedium,
                                  decoration: const InputDecoration(
                                    hintText: 'you@email.com',
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: AppColors.textSecondary,
                                        size: 18),
                                  ),
                                  validator: (v) =>
                                      v == null || !v.contains('@')
                                          ? 'Enter a valid email'
                                          : null,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Password ──────────────────────────────
                              LabelledField(
                                label: 'Password',
                                child: TextFormField(
                                  controller: _passCtrl,
                                  enabled: !_loading,
                                  obscureText: _obscurePass,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword
                                  ],
                                  style: AppTextStyles.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: 'At least 8 characters',
                                    prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: AppColors.textSecondary,
                                        size: 18),
                                    suffixIcon: _visToggle(
                                        _obscurePass,
                                        () => setState(() =>
                                            _obscurePass = !_obscurePass)),
                                  ),
                                  validator: (v) => v == null || v.length < 8
                                      ? 'Minimum 8 characters'
                                      : null,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Confirm password ──────────────────────
                              LabelledField(
                                label: 'Confirm Password',
                                child: TextFormField(
                                  controller: _confirmCtrl,
                                  enabled: !_loading,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.newPassword
                                  ],
                                  style: AppTextStyles.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: 'Re-enter password',
                                    prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: AppColors.textSecondary,
                                        size: 18),
                                    suffixIcon: _visToggle(
                                        _obscureConfirm,
                                        () => setState(() =>
                                            _obscureConfirm =
                                                !_obscureConfirm)),
                                  ),
                                  validator: (v) => v != _passCtrl.text
                                      ? 'Passwords do not match'
                                      : null,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
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
                                      style: AppTextStyles.cardSubtitle),
                                  GestureDetector(
                                    onTap: () => context.pop(),
                                    child: Text('Sign in',
                                        style: AppTextStyles.bodySemibold
                                            .copyWith(
                                                color: AppColors.accent,
                                                fontSize: 13)),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  Widget _visToggle(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: onTap,
      );
}
