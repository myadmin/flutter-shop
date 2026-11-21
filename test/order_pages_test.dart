import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/components/Order/hm_order_card.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/models/order_list.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/OrderDetail/index.dart';
import 'package:hm_shop/pages/OrderList/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/user_controller.dart';

import 'helpers/mock_http.dart';

/// 订单列表页与订单详情页的主要状态流：
/// 成功渲染、按状态筛选、空态、未登录、失败重试、删除订单与状态主操作。
void main() {
  late UserController userController;

  setUp(() {
    Get.reset();
    userController = Get.put(UserController(), permanent: true);
    Get.put(CartController(), permanent: true);
  });

  tearDown(Get.reset);

  /// 模拟已登录（列表页靠 `UserController.isLoggedIn` 判断）
  void login() {
    userController.updateUserInfo(
      UserInfo.fromJson({'id': 'u-1', 'nickname': '晚星12'}),
    );
  }

  /// 挂载页面并等待首屏请求落地
  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }

  group('订单列表页', () {
    testWidgets('加载成功展示订单卡片与合计金额', (tester) async {
      login();
      final adapter = installMock((options) => envelope(orderListJson()));

      await pumpPage(tester, const OrderListPage());

      expect(find.text('我的订单'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.byType(HmOrderCard), findsOneWidget);
      // 订单号只展示后 8 位
      expect(find.text('订单号 00000042'), findsOneWidget);
      expect(find.text('￥190.00'), findsOneWidget);
      expect(find.text('共 2 件'), findsOneWidget);
      expect(find.text('测试商品'), findsOneWidget);
      expect(find.text('￥89.00'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      expect(find.byType(AppErrorView), findsNothing);

      // 「全部」不传 orderState，只带分页参数
      final query = adapter.requests.single.uri.queryParameters;
      expect(query['page'], '1');
      expect(query['pageSize'], '10');
      expect(query.containsKey('orderState'), isFalse);
    });

    testWidgets('切换到待付款 tab 会带上 orderState 重新请求', (tester) async {
      login();
      final adapter = installMock((options) => envelope(orderListJson()));

      await pumpPage(tester, const OrderListPage());
      expect(adapter.requests, hasLength(1));

      await tester.tap(find.text('待付款'));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.uri.queryParameters['orderState'], '1');
    });

    testWidgets('没有订单时展示空态', (tester) async {
      login();
      installMock(
        (options) => envelope(orderListJson(counts: 0, pages: 0, items: [])),
      );

      await pumpPage(tester, const OrderListPage());

      expect(find.text('还没有订单'), findsOneWidget);
      expect(find.byType(HmOrderCard), findsNothing);
    });

    testWidgets('未登录时提示登录且不请求接口', (tester) async {
      final adapter = installMock((options) => envelope(orderListJson()));

      await pumpPage(tester, const OrderListPage());

      expect(find.text('登录后查看订单'), findsOneWidget);
      expect(find.text('去登录'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('加载失败展示错误视图，点重试后恢复', (tester) async {
      login();
      var shouldFail = true;
      final adapter = installMock(
        (options) =>
            shouldFail ? envelopeError('订单服务异常') : envelope(orderListJson()),
      );

      await pumpPage(tester, const OrderListPage());

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('订单服务异常'), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.text('重新加载'));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.byType(AppErrorView), findsNothing);
      expect(find.byType(HmOrderCard), findsOneWidget);
      expect(adapter.requests, hasLength(2));
    });

    testWidgets('确认删除后发出 DELETE 请求并从列表移除', (tester) async {
      login();
      final adapter = installMock((options) {
        if (options.method.toUpperCase() == 'DELETE') {
          return envelope(null);
        }
        return envelope(
          orderListJson(
            counts: 2,
            items: [
              orderItemJson(id: 'order-00000042'),
              orderItemJson(id: 'order-00000043'),
            ],
          ),
        );
      });

      await pumpPage(tester, const OrderListPage());
      expect(find.byType(HmOrderCard), findsNWidgets(2));

      await tester.tap(find.text('删除订单').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.text('确定要删除这笔订单吗？'), findsOneWidget);

      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      final deletes = adapter.requestsWhere('DELETE');
      expect(deletes, hasLength(1));
      expect(deletes.single.data, {
        'ids': ['order-00000042'],
      });
      expect(find.byType(HmOrderCard), findsOneWidget);
    });
  });

  group('订单详情页', () {
    testWidgets('加载成功展示状态、收货信息与金额明细', (tester) async {
      final adapter = installMock(
        (options) => envelope(orderDetailJson(orderState: 2)),
      );

      await pumpPage(tester, const OrderDetailPage(orderId: 'order-00000042'));

      expect(find.text('待发货'), findsOneWidget);
      expect(find.text('商家正在备货，请耐心等待'), findsOneWidget);
      expect(find.text('张三'), findsOneWidget);
      expect(find.text('13800138000'), findsOneWidget);
      expect(find.text('北京市 东城区23号'), findsOneWidget);
      expect(find.text('商品总额'), findsOneWidget);
      expect(find.text('￥178.00'), findsOneWidget);
      expect(find.text('实付金额'), findsOneWidget);
      expect(find.text('￥190.00'), findsOneWidget);
      expect(find.text('在线支付'), findsOneWidget);
      expect(find.text('提醒发货'), findsOneWidget);
      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.uri.path,
        contains('/member/order/order-00000042'),
      );
    });

    testWidgets('缺少订单 id 时提示且不发请求', (tester) async {
      final adapter = installMock((options) => envelope(orderDetailJson()));

      await pumpPage(tester, const OrderDetailPage(orderId: ''));

      expect(find.text('订单信息缺失，请返回重新进入'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('「再次购买」会按订单商品调用加购接口', (tester) async {
      final adapter = installMock((options) {
        if (options.uri.path.contains('/member/cart')) {
          return envelope(cartItemJson());
        }
        return envelope(orderDetailJson(orderState: OrderState.finished));
      });

      await pumpPage(tester, const OrderDetailPage(orderId: 'order-00000042'));

      await tester.tap(find.text('再次购买'));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      final posts = adapter.requestsWhere('POST');
      expect(posts, hasLength(1));
      expect(posts.single.uri.path, contains('/member/cart'));
      expect(posts.single.data, containsPair('skuId', 'sku-1'));
      expect(find.text('已加入购物车'), findsOneWidget);
    });

    testWidgets('「去支付」明确提示接口未提供，不发请求', (tester) async {
      final adapter = installMock(
        (options) => envelope(orderDetailJson(orderState: OrderState.unpaid)),
      );

      await pumpPage(tester, const OrderDetailPage(orderId: 'order-00000042'));

      await tester.tap(find.text('去支付'));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.text('演示接口未提供「去支付」，暂时无法完成'), findsOneWidget);
      expect(adapter.requestsWhere('POST'), isEmpty);
    });
  });
}
