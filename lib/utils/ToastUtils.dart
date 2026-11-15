import 'package:flutter/material.dart';

class ToastUtils {
  static void showToast(
    BuildContext context,
    String? message, {
    int? duration = 2,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: 120,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: duration ?? 2),
        content: Text(message ?? '加载成功', textAlign: TextAlign.center),
      ),
    );
  }
}
