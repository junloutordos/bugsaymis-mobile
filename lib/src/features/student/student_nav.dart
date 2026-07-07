import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class StudentBottomNav extends StatelessWidget {
  final int currentIndex;
  const StudentBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: kNavShadow,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: currentIndex,
            backgroundColor: AppColors.surface,
            elevation: 0,
            onDestinationSelected: (i) {
              switch (i) {
                case 0: context.go('/student/home');
                case 1: context.go('/student/attendance');
                case 2: context.go('/student/grades');
                case 3: context.go('/student/schedule');
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Attendance',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'Grades',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Schedule',
              ),
            ],
          ),
        ),
      );
}
