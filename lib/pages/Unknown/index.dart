import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 未知路由兜底页
///
/// 启用真实路径策略后，用户可能直接访问一个不存在的地址（例如手改了
/// 地址栏，或引用了旧版本的深链），此时由 [MaterialApp.onUnknownRoute]
/// 展示这个页面，而不是白屏 / 断言失败。
class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key, this.location});

  /// 触发兜底的原始路由名，用于给用户一点线索
  final String? location;

  void _backToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('页面不存在'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.explore_off_outlined,
                size: 56,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                '没有找到这个页面',
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                location == null || location!.isEmpty
                    ? '地址可能已经失效，回首页继续逛逛吧'
                    : '地址 $location',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => _backToHome(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: const StadiumBorder(),
                ),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
