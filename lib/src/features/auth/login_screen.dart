import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;
  bool _googleLoading = false;

  late final AnimationController _introCtrl;
  late final Animation<double> _brandAnim;
  late final Animation<double> _cardAnim;

  /// Native Google sign-in is available on Android and iOS only.
  bool get _googleAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _brandAnim = CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic));
    _cardAnim = CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic));
    _introCtrl.forward();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
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
      TextInput.finishAutofillContext();
      context.go('/home');
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final result =
          await ref.read(authStateProvider.notifier).loginWithGoogle();
      if (!mounted) return;

      switch (result) {
        case GoogleLoginSuccess():
          context.go('/student/home');
        case GoogleLoginNeedsLink(:final idToken, :final email):
          context.push('/student/link',
              extra: {'idToken': idToken, 'email': email});
        case GoogleLoginCancelled():
          break;
      }
    } catch (e) {
      if (!mounted) return;
      final err = e.toString();
      final msg = err.contains('403') || err.contains('PSHS-CRC')
          ? 'Only official PSHS-CRC accounts (@crc.pshs.edu.ph) are allowed.'
          : 'Google sign-in failed. Check your connection and try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;
    // Both sign-in paths disable while either is in flight so they can't race.
    final busy = isLoading || _googleLoading;

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
                  _Entrance(animation: _brandAnim, child: _brandBlock()),
                  const SizedBox(height: 36),
                  _Entrance(animation: _cardAnim, child: _formCard(busy, isLoading)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandBlock() => Center(
        child: Column(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Image.asset(
                'assets/images/atlas_arrow.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 50),
              ),
            ),
            const SizedBox(height: 14),
            Text('AtlasGo',
                style: AppTextStyles.screenTitle.copyWith(
                    color: Colors.white, fontSize: 30, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Parent & Student Portal',
                style: AppTextStyles.cardSubtitle
                    .copyWith(color: Colors.white60)),
          ],
        ),
      );

  Widget _formCard(bool busy, bool isLoading) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sheet)),
          boxShadow: kFormShadow,
        ),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                Text('Sign in to your account',
                    style: AppTextStyles.cardSubtitle),

                const SizedBox(height: 24),

                // ── Student: Google sign-in ───────────────────────────
                if (_googleAvailable) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _googleSignIn,
                      icon: _googleLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.school_rounded, size: 20),
                      label: Text(
                        'Student — Continue with Google',
                        style: AppTextStyles.bodySemibold
                            .copyWith(color: AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text('Use your @crc.pshs.edu.ph account',
                        style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('parents sign in with email',
                            style:
                                AppTextStyles.caption.copyWith(fontSize: 11)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],

                // ── Email ─────────────────────────────────────────────
                LabelledField(
                  label: 'Email address',
                  child: TextFormField(
                    controller: _emailCtrl,
                    enabled: !busy,
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
                          color: AppColors.textSecondary, size: 18),
                    ),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Password ──────────────────────────────────────────
                LabelledField(
                  label: 'Password',
                  child: TextFormField(
                    controller: _passCtrl,
                    enabled: !busy,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppColors.textSecondary, size: 18),
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
                        v == null || v.isEmpty ? 'Enter your password' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Sign In button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: 'Sign In',
                    isLoading: isLoading,
                    onPressed: busy ? null : _submit,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Register links ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Parent? ', style: AppTextStyles.cardSubtitle),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text('Create account',
                          style: AppTextStyles.bodySemibold.copyWith(
                              color: AppColors.accent, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// Fade + slide-up entrance used by the auth screens.
class _Entrance extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _Entrance({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: animation,
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, inner) => Transform.translate(
            offset: Offset(0, 16 * (1 - animation.value)),
            child: inner,
          ),
          child: child,
        ),
      );
}
