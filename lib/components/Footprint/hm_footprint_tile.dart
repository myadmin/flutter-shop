import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/footprint.dart';

/// 足迹列表的一行：商品图 + 名称 + 价格 + 最近浏览时间
class HmFootprintTile extends StatelessWidget {
  const HmFootprintTile({super.key, required this.item, this.onTap});

  /// 足迹条目
  final FootprintItem item;

  /// 点击回调，通常用于跳转商品详情
  final VoidCallback? onTap;

  static const double _imageSize = 88;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.image),
                child: AppNetworkImage(
                  url: item.picture,
                  width: _imageSize,
                  height: _imageSize,
                  decodeWidth: _imageSize,
                  placeholderIconSize: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.isEmpty ? '商品信息已失效' : item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '￥${item.price}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.viewedTimeText} 浏览',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
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
