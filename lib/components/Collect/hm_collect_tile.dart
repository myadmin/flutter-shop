import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/collect.dart';

/// 收藏列表的一行：商品图 + 名称 + 价格 + 收藏时间
///
/// 收藏项字段做了容错，名称或图片可能为空：名称缺失时展示「商品信息已失效」，
/// 图片缺失时 `AppNetworkImage` 会渲染占位块，不至于出现空白行。
class HmCollectTile extends StatelessWidget {
  const HmCollectTile({super.key, required this.item, this.onTap});

  /// 收藏项
  final CollectItem item;

  /// 点击回调；没有商品 id 时为 null（卡片不可点）
  final VoidCallback? onTap;

  static const double _imageSize = 88;

  @override
  Widget build(BuildContext context) {
    // 字段兜底后仍可能全空（商品被下架、接口字段改名），此时只留一句提示，
    // 不展示「￥0.00」这种会误导人的占位价格。
    final bool hasInfo = item.name.isNotEmpty;
    final bool showPrice = hasInfo || item.price != '0.00';
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
                  url: item.picture,
                  width: _imageSize,
                  height: _imageSize,
                  decodeWidth: _imageSize,
                  placeholderIconSize: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasInfo ? item.name : '商品信息已失效',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Colors.black,
                      ),
                    ),
                    if (showPrice) ...[
                      const SizedBox(height: 8),
                      Text(
                        '￥${item.price}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    if (item.createTime.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '收藏于 ${item.createTime}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
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
