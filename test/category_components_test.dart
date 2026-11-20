import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/Category/hm_category_panel.dart';
import 'package:hm_shop/components/Category/hm_category_rail.dart';
import 'package:hm_shop/components/Category/hm_category_recommend.dart';
import 'package:hm_shop/components/Category/hm_category_search.dart';
import 'package:hm_shop/components/common/hm_goods_card.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

CategoryItem _category(String id, String name, {List<CategoryItem>? children}) {
  return CategoryItem(id: id, name: name, picture: '', children: children);
}

GoodDetailItem _goods(
  String id,
  String name, {
  String price = '69.90',
  int payCount = 12,
}) {
  return GoodDetailItem(
    id: id,
    name: name,
    price: price,
    picture: '',
    orderNum: 5,
    payCount: payCount,
  );
}

void main() {
  group('分类页组件', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('HmCategorySearch 展示占位文案并响应点击', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(HmCategorySearch(onTap: () => tapped = true)),
      );

      expect(find.text('搜索商品'), findsOneWidget);
      await tester.tap(find.text('搜索商品'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('HmCategorySearch 支持自定义占位文案', (tester) async {
      await tester.pumpWidget(wrap(const HmCategorySearch(hintText: '搜索分类')));

      expect(find.text('搜索分类'), findsOneWidget);
      expect(find.text('搜索商品'), findsNothing);
    });

    testWidgets('HmCategoryRail 渲染全部一级分类并回调下标', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 400,
            child: HmCategoryRail(
              categories: [
                _category('1', '气质女装'),
                _category('2', '女士内衣'),
                _category('3', '箱包手袋'),
              ],
              selectedIndex: 0,
              onSelected: tapped.add,
            ),
          ),
        ),
      );

      expect(find.text('气质女装'), findsOneWidget);
      expect(find.text('箱包手袋'), findsOneWidget);

      await tester.tap(find.text('箱包手袋'));
      await tester.pump();
      expect(tapped, [2]);
    });

    testWidgets('HmCategoryRail 选中项加粗、未选中项为次要色', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 400,
            child: HmCategoryRail(
              categories: [_category('1', '气质女装'), _category('2', '女士内衣')],
              selectedIndex: 1,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      final unselected = tester.widget<Text>(find.text('气质女装'));
      final selected = tester.widget<Text>(find.text('女士内衣'));

      expect(selected.style?.fontWeight, FontWeight.w600);
      expect(selected.style?.color, Colors.black);
      expect(unselected.style?.fontWeight, FontWeight.normal);
      expect(unselected.style?.color, AppColors.textSecondary);
    });

    testWidgets('HmCategoryPanel 渲染分类标题、数量与全部子分类', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            height: 500,
            child: HmCategoryPanel(
              category: _category(
                '1',
                '气质女装',
                children: [
                  _category('11', '半裙'),
                  _category('12', '连衣裙'),
                  _category('13', '衬衫'),
                ],
              ),
              onSubCategoryTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('气质女装'), findsOneWidget);
      expect(find.text('共 3 个分类'), findsOneWidget);
      expect(find.text('半裙'), findsOneWidget);
      expect(find.text('连衣裙'), findsOneWidget);
      expect(find.text('衬衫'), findsOneWidget);
      expect(find.text('更多分类持续上新'), findsOneWidget);
    });

    testWidgets('HmCategoryPanel 点击子分类回调对应模型', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            height: 500,
            child: HmCategoryPanel(
              category: _category(
                '1',
                '气质女装',
                children: [_category('11', '半裙'), _category('12', '连衣裙')],
              ),
              onSubCategoryTap: (child) => tapped.add(child.id),
            ),
          ),
        ),
      );

      await tester.tap(find.text('连衣裙'));
      await tester.pump();
      expect(tapped, ['12']);
    });

    testWidgets('HmCategoryPanel 无子分类时展示空态', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            height: 500,
            child: HmCategoryPanel(
              category: _category('1', '时尚女鞋'),
              onSubCategoryTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('「时尚女鞋」暂无子分类'), findsOneWidget);
      expect(find.text('更多分类持续上新'), findsNothing);
    });
  });

  group('分类页推荐区块', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('HmGoodsCard 展示名称、价格与付款人数并响应点击', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 160,
            height: 220,
            child: HmGoodsCard(
              item: _goods('1', '春季半裙'),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('春季半裙'), findsOneWidget);
      expect(find.text('￥69.90'), findsOneWidget);
      expect(find.text('12人付款'), findsOneWidget);

      await tester.tap(find.text('春季半裙'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('HmCategoryRecommend 渲染标题与商品并回调点击', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: HmCategoryRecommend(
              items: [_goods('101', '直筒牛仔裤'), _goods('102', '针织开衫')],
              onGoodsTap: (item) => tapped.add(item.id),
            ),
          ),
        ),
      );

      expect(find.text('猜你喜欢'), findsOneWidget);
      expect(find.text('为你精选'), findsOneWidget);
      expect(find.text('直筒牛仔裤'), findsOneWidget);

      await tester.tap(find.text('针织开衫'));
      await tester.pump();
      expect(tapped, ['102']);
    });

    testWidgets('HmCategoryRecommend 加载中展示进度条', (tester) async {
      await tester.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: HmCategoryRecommend(
              items: const [],
              isLoading: true,
              onGoodsTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('暂无推荐商品'), findsNothing);
    });

    testWidgets('HmCategoryRecommend 无数据时展示占位文案', (tester) async {
      await tester.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: HmCategoryRecommend(items: const [], onGoodsTap: (_) {}),
          ),
        ),
      );

      expect(find.text('暂无推荐商品'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
