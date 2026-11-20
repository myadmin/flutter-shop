import 'package:flutter/material.dart';
import 'package:hm_shop/models/goods.dart';

/// 商品详情页的价格、销量与标题区块
///
/// 划线价仅在存在且与售价不同时展示，避免原名价等于售价时的冗余信息。
class HmGoodsPriceInfo extends StatelessWidget {
  final GoodsDetail detail;

  const HmGoodsPriceInfo({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final bool showOldPrice =
        detail.oldPrice.isNotEmpty && detail.oldPrice != detail.price;
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '￥${detail.price}',
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              if (showOldPrice) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '￥${detail.oldPrice}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '已售${detail.salesCount} · 评价${detail.commentCount}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (detail.desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail.desc,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
