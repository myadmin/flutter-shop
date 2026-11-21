import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 通用空态 / 未登录态
///
/// 图标 + 标题 + 说明 + 可选操作按钮。购物车、订单列表、收藏列表共用
/// 同一套排版，只是文案与按钮行为不同。
class HmEmptyView extends StatelessWidget {
  const HmEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.description = '',
    this.actionText = '',
    this.onAction,
  });

  final IconData icon;
  final String title;

  /// 补充说明，空串时不占位
  final String description;

  /// 操作按钮文案，空串时不展示按钮
  final String actionText;

  final VoidCallback? onAction;

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
          if (description.isNotEmpty) ...[
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
          ],
          if (actionText.isNotEmpty && onAction != null) ...[
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
        ],
      ),
    );
  }
}
