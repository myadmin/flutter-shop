import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 「图标 + 文案」纵向排列的入口按钮，用于「我的收藏 / 待付款」等宫格入口。
class HmEntryItem extends StatelessWidget {
  const HmEntryItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.badge = 0,
  });

  /// 本地图标资源路径
  final String icon;

  /// 入口文案
  final String label;

  /// 点击回调，为空时仅作静态展示
  final VoidCallback? onTap;

  /// 右上角角标数字，0 表示不展示
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(icon, width: 30, height: 30, fit: BoxFit.cover),
              if (badge > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: AppColors.badge,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
