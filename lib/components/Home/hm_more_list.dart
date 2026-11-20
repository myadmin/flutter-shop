import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/hm_goods_card.dart';
import 'package:hm_shop/models/home.dart';

/// 商品瀑布网格（两列），首页推荐列表与「我的-猜你喜欢」共用。
class HmMoreList extends StatelessWidget {
  const HmMoreList({super.key, required this.recommendList, this.onItemTap});

  /// 推荐列表数据
  final List<GoodDetailItem> recommendList;

  /// 商品点击回调
  final ValueChanged<GoodDetailItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78, // 卡片宽高比，数值越大格子越矮
      ),
      itemCount: recommendList.length,
      itemBuilder: (BuildContext context, int index) {
        final GoodDetailItem item = recommendList[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: HmGoodsCard(
            item: item,
            onTap: onItemTap == null ? null : () => onItemTap!(item),
          ),
        );
      },
    );
  }
}
