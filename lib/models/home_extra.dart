import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/models/parsers.dart';

/// 首页「专题精选」条目（`/home/special`）
///
/// 接口只下发列表、没有专题详情接口，所以这里的字段够卡片展示即可：
/// 标题、一句话简介、最低价、封面与三项人气数据。
class SpecialTopicItem {
  String id;
  String title;
  String summary;

  /// 最低价，已统一成两位小数的金额字符串
  String lowestPrice;
  String cover;

  /// 收藏 / 浏览 / 回复数，卡片上展示人气
  int collectNum;
  int viewNum;
  int replyNum;

  SpecialTopicItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.lowestPrice,
    required this.cover,
    required this.collectNum,
    required this.viewNum,
    required this.replyNum,
  });

  factory SpecialTopicItem.fromJson(Map<String, dynamic> json) {
    return SpecialTopicItem(
      id: asString(json['id']),
      title: asString(json['title']),
      summary: asString(json['summary']),
      lowestPrice: asAmount(json['lowestPrice']),
      cover: asString(json['cover']),
      collectNum: asInt(json['collectNum']),
      viewNum: asInt(json['viewNum']),
      replyNum: asInt(json['replyNum']),
    );
  }

  /// 卡片上展示的人气文案，三项都为 0 时返回空串（不占位）
  String get popularityText {
    if (collectNum > 0) {
      return '$collectNum 人收藏';
    }
    if (viewNum > 0) {
      return '$viewNum 人浏览';
    }
    return '';
  }
}

/// 首页分类楼层（`/home/goods`）
///
/// 一个楼层对应一个一级分类：标题、促销语、若干二级分类入口，
/// 以及横向展示的商品。
class HomeFloor {
  String id;
  String name;
  String picture;

  /// 促销语，接口里带 `\r\n` 换行，这里已压成单行
  String saleInfo;

  /// 二级分类入口
  List<CategoryItem> children;

  /// 楼层商品
  List<GoodsItem> goods;

  HomeFloor({
    required this.id,
    required this.name,
    required this.picture,
    required this.saleInfo,
    required this.children,
    required this.goods,
  });

  factory HomeFloor.fromJson(Map<String, dynamic> json) {
    return HomeFloor(
      id: asString(json['id']),
      name: asString(json['name']),
      picture: asString(json['picture']),
      saleInfo: _collapseWhitespace(asString(json['saleInfo'])),
      children: asList(json['children'], CategoryItem.fromJson),
      goods: asList(json['goods'], GoodsItem.fromJson),
    );
  }

  /// 把 `大额优惠\r\n等你来拿` 这类带换行的促销语压成一行
  static String _collapseWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
