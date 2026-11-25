import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/hm_goods_summary_tile.dart';
import 'package:hm_shop/models/footprint.dart';

/// 足迹列表的一行：商品图 + 名称 + 价格 + 最近浏览时间
///
/// 布局交给 [HmGoodsSummaryTile]，这里只负责把足迹项映射成通用字段。
class HmFootprintTile extends StatelessWidget {
  const HmFootprintTile({super.key, required this.item, this.onTap});

  /// 足迹条目
  final FootprintItem item;

  /// 点击回调，通常用于跳转商品详情
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HmGoodsSummaryTile(
      name: item.name,
      price: item.price,
      picture: item.picture,
      metaText: '${item.viewedTimeText} 浏览',
      onTap: onTap,
    );
  }
}
