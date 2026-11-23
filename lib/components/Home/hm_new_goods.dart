import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/components/common/hm_section_header.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

/// 首页「新品首发」模块：横滑商品卡。
///
/// 数据来自 `/home/new`，条目结构与 [GoodsItem] 一致，点击进商品详情。
/// 没有数据时整块不渲染，避免留下一排空标题。
class HmNewGoods extends StatelessWidget {
  final List<GoodsItem> goodsList;

  /// 点击商品回调，为空时卡片不可点
  final ValueChanged<GoodsItem>? onGoodsTap;

  const HmNewGoods({super.key, required this.goodsList, this.onGoodsTap});

  static const double _cardWidth = 132;
  static const double _imageHeight = 132;

  /// 名称固定占两行的高度，保证每张卡的价格行在同一水平线上
  static const double _nameHeight = 33;
  static const double _cardHeight = _imageHeight + 72;

  @override
  Widget build(BuildContext context) {
    if (goodsList.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: HmSectionHeader(title: '新品首发', subtitle: '刚刚上新，先人一步'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: _cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: goodsList.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              return _buildCard(goodsList[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(GoodsItem goods) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onGoodsTap == null ? null : () => onGoodsTap!(goods),
        child: SizedBox(
          width: _cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                url: goods.picture,
                width: _cardWidth,
                height: _imageHeight,
                fit: BoxFit.cover,
                decodeWidth: _cardWidth,
                placeholderIconSize: 32,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: _nameHeight,
                      child: Text(
                        goods.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            '￥${goods.price}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (goods.soldCount > 0)
                          Text(
                            '已售${goods.soldCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
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
