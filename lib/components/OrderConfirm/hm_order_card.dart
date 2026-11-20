import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 订单确认页的通用卡片容器
///
/// 统一灰底圆角与内边距，地址、商品、金额三块共用。
class OrderCard extends StatelessWidget {
  final Widget child;

  const OrderCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
