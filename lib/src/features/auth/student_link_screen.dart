import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../portal/portal_widgets.dart';
import 'auth_provider.dart';

/// First Google sign-in: link the school account to a student record by
/// PISAY ID — one-time step, mirrors the /student-portal link page.
class StudentLinkScreen extends ConsumerStatefulWidget {
  final String idToken;
  final String email;

  const StudentLinkScreen(
      {super.key, required this.idToken, required this.email});

  @override
  ConsumerState<StudentLinkScreen> createState() => _StudentLinkScreenState();
}

class _StudentLinkScreenState extends ConsumerState<StudentLinkScreen> {
  final _pisayCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pisayCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pisayId = _pisayCtrl.text.trim();
    if (pisayId.isEmpty) {
      showErrorSnack(context, 'Enter your PISAY ID.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .linkStudentAccount(widget.idToken, pisayId);
      if (mounted) context.go('/student/home');
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.authBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Link your account'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.accentBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.badge_rounded,
                            color: AppColors.accent, size: 24),
                      ),
                      const SizedBox(height: 16),
                      Text('One last step',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 6),
                      Text(
                        'Signed in as ${widget.email}. Enter your PISAY ID once to link it to your student record.',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _pisayCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15),
                        decoration: const InputDecoration(
                          labelText: 'PISAY ID',
                          hintText: 'e.g. 25-12345',
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        text: 'Link & Continue',
                        isLoading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Only enrolled students can link. Contact the Guidance Office if you need help.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
