import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _loading   = false;
  bool _resending = false;
  int  _resendCountdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 1) {
        t.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code from your email.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/verify-email', data: {
        'email': widget.email,
        'otp'  : _otp,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! You can now sign in.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or expired code. Check your email and try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/resend-verification', data: {'email': widget.email});
      if (mounted) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent to your email.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
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
                height: 220,
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

                    const SizedBox(height: 4),

                    // ── Icon + heading ────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.mark_email_read_outlined,
                                color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 16),
                          Text('Check your email',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Card ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: kFormShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enter verification code',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2)),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5),
                              children: [
                                const TextSpan(
                                    text: 'We sent a 6-digit code to '),
                                TextSpan(
                                    text: widget.email,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── OTP boxes ─────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (i) => _OtpBox(
                                  controller: _controllers[i],
                                  focusNode: _focusNodes[i],
                                  onChanged: (val) {
                                    if (val.isNotEmpty && i < 5) {
                                      _focusNodes[i + 1].requestFocus();
                                    }
                                    if (val.isEmpty && i > 0) {
                                      _focusNodes[i - 1].requestFocus();
                                    }
                                    if (_otp.length == 6) _submit();
                                  },
                                )),
                          ),

                          const SizedBox(height: 28),

                          // ── Verify button ─────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: GradientButton(
                              text: 'Verify Email',
                              isLoading: _loading,
                              onPressed: _loading ? null : _submit,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Resend ────────────────────────────────
                          Center(
                            child: _resendCountdown > 0
                                ? Text(
                                    'Resend code in ${_resendCountdown}s',
                                    style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  )
                                : GestureDetector(
                                    onTap: _resending ? null : _resend,
                                    child: Text(
                                      _resending ? 'Sending…' : 'Resend code',
                                      style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.accent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 12),

                          Center(
                            child: Text(
                              'Code expires in 15 minutes.\nCheck spam if you don\'t see it.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textDisabled,
                                  fontSize: 12,
                                  height: 1.6),
                            ),
                          ),
                        ],
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

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 46,
        height: 56,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.background,
            contentPadding: EdgeInsets.zero,
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
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
        ),
      );
}
