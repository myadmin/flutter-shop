import 'package:hm_shop/models/parsers.dart';

class BannerItem {
  String id;
  String imageUrl;

  BannerItem({required this.id, required this.imageUrl});

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: asString(json['id']),
      imageUrl: asString(json['imgUrl']),
    );
  }
}

class CategoryItem {
  String id;
  String name;
  String picture;
  List<CategoryItem>? children;
  List<CategoryItem>? goods;

  CategoryItem({
    required this.id,
    required this.name,
    required this.picture,
    this.children,
    this.goods,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: asString(json['id']),
      name: asString(json['name']),
      picture: asString(json['picture']),
      children: json['children'] == null
          ? null
          : asList(json['children'], CategoryItem.fromJson),
      goods: json['goods'] == null
          ? null
          : asList(json['goods'], CategoryItem.fromJson),
    );
  }
}

// 特惠推荐
class SpecialRecommendResult {
  String id;
  String title;
  List<SubType> subTypes;

  SpecialRecommendResult({
    required this.id,
    required this.title,
    required this.subTypes,
  });

  factory SpecialRecommendResult.fromJson(Map<String, dynamic> json) {
    return SpecialRecommendResult(
      id: asString(json['id']),
      title: asString(json['title']),
      subTypes: asList(json['subTypes'], SubType.fromJson),
    );
  }
}

// 特惠推荐子类型
class SubType {
  String id;
  String title;
  GoodsItems goodsItems;

  SubType({required this.id, required this.title, required this.goodsItems});

  factory SubType.fromJson(Map<String, dynamic> json) {
    return SubType(
      id: asString(json['id']),
      title: asString(json['title']),
      goodsItems: GoodsItems.fromJson(asMapOrEmpty(json['goodsItems'])),
    );
  }
}

// 特惠推荐商品分页数据
class GoodsItems {
  int counts;
  int pageSize;
  int pages;
  int page;
  List<GoodsItem> items;

  GoodsItems({
    required this.counts,
    required this.pageSize,
    required this.pages,
    required this.page,
    required this.items,
  });

  factory GoodsItems.fromJson(Map<String, dynamic> json) {
    return GoodsItems(
      counts: asInt(json['counts']),
      pageSize: asInt(json['pageSize']),
      pages: asInt(json['pages']),
      page: asInt(json['page']),
      items: asList(json['items'], GoodsItem.fromJson),
    );
  }
}

// 特惠推荐商品
class GoodsItem {
  String id;
  String name;
  String? desc;
  String price;
  String picture;
  int orderNum;

  GoodsItem({
    required this.id,
    required this.name,
    this.desc,
    required this.price,
    required this.picture,
    required this.orderNum,
  });

  factory GoodsItem.fromJson(Map<String, dynamic> json) {
    return GoodsItem(
      id: asString(json['id']),
      name: asString(json['name']),
      desc: json['desc'] == null ? null : asString(json['desc']),
      price: asAmount(json['price']),
      picture: asString(json['picture']),
      orderNum: asInt(json['orderNum']),
    );
  }
}

class GoodDetailItem extends GoodsItem {
  int payCount;

  GoodDetailItem({
    required super.id,
    required super.name,
    required super.price,
    required super.picture,
    required super.orderNum,
    required this.payCount,
  }) : super(desc: "");

  factory GoodDetailItem.fromJson(Map<String, dynamic> json) {
    return GoodDetailItem(
      id: asString(json['id']),
      name: asString(json['name']),
      // 接口返回的 price 可能是数字（如 69.9），统一转成金额字符串
      price: asAmount(json['price']),
      picture: asString(json['picture']),
      orderNum: asInt(json['orderNum']),
      payCount: asInt(json['payCount']),
    );
  }
}

class GoodsDetailsItems {
  int counts;
  int pageSize;
  int pages;
  int page;
  List<GoodDetailItem> items;

  GoodsDetailsItems({
    required this.counts,
    required this.pageSize,
    required this.pages,
    required this.page,
    required this.items,
  });

  factory GoodsDetailsItems.fromJson(Map<String, dynamic> json) {
    return GoodsDetailsItems(
      counts: asInt(json['counts']),
      pageSize: asInt(json['pageSize']),
      pages: asInt(json['pages']),
      page: asInt(json['page']),
      items: asList(json['items'], GoodDetailItem.fromJson),
    );
  }
}
