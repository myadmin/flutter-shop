import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/Collect/hm_collect_tile.dart';
import 'package:hm_shop/components/Footprint/hm_footprint_tile.dart';
import 'package:hm_shop/components/common/hm_goods_summary_tile.dart';
import 'package:hm_shop/models/collect.dart';
import 'package:hm_shop/models/footprint.dart';

/// 收藏 / 足迹两个列表条目共用的商品摘要组件
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  CollectItem collectItem({
    String name = '收藏商品',
    String price = '69.90',
    String createTime = '2026-11-25',
    String goodsId = 'goods-1',
  }) {
    return CollectItem(
      id: 'collect-1',
      goodsId: goodsId,
      name: name,
      picture: '',
      price: price,
      collectType: 1,
      createTime: createTime,
    );
  }

  FootprintItem footprintItem({
    String name = '足迹商品',
    String price = '99.00',
    String goodsId = 'goods-1',
  }) {
    return FootprintItem(
      goodsId: goodsId,
      name: name,
      picture: '',
      price: price,
      viewedAt: DateTime(2026, 11, 25, 10),
    );
  }

  group('HmGoodsSummaryTile', () {
    testWidgets('展示名称、价格与附注', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const HmGoodsSummaryTile(
            name: '秋季新款风衣',
            price: '298.00',
            picture: '',
            metaText: '收藏于 2026-11-25',
          ),
        ),
      );

      expect(find.text('秋季新款风衣'), findsOneWidget);
      expect(find.text('￥298.00'), findsOneWidget);
      expect(find.text('收藏于 2026-11-25'), findsOneWidget);
    });

    testWidgets('名称为空时展示失效提示', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const HmGoodsSummaryTile(
            name: '',
            price: '0.00',
            picture: '',
            metaText: '',
            showPrice: false,
          ),
        ),
      );

      expect(find.text('商品信息已失效'), findsOneWidget);
      expect(find.text('￥0.00'), findsNothing);
    });

    testWidgets('showPrice 为 false 时不展示价格', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const HmGoodsSummaryTile(
            name: '秋季新款风衣',
            price: '298.00',
            picture: '',
            metaText: '',
            showPrice: false,
          ),
        ),
      );

      expect(find.text('秋季新款风衣'), findsOneWidget);
      expect(find.text('￥298.00'), findsNothing);
    });

    testWidgets('附注为空时不占位', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const HmGoodsSummaryTile(
            name: '秋季新款风衣',
            price: '298.00',
            picture: '',
            metaText: '',
          ),
        ),
      );

      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('点击条目触发回调', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        wrap(
          HmGoodsSummaryTile(
            name: '秋季新款风衣',
            price: '298.00',
            picture: '',
            metaText: '',
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(HmGoodsSummaryTile));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('收藏 / 足迹条目的字段映射', () {
    testWidgets('收藏条目拼出「收藏于」附注', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(HmCollectTile(item: collectItem(createTime: '2026-11-20'))),
      );

      expect(find.text('收藏商品'), findsOneWidget);
      expect(find.text('￥69.90'), findsOneWidget);
      expect(find.text('收藏于 2026-11-20'), findsOneWidget);
    });

    testWidgets('收藏条目信息全空时不展示 0.00 价格', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          HmCollectTile(
            item: collectItem(name: '', price: '0.00', createTime: ''),
          ),
        ),
      );

      expect(find.text('商品信息已失效'), findsOneWidget);
      expect(find.text('￥0.00'), findsNothing);
    });

    testWidgets('足迹条目拼出「浏览」附注并恒显价格', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(HmFootprintTile(item: footprintItem())));

      expect(find.text('足迹商品'), findsOneWidget);
      expect(find.text('￥99.00'), findsOneWidget);
      expect(find.textContaining('浏览'), findsOneWidget);
    });
  });
}
