import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/GoodsDetail/hm_sku_selector.dart';
import 'package:hm_shop/models/goods.dart';

/// 构造一个两维规格（颜色 × 尺码）的商品：
/// - 米白 / M：缺货
/// - 米白 / L：5 件
/// - 黑色 / L：2 件
GoodsDetail _buildDetail() {
  return GoodsDetail(
    id: 'goods-1',
    name: '测试商品',
    desc: '',
    price: '69.90',
    oldPrice: '99.90',
    mainPictures: const [''],
    salesCount: 0,
    commentCount: 0,
    properties: const [],
    detailPictures: const [],
    skus: [
      GoodsSku(
        id: 'sku-white-m',
        price: '69.90',
        inventory: 0,
        picture: '',
        specs: [
          GoodsSkuSpec(name: '颜色', valueName: '米白'),
          GoodsSkuSpec(name: '尺码', valueName: 'M'),
        ],
      ),
      GoodsSku(
        id: 'sku-white-l',
        price: '69.90',
        inventory: 5,
        picture: '',
        specs: [
          GoodsSkuSpec(name: '颜色', valueName: '米白'),
          GoodsSkuSpec(name: '尺码', valueName: 'L'),
        ],
      ),
      GoodsSku(
        id: 'sku-black-l',
        price: '79.90',
        inventory: 2,
        picture: '',
        specs: [
          GoodsSkuSpec(name: '颜色', valueName: '黑色'),
          GoodsSkuSpec(name: '尺码', valueName: 'L'),
        ],
      ),
    ],
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('商品详情规格选择弹层', () {
    testWidgets('默认选中第一个有库存的规格', (tester) async {
      await tester.pumpWidget(_wrap(HmSkuSelector(detail: _buildDetail())));

      expect(find.text('￥69.90'), findsOneWidget);
      expect(find.text('库存 5 件'), findsOneWidget);
      expect(find.text('已选 米白 / L'), findsOneWidget);
    });

    testWidgets('缺货的规格值不可点击', (tester) async {
      await tester.pumpWidget(_wrap(HmSkuSelector(detail: _buildDetail())));

      // 「米白 / M」组合没有库存，点击后选择不应变化
      await tester.tap(find.text('M'));
      await tester.pump();

      expect(find.text('已选 米白 / L'), findsOneWidget);
    });

    testWidgets('切换规格后价格与库存同步更新', (tester) async {
      await tester.pumpWidget(_wrap(HmSkuSelector(detail: _buildDetail())));

      await tester.tap(find.text('黑色'));
      await tester.pump();

      expect(find.text('￥79.90'), findsOneWidget);
      expect(find.text('库存 2 件'), findsOneWidget);
      expect(find.text('已选 黑色 / L'), findsOneWidget);
    });

    testWidgets('数量超过新规格库存时自动收敛', (tester) async {
      await tester.pumpWidget(_wrap(HmSkuSelector(detail: _buildDetail())));

      // 米白 / L 有 5 件，先加到 5
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }
      expect(find.text('5'), findsOneWidget);

      // 切到库存只有 2 件的黑色 / L，数量应被收进 2
      await tester.tap(find.text('黑色'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('确认后返回选中的规格与数量', (tester) async {
      SkuSelection? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return TextButton(
                  onPressed: () async {
                    result = await showSkuSelector(
                      context,
                      detail: _buildDetail(),
                      confirmText: '加入购物车',
                    );
                  },
                  child: const Text('打开规格'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开规格'));
      await tester.pumpAndSettle();
      expect(find.text('已选 米白 / L'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.text('加入购物车'));
      await tester.pumpAndSettle();

      expect(result?.sku.id, 'sku-white-l');
      expect(result?.count, 2);
    });
  });
}
