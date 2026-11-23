import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

/// 首页顶部的一级分类横滑入口。
///
/// 点击某一项时通过 [onCategoryTap] 把分类抛给调用方（首页交给底部 tab
/// 容器，切到「分类」页并选中同一分类）；回调为空时不响应点击。
class HmCategory extends StatelessWidget {
  final List<CategoryItem> categoryList;

  /// 点击一级分类的回调，为空时整排分类不可点击
  final ValueChanged<CategoryItem>? onCategoryTap;

  const HmCategory({super.key, required this.categoryList, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoryList.length,
        itemBuilder: (BuildContext context, int index) {
          final category = categoryList[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            // 用 Material + InkWell 而不是 GestureDetector：点击时有水波纹，
            // 分类块是圆角胶囊，墨水必须裁到圆角内才不会溢出
            child: Material(
              color: AppColors.categoryTile,
              borderRadius: BorderRadius.circular(40),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onCategoryTap == null
                    ? null
                    : () => onCategoryTap!(category),
                child: SizedBox(
                  width: 80,
                  height: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppNetworkImage(
                        url: category.picture,
                        width: 40,
                        height: 40,
                        decodeWidth: 40,
                        placeholderIconSize: 32,
                      ),
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
