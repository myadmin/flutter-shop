import 'package:flutter/material.dart';

/// 「猜你喜欢」分区标题，作为 pinned 的 SliverPersistentHeader 使用。
///
/// 高度固定为 [height]，内容为居中标题，因此 [shouldRebuild] 恒为 false。
class HmGuess extends SliverPersistentHeaderDelegate {
  const HmGuess({this.height = 60, this.title = '猜你喜欢'});

  /// 标题栏高度
  final double height;

  /// 标题文案
  final String title;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      alignment: Alignment.center,
      color: Colors.white,
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, color: Colors.black),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant HmGuess oldDelegate) {
    // 只有高度或文案变化时才需要重建，避免滚动过程中无谓刷新
    return oldDelegate.height != height || oldDelegate.title != title;
  }
}
