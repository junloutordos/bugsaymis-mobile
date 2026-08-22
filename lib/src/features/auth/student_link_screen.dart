import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        body: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: AppGradients.hero,
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            shape: const CircleBorder(),
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.badge_rounded, color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 16),
                          Text('One last step',
                              style: AppTextStyles.screenTitle.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sheet)),
                        boxShadow: kFormShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Link your student record',
                              style: AppTextStyles.sectionHeader),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.cardSubtitle.copyWith(height: 1.5),
                              children: [
                                const TextSpan(text: 'Signed in as '),
                                TextSpan(text: widget.email, style: AppTextStyles.fieldLabel),
                                const TextSpan(text: '. Enter your PISAY ID once to link it.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _pisayCtrl,
                            textCapitalization: TextCapitalization.characters,
                            style: AppTextStyles.bodyMedium,
                            decoration: const InputDecoration(
                              labelText: 'PISAY ID',
                              hintText: 'e.g. 25-12345',
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: GradientButton(
                              text: 'Link & Continue',
                              isLoading: _loading,
                              onPressed: _loading ? null : _submit,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Only enrolled students can link. Contact the Guidance Office if you need help.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption,
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
