import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 通用商品条目：左侧商品图，右侧标题 / 价格 / 一行附注
///
/// 收藏列表与足迹列表原本各写一份几乎逐行相同的实现（93 行 + 82 行），
/// 差异只有「附注文案」和「价格是否展示」，这里合并成一个组件。
class HmGoodsSummaryTile extends StatelessWidget {
  const HmGoodsSummaryTile({
    super.key,
    required this.name,
    required this.price,
    required this.picture,
    required this.metaText,
    this.onTap,
    this.showPrice = true,
    this.imageSize = 88,
  });

  /// 商品名称；为空时展示「商品信息已失效」
  final String name;

  /// 商品价格（已格式化，如 `69.90`）
  final String price;

  /// 商品图地址
  final String picture;

  /// 附注文案，如「收藏于 2026-11-25」；为空时不展示
  final String metaText;

  /// 点击回调；没有商品 id 时为 null（条目不可点）
  final VoidCallback? onTap;

  /// 是否展示价格（名称与价格都缺失时不展示，避免出现「￥0.00」误导）
  final bool showPrice;

  /// 商品图边长
  final double imageSize;

  static const String _invalidText = '商品信息已失效';

  @override
  Widget build(BuildContext context) {
    final bool hasInfo = name.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.image),
                child: AppNetworkImage(
                  url: picture,
                  width: imageSize,
                  height: imageSize,
                  decodeWidth: imageSize,
                  placeholderIconSize: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasInfo ? name : _invalidText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tileTitle,
                    ),
                    if (showPrice) ...[
                      const SizedBox(height: 8),
                      Text('￥$price', style: AppTextStyles.price),
                    ],
                    if (metaText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(metaText, style: AppTextStyles.captionSmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
