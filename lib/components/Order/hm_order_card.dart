import 'package:flutter/material.dart';
import 'package:hm_shop/components/Order/hm_order_sku_row.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/order_list.dart';

/// 订单列表里的一张订单卡片
///
/// 自上而下：订单状态与下单时间 → 商品行 → 合计金额 → 操作按钮。
/// 操作按钮由调用方决定是否传入：列表页传「删除订单」与状态对应的主操作。
class HmOrderCard extends StatelessWidget {
  const HmOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onDelete,
    this.onPrimaryAction,
    this.maxSkuRows = 3,
  });

  final OrderItem order;

  /// 点击卡片进入订单详情
  final VoidCallback? onTap;

  /// 删除订单（接口支持，可用）
  final VoidCallback? onDelete;

  /// 状态对应的主操作（去支付 / 提醒发货 / 确认收货 / 去评价 / 再次购买）
  final VoidCallback? onPrimaryAction;

  /// 最多展示几行商品，超出部分折叠成「共 N 件商品」
  final int maxSkuRows;

  @override
  Widget build(BuildContext context) {
    final primaryText = OrderState.primaryActionOf(order.orderState);
    final visibleSkus = order.skus.take(maxSkuRows).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '订单号 ${order.shortId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      OrderState.labelOf(order.orderState),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(order.createTime, style: AppTextStyles.captionSmall),
                const Divider(height: 16, color: AppColors.divider),
                for (final sku in visibleSkus) HmOrderSkuRow(sku: sku),
                if (order.skus.length > visibleSkus.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '还有 ${order.skus.length - visibleSkus.length} 件商品',
                      style: AppTextStyles.captionSmall,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '共 ${order.goodsCount} 件',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 8),
                    const Text('实付', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 2),
                    Text('￥${order.payMoney}', style: AppTextStyles.price),
                  ],
                ),
                if (onDelete != null || onPrimaryAction != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onDelete != null)
                        _OrderCardButton(
                          text: '删除订单',
                          onPressed: onDelete,
                          filled: false,
                        ),
                      if (onDelete != null && onPrimaryAction != null)
                        const SizedBox(width: 8),
                      if (onPrimaryAction != null && primaryText.isNotEmpty)
                        _OrderCardButton(
                          text: primaryText,
                          onPressed: onPrimaryAction,
                          filled: true,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 订单卡片上的小按钮
class _OrderCardButton extends StatelessWidget {
  const _OrderCardButton({
    required this.text,
    required this.onPressed,
    required this.filled,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(text),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.bodySmall,
              ),
              child: Text(text),
            ),
    );
  }
}
