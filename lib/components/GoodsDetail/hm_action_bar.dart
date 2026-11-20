import 'package:flutter/material.dart';

/// 商品详情底部操作栏
///
/// 由详情页挂载在 Scaffold 的 bottomNavigationBar 上，
/// 始终固定在视口底部，左侧展示单价，右侧提供购买操作入口。
class HmActionBar extends StatelessWidget {
  // 当前商品单价
  final String price;

  // 加入购物车回调
  final VoidCallback? onAddCart;

  // 立即购买回调
  final VoidCallback? onBuyNow;

  const HmActionBar({
    super.key,
    required this.price,
    this.onAddCart,
    this.onBuyNow,
  });

  // 操作栏内容最大宽度，避免 PC 端按钮被拉得过宽
  static const double _maxContentWidth = 600;

  // 构建操作按钮，primary 为 true 时使用主色突出展示
  Widget _buildButton({
    required String text,
    required bool primary,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? const Color(0xFFF47D62)
              : const Color(0xFFFFF2E8),
          foregroundColor: primary ? Colors.white : const Color(0xFF561814),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: Text(text, maxLines: 1),
      ),
    );
  }

  // 单价信息
  Widget _buildPrice() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('单价', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          '￥$price',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          // heightFactor 为 1 时按内容高度收缩，避免撑满整个视口
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: _buildPrice()),
                  const SizedBox(width: 10),
                  _buildButton(
                    text: '加入购物车',
                    primary: false,
                    onPressed: onAddCart,
                  ),
                  const SizedBox(width: 10),
                  _buildButton(
                    text: '立即购买',
                    primary: true,
                    onPressed: onBuyNow,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
