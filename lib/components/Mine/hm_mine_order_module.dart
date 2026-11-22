import 'package:flutter/material.dart';
import 'package:hm_shop/components/Mine/hm_entry_item.dart';
import 'package:hm_shop/constants/app_assets.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 「我的」页面订单管理入口区
class HmMineOrderModule extends StatelessWidget {
  const HmMineOrderModule({
    super.key,
    required this.onEntryTap,
    this.counts = const {},
  });

  /// 入口点击回调，参数为入口名称
  final ValueChanged<String> onEntryTap;

  /// 各入口的角标数字，键为入口名称；缺失或为 0 时不展示角标
  final Map<String, int> counts;

  static const List<({String icon, String label})> _entries = [
    (icon: AppAssets.icUserOrder, label: '我的订单'),
    (icon: AppAssets.icUserObligation, label: '待付款'),
    (icon: AppAssets.icUserUnshipped, label: '待发货'),
    (icon: AppAssets.icUserUnreceived, label: '待收货'),
    (icon: AppAssets.icUserUnevaluated, label: '待评价'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '订单管理',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final entry in _entries)
                    HmEntryItem(
                      icon: entry.icon,
                      label: entry.label,
                      badge: counts[entry.label] ?? 0,
                      onTap: () => onEntryTap(entry.label),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
