import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/hm_goods_summary_tile.dart';
import 'package:hm_shop/models/collect.dart';

/// 收藏列表的一行：商品图 + 名称 + 价格 + 收藏时间
///
/// 收藏项字段做了容错，名称或图片可能为空：名称缺失时展示「商品信息已失效」，
/// 图片缺失时 `AppNetworkImage` 会渲染占位块，不至于出现空白行。
/// 具体布局交给 [HmGoodsSummaryTile]，这里只负责把收藏项映射成通用字段。
class HmCollectTile extends StatelessWidget {
  const HmCollectTile({super.key, required this.item, this.onTap});

  /// 收藏项
  final CollectItem item;

  /// 点击回调；没有商品 id 时为 null（卡片不可点）
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 字段兜底后仍可能全空（商品被下架、接口字段改名），此时只留一句提示，
    // 不展示「￥0.00」这种会误导人的占位价格。
    final bool hasInfo = item.name.isNotEmpty;
    return HmGoodsSummaryTile(
      name: item.name,
      price: item.price,
      picture: item.picture,
      metaText: item.createTime.isEmpty ? '' : '收藏于 ${item.createTime}',
      showPrice: hasInfo || item.price != '0.00',
      onTap: onTap,
    );
  }
}
