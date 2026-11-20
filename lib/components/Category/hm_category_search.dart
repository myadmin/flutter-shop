import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 分类页顶部的搜索入口。
///
/// 与首页盖在轮播图上的半透明搜索框不同，分类页是白底页面，
/// 这里用实心胶囊，视觉上更像「一个可以点的输入框」。
class HmCategorySearch extends StatelessWidget {
  const HmCategorySearch({super.key, this.onTap, this.hintText = '搜索商品'});

  /// 点击整条搜索栏的回调；为空时仅做展示
  final VoidCallback? onTap;

  /// 占位文案
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.small,
        AppSpacing.page,
        AppSpacing.small,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                hintText,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
