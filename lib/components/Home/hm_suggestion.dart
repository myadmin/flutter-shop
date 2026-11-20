import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_assets.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

/// 特惠推荐区
///
/// 左侧为本地活动图，右侧展示接口返回的前 3 个商品。
class HmSuggestion extends StatelessWidget {
  final SpecialRecommendResult specialRecommendResult;
  final ValueChanged<GoodsItem>? onGoodsTap;

  const HmSuggestion({
    super.key,
    required this.specialRecommendResult,
    this.onGoodsTap,
  });

  /// 商品图片宽高比，宽度随可用空间自适应，避免固定宽度在窄屏下被挤压
  static const double _imageAspectRatio = 100 / 140;

  List<GoodsItem> _getDisplayItems() {
    if (specialRecommendResult.subTypes.isEmpty) {
      return const [];
    }
    return specialRecommendResult.subTypes.first.goodsItems.items
        .take(3)
        .toList();
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Text(
            '特惠推荐',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
            ),
          ),
          SizedBox(width: 10),
          Text(
            '精选省攻略',
            style: TextStyle(fontSize: 12, color: AppColors.lightBrown),
          ),
        ],
      ),
    );
  }

  Widget _buildLeft() {
    // 按外层分配的宽度等比撑满，避免固定尺寸被挤压变形
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.image),
      child: AspectRatio(
        aspectRatio: _imageAspectRatio,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.homeCmdInner),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _getChildrenList() {
    final list = _getDisplayItems();
    return List.generate(list.length, (index) {
      final goods = list[index];
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onGoodsTap == null ? null : () => onGoodsTap!(goods),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.image),
              child: AspectRatio(
                aspectRatio: _imageAspectRatio,
                // 按格子实际宽度解码，避免小图按原图尺寸解码
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      // 白色底避免透明图片露出下层背景
                      color: Colors.white,
                      child: AppNetworkImage(
                        url: goods.picture,
                        fit: BoxFit.cover,
                        decodeWidth: constraints.maxWidth,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              // 价格过长时等比缩小，避免换行或溢出
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '￥${goods.price}',
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: const DecorationImage(
            image: AssetImage(AppAssets.homeCmdSm),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Row(
              // 顶部对齐，避免左侧活动图被垂直居中下移
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Expanded(child: _buildLeft()),
                ..._getChildrenList().map((child) => Expanded(child: child)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
