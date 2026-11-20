import 'package:flutter/material.dart';
import 'package:hm_shop/components/Mine/hm_entry_item.dart';
import 'package:hm_shop/constants/app_assets.dart';

/// 「我的」页面快捷入口区（我的收藏 / 我的足迹 / 我的客服）
class HmMineQuickActions extends StatelessWidget {
  const HmMineQuickActions({super.key, required this.onEntryTap});

  /// 入口点击回调，参数为入口名称
  final ValueChanged<String> onEntryTap;

  static const List<({String icon, String label})> _entries = [
    (icon: AppAssets.icUserCollect, label: '我的收藏'),
    (icon: AppAssets.icUserHistory, label: '我的足迹'),
    (icon: AppAssets.icUserService, label: '我的客服'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final entry in _entries)
              HmEntryItem(
                icon: entry.icon,
                label: entry.label,
                onTap: () => onEntryTap(entry.label),
              ),
          ],
        ),
      ),
    );
  }
}
