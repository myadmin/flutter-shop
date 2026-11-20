import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/components/Cart/hm_cart_empty.dart';
import 'package:hm_shop/components/Cart/hm_cart_quantity_stepper.dart';
import 'package:hm_shop/components/Cart/hm_cart_summary_bar.dart';
import 'package:hm_shop/components/Cart/hm_cart_tile.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/cart.dart';
import 'package:hm_shop/stores/cart_controller.dart';

CartItem _item({
  String skuId = '300476623',
  String name = '趣味小恐龙绣花衬衫',
  String attrsText = '颜色:米白 尺码:73/18M',
  String nowPrice = '89.00',
  int count = 2,
  int stock = 10,
  bool selected = true,
  bool isEffective = true,
}) {
  return CartItem(
    id: '4026450',
    skuId: skuId,
    name: name,
    attrsText: attrsText,
    picture: '',
    price: '99.00',
    nowPrice: nowPrice,
    selected: selected,
    stock: stock,
    count: count,
    isEffective: isEffective,
    postFee: '1.00',
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('购物车模型', () {
    test('解析接口返回的完整字段', () {
      final item = CartItem.fromJson(const <String, dynamic>{
        'id': '4026450',
        'skuId': '300476623',
        'name': '趣味小恐龙绣花衬衫',
        'attrsText': '颜色:米白 尺码:73/18M ',
        'picture': 'https://img/a.jpg',
        'price': '99',
        'nowPrice': 89.9,
        'selected': true,
        'stock': 4936,
        'count': '3',
        'isEffective': true,
        'postFee': 1,
      });

      expect(item.id, '4026450');
      expect(item.skuId, '300476623');
      // 规格文案去掉尾部空格，便于单行展示
      expect(item.attrsText, '颜色:米白 尺码:73/18M');
      // 数字金额统一补两位小数
      expect(item.price, '99.00');
      expect(item.nowPrice, '89.90');
      expect(item.postFee, '1.00');
      // 字符串数量也能解析
      expect(item.count, 3);
      expect(item.subtotalText, '269.70');
    });

    test('字段类型不稳定时不抛异常', () {
      final item = CartItem.fromJson(const <String, dynamic>{
        'skuId': 300476623,
        'selected': 'true',
        'isEffective': 1,
        'count': null,
        'nowPrice': 'abc',
      });

      expect(item.skuId, '300476623');
      expect(item.selected, isTrue);
      expect(item.isEffective, isTrue);
      // 数量缺失时按 1 件处理
      expect(item.count, 1);
      // 非法金额回退为 0.00
      expect(item.nowPrice, '0.00');
      expect(item.nowPriceValue, 0);
    });

    test('未勾选或已失效的商品不参与结算', () {
      expect(_item().isCheckoutSelected, isTrue);
      expect(_item(selected: false).isCheckoutSelected, isFalse);
      expect(_item(isEffective: false).isCheckoutSelected, isFalse);
    });

    test('数量受库存限制', () {
      expect(_item(count: 2, stock: 3).canIncrease, isTrue);
      expect(_item(count: 3, stock: 3).canIncrease, isFalse);
    });

    test('copyWith 只覆盖传入的字段', () {
      final item = _item(count: 2, selected: true);
      final updated = item.copyWith(count: 5);

      expect(updated.count, 5);
      expect(updated.selected, isTrue);
      expect(updated.skuId, item.skuId);
      expect(item.count, 2, reason: '原对象不应被修改');
    });
  });

  group('购物车数量步进器', () {
    testWidgets('点击加减回调相邻数量', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        _wrap(
          HmCartQuantityStepper(count: 2, stock: 10, onChanged: changes.add),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.remove));
      expect(changes, [3, 1]);
    });

    testWidgets('到达边界时按钮禁用', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        _wrap(
          HmCartQuantityStepper(count: 1, stock: 1, onChanged: changes.add),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.remove));
      expect(changes, isEmpty, reason: '数量 1 / 库存 1 时加减都不可用');
    });

    testWidgets('请求在途时禁用整组', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        _wrap(
          HmCartQuantityStepper(
            count: 2,
            stock: 10,
            enabled: false,
            onChanged: changes.add,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      expect(changes, isEmpty);
    });
  });

  group('购物车条目', () {
    testWidgets('展示名称、规格与现价并响应勾选', (tester) async {
      final selected = <bool>[];
      await tester.pumpWidget(
        _wrap(
          HmCartTile(
            item: _item(),
            onSelectedChanged: selected.add,
            onCountChanged: (_) {},
            onDelete: () {},
          ),
        ),
      );

      expect(find.text('趣味小恐龙绣花衬衫'), findsOneWidget);
      expect(find.text('颜色:米白 尺码:73/18M'), findsOneWidget);
      expect(find.text('￥89.00'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      expect(selected, [false]);
    });

    testWidgets('删除按钮触发回调', (tester) async {
      var deleted = 0;
      await tester.pumpWidget(
        _wrap(
          HmCartTile(
            item: _item(),
            onSelectedChanged: (_) {},
            onCountChanged: (_) {},
            onDelete: () => deleted++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, 1);
    });

    testWidgets('失效商品展示提示并禁用交互', (tester) async {
      final selected = <bool>[];
      final counts = <int>[];
      await tester.pumpWidget(
        _wrap(
          HmCartTile(
            item: _item(isEffective: false),
            onSelectedChanged: selected.add,
            onCountChanged: counts.add,
            onDelete: () {},
          ),
        ),
      );

      expect(find.text('商品已失效'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.byIcon(Icons.add));
      expect(selected, isEmpty);
      expect(counts, isEmpty);
    });
  });

  group('购物车结算栏', () {
    testWidgets('展示合计与件数并响应全选', (tester) async {
      final allSelected = <bool>[];
      var checkout = 0;
      await tester.pumpWidget(
        _wrap(
          HmCartSummaryBar(
            allSelected: false,
            onAllSelectedChanged: allSelected.add,
            selectedCount: 2,
            totalAmount: '269.70',
            onCheckout: () => checkout++,
          ),
        ),
      );

      expect(find.text('￥269.70'), findsOneWidget);
      expect(find.text('合计（不含运费）'), findsOneWidget);
      expect(find.text('结算(2)'), findsOneWidget);

      await tester.tap(find.text('全选'));
      expect(allSelected, [true]);

      await tester.tap(find.text('结算(2)'));
      expect(checkout, 1);
    });

    testWidgets('未选择商品时结算按钮不可点击', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HmCartSummaryBar(
            allSelected: false,
            onAllSelectedChanged: (_) {},
            selectedCount: 0,
            totalAmount: '0.00',
            onCheckout: null,
          ),
        ),
      );

      expect(find.text('结算'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(
        button.style?.backgroundColor?.resolve(<WidgetState>{}),
        AppColors.primary,
      );
    });
  });

  group('购物车空态', () {
    testWidgets('展示文案并响应操作按钮', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          HmCartEmpty(
            icon: Icons.shopping_cart_outlined,
            title: '购物车还是空的',
            description: '挑几件喜欢的商品放进来吧',
            actionText: '去逛逛',
            onAction: () => tapped++,
          ),
        ),
      );

      expect(find.text('购物车还是空的'), findsOneWidget);
      expect(find.text('挑几件喜欢的商品放进来吧'), findsOneWidget);

      await tester.tap(find.text('去逛逛'));
      expect(tapped, 1);
    });
  });

  group('购物车全局状态', () {
    setUp(() => Get.reset());
    tearDown(() => Get.reset());

    test('件数可本地更新与清空', () {
      final controller = Get.put(CartController(), permanent: true);
      expect(controller.count.value, 0);

      controller.setCount(13);
      expect(controller.count.value, 13);

      controller.setCount(-1);
      expect(controller.count.value, 0, reason: '负数归零');

      controller.setCount(3);
      controller.clear();
      expect(controller.count.value, 0);
    });

    test('未登录时刷新件数不发请求', () async {
      final controller = Get.put(CartController(), permanent: true);
      controller.setCount(5);

      await controller.refreshCount();
      expect(controller.count.value, 0);
    });
  });
}
