import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

/// 商品卡片（图片 + 标题 + 价格 + 付款人数），首页推荐与分类页推荐共用。
///
/// 卡片自身不决定尺寸，由外层的网格决定：图片用 Expanded 吃掉文字之外的
/// 剩余高度，避免窄屏下固定正方形图片把价格行挤出卡片。
class HmGoodsCard extends StatelessWidget {
  const HmGoodsCard({super.key, required this.item, this.onTap});

  /// 商品数据；首页推荐、分类推荐、分类商品列表共用
  final GoodsItem item;

  /// 点击整张卡片
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 读屏软件把「图片 + 标题 + 价格 + 付款人数」当成一个按钮朗读，
    // 而不是逐个碎片读，避免整页几十个商品卡时焦点乱跳
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // 按实际可用宽度解码，避免手机网格里按原图尺寸解码白占内存
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.image),
                      child: AppNetworkImage(
                        url: item.picture,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        decodeWidth: constraints.maxWidth,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    // 价格占满剩余宽度并等比缩小，避免窄屏横向溢出
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: '￥${item.price}',
                            style: AppTextStyles.pageTitle,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      '${item.soldCount}人付款',
                      style: const TextStyle(color: Colors.grey),
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
