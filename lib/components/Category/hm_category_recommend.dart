import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/hm_goods_card.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

/// 分类页右侧底部的「猜你喜欢」区块。
///
/// 二级分类点进去还没有商品列表页，这里用推荐商品补上一条通往商品详情的
/// 路径，同时避免右侧内容过少时大片留白。
class HmCategoryRecommend extends StatelessWidget {
  const HmCategoryRecommend({
    super.key,
    required this.items,
    required this.onGoodsTap,
    this.isLoading = false,
  });

  /// 推荐商品
  final List<GoodDetailItem> items;

  /// 点击商品回调
  final ValueChanged<GoodDetailItem> onGoodsTap;

  /// 是否正在加载（只在首次加载时展示转圈，失败时静默降级）
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.small),
        const Divider(
          height: 1,
          thickness: 0.5,
          color: AppColors.divider,
          indent: 12,
          endIndent: 12,
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Row(
            children: [
              Text('猜你喜欢', style: AppTextStyles.bodyStrong),
              Spacer(),
              Text('为你精选', style: AppTextStyles.captionSmall),
            ],
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('暂无推荐商品', style: AppTextStyles.caption)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              // 按可用宽度自动分列：手机两列，宽屏最多六列，
              // 避免宽屏下卡片被拉成竖长条
              maxCrossAxisExtent: 210,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final GoodDetailItem item = items[index];
              return HmGoodsCard(item: item, onTap: () => onGoodsTap(item));
            },
          ),
        const SizedBox(height: AppSpacing.large),
      ],
    );
  }
}
