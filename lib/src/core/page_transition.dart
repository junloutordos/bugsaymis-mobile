import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';

/// Shared full-screen route transition (fade + scale-in), replacing the
/// default platform push animation. Used for full-screen (non-tab) routes
/// so they share one consistent "premium" page-transition feel instead of
/// each hand-rolling its own CustomTransitionPage.
CustomTransitionPage<T> appPageTransition<T>({
  required LocalKey pageKey,
  required Widget child,
  bool fullscreenDialog = false,
}) {
  return CustomTransitionPage<T>(
    key: pageKey,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: AppMotion.base,
    reverseTransitionDuration: AppMotion.fast,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.standard);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
