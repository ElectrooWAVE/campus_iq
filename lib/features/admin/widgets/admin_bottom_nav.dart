import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNav({super.key, required this.currentIndex});

  static const _routes = [
    '/admin/home',
    '/admin/content',
    '/admin/students',
    '/admin/analytics',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (LucideIcons.layoutDashboard, 'Home'),
      (LucideIcons.clipboardList, 'Content'),
      (LucideIcons.users, 'Students'),
      (LucideIcons.barChart2, 'Analytics'),
    ];

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
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              return GestureDetector(
                onTap: () => context.go(_routes[i]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].$1,
                      size: 22,
                      color: active ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
