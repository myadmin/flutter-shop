import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 购物车的空态 / 未登录态
///
/// 两种状态共用一套排版：图标 + 标题 + 说明 + 操作按钮，
/// 只是文案与按钮行为不同（去逛逛 / 去登录）。
class HmCartEmpty extends StatelessWidget {
  final IconData icon;

  final String title;

  final String description;

  final String actionText;

  final VoidCallback onAction;

  const HmCartEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.divider),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                padding: const EdgeInsets.symmetric(horizontal: 26),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(actionText),
            ),
          ),
        ],
      ),
    );
  }
}
