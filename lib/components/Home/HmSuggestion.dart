import 'package:flutter/material.dart';
import 'package:hm_shop/models/home.dart';

class HmSuggestion extends StatefulWidget {
  // 特惠推荐结果
  final SpecialRecommendResult specialRecommendResult;

  const HmSuggestion({Key? key, required this.specialRecommendResult})
    : super(key: key);

  @override
  _HmSuggestionState createState() => _HmSuggestionState();
}

class _HmSuggestionState extends State<HmSuggestion> {
  List<GoodsItem> _getDisplayItems() {
    if (widget.specialRecommendResult.subTypes.isEmpty) {
      return [];
    }

    return widget.specialRecommendResult.subTypes.first.goodsItems.items
        .take(3)
        .toList();
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Text(
            '特惠推荐',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 86, 24, 20),
            ),
          ),
          SizedBox(width: 10),
          Text(
            '精选省攻略',
            style: TextStyle(
              fontSize: 12,
              color: Color.fromARGB(255, 124, 63, 58),
            ),
          ),
        ],
      ),
    );
  }

  // 左侧结构
  Widget _buildLeft() {
    return Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: AssetImage('lib/assets/home_cmd_inner.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  List<Widget> _getChildrenList() {
    List<GoodsItem> list = _getDisplayItems();
    return List.generate(list.length, (int index) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 100,
              height: 140,
              color: Colors.white,
              child: Image.network(
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'lib/assets/home_cmd_inner.png',
                    width: 100,
                    height: 140,
                    fit: BoxFit.cover,
                  );
                },
                list[index].picture,
                width: 100,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 244, 125, 98),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "￥${list[index].price}元",
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: AssetImage('lib/assets/home_cmd_sm.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // 顶部内容
            _buildHeader(),
            SizedBox(height: 10),
            Row(
              children: [
                // 左侧图片与右侧商品均分空间，保证左右及中间间距一致
                Expanded(child: Center(child: _buildLeft())),
                ..._getChildrenList().map(
                  (child) => Expanded(child: Center(child: child)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
