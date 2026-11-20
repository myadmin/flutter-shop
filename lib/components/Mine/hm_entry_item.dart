import 'package:flutter/material.dart';

/// 「图标 + 文案」纵向排列的入口按钮，用于「我的收藏 / 待付款」等宫格入口。
class HmEntryItem extends StatelessWidget {
  const HmEntryItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  /// 本地图标资源路径
  final String icon;

  /// 入口文案
  final String label;

  /// 点击回调，为空时仅作静态展示
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(icon, width: 30, height: 30, fit: BoxFit.cover),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
