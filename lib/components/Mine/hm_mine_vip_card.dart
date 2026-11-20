import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_assets.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 「我的」页面会员卡入口
class HmMineVipCard extends StatelessWidget {
  const HmMineVipCard({super.key, required this.onOpenTap});

  final VoidCallback onOpenTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.vipBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Image.asset(AppAssets.icUserVip, width: 30, height: 30),
            const SizedBox(width: 10),
            const Expanded(
              // 按可用宽度等比缩小，保证各类机型下文案都只占一行
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '升级美荟商城会员，尊享无限免邮',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.vipForeground,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: onOpenTap,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.vipForeground,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('立即开通', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
