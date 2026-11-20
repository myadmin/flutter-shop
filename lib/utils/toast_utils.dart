import 'package:flutter/material.dart';

/// 轻提示工具：以居中浮动 SnackBar 的形式展示短文案。
///
/// 同一时间只展示一条提示，避免连续错误时提示叠加刷屏。
class ToastUtils {
  const ToastUtils._();

  /// 上一次提示的展示截止时间，在此之前的重复调用会被丢弃。
  static DateTime? _throttleUntil;

  static void showToast(
    BuildContext context,
    String? message, {
    int duration = 2,
  }) {
    final now = DateTime.now();
    final until = _throttleUntil;
    if (until != null && now.isBefore(until)) {
      return;
    }
    _throttleUntil = now.add(Duration(seconds: duration));

    final text = message ?? '加载成功';
    // 测量文本实际宽度，让 toast 宽度随内容自适应
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontSize: 14)),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final double textWidth = painter.width;
    painter.dispose();

    final double maxWidth = MediaQuery.sizeOf(context).width - 32;
    double width = textWidth + 56; // 48 内边距 + 8 余量
    if (width > maxWidth) {
      width = maxWidth;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(40)),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: duration),
        content: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
