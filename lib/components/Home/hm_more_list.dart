import 'package:flutter/material.dart';
import 'package:hm_shop/models/home.dart';

class HmMoreList extends StatelessWidget {
  // 推荐列表数据
  final List<GoodDetailItem> recommendList;
  // 商品点击回调
  final ValueChanged<GoodDetailItem>? onItemTap;
  // 构造函数，透传推荐列表数据与点击回调
  const HmMoreList({super.key, required this.recommendList, this.onItemTap});

  // 获取推荐列表项
  Widget _getChildren(int index) {
    final item = recommendList[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 上方：商品图片，占据文字区域之外的剩余高度，
        // 避免窄屏（如 iPhone 12）下固定正方形图片把价格行挤出卡片造成溢出
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8), // 图片圆角
            child: Image.network(
              item.picture, // 商品图片地址
              width: double.infinity,
              fit: BoxFit.cover, // 等比裁剪铺满
              errorBuilder: (context, error, stackTrace) {
                // 图片加载失败时展示本地占位图
                return Image.asset(
                  'lib/assets/home_cmd_inner.png',
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6), // 图片与标题之间的间距
        // 中间：商品标题，最多展示两行，超出省略
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
        const SizedBox(height: 6), // 标题与价格行之间的间距
        // 下方：左右布局，左侧金额，右侧付款人数
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            // 间距
            children: [
              // 金额区域占满剩余宽度，价格过长时等比缩小，避免窄屏横向溢出
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      text: '￥${item.price}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6), // 金额与付款人数之间的间距
              Text(
                '${item.payCount}人付款',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78, // 卡片宽高比，数值越大格子越矮、行间空白越小
      ),
      itemCount: recommendList.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onItemTap == null
                ? null
                : () => onItemTap!(recommendList[index]),
            child: _getChildren(index),
          ),
        );
      },
    );
  }
}
