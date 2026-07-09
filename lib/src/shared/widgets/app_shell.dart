import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

enum ShellRole { parent, student }

class NavTab {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const NavTab(this.icon, this.selectedIcon, this.label);
}

const _parentTabs = [
  NavTab(Icons.home_outlined, Icons.home_rounded, 'Home'),
  NavTab(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Attendance'),
  NavTab(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Grades'),
  NavTab(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Schedule'),
];

const _studentTabs = [
  NavTab(Icons.home_outlined, Icons.home_rounded, 'Home'),
  NavTab(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Attendance'),
  NavTab(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Grades'),
  NavTab(Icons.widgets_outlined, Icons.widgets_rounded, 'Services'),
];

/// Persistent scaffold around the tab branches of a [StatefulShellRoute].
/// Students get a raised center button that opens the digital ID full-screen.
///
/// NOTE: the strip above the student nav bar (behind the raised button) is
/// transparent — this Scaffold's background must match the tab screens'
/// background so the overhang reads seamlessly.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  final ShellRole role;

  const AppShell({super.key, required this.shell, required this.role});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: shell,
        bottomNavigationBar: AppNavBar(
          currentIndex: shell.currentIndex,
          tabs: role == ShellRole.parent ? _parentTabs : _studentTabs,
          onSelect: (i) => shell.goBranch(
            i,
            initialLocation: i == shell.currentIndex,
          ),
          centerButton: role == ShellRole.student
              ? _IdCenterButton(onTap: () => context.push('/student/id'))
              : null,
        ),
      );
}

/// Hand-rolled bottom nav: visually matches the themed [NavigationBar]
/// (white bar, rounded top, pill indicator) but can host an overhanging
/// center button, which NavigationBar cannot (clipping + hit-testing).
class AppNavBar extends StatelessWidget {
  static const double _barHeight = 64;
  static const double _overhang = 26;

  final int currentIndex;
  final List<NavTab> tabs;
  final ValueChanged<int> onSelect;
  final Widget? centerButton;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.tabs,
    required this.onSelect,
    this.centerButton,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final hasCenter = centerButton != null;
    final half = tabs.length ~/ 2;

    // The widget's own height includes the overhang so the raised button
    // remains inside bounds — taps on it hit-test without any Stack hacks.
    return SizedBox(
      height: _barHeight + bottomInset + (hasCenter ? _overhang : 0),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: hasCenter ? _overhang : 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
                boxShadow: kNavShadow,
              ),
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Row(
                children: [
                  for (var i = 0; i < half; i++)
                    Expanded(
                      child: _NavItem(
                        tab: tabs[i],
                        selected: i == currentIndex,
                        onTap: () => onSelect(i),
                      ),
                    ),
                  if (hasCenter)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 38),
                        child: Text(
                          'My ID',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.label
                              .copyWith(fontSize: 11, letterSpacing: 0),
                        ),
                      ),
                    ),
                  for (var i = half; i < tabs.length; i++)
                    Expanded(
                      child: _NavItem(
                        tab: tabs[i],
                        selected: i == currentIndex,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (hasCenter)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(child: centerButton),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        radius: 40,
        child: Semantics(
          selected: selected,
          button: true,
          label: tab.label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 56,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(
                  selected ? tab.selectedIcon : tab.icon,
                  size: 22,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      selected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Raised circular gradient button docked in the nav's center — opens the
/// digital student ID.
class _IdCenterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _IdCenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Digital student ID',
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: AppGradients.button,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const Icon(Icons.qr_code_2_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
        ),
      );
}
