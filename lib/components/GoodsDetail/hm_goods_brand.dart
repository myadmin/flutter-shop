import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/goods.dart';

/// 商品详情页的品牌信息卡片
///
/// logo 为空时展示店铺图标占位，保证与有 logo 时一致的块高。
class HmGoodsBrand extends StatelessWidget {
  final GoodsBrand brand;

  const HmGoodsBrand({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: brand.logo.isEmpty
                ? Container(
                    width: 40,
                    height: 40,
                    color: AppColors.imagePlaceholder,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 22,
                      color: Colors.grey,
                    ),
                  )
                : AppNetworkImage(
                    url: brand.logo,
                    width: 40,
                    height: 40,
                    decodeWidth: 40,
                    placeholderIconSize: 22,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              brand.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const Text(
            '品牌直供',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
