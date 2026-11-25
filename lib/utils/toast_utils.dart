import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 轻提示工具：以居中浮动 SnackBar 的形式展示短文案。
///
/// 同一时间只展示一条提示，避免连续错误时提示叠加刷屏。
class ToastUtils {
  const ToastUtils._();

  /// 上一条提示的文案与其展示截止时间
  static String? _lastMessage;
  static DateTime? _throttleUntil;

  static void showToast(
    BuildContext context,
    String? message, {
    int duration = 2,
  }) {
    final text = message ?? '加载成功';
    final now = DateTime.now();
    final until = _throttleUntil;
    // 只对「同一条文案」去重：既避免同一个动作连点刷屏，
    // 又不会把紧接着出现的关键提示（例如「库存不足」）吞掉。
    if (_lastMessage == text && until != null && now.isBefore(until)) {
      return;
    }
    _lastMessage = text;
    _throttleUntil = now.add(Duration(seconds: duration));
    // 测量文本实际宽度，让 toast 宽度随内容自适应
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: AppTextStyles.body),
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

    final messenger = ScaffoldMessenger.of(context);
    // 新提示直接顶掉旧提示，避免 SnackBar 队列把关键信息延后好几秒才出现
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.toast)),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: duration),
        content: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
