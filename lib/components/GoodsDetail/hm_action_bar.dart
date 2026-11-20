import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';

/// 商品详情底部操作栏
///
/// 由详情页挂载在 Scaffold 的 bottomNavigationBar 上，
/// 始终固定在视口底部，左侧展示单价，右侧提供购买操作入口。
class HmActionBar extends StatelessWidget {
  // 当前商品单价
  final String price;

  // 加入购物车回调
  final VoidCallback? onAddCart;

  // 立即购买回调
  final VoidCallback? onBuyNow;

  const HmActionBar({
    super.key,
    required this.price,
    this.onAddCart,
    this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return HmBottomBar(
      child: Row(
        children: [
          Expanded(
            child: HmBottomBarPrice(label: '单价', amount: '￥$price'),
          ),
          const SizedBox(width: 10),
          HmBottomBarButton(text: '加入购物车', onPressed: onAddCart),
          const SizedBox(width: 10),
          HmBottomBarButton(text: '立即购买', primary: true, onPressed: onBuyNow),
        ],
      ),
    );
  }
}
