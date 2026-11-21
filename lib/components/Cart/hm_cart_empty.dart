import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/hm_empty_view.dart';

/// 购物车的空态 / 未登录态
///
/// 排版复用 [HmEmptyView]，这里只保留「购物车语义」的参数名，
/// 免得调用方去记通用组件的可选参数。
class HmCartEmpty extends StatelessWidget {
  final IconData icon;

  final String title;

  final String description;

  final String actionText;

  final VoidCallback onAction;

  const HmCartEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return HmEmptyView(
      icon: icon,
      title: title,
      description: description,
      actionText: actionText,
      onAction: onAction,
    );
  }
}
