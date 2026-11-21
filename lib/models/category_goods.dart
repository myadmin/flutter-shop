import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/models/parsers.dart';

/// 分类下的商品聚合数据（`/category/sub/filter` 返回的 result）
///
/// 接口一次返回该分类下的全部商品（不分页），并附带同级分类，
/// 供商品列表页顶部做快速切换。
class CategoryGoodsResult {
  const CategoryGoodsResult({
    required this.id,
    required this.name,
    required this.parentName,
    required this.goods,
    required this.siblings,
  });

  /// 当前分类 id
  final String id;

  /// 当前分类名，例如「渔夫帽」
  final String name;

  /// 所属一级分类名，例如「时尚饰品」
  final String parentName;

  /// 该分类下的商品
  final List<GoodsItem> goods;

  /// 同级分类（含当前分类），用于顶部切换
  final List<CategorySibling> siblings;

  factory CategoryGoodsResult.fromJson(Map<String, dynamic> json) {
    return CategoryGoodsResult(
      id: asString(json['id']),
      name: asString(json['name']),
      parentName: asString(json['parentName']),
      goods: asList(json['goods'], GoodsItem.fromJson),
      siblings: asList(json['categories'], CategorySibling.fromJson),
    );
  }
}

/// 同级分类（只有 id 与名称，接口的 `categories` 字段）
class CategorySibling {
  const CategorySibling({required this.id, required this.name});

  final String id;
  final String name;

  factory CategorySibling.fromJson(Map<String, dynamic> json) {
    return CategorySibling(
      id: asString(json['id']),
      name: asString(json['name']),
    );
  }
}
