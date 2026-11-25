import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/components/common/hm_section_header.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

/// 首页「人气好物榜」模块：竖排名次列表。
///
/// 数据来自 `/hot/new`（结构与 `/hot/inVogue` 相同），取第一个子分类的
/// 前 [maxCount] 件商品；名次用徽标展示，前三名用主色区分。
class HmRankList extends StatelessWidget {
  final SpecialRecommendResult? result;

  /// 点击商品回调，为空时行不可点
  final ValueChanged<GoodsItem>? onGoodsTap;

  /// 最多展示几条
  final int maxCount;

  const HmRankList({
    super.key,
    this.result,
    this.onGoodsTap,
    this.maxCount = 4,
  });

  static const double _imageSize = 64;

  List<GoodsItem> _getDisplayItems() {
    final result = this.result;
    if (result == null || result.subTypes.isEmpty) {
      return const [];
    }
    return result.subTypes.first.goodsItems.items.take(maxCount).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _getDisplayItems();
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HmSectionHeader(title: '人气好物榜', subtitle: '大家都在买'),
          const SizedBox(height: 6),
          for (var index = 0; index < items.length; index++)
            _buildRow(index, items[index]),
        ],
      ),
    );
  }

  Widget _buildRow(int index, GoodsItem goods) {
    return InkWell(
      onTap: onGoodsTap == null ? null : () => onGoodsTap!(goods),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: index < 3 ? 16 : 14,
                  fontWeight: FontWeight.w700,
                  color: index < 3
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.image),
              child: AppNetworkImage(
                url: goods.picture,
                width: _imageSize,
                height: _imageSize,
                fit: BoxFit.cover,
                decodeWidth: _imageSize,
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
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '￥${goods.price}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (goods.soldCount > 0)
                        Text(
                          '已售${goods.soldCount}',
                          style: AppTextStyles.captionSmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
