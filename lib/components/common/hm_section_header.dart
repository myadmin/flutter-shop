import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 首页各内容模块的标题栏（主标题 + 灰色副标题）。
///
/// 首页现在有新品首发、人气好物榜、品牌好店、爆款推荐等多个模块，
/// 标题样式统一走这里，避免每个模块各写一份 TextStyle。
class HmSectionHeader extends StatelessWidget {
  final String title;

  /// 副标题，为空时不占位
  final String subtitle;

  const HmSectionHeader({super.key, required this.title, this.subtitle = ''});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.lightBrown),
            ),
          ),
        ],
      ],
    );
  }
}
