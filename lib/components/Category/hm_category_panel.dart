import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

/// 分类页右侧的子分类宫格。
///
/// 展示当前一级分类下的全部二级分类（图片 + 名称），点击回调由页面接管。
class HmCategoryPanel extends StatelessWidget {
  const HmCategoryPanel({
    super.key,
    required this.category,
    required this.onSubCategoryTap,
    this.controller,
    this.recommend,
  });

  /// 当前选中的一级分类
  final CategoryItem category;

  /// 点击某个二级分类时回调
  final ValueChanged<CategoryItem> onSubCategoryTap;

  /// 右侧滚动控制器，切换一级分类时由页面用它回到顶部
  final ScrollController? controller;

  /// 宫格下方的追加内容（页面传入「猜你喜欢」区块），为空则不占位
  final Widget? recommend;

  /// 宫格左右内边距
  static const double _hPadding = 12;

  /// 宫格列间距
  static const double _hSpacing = 8;

  /// 图片下方文字区高度：间距 6 + 一行名称约 16，再留几像素余量，
  /// 避免不同字体、文字缩放下出现 1 像素溢出
  static const double _textAreaHeight = 26;

  @override
  Widget build(BuildContext context) {
    final List<CategoryItem> children = category.children ?? const [];
    if (children.isEmpty) {
      return _buildEmpty();
    }
    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int crossAxisCount = _resolveCrossAxisCount(
            constraints.maxWidth,
          );
          // 按列数反推单元格宽度，把图片限制成正方形（宽屏下不再拉伸）
          final double cellWidth =
              (constraints.maxWidth -
                  _hPadding * 2 -
                  _hSpacing * (crossAxisCount - 1)) /
              crossAxisCount;
          final double imageSize = cellWidth.clamp(64.0, 120.0);
          return CustomScrollView(
            controller: controller,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(children.length)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: _hPadding),
                sliver: SliverGrid.builder(
                  // 图片固定为正方形、文字行高固定，所以这里按算出来的单元格
                  // 尺寸给 mainAxisExtent，避免宽屏下图片被拉成又宽又扁的长条
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: _hSpacing,
                    mainAxisExtent: imageSize + _textAreaHeight,
                  ),
                  itemCount: children.length,
                  itemBuilder: (BuildContext context, int index) {
                    final CategoryItem child = children[index];
                    return _buildSubCategory(child, imageSize);
                  },
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text('更多分类持续上新', style: AppTextStyles.captionSmall),
                  ),
                ),
              ),
              if (recommend != null) SliverToBoxAdapter(child: recommend!),
            ],
          );
        },
      ),
    );
  }

  /// Web 宽屏下多排两列，避免每格被拉成又宽又扁的长条
  int _resolveCrossAxisCount(double width) {
    if (width >= 1100) return 6;
    if (width >= 860) return 5;
    if (width >= 640) return 4;
    return 3;
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: Row(
        children: [
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text('共 $count 个分类', style: AppTextStyles.captionSmall),
        ],
      ),
    );
  }

  Widget _buildSubCategory(CategoryItem child, double imageSize) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSubCategoryTap(child),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.image),
            child: AppNetworkImage(
              url: child.picture,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.cover,
              // 按实际显示尺寸解码，避免大图占用解码内存
              decodeWidth: imageSize,
              placeholderIconSize: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            child.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.category_outlined,
              size: 44,
              color: AppColors.divider,
            ),
            const SizedBox(height: AppSpacing.module),
            Text(
              '「${category.name}」暂无子分类',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
