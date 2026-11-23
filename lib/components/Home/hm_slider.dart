import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/utils/toast_utils.dart';

class HmSlider extends StatefulWidget {
  final List<BannerItem> bannerList;

  /// 是否允许自动轮播
  ///
  /// 首页被 IndexedStack 保活，切到其它 tab 后这个 widget 仍在树上；
  /// 传 false 可以让 carousel_slider 取消定时器（它在 didUpdateWidget 里
  /// 会调用 handleAutoPlay 重新决定是否起定时器）。
  final bool autoPlay;

  /// 点击某张轮播图时的回调
  ///
  /// 轮播本身不决定跳哪里：banner 上的 `hrefUrl` / `type` 由调用方解释
  /// （首页会按类型切分类 tab 或进商品详情），传 null 时点击给出提示。
  final ValueChanged<BannerItem>? onBannerTap;

  const HmSlider({
    super.key,
    required this.bannerList,
    this.autoPlay = true,
    this.onBannerTap,
  });

  @override
  State<HmSlider> createState() => _HmSliderState();
}

class _HmSliderState extends State<HmSlider> {
  final CarouselSliderController _controller = CarouselSliderController();

  int _currentIndex = 0;

  Widget _getSlider() {
    return CarouselSlider(
      carouselController: _controller,
      items: List.generate(widget.bannerList.length, (int index) {
        final BannerItem banner = widget.bannerList[index];
        final ValueChanged<BannerItem>? onBannerTap = widget.onBannerTap;
        return GestureDetector(
          // opaque：图片本身不可点也要占住整块区域，否则点在图片留白处没反应
          behavior: HitTestBehavior.opaque,
          onTap: onBannerTap == null ? null : () => onBannerTap(banner),
          child: AppNetworkImage(
            url: banner.imageUrl,
            fit: BoxFit.cover,
            decodeWidth: MediaQuery.sizeOf(context).width,
          ),
        );
      }),
      options: CarouselOptions(
        viewportFraction: 1.0,
        autoPlay: widget.autoPlay,
        autoPlayInterval: const Duration(seconds: 4),
        height: 300,
        onPageChanged: (index, reason) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  /// 搜索框目前是纯展示：点击后给出「功能未开放」提示，避免静默无响应。
  Widget _getSearch() {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ToastUtils.showToast(context, '搜索功能开发中，敬请期待');
          },
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.searchOverlay,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  '搜索...',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getDots() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.bannerList.length, (int index) {
            return GestureDetector(
              onTap: () {
                _controller.animateToPage(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: index == _currentIndex ? 40 : 20,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: index == _currentIndex
                      ? Colors.white
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [_getSlider(), _getSearch(), _getDots()]);
  }
}
