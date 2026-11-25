import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 底部固定操作栏外壳
///
/// 统一处理贴底阴影、安全区、PC 端最大宽度与内边距，
/// 商品详情页与订单确认页共用同一套视觉与布局规则。
class HmBottomBar extends StatelessWidget {
  /// 栏内自适应高度的内容（通常是一个 Row）
  final Widget child;

  const HmBottomBar({super.key, required this.child});

  /// 操作栏内容最大宽度，避免 PC 端内容被拉得过宽
  static const double maxContentWidth = 600;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.barShadow,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          // heightFactor 为 1 时按内容高度收缩，避免撑满整个视口
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 底栏左侧的金额信息（标签 + 金额）
///
/// 详情页展示单价、订单页展示应付金额，两者排版完全一致。
class HmBottomBarPrice extends StatelessWidget {
  final String label;

  final String amount;

  const HmBottomBarPrice({
    super.key,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.pageTitle,
        ),
      ],
    );
  }
}

/// 底栏主/次按钮
///
/// primary 为 true 时使用主色实心样式，否则使用浅色次级样式。
class HmBottomBarButton extends StatelessWidget {
  final String text;

  final bool primary;

  final VoidCallback? onPressed;

  /// 按钮内容，默认按 [text] 渲染；加载态可传入自定义指示器
  final Widget? child;

  const HmBottomBarButton({
    super.key,
    required this.text,
    this.primary = false,
    this.onPressed,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? AppColors.primary
              : AppColors.primarySurface,
          foregroundColor: primary ? Colors.white : AppColors.darkBrown,
          disabledBackgroundColor: primary ? AppColors.primaryDisabled : null,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: child ?? Text(text, maxLines: 1),
      ),
    );
  }
}
