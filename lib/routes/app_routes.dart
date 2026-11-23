/// 路由名与深链地址的唯一来源
///
/// 带参数的页面把参数编进查询串（`/goods?id=42`），而不是塞进
/// `arguments`：这样地址栏里的 URL 可以直接分享 / 刷新，路由层也能从
/// 查询串还原出参数。
///
/// 单独成文件（不 import 任何页面）是为了让页面反向 import 它时不产生
/// 「页面 ↔ 路由表」的循环依赖。
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
  static const String goodsPath = '/goods';
  static const String goodsListPath = '/goods/list';
  static const String orderConfirmPath = '/order/confirm';
  static const String orderListPath = '/orders';
  static const String orderDetailPath = '/orders/detail';
  static const String collectPath = '/collect';
  static const String customerServicePath = '/customer-service';
  static const String footprintPath = '/footprint';
  static const String vipPath = '/vip';
  static const String profilePath = '/profile';
  static const String brandPath = '/brand';

  /// 商品详情：`/goods?id=<商品 id>`
  static String goods(String goodsId) =>
      '$goodsPath?id=${Uri.encodeQueryComponent(goodsId)}';

  /// 分类商品列表：`/goods/list?categoryId=<分类 id>&title=<分类名>`
  static String goodsList(String categoryId, String title) =>
      '$goodsListPath?categoryId=${Uri.encodeQueryComponent(categoryId)}'
      '&title=${Uri.encodeQueryComponent(title)}';

  /// 订单确认：`/order/confirm?skuId=<规格 id>&count=<数量>`
  static String orderConfirm(String skuId, int count) =>
      '$orderConfirmPath?skuId=${Uri.encodeQueryComponent(skuId)}&count=$count';

  /// 我的订单：`/orders?state=<orderState>`，state 为 0 时不带查询串
  static String orderList([int state = 0]) =>
      state == 0 ? orderListPath : '$orderListPath?state=$state';

  /// 订单详情：`/orders/detail?id=<订单 id>`
  static String orderDetail(String orderId) =>
      '$orderDetailPath?id=${Uri.encodeQueryComponent(orderId)}';

  /// 品牌详情：`/brand?id=<品牌 id>`
  static String brand(String brandId) =>
      '$brandPath?id=${Uri.encodeQueryComponent(brandId)}';
}
