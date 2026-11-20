import 'package:hm_shop/models/parsers.dart';

/// 购物车条目（`/member/cart` 列表里的一项）
///
/// 注意接口里各字段的实际含义：
/// - [id] 是**商品 id**（同一商品的不同规格会是同一个 [id]），
/// - [skuId] 才是购物车条目的唯一标识，更新数量、切换选中、删除都用它，
/// - 价格字段已由接口返回成两位小数字符串（`"69.90"`），[nowPrice] 为现价。
class CartItem {
  /// 商品 id
  String id;

  /// 规格 id，购物车条目的唯一标识
  String skuId;

  String name;

  /// 规格描述，如「颜色:米白 尺码:73/18M」
  String attrsText;

  String picture;

  /// 原价
  String price;

  /// 现价
  String nowPrice;

  /// 是否被勾选结算
  bool selected;

  int stock;

  int count;

  /// 商品是否有效（下架、无库存时为 false）
  bool isEffective;

  /// 单件运费
  String postFee;

  CartItem({
    required this.id,
    required this.skuId,
    required this.name,
    required this.attrsText,
    required this.picture,
    required this.price,
    required this.nowPrice,
    required this.selected,
    required this.stock,
    required this.count,
    required this.isEffective,
    required this.postFee,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: asString(json['id']),
      skuId: asString(json['skuId']),
      name: asString(json['name']),
      attrsText: asString(json['attrsText']).trim(),
      picture: asString(json['picture']),
      price: asAmount(json['price']),
      nowPrice: asAmount(json['nowPrice']),
      selected: asBool(json['selected']),
      stock: asInt(json['stock']),
      count: asInt(json['count'], fallback: 1),
      isEffective: asBool(json['isEffective'], fallback: true),
      postFee: asAmount(json['postFee']),
    );
  }

  /// 现价的数值形式，用于计算合计
  double get nowPriceValue => double.tryParse(nowPrice) ?? 0;

  /// 该条目的商品金额（现价 × 数量）
  String get subtotalText => (nowPriceValue * count).toStringAsFixed(2);

  /// 是否还能继续加数量（受库存限制）
  bool get canIncrease => count < stock;

  /// 参与结算：既要勾选，也要是有效商品
  bool get isCheckoutSelected => selected && isEffective;

  /// 乐观更新用：复制一份并覆盖部分字段
  CartItem copyWith({int? count, bool? selected}) {
    return CartItem(
      id: id,
      skuId: skuId,
      name: name,
      attrsText: attrsText,
      picture: picture,
      price: price,
      nowPrice: nowPrice,
      selected: selected ?? this.selected,
      stock: stock,
      count: count ?? this.count,
      isEffective: isEffective,
      postFee: postFee,
    );
  }
}
