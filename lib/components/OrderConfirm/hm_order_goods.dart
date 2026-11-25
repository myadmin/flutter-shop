import 'package:flutter/material.dart';
import 'package:hm_shop/components/OrderConfirm/hm_order_card.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/order.dart';

/// 订单确认页的商品信息卡片
///
/// 左图右文，右侧展示名称、规格、单价与购买数量。
class HmOrderGoods extends StatelessWidget {
  final PreOrderGoods goods;

  const HmOrderGoods({super.key, required this.goods});

  @override
  Widget build(BuildContext context) {
    return OrderCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.image),
            child: AppNetworkImage(
              url: goods.picture,
              width: 76,
              height: 76,
              decodeWidth: 76,
              placeholderIconSize: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goods.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong,
                ),
                const SizedBox(height: 4),
                Text(
                  goods.attrsText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '￥${goods.price}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Text('x${goods.count}', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
