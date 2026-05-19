import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class StudentBottomNav extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;

  const StudentBottomNav({
    super.key,
    required this.currentIndex,
    this.unreadCount = 0,
  });

  static const _routes = [
    '/student/home',
    '/student/schedule',
    '/student/chat',
    '/student/notes',
    '/student/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: LucideIcons.home, label: 'Home', index: 0, current: currentIndex, onTap: () => context.go(_routes[0])),
              _NavItem(icon: LucideIcons.calendar, label: 'Schedule', index: 1, current: currentIndex, onTap: () => context.go(_routes[1])),
              // Center AI button (larger)
              GestureDetector(
                onTap: () => context.go(_routes[2]),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: currentIndex == 2
                          ? [AppColors.primary, AppColors.secondary]
                          : [AppColors.primary.withOpacity(0.7), AppColors.secondary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.messageSquare, color: Colors.white, size: 22),
                ),
              ),
              _NavItem(icon: LucideIcons.fileText, label: 'Notes', index: 3, current: currentIndex, onTap: () => context.go(_routes[3])),
              _NavItem(icon: LucideIcons.user, label: 'Profile', index: 4, current: currentIndex, onTap: () => context.go(_routes[4])),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: active ? AppColors.primary : AppColors.textMuted,
                ),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
