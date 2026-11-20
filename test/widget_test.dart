import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/GoodsDetail/hm_action_bar.dart';
import 'package:hm_shop/components/GoodsDetail/hm_goods_gallery.dart';
import 'package:hm_shop/components/GoodsDetail/hm_goods_price_info.dart';
import 'package:hm_shop/components/Home/hm_hot.dart';
import 'package:hm_shop/components/OrderConfirm/hm_order_address.dart';
import 'package:hm_shop/components/OrderConfirm/hm_order_card.dart';
import 'package:hm_shop/components/OrderConfirm/hm_order_goods.dart';
import 'package:hm_shop/components/OrderConfirm/hm_order_summary.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/goods.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/models/order.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/Home/skeleton.dart';

void main() {
  group('hm_shop Widget & Model Tests', () {
    testWidgets('HomeSkeleton 能够正常渲染并包含呼吸动画', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeSkeleton())),
      );

      expect(find.byType(HomeSkeleton), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HomeSkeleton),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('HmHot 能够根据配置正确渲染爆款推荐与一站全买标题', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HmHot(
                  config: HmHotConfig.inVogue,
                  result: SpecialRecommendResult(
                    id: '1',
                    title: '爆款推荐',
                    subTypes: [],
                  ),
                ),
                HmHot(
                  config: HmHotConfig.oneStop,
                  result: SpecialRecommendResult(
                    id: '2',
                    title: '一站全买',
                    subTypes: [],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('爆款推荐'), findsOneWidget);
      expect(find.text('最受欢迎'), findsOneWidget);
      expect(find.text('一站全买'), findsOneWidget);
      expect(find.text('精心优选'), findsOneWidget);
    });

    test('UserInfo 能够正确从 json 解析并判断登录态', () {
      final guest = UserInfo.fromJson({});
      expect(guest.isLoggedIn, isFalse);

      final user = UserInfo.fromJson({
        'id': '1001',
        'account': 'test_user',
        'nickname': '测试账号',
        'token': 'mock_token',
      });
      expect(user.isLoggedIn, isTrue);
      expect(user.account, 'test_user');
      expect(user.nickname, '测试账号');
    });

    test('GoodsDetail 解析 SKU 并优先选择有库存的规格', () {
      final detail = GoodsDetail.fromJson({
        'id': '4026450',
        'name': '测试商品',
        'price': 89,
        'skus': [
          {
            'id': 'sku-1',
            'price': '89.00',
            'inventory': 0,
            'picture': '',
            'specs': [
              {'name': '颜色', 'valueName': '米白'},
            ],
          },
          {
            'id': 'sku-2',
            'price': '89.00',
            'inventory': 10,
            'picture': '',
            'specs': [
              {'name': '颜色', 'valueName': '暗绿色'},
              {'name': '尺码', 'valueName': '90/3T'},
            ],
          },
        ],
      });

      expect(detail.defaultSku?.id, 'sku-2');
      expect(detail.defaultSku?.specText, '颜色:暗绿色 尺码:90/3T');
    });

    test('PreOrderResult 优先返回默认收货地址', () {
      final result = PreOrderResult.fromJson({
        'userAddresses': [
          {'id': '1', 'receiver': '张三', 'isDefault': 0},
          {'id': '2', 'receiver': '李四', 'isDefault': 1},
        ],
        'goods': <dynamic>[],
        'summary': {'goodsCount': 0, 'totalPayPrice': 90.0},
      });

      expect(result.defaultAddress?.id, '2');
      expect(result.defaultAddress?.receiver, '李四');
      expect(result.summary.totalPayPrice, '90.00');
    });

    testWidgets('HmActionBar 展示单价并触发按钮回调', (WidgetTester tester) async {
      int addCartCount = 0;
      int buyNowCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: HmActionBar(
              price: '89.00',
              onAddCart: () => addCartCount++,
              onBuyNow: () => buyNowCount++,
            ),
          ),
        ),
      );

      expect(find.text('单价'), findsOneWidget);
      expect(find.text('￥89.00'), findsOneWidget);
      expect(find.text('加入购物车'), findsOneWidget);
      expect(find.text('立即购买'), findsOneWidget);

      await tester.tap(find.text('加入购物车'));
      await tester.tap(find.text('立即购买'));

      expect(addCartCount, 1);
      expect(buyNowCount, 1);
    });

    testWidgets('HmActionBar 固定在视口底部且不遮挡滚动内容', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) {
                return SizedBox(height: 60, child: Text('商品$index'));
              },
            ),
            bottomNavigationBar: const HmActionBar(price: '89.00'),
          ),
        ),
      );

      final Rect barRect = tester.getRect(find.byType(HmActionBar));
      // 操作栏按内容高度收缩，且贴合视口底部
      expect(barRect.height, lessThan(120));
      expect(barRect.bottom, tester.getSize(find.byType(Scaffold)).height);
      // 页面主体仍有可滚动空间
      expect(tester.getRect(find.byType(ListView)).height, greaterThan(0));

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(HmActionBar), findsOneWidget);
      expect(tester.getRect(find.byType(HmActionBar)), barRect);
      // 页面内容在操作栏上方结束，说明操作栏未遮挡内容
      expect(
        tester.getRect(find.byType(ListView)).bottom,
        lessThanOrEqualTo(barRect.top),
      );
    });

    testWidgets('HmActionBar 在移动端与 PC 端尺寸下均正常显示', (WidgetTester tester) async {
      addTearDown(tester.view.reset);
      final sizes = <Size>[
        const Size(375, 812), // 移动端
        const Size(768, 1024), // 平板
        const Size(1280, 800), // PC
      ];

      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox.expand(),
              bottomNavigationBar: HmActionBar(price: '3103.00'),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull, reason: '尺寸 $size 下操作栏渲染异常');
        expect(find.text('￥3103.00'), findsOneWidget);
        expect(find.text('加入购物车'), findsOneWidget);
        expect(find.text('立即购买'), findsOneWidget);
      }
    });
    testWidgets('HmOrderAddress 优先展示姓名电话与完整地址', (WidgetTester tester) async {
      final address = OrderAddress(
        id: '1',
        receiver: '张三',
        contact: '13800138000',
        fullLocation: '北京市 东城区',
        address: '23号',
        isDefault: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HmOrderAddress(address: address)),
        ),
      );

      expect(find.text('张三'), findsOneWidget);
      expect(find.text('13800138000'), findsOneWidget);
      // fullAddress 由 fullLocation 与 address 拼接而成
      expect(find.text('北京市 东城区23号'), findsOneWidget);
    });

    testWidgets('HmOrderAddress 在无地址时展示占位文案', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HmOrderAddress(address: null))),
      );

      expect(find.text('暂无收货地址'), findsOneWidget);
      expect(find.byType(OrderCard), findsOneWidget);
    });

    testWidgets('HmOrderGoods 展示名称规格与购买数量', (WidgetTester tester) async {
      final goods = PreOrderGoods(
        id: '1',
        name: '测试商品',
        picture: '',
        count: 3,
        attrsText: '颜色：白色',
        price: '99.00',
        totalPayPrice: '297.00',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HmOrderGoods(goods: goods)),
        ),
      );

      expect(find.text('测试商品'), findsOneWidget);
      expect(find.text('颜色：白色'), findsOneWidget);
      expect(find.text('￥99.00'), findsOneWidget);
      expect(find.text('x3'), findsOneWidget);
    });

    testWidgets('HmOrderSummary 突出展示应付金额', (WidgetTester tester) async {
      final summary = OrderSummary(
        goodsCount: 2,
        totalPrice: '200.00',
        totalPayPrice: '190.00',
        postFee: '0.00',
        discountPrice: '10.00',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HmOrderSummary(summary: summary)),
        ),
      );

      expect(find.text('商品件数'), findsOneWidget);
      expect(find.text('2件'), findsOneWidget);
      expect(find.text('运费'), findsOneWidget);
      expect(find.text('￥190.00'), findsOneWidget);

      // 应付金额使用主色加粗，与其它汇总行区分
      final payText = tester.widget<Text>(find.text('￥190.00'));
      expect(payText.style?.fontWeight, FontWeight.w800);
      expect(payText.style?.color, AppColors.primary);
    });

    testWidgets('HmGoodsGallery 无主图时使用占位图', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HmGoodsGallery(
              pictures: const [],
              currentIndex: 0,
              onIndexChanged: (_) {},
            ),
          ),
        ),
      );

      // 无主图时不应创建轮播，避免空列表异常
      expect(find.byType(CarouselSlider), findsNothing);
      expect(find.byType(AppNetworkImage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HmGoodsPriceInfo 仅在划线价与售价不同时展示划线价', (
      WidgetTester tester,
    ) async {
      Future<void> pumpWithPrices(String price, String oldPrice) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HmGoodsPriceInfo(
                detail: GoodsDetail(
                  id: '1',
                  name: '测试商品',
                  desc: '',
                  price: price,
                  oldPrice: oldPrice,
                  mainPictures: const [],
                  salesCount: 0,
                  commentCount: 0,
                  properties: const [],
                  detailPictures: const [],
                  skus: const [],
                ),
              ),
            ),
          ),
        );
      }

      // 划线价与售价相同时不展示，避免冗余
      await pumpWithPrices('99.00', '99.00');
      expect(find.text('￥99.00'), findsOneWidget);

      await pumpWithPrices('99.00', '199.00');
      expect(find.text('￥199.00'), findsOneWidget);

      final oldPriceText = tester.widget<Text>(find.text('￥199.00'));
      expect(oldPriceText.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('HmBottomBarButton 在主色模式下使用禁用底色', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HmBottomBarButton(text: '提交订单', primary: true)),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(
        button.style?.backgroundColor?.resolve(<WidgetState>{}),
        AppColors.primary,
      );
      expect(
        button.style?.backgroundColor?.resolve(<WidgetState>{
          WidgetState.disabled,
        }),
        AppColors.primaryDisabled,
      );
    });

    testWidgets('HmBottomBarButton 使用自定义 child 覆盖文案', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HmBottomBarButton(
              text: '提交订单',
              primary: true,
              child: SizedBox(width: 18, height: 18, child: Placeholder()),
            ),
          ),
        ),
      );

      // 加载态下用指示器替代文案，避免按钮宽度跳动
      expect(find.text('提交订单'), findsNothing);
      expect(find.byType(Placeholder), findsOneWidget);
    });
  });
}
