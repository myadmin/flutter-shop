// https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/1.jpg
// https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/2.png
// https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/3.jpg
// BannerItem(
//   id: '1',
//   imageUrl:
//       'https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/1.jpg',
// ),
// BannerItem(
//   id: '2',
//   imageUrl:
//       'https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/2.png',
// ),
// BannerItem(
//   id: '3',
//   imageUrl:
//       'https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/3.jpg',
// ),
// https://meikou-api.itheima.net
// https://meikou-api.itheima.net/home/banner

class BannerItem {
  String id;
  String imageUrl;

  BannerItem({required this.id, required this.imageUrl});

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(id: json['id'], imageUrl: json['imgUrl']);
  }
}

// 根据json编写class对象和工厂转化函数
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

  // 工厂转化函数
  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    // 必须返回CategoryItem对象，否则会报错
    return CategoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      picture: json['picture'] ?? '',
      children: json['children'] == null
          ? null
          : (json['children'] as List)
                .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
                .toList(),
      goods: json['goods'] == null
          ? null
          : (json['goods'] as List)
                .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
                .toList(),
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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subTypes: json['subTypes'] == null
          ? []
          : (json['subTypes'] as List)
                .map((e) => SubType.fromJson(e as Map<String, dynamic>))
                .toList(),
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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      goodsItems: GoodsItems.fromJson(
        json['goodsItems'] as Map<String, dynamic>? ?? {},
      ),
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
      counts: json['counts'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
      pages: json['pages'] ?? 0,
      page: json['page'] ?? 0,
      items: json['items'] == null
          ? []
          : (json['items'] as List)
                .map((e) => GoodsItem.fromJson(e as Map<String, dynamic>))
                .toList(),
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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      desc: json['desc'],
      price: json['price'] ?? '',
      picture: json['picture'] ?? '',
      orderNum: json['orderNum'] ?? 0,
    );
  }
}

/// 安全转换为字符串，空值统一返回空字符串
String _toSafeString(dynamic value) => value?.toString() ?? '';

/// 安全转换为可空字符串，空值返回 null
String? _toNullableString(dynamic value) => value?.toString();

/// 安全转换为整数，非数字统一返回 0
int _toSafeInt(dynamic value) => value is num ? value.toInt() : 0;

// 爆款推荐
/// 爆款推荐数据模型
/// 接口地址：GET /hot/inVogue
class HotInVogueResult {
  /// 模块 ID
  final String id;

  /// 模块标题，例如“爆款推荐”
  final String title;

  /// 子类型列表，例如“24小时热榜”“热销总榜”
  final List<HotInVogueSubType> subTypes;

  const HotInVogueResult({
    required this.id,
    required this.title,
    required this.subTypes,
  });

  factory HotInVogueResult.fromJson(Map<String, dynamic> json) {
    return HotInVogueResult(
      id: _toSafeString(json['id']),
      title: _toSafeString(json['title']),
      subTypes: (json['subTypes'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(HotInVogueSubType.fromJson)
              .toList() ??
          const <HotInVogueSubType>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subTypes': subTypes.map((item) => item.toJson()).toList(),
    };
  }
}

/// 爆款推荐子类型数据模型
class HotInVogueSubType {
  /// 子类型 ID
  final String id;

  /// 子类型标题
  final String title;

  /// 子类型下的商品分页数据
  final HotInVogueGoodsItems goodsItems;

  const HotInVogueSubType({
    required this.id,
    required this.title,
    required this.goodsItems,
  });

  factory HotInVogueSubType.fromJson(Map<String, dynamic> json) {
    return HotInVogueSubType(
      id: _toSafeString(json['id']),
      title: _toSafeString(json['title']),
      goodsItems: HotInVogueGoodsItems.fromJson(
        json['goodsItems'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'goodsItems': goodsItems.toJson(),
    };
  }
}

/// 爆款推荐商品分页数据模型
class HotInVogueGoodsItems {
  /// 商品总数量
  final int counts;

  /// 每页数量
  final int pageSize;

  /// 总页数
  final int pages;

  /// 当前页码
  final int page;

  /// 当前页商品列表
  final List<HotInVogueGoodsItem> items;

  const HotInVogueGoodsItems({
    required this.counts,
    required this.pageSize,
    required this.pages,
    required this.page,
    required this.items,
  });

  factory HotInVogueGoodsItems.fromJson(Map<String, dynamic> json) {
    return HotInVogueGoodsItems(
      counts: _toSafeInt(json['counts']),
      pageSize: _toSafeInt(json['pageSize']),
      pages: _toSafeInt(json['pages']),
      page: _toSafeInt(json['page']),
      items: (json['items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(HotInVogueGoodsItem.fromJson)
              .toList() ??
          const <HotInVogueGoodsItem>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'counts': counts,
      'pageSize': pageSize,
      'pages': pages,
      'page': page,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

/// 爆款推荐商品数据模型
class HotInVogueGoodsItem {
  /// 商品 ID
  final String id;

  /// 商品名称
  final String name;

  /// 商品描述，接口可能返回 null
  final String? desc;

  /// 商品价格，接口以字符串返回，例如 “199.00”
  final String price;

  /// 商品图片地址
  final String picture;

  /// 商品排序值
  final int orderNum;

  const HotInVogueGoodsItem({
    required this.id,
    required this.name,
    this.desc,
    required this.price,
    required this.picture,
    required this.orderNum,
  });

  factory HotInVogueGoodsItem.fromJson(Map<String, dynamic> json) {
    return HotInVogueGoodsItem(
      id: _toSafeString(json['id']),
      name: _toSafeString(json['name']),
      desc: _toNullableString(json['desc']),
      price: _toSafeString(json['price']),
      picture: _toSafeString(json['picture']),
      orderNum: _toSafeInt(json['orderNum']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
      'price': price,
      'picture': picture,
      'orderNum': orderNum,
    };
  }
}

// 一站全买
/// 一站全买数据模型
/// 接口地址：GET /hot/oneStop
class OneStopResult {
  /// 模块 ID
  final String id;

  /// 模块标题，例如“一站全买”
  final String title;

  /// 子类型列表，例如“搞定熊孩子”“家里不凌乱”
  final List<OneStopSubType> subTypes;

  const OneStopResult({
    required this.id,
    required this.title,
    required this.subTypes,
  });

  factory OneStopResult.fromJson(Map<String, dynamic> json) {
    return OneStopResult(
      id: _toSafeString(json['id']),
      title: _toSafeString(json['title']),
      subTypes: (json['subTypes'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(OneStopSubType.fromJson)
              .toList() ??
          const <OneStopSubType>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subTypes': subTypes.map((item) => item.toJson()).toList(),
    };
  }
}

/// 一站全买子类型数据模型
class OneStopSubType {
  /// 子类型 ID
  final String id;

  /// 子类型标题
  final String title;

  /// 子类型下的商品分页数据
  final OneStopGoodsItems goodsItems;

  const OneStopSubType({
    required this.id,
    required this.title,
    required this.goodsItems,
  });

  factory OneStopSubType.fromJson(Map<String, dynamic> json) {
    return OneStopSubType(
      id: _toSafeString(json['id']),
      title: _toSafeString(json['title']),
      goodsItems: OneStopGoodsItems.fromJson(
        json['goodsItems'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'goodsItems': goodsItems.toJson(),
    };
  }
}

/// 一站全买商品分页数据模型
class OneStopGoodsItems {
  /// 商品总数量
  final int counts;

  /// 每页数量
  final int pageSize;

  /// 总页数
  final int pages;

  /// 当前页码
  final int page;

  /// 当前页商品列表
  final List<OneStopGoodsItem> items;

  const OneStopGoodsItems({
    required this.counts,
    required this.pageSize,
    required this.pages,
    required this.page,
    required this.items,
  });

  factory OneStopGoodsItems.fromJson(Map<String, dynamic> json) {
    return OneStopGoodsItems(
      counts: _toSafeInt(json['counts']),
      pageSize: _toSafeInt(json['pageSize']),
      pages: _toSafeInt(json['pages']),
      page: _toSafeInt(json['page']),
      items: (json['items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(OneStopGoodsItem.fromJson)
              .toList() ??
          const <OneStopGoodsItem>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'counts': counts,
      'pageSize': pageSize,
      'pages': pages,
      'page': page,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

/// 一站全买商品数据模型
class OneStopGoodsItem {
  /// 商品 ID
  final String id;

  /// 商品名称
  final String name;

  /// 商品描述，接口可能返回 null
  final String? desc;

  /// 商品价格，接口以字符串返回，例如 “199.00”
  final String price;

  /// 商品图片地址
  final String picture;

  /// 商品排序值
  final int orderNum;

  const OneStopGoodsItem({
    required this.id,
    required this.name,
    this.desc,
    required this.price,
    required this.picture,
    required this.orderNum,
  });

  factory OneStopGoodsItem.fromJson(Map<String, dynamic> json) {
    return OneStopGoodsItem(
      id: _toSafeString(json['id']),
      name: _toSafeString(json['name']),
      desc: _toNullableString(json['desc']),
      price: _toSafeString(json['price']),
      picture: _toSafeString(json['picture']),
      orderNum: _toSafeInt(json['orderNum']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
      'price': price,
      'picture': picture,
      'orderNum': orderNum,
    };
  }
}