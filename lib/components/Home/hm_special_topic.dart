import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/components/common/hm_section_header.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home_extra.dart';

/// 首页「专题精选」模块：横滑大图专题卡。
///
/// 数据来自 `/home/special`，接口只给列表、没有专题详情接口，
/// 所以点击只把专题抛给调用方（由首页决定提示还是跳分类）。
class HmSpecialTopic extends StatelessWidget {
  const HmSpecialTopic({
    super.key,
    required this.topics,
    this.onTopicTap,
    this.maxCount = 6,
  });

  final List<SpecialTopicItem> topics;

  /// 点击专题回调，为空时卡片不可点
  final ValueChanged<SpecialTopicItem>? onTopicTap;

  final int maxCount;

  static const double _cardWidth = 220;
  static const double _coverHeight = 124;

  @override
  Widget build(BuildContext context) {
    final List<SpecialTopicItem> display = topics.take(maxCount).toList();
    if (display.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: HmSectionHeader(title: '专题精选', subtitle: '编辑严选，一次逛够'),
        ),
        const SizedBox(height: AppSpacing.module),
        SizedBox(
          height: _coverHeight + 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            itemCount: display.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: AppSpacing.module),
            itemBuilder: (BuildContext context, int index) {
              return _buildCard(display[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(SpecialTopicItem topic) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTopicTap == null ? null : () => onTopicTap!(topic),
        child: SizedBox(
          width: _cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                url: topic.cover,
                width: _cardWidth,
                height: _coverHeight,
                fit: BoxFit.cover,
                decodeWidth: _cardWidth,
                placeholderIconSize: 32,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      topic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '￥${topic.lowestPrice} 起',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (topic.popularityText.isNotEmpty)
                          Text(
                            topic.popularityText,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
