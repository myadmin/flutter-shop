import 'package:flutter/material.dart';
import 'package:hm_shop/models/home.dart';

class HmMoreList extends StatefulWidget {
  // 推荐列表数据
  final List<GoodDetailItem> recommendList;
  // 构造函数，透传推荐列表数据
  const HmMoreList({Key? key, required this.recommendList}) : super(key: key);

  @override
  _HmMoreListState createState() => _HmMoreListState();
}

class _HmMoreListState extends State<HmMoreList> {
  // 获取推荐列表项
  Widget _getChildren(int index) {
    final item = widget.recommendList[index];
    return Column(
      children: [
        // 上方：商品图片
        ClipRRect(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8), // 图片圆角
            child: AspectRatio(
              aspectRatio: 1.0, // 图片宽度与高度的比例
              child: Image.network(
                item.picture, // 商品图片地址
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
        ),
        SizedBox(height: 6), // 图片与标题之间的间距
        // 中间：商品标题，最多展示两行，超出省略
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
        SizedBox(height: 6), // 标题与价格行之间的间距
        // 下方：左右布局，左侧金额，右侧付款人数
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // 间距
            children: [
              Text.rich(
                TextSpan(
                  text: '￥${item.price}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: " "),
                    TextSpan(
                      text: item.price,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
              Text('${item.payCount}人付款', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78, // 卡片宽高比，数值越大格子越矮、行间空白越小
      ),
      itemCount: widget.recommendList.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: _getChildren(index),
        );
      },
    );
  }
}
