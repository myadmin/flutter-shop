import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/hm_goods_compact_card.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/models/home_extra.dart';

/// 首页分类楼层：一个一级分类一块，含标题、促销语、二级分类入口与横滑商品。
///
/// 数据来自 `/home/goods`（4 个楼层），点击楼层标题进该分类的商品列表页，
/// 点击二级分类进对应子分类的列表页，点击商品进详情页。
class HmHomeFloor extends StatelessWidget {
  const HmHomeFloor({
    super.key,
    required this.floor,
    this.onGoodsTap,
    this.onCategoryTap,
    this.onFloorTap,
    this.maxGoods = 8,
  });

  final HomeFloor floor;

  /// 点击商品
  final ValueChanged<GoodsItem>? onGoodsTap;

  /// 点击二级分类
  final ValueChanged<CategoryItem>? onCategoryTap;

  /// 点击「查看全部」/ 楼层标题
  final VoidCallback? onFloorTap;

  /// 横滑最多展示几件商品
  final int maxGoods;

  static const double _cardWidth = 110;
  static const double _imageHeight = 110;

  @override
  Widget build(BuildContext context) {
    final List<GoodsItem> goods = floor.goods.take(maxGoods).toList();
    if (goods.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildHeader(),
          ),
          if (floor.children.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCategoryChips(),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: HmGoodsCompactCard.heightFor(context, _imageHeight),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: goods.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final GoodsItem item = goods[index];
                return HmGoodsCompactCard(
                  goods: item,
                  width: _cardWidth,
                  imageHeight: _imageHeight,
                  onTap: onGoodsTap == null ? null : () => onGoodsTap!(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 楼层标题：分类名 + 促销语 + 「查看全部」
  Widget _buildHeader() {
    return Row(
      children: [
        Flexible(
          child: Text(
            floor.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
            ),
          ),
        ),
        if (floor.saleInfo.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.image),
              ),
              child: Text(
                floor.saleInfo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.primary),
              ),
            ),
          ),
        ],
        const Spacer(),
        if (onFloorTap != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onFloorTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('查看全部', style: AppTextStyles.captionSmall),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 二级分类入口：横滑胶囊
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: floor.children.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final CategoryItem child = floor.children[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCategoryTap == null ? null : () => onCategoryTap!(child),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                child.name,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.lightBrown,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
