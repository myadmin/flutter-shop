import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 统一的网络图片组件，封装了加载中占位、失败兜底与解码尺寸。
///
/// 之前每个页面都各写一遍「灰底 + broken_image 图标」的 errorBuilder，
/// 样式略有差异；同时所有图片都没有设置 cacheWidth，列表滚动时按原图
/// 分辨率解码，内存占用偏高。
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderIconSize = 48,
    this.decodeWidth,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double placeholderIconSize;

  /// 解码宽度（逻辑像素），用于降低大图解码内存开销。
  /// 传入后按设备像素比换算成物理像素的 cacheWidth。
  final double? decodeWidth;

  @override
  Widget build(BuildContext context) {
    final cacheWidth = decodeWidth == null
        ? null
        : (decodeWidth! * MediaQuery.devicePixelRatioOf(context)).round();

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _buildPlaceholder(showIcon: false);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(showIcon: true);
      },
    );
  }

  Widget _buildPlaceholder({required bool showIcon}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.imagePlaceholder,
      alignment: Alignment.center,
      child: showIcon
          ? Icon(
              Icons.broken_image_outlined,
              size: placeholderIconSize,
              color: Colors.grey,
            )
          : null,
    );
  }
}
