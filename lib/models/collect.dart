import 'package:hm_shop/models/parsers.dart';

/// 收藏列表项
///
/// 接口 `GET /member/collect` 必须带 `collectType`（只支持 1 / 2，传 0 或 9
/// 会在 SQL 层直接报错），但演示账号的收藏为空，真实字段名无法验证。因此
/// 这里对同一含义的字段做多组兜底取值：任一组缺失只影响展示（名称、图片、
/// 价格为空时卡片不渲染对应元素），不会抛异常。
class CollectItem {
  const CollectItem({
    required this.id,
    required this.goodsId,
    required this.name,
    required this.picture,
    required this.price,
    required this.collectType,
    required this.createTime,
  });

  /// 收藏记录 id
  final String id;

  /// 商品 id，用于跳转商品详情；缺失时卡片不可点
  final String goodsId;

  /// 商品名称
  final String name;

  /// 商品图片
  final String picture;

  /// 商品价格（两位小数）
  final String price;

  /// 收藏类型，对应请求参数 `collectType`
  final int collectType;

  /// 收藏时间
  final String createTime;

  /// 有商品 id 才能跳到商品详情
  bool get canOpenGoods => goodsId.isNotEmpty;

  factory CollectItem.fromJson(Map<String, dynamic> json) {
    return CollectItem(
      id: asString(json['id']),
      goodsId: asString(json['goodsId'] ?? json['spuId'] ?? json['goods_id']),
      name: asString(json['name'] ?? json['goodsName'] ?? json['title']),
      picture: asString(
        json['picture'] ?? json['image'] ?? json['goodsPicture'],
      ),
      price: asAmount(json['price'] ?? json['goodsPrice']),
      collectType: asInt(json['collectType'] ?? json['collect_type']),
      createTime: asString(json['createTime'] ?? json['create_time']),
    );
  }
}

/// 收藏列表分页结果
class CollectListResult {
  const CollectListResult({
    required this.counts,
    required this.pages,
    required this.page,
    required this.items,
  });

  /// 收藏总数
  final int counts;

  /// 总页数
  final int pages;

  /// 当前页
  final int page;

  /// 当前页的收藏项
  final List<CollectItem> items;

  /// 是否还有下一页
  bool get hasMore => page < pages;

  factory CollectListResult.fromJson(Map<String, dynamic> json) {
    return CollectListResult(
      counts: asInt(json['counts']),
      pages: asInt(json['pages']),
      page: asInt(json['page'], fallback: 1),
      items: asList(json['items'], CollectItem.fromJson),
    );
  }
}
