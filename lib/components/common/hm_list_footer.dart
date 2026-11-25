import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_text_styles.dart';

/// 分页列表底部的状态条
///
/// 三种状态：正在加载下一页（小转圈）、还有下一页（占位撑开一点高度）、
/// 没有更多了（灰色提示）。收藏、订单等分页列表共用。
class HmListFooter extends StatelessWidget {
  const HmListFooter({
    super.key,
    required this.loadingMore,
    required this.hasMore,
    this.noMoreText = '没有更多了',
  });

  /// 是否正在加载下一页
  final bool loadingMore;

  /// 是否还有下一页
  final bool hasMore;

  /// 没有更多数据时的提示文案
  final String noMoreText;

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (hasMore) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(child: Text(noMoreText, style: AppTextStyles.caption)),
    );
  }
}
