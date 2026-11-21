import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/order_list.dart';

/// 订单列表顶部的状态切换 tab
///
/// 五个 tab 平分宽度（手机宽度下也放得下），选中项文字变主色并带下划线。
class HmOrderStatusTabs extends StatelessWidget {
  const HmOrderStatusTabs({
    super.key,
    required this.currentState,
    required this.onChanged,
  });

  final int currentState;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            for (final state in OrderState.tabs)
              Expanded(child: _buildTab(state, state == currentState)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int state, bool selected) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(state),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            OrderState.labelOf(state),
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.primary : Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
