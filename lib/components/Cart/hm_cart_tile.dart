import 'package:flutter/material.dart';
import 'package:hm_shop/components/Cart/hm_cart_quantity_stepper.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/cart.dart';

/// 购物车条目卡片
///
/// 从左到右依次是：勾选框、商品图、商品信息（名称 / 规格 / 价格 / 数量步进器）。
/// 点击商品图或商品信息会进入商品详情页（[onTap]），勾选框、删除与数量步进器
/// 各自处理自己的点击，不会误触发跳转。
/// 失效商品（下架或无货）会展示「商品已失效」并禁用勾选与数量操作。
class HmCartTile extends StatelessWidget {
  final CartItem item;

  final ValueChanged<bool> onSelectedChanged;

  final ValueChanged<int> onCountChanged;

  final VoidCallback onDelete;

  /// 点击商品图 / 商品信息时的回调（进入详情页），为空则不可点
  final VoidCallback? onTap;

  /// 该条目有请求在途时禁用交互
  final bool busy;

  const HmCartTile({
    super.key,
    required this.item,
    required this.onSelectedChanged,
    required this.onCountChanged,
    required this.onDelete,
    this.onTap,
    this.busy = false,
  });

  /// 商品图展示尺寸，同时作为解码尺寸
  static const double _imageSize = 84;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !busy && item.isEffective;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.selected,
            activeColor: AppColors.primary,
            onChanged: enabled
                ? (value) => onSelectedChanged(value ?? false)
                : null,
          ),
          Expanded(
            // 只有图片与文字区域可点，勾选框 / 步进器 / 删除各自独占手势
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.image),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppRadius.image),
                      ),
                      child: AppNetworkImage(
                        url: item.picture,
                        width: _imageSize,
                        height: _imageSize,
                        decodeWidth: _imageSize,
                        placeholderIconSize: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInfo(enabled)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: busy ? null : onDelete,
              child: const Padding(
                padding: EdgeInsets.only(left: 6, top: 2),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        if (item.attrsText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: const BoxDecoration(
              color: AppColors.pageBackground,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: Text(
              item.attrsText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label,
            ),
          ),
        ],
        if (!item.isEffective) ...[
          const SizedBox(height: 4),
          const Text(
            '商品已失效',
            style: TextStyle(fontSize: 11, color: AppColors.primary),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '￥${item.nowPrice}',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            HmCartQuantityStepper(
              count: item.count,
              stock: item.stock,
              enabled: enabled,
              onChanged: onCountChanged,
            ),
          ],
        ),
      ],
    );
  }
}
