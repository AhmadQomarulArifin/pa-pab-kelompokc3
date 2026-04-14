import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? subtitle;
  final List<Widget>? actions;
  final bool showProgress;
  final double progressValue;

  const AppTopBar({
    super.key,
    this.subtitle,
    this.actions,
    this.showProgress = false,
    this.progressValue = 0.65,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        border: Border(
          bottom: BorderSide(
            color: AppColors.secondary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProgress)
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.transparent,
              color: AppColors.secondary,
              minHeight: 2,
            ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.coffee, color: AppColors.primaryContainer, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Nol Persen Kafe',
                    style: AppTextStyles.headlineSm.copyWith(fontSize: 17),
                  ),
                  if (subtitle != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 1,
                      height: 16,
                      color: AppColors.outlineVariant,
                    ),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}