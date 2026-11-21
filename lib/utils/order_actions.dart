import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/cart.dart';
import 'package:hm_shop/models/order_list.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/utils/api_exception.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 弹出「删除订单」确认框，返回用户是否确认
Future<bool> confirmDeleteOrder(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: const Text('确定要删除这笔订单吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// 执行订单状态对应的主操作
///
/// 只有「再次购买」能落到真实接口（复用购物车加购）；支付、提醒发货、
/// 确认收货、评价在演示后端都没有开放接口，这里明确告知用户，
/// 而不是弹一个「操作成功」的假提示。
Future<void> performOrderPrimaryAction(
  BuildContext context,
  OrderItem order,
) async {
  final action = OrderState.primaryActionOf(order.orderState);
  if (action.isEmpty) return;

  if (action != '再次购买') {
    ToastUtils.showToast(context, '演示接口未提供「$action」，暂时无法完成');
    return;
  }

  if (order.skus.isEmpty) {
    ToastUtils.showToast(context, '该订单没有可再次购买的商品');
    return;
  }

  try {
    for (final sku in order.skus) {
      await addCartAPI(sku.id, sku.quantity);
    }
    if (!context.mounted) return;
    if (Get.isRegistered<CartController>()) {
      await Get.find<CartController>().refreshCount();
    }
    if (!context.mounted) return;
    ToastUtils.showToast(context, '已加入购物车');
  } catch (e) {
    if (!context.mounted) return;
    ToastUtils.showToast(context, resolveErrorMessage(e, fallback: '加入购物车失败'));
  }
}
