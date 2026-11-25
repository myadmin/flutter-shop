import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/Cart/hm_cart_quantity_stepper.dart';
import 'package:hm_shop/components/Home/hm_category.dart';
import 'package:hm_shop/components/common/hm_goods_card.dart';
import 'package:hm_shop/components/common/hm_goods_summary_tile.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/routes/index.dart';

/// 无障碍：字号缩放夹取 + 读屏语义
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  GoodsItem goods({String name = '秋季新款风衣'}) {
    return GoodsItem(
      id: 'goods-1',
      name: name,
      price: '298.00',
      picture: '',
      orderNum: 12,
    );
  }

  /// 读出 clampTextScale 之后子节点实际拿到的缩放比
  Future<double> scaledFactor(WidgetTester tester, double input) async {
    late double scaled;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(input)),
        child: Builder(
          builder: (BuildContext context) => clampTextScale(
            context,
            Builder(
              builder: (BuildContext inner) {
                // 10 号字放大后的实际字号 ÷ 10 就是生效的缩放比
                scaled = MediaQuery.textScalerOf(inner).scale(10) / 10;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    return scaled;
  }

  group('字号缩放夹取', () {
    testWidgets('系统字号放大到 3 倍时夹到 1.3', (WidgetTester tester) async {
      expect(await scaledFactor(tester, 3), closeTo(1.3, 0.001));
    });

    testWidgets('系统字号缩小到 0.5 倍时抬到 1.0', (WidgetTester tester) async {
      expect(await scaledFactor(tester, 0.5), closeTo(1, 0.001));
    });

    testWidgets('1.2 倍属于正常范围，原样保留', (WidgetTester tester) async {
      expect(await scaledFactor(tester, 1.2), closeTo(1.2, 0.001));
    });
  });

  group('商品卡读屏语义', () {
    testWidgets('整张卡合并成一个按钮，标签含名称与价格', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(HmGoodsCard(item: goods(), onTap: () {})));

      final SemanticsNode node = tester.getSemantics(find.byType(HmGoodsCard));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node.label, contains('秋季新款风衣'));
      expect(node.label, contains('298.00'));
      handle.dispose();
    });

    testWidgets('不可点击时不带按钮标记', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(HmGoodsCard(item: goods())));

      final SemanticsNode node = tester.getSemantics(find.byType(HmGoodsCard));
      expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('商品摘要条目同样读成按钮', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          HmGoodsSummaryTile(
            name: '收藏商品',
            price: '69.90',
            picture: '',
            metaText: '收藏于 2026-11-25',
            onTap: () {},
          ),
        ),
      );

      final SemanticsNode node = tester.getSemantics(
        find.byType(HmGoodsSummaryTile),
      );
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node.label, contains('收藏商品'));
      handle.dispose();
    });
  });

  group('首页分类入口读屏语义', () {
    testWidgets('每个分类块读成一个按钮，标签是分类名', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          HmCategory(
            categoryList: [
              CategoryItem(id: 'c1', name: '女装', picture: ''),
              CategoryItem(id: 'c2', name: '鞋靴', picture: ''),
            ],
            onCategoryTap: (_) {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('女装'), findsOneWidget);
      expect(find.bySemanticsLabel('鞋靴'), findsOneWidget);
      handle.dispose();
    });
  });

  group('购物车数量步进器', () {
    testWidgets('加减按钮带动作名提示', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(HmCartQuantityStepper(count: 2, stock: 10, onChanged: (_) {})),
      );

      expect(find.byTooltip('减少数量'), findsOneWidget);
      expect(find.byTooltip('增加数量'), findsOneWidget);
    });

    testWidgets('数量本身读成「数量 N」', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(HmCartQuantityStepper(count: 3, stock: 10, onChanged: (_) {})),
      );

      expect(find.bySemanticsLabel('数量 3'), findsOneWidget);
      handle.dispose();
    });
  });
}
