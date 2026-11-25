import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/components/common/hm_section_header.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/brand.dart';

/// 首页「品牌好店」模块：横滑品牌卡。
///
/// 数据来自 `/home/brand`，点击进品牌详情页（`/brand?id=<品牌 id>`）。
class HmBrandStrip extends StatelessWidget {
  final List<BrandItem> brandList;

  /// 点击品牌回调，为空时卡片不可点
  final ValueChanged<BrandItem>? onBrandTap;

  const HmBrandStrip({super.key, required this.brandList, this.onBrandTap});

  static const double _cardWidth = 76;
  static const double _logoSize = 44;

  @override
  Widget build(BuildContext context) {
    if (brandList.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: HmSectionHeader(title: '品牌好店', subtitle: '官方直供，品质保障'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: brandList.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              // 每个品牌卡读成一个按钮（品牌名），logo 不单独成为焦点
              return MergeSemantics(
                child: Semantics(
                  button: onBrandTap != null,
                  child: _buildCard(brandList[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BrandItem brand) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onBrandTap == null ? null : () => onBrandTap!(brand),
        child: SizedBox(
          width: _cardWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppNetworkImage(
                url: brand.logo,
                width: _logoSize,
                height: _logoSize,
                fit: BoxFit.contain,
                decodeWidth: _logoSize,
                placeholderIconSize: 24,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  brand.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
