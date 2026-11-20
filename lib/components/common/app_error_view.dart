import 'package:flutter/material.dart';

/// 统一的整页/整块加载失败提示，带重试按钮。
///
/// 之前商品详情页与订单确认页各写了一份几乎相同的实现，首页则完全没有。
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryText = '重新加载',
  });

  final String message;
  final VoidCallback onRetry;
  final String retryText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
            ),
            child: Text(retryText),
          ),
        ],
      ),
    );
  }
}
