import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';

/// 商品详情主图轮播
///
/// 主图按正方形展示，底部指示器标识当前下标；
/// 无主图时用占位图兜底，避免页面塌陷。
class HmGoodsGallery extends StatelessWidget {
  final List<String> pictures;

  /// 当前展示的下标，由父级持有以保持滚动位置
  final int currentIndex;

  final ValueChanged<int> onIndexChanged;

  const HmGoodsGallery({
    super.key,
    required this.pictures,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (pictures.isEmpty) {
      return const AppNetworkImage(url: '', height: 300);
    }
    // 商品主图为正方形，按屏幕宽度等比展示
    final double imageSize = MediaQuery.sizeOf(context).width;
    return Stack(
      children: [
        CarouselSlider(
          items: pictures.map((picture) {
            return AppNetworkImage(
              url: picture,
              width: imageSize,
              fit: BoxFit.cover,
              decodeWidth: imageSize,
            );
          }).toList(),
          options: CarouselOptions(
            height: imageSize,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) => onIndexChanged(index),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pictures.length, (int index) {
              final bool active = index == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
