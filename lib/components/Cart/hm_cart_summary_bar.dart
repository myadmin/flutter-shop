import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 购物车底部结算栏
///
/// 左侧全选框、中间合计金额、右侧结算按钮，外壳复用 [HmBottomBar]，
/// 与商品详情页、订单确认页的底栏保持相同的贴底与最大宽度规则。
class HmCartSummaryBar extends StatelessWidget {
  final bool allSelected;

  final ValueChanged<bool> onAllSelectedChanged;

  /// 已勾选且有效的商品件数，用于按钮文案
  final int selectedCount;

  /// 合计金额（已格式化为两位小数）
  final String totalAmount;

  final VoidCallback? onCheckout;

  /// 全选请求在途时禁用全选框
  final bool busy;

  const HmCartSummaryBar({
    super.key,
    required this.allSelected,
    required this.onAllSelectedChanged,
    required this.selectedCount,
    required this.totalAmount,
    required this.onCheckout,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return HmBottomBar(
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: busy ? null : () => onAllSelectedChanged(!allSelected),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: allSelected,
                  activeColor: AppColors.primary,
                  onChanged: busy
                      ? null
                      : (value) => onAllSelectedChanged(value ?? false),
                ),
                const Text(
                  '全选',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: HmBottomBarPrice(
                  label: '合计（不含运费）',
                  amount: '￥$totalAmount',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          HmBottomBarButton(
            text: selectedCount == 0 ? '结算' : '结算($selectedCount)',
            primary: true,
            onPressed: onCheckout,
          ),
        ],
      ),
    );
  }
}
