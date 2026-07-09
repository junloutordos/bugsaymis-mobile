import 'package:flutter/material.dart';
import '../../core/theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String subtext;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.icon,
    required this.headline,
    required this.subtext,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.accentBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 38, color: AppColors.accent),
              ),
              const SizedBox(height: 20),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 8),
              Text(
                subtext,
                textAlign: TextAlign.center,
                style: AppTextStyles.custom(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              ),
              if (ctaLabel != null && onCta != null) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: 200,
                  child: GradientButton(
                    text: ctaLabel!,
                    onPressed: onCta,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class ErrorRetryView extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  const ErrorRetryView({super.key, required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message ?? 'Could not load data',
              style: AppTextStyles.custom(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
