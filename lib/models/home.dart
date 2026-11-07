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
