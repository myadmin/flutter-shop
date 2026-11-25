import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 首页「服务保障」静态条：正品保障 / 极速发货 / 七天无理由 / 售后无忧。
///
/// 后端没有对应的服务承诺接口，这里做成纯静态展示，放在轮播图下方，
/// 让首屏第一屏就能看到平台的承诺信息。
class HmServicePromise extends StatelessWidget {
  const HmServicePromise({super.key});

  /// 图标 + 文案，纯静态数据
  static const List<({IconData icon, String label})> _promises = [
    (icon: Icons.verified_outlined, label: '正品保障'),
    (icon: Icons.local_shipping_outlined, label: '极速发货'),
    (icon: Icons.autorenew, label: '七天无理由'),
    (icon: Icons.support_agent, label: '售后无忧'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            for (final promise in _promises)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(promise.icon, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        promise.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.lightBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
