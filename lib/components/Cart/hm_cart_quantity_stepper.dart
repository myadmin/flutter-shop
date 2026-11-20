import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 购物车数量步进器（− 数量 +）
///
/// 到达库存上限时「+」自动禁用；数量下限为 1，减到 1 后「−」禁用，
/// 删除商品走条目上的删除按钮，避免误操作把商品数量减成 0。
class HmCartQuantityStepper extends StatelessWidget {
  final int count;

  /// 库存上限，用于禁用「+」
  final int stock;

  final ValueChanged<int> onChanged;

  /// 请求进行中时整组禁用，避免连点产生并发请求
  final bool enabled;

  const HmCartQuantityStepper({
    super.key,
    required this.count,
    required this.stock,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove,
          enabled: enabled && count > 1,
          onTap: () => onChanged(count - 1),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          enabled: enabled && count < stock,
          onTap: () => onChanged(count + 1),
        ),
      ],
    );
  }
}

/// 步进器的单个按钮
class _StepperButton extends StatelessWidget {
  final IconData icon;

  final bool enabled;

  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? Colors.black87 : AppColors.divider,
        ),
      ),
    );
  }
}
