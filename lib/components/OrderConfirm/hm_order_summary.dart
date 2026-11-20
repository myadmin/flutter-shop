import 'package:flutter/material.dart';
import 'package:hm_shop/components/OrderConfirm/hm_order_card.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/order.dart';

/// 订单确认页的金额汇总卡片
///
/// 依次展示商品件数、商品金额、运费与应付金额，
/// 其中应付金额以主色加粗突出。
class HmOrderSummary extends StatelessWidget {
  final OrderSummary summary;

  const HmOrderSummary({super.key, required this.summary});

  Widget _buildRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 15 : 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.normal,
              color: highlight ? AppColors.primary : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrderCard(
      child: Column(
        children: [
          _buildRow('商品件数', '${summary.goodsCount}件'),
          _buildRow('商品金额', '￥${summary.totalPrice}'),
          _buildRow('运费', '￥${summary.postFee}'),
          _buildRow('应付金额', '￥${summary.totalPayPrice}', highlight: true),
        ],
      ),
    );
  }
}
