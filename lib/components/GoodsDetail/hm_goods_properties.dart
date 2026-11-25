import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/goods.dart';

/// 商品详情页的参数列表与「商品详情」分割标题
///
/// 参数左列固定宽度、右列自适应，长参数值可自动换行。
class HmGoodsProperties extends StatelessWidget {
  final List<GoodsProperty> properties;

  const HmGoodsProperties({super.key, required this.properties});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '商品参数',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          ...properties.map((property) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(property.name, style: AppTextStyles.caption),
                  ),
                  Expanded(
                    child: Text(
                      property.value,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 商品详情页「商品详情」分割标题
class HmGoodsDetailHeader extends StatelessWidget {
  const HmGoodsDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.divider, thickness: 0.5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('商品详情', style: AppTextStyles.bodyStrong),
          ),
          Expanded(child: Divider(color: AppColors.divider, thickness: 0.5)),
        ],
      ),
    );
  }
}
