import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

/// 分类页左侧的一级分类导航。
///
/// 选中项用「白底 + 左侧主色竖条 + 加粗黑字」与未选中项（灰底 + 灰字）
/// 区分开，右侧内容区也是白底，视觉上两者连成一片。
class HmCategoryRail extends StatelessWidget {
  const HmCategoryRail({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    this.controller,
    this.itemHeight = defaultItemHeight,
    this.width = 92,
  });

  /// 单项默认高度
  ///
  /// 分类页在「外部指定选中项」时需要按这个高度算出要滚动到哪个偏移，
  /// 所以把默认值提成常量，避免两处写死后不同步。
  static const double defaultItemHeight = 56;

  /// 一级分类列表
  final List<CategoryItem> categories;

  /// 当前选中的下标
  final int selectedIndex;

  /// 点击某一级分类时回调下标
  final ValueChanged<int> onSelected;

  /// 列表滚动控制器；由分类页持有，用于把外部选中的分类滚到可视区
  final ScrollController? controller;

  /// 单项高度
  final double itemHeight;

  /// 导航栏宽度
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: AppColors.pageBackground,
      child: ListView.builder(
        controller: controller,
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        itemBuilder: (BuildContext context, int index) {
          final bool selected = index == selectedIndex;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(index),
            child: Container(
              height: itemHeight,
              color: selected ? Colors.white : Colors.transparent,
              child: Stack(
                children: [
                  if (selected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 3, color: AppColors.primary),
                    ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        categories[index].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selected
                              ? Colors.black
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
