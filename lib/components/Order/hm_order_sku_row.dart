import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/order_list.dart';

/// 订单里的商品行：图片 + 名称 + 规格 + 单价 × 数量
///
/// 订单列表卡片与订单详情页共用，保证两处排版一致。
class HmOrderSkuRow extends StatelessWidget {
  const HmOrderSkuRow({super.key, required this.sku});

  final OrderSku sku;

  static const double _imageSize = 64;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.image),
            child: AppNetworkImage(
              url: sku.image,
              width: _imageSize,
              height: _imageSize,
              decodeWidth: _imageSize,
              placeholderIconSize: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sku.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                ),
                if (sku.attrsText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sku.attrsText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionSmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '￥${sku.price}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text('×${sku.quantity}', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
