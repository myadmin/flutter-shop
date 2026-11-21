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
}
