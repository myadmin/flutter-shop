import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

/// 首页横滑用的紧凑商品卡（图 + 两行名 + 价格 + 销量）。
///
/// 「新品首发」与分类楼层都是「横滑一排小卡」，卡片结构完全一致，
/// 抽在这里共用，避免两处各写一份布局后样式走偏。
class HmGoodsCompactCard extends StatelessWidget {
  const HmGoodsCompactCard({
    super.key,
    required this.goods,
    this.onTap,
    this.width = 132,
    this.imageHeight = 132,
  });

  final GoodsItem goods;

  /// 点击回调，为空时卡片不可点
  final VoidCallback? onTap;

  final double width;
  final double imageHeight;

  /// 名称固定占两行的高度（1 倍字号下的基准值）
  static const double _nameHeight = 33;

  /// 图片 + 名称区 + 价格行（1 倍字号下的基准值）
  static const double _textAreaHeight = 72;

  /// 当前字号相对 1 倍的缩放比（应用根节点已把缩放夹在 1.0～1.3）
  ///
  /// 名称区高度是写死的（保证一排卡片的价签在同一水平线），字号变大后
  /// 两行字会超出这个固定高度被裁掉，所以按缩放比同比放大。
  static double _scaleOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(12) / 12;

  /// 卡片总高度：外层横滑列表要按这个值定高
  static double heightFor(BuildContext context, double imageHeight) =>
      imageHeight + _textAreaHeight * _scaleOf(context);

  @override
  Widget build(BuildContext context) {
    // 读屏软件把整张卡读成一个按钮，避免图片 / 名称 / 价格被拆成多个焦点
    return MergeSemantics(
      child: Semantics(button: onTap != null, child: _buildCard(context)),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                url: goods.picture,
                width: width,
                height: imageHeight,
                fit: BoxFit.cover,
                decodeWidth: width,
                placeholderIconSize: 32,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: _nameHeight * _scaleOf(context),
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
                    // 楼层里的小卡只有 110 宽，「￥1566.00 + 已售17」放不下，
                    // 价格用 FittedBox 缩排而不是截断成「￥1566....」
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '￥${goods.price}',
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        if (goods.soldCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '已售${goods.soldCount}',
                              maxLines: 1,
                              softWrap: false,
                              style: AppTextStyles.label,
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
