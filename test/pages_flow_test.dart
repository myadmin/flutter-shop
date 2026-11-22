import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/components/GoodsDetail/hm_action_bar.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/pages/GoodsDetail/index.dart';
import 'package:hm_shop/pages/OrderConfirm/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_http.dart';

/// 商品详情页与订单确认页的主要状态流：
/// 成功渲染、失败后可重试、缺少入参时不发请求。
void main() {
  setUp(() {
    Get.reset();
    Get.put(CartController(), permanent: true);
    // 商品详情加载成功会写一条本地足迹，这里给 shared_preferences 一个内存实现
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(Get.reset);

  /// 挂载页面并等待首屏请求落地
  ///
  /// 默认测试视口是 800×600，商品主图高度等于屏宽，会把下方内容挤出视口、
  /// 懒加载的 sliver 因此不会构建，所以这里统一改用手机尺寸。
  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }

  group('商品详情页', () {
    testWidgets('加载成功展示商品信息与底部操作条', (tester) async {
      final adapter = installMock(
        (options) => envelope(
          goodsDetailJson(
            skus: [skuJson()],
            brand: {'id': 'brand-1', 'name': '测试品牌', 'logo': ''},
            properties: [
              {'name': '材质', 'value': '纯棉'},
            ],
            detailPictures: [''],
          ),
        ),
      );

      await pumpPage(tester, const GoodsDetailPage(goodsId: 'goods-1'));

      expect(find.text('测试商品'), findsOneWidget);
      expect(find.text('测试品牌'), findsOneWidget);
      expect(find.text('材质'), findsOneWidget);
      expect(find.text('纯棉'), findsOneWidget);
      expect(find.byType(HmActionBar), findsOneWidget);
      expect(find.byType(AppErrorView), findsNothing);
      expect(adapter.requests, hasLength(1));
    });

    testWidgets('加载失败展示错误视图，点重试后恢复内容', (tester) async {
      var shouldFail = true;
      final adapter = installMock(
        (options) =>
            shouldFail ? envelopeError('商品不存在') : envelope(goodsDetailJson()),
      );

      await pumpPage(tester, const GoodsDetailPage(goodsId: 'goods-1'));

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('商品不存在'), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.text('重新加载'));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.byType(AppErrorView), findsNothing);
      expect(find.text('测试商品'), findsOneWidget);
      expect(adapter.requests, hasLength(2));
    });

    testWidgets('缺少商品 id 时直接提示且不发请求', (tester) async {
      final adapter = installMock((options) => envelope(goodsDetailJson()));

      await pumpPage(tester, const GoodsDetailPage(goodsId: ''));

      expect(find.text('商品信息缺失'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });
  });

  group('订单确认页', () {
    testWidgets('加载成功展示地址、商品与应付金额', (tester) async {
      final adapter = installMock((options) => envelope(preOrderJson()));

      await pumpPage(tester, const OrderConfirmPage(skuId: 'sku-1', count: 2));

      expect(find.text('张三'), findsOneWidget);
      expect(find.text('北京市 东城区23号'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      expect(find.text('提交订单'), findsOneWidget);
      expect(find.text('￥190.00'), findsWidgets);
      expect(find.byType(HmBottomBar), findsOneWidget);
      expect(adapter.requests, hasLength(1));
    });

    testWidgets('加载失败展示服务端提示', (tester) async {
      installMock((options) => envelopeError('收货地址不存在'));

      await pumpPage(tester, const OrderConfirmPage(skuId: 'sku-1', count: 1));

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('收货地址不存在'), findsOneWidget);
    });

    testWidgets('缺少 skuId 时直接提示且不发请求', (tester) async {
      final adapter = installMock((options) => envelope(preOrderJson()));

      await pumpPage(tester, const OrderConfirmPage(skuId: '', count: 1));

      expect(find.text('商品信息缺失'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });
  });
}
