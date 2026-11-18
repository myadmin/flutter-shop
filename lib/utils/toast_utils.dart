import 'package:flutter/material.dart';

class ToastUtils {
  // 阀门控制
  static bool showLoading = false;

  static void showToast(
    BuildContext context,
    String? message, {
    int? duration = 2,
  }) {
    if (ToastUtils.showLoading) {
      return;
    }
    ToastUtils.showLoading = true;
    Future.delayed(Duration(seconds: duration ?? 2), () {
      ToastUtils.showLoading = false;
    });

    final String text = message ?? '加载成功';
    // 测量文本实际宽度，让 toast 宽度随内容自适应
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontSize: 14)),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final double textWidth = painter.width;
    painter.dispose();

    final double maxWidth = MediaQuery.of(context).size.width - 32;
    double width = textWidth + 56; // 48 内边距 + 8 余量
    if (width > maxWidth) {
      width = maxWidth;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: duration ?? 2),
        content: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
