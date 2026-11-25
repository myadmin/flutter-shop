import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/hm_goods_compact_card.dart';
import 'package:hm_shop/components/common/hm_section_header.dart';
import 'package:hm_shop/models/home.dart';

/// 首页「新品首发」模块：横滑商品卡。
///
/// 数据来自 `/home/new`，条目结构与 [GoodsItem] 一致，点击进商品详情。
/// 没有数据时整块不渲染，避免留下一排空标题。
class HmNewGoods extends StatelessWidget {
  final List<GoodsItem> goodsList;

  /// 点击商品回调，为空时卡片不可点
  final ValueChanged<GoodsItem>? onGoodsTap;

  const HmNewGoods({super.key, required this.goodsList, this.onGoodsTap});

  static const double _cardWidth = 132;
  static const double _imageHeight = 132;

  @override
  Widget build(BuildContext context) {
    if (goodsList.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: HmSectionHeader(title: '新品首发', subtitle: '刚刚上新，先人一步'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: HmGoodsCompactCard.heightFor(_imageHeight),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: goodsList.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final GoodsItem goods = goodsList[index];
              return HmGoodsCompactCard(
                goods: goods,
                width: _cardWidth,
                imageHeight: _imageHeight,
                onTap: onGoodsTap == null ? null : () => onGoodsTap!(goods),
              );
            },
          ),
        ),
      ],
    );
  }
}
