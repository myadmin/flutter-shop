import 'package:hm_shop/models/parsers.dart';

// 商品详情（/goods 接口返回的 result 数据）
class GoodsDetail {
  String id;
  String name;
  String desc;
  String price;
  String oldPrice;
  List<String> mainPictures;
  int salesCount;
  int commentCount;
  GoodsBrand? brand;
  List<GoodsProperty> properties;
  List<String> detailPictures;
  List<GoodsSku> skus;

  GoodsDetail({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.oldPrice,
    required this.mainPictures,
    required this.salesCount,
    required this.commentCount,
    this.brand,
    required this.properties,
    required this.detailPictures,
    required this.skus,
  });

  // 默认购买规格：优先取第一个有库存的规格
  GoodsSku? get defaultSku {
    for (final sku in skus) {
      if (sku.inventory > 0) {
        return sku;
      }
    }
    return skus.isEmpty ? null : skus.first;
  }

  factory GoodsDetail.fromJson(Map<String, dynamic> json) {
    final details = asMapOrEmpty(json['details']);
    final brand = asMapOrNull(json['brand']);
    return GoodsDetail(
      id: asString(json['id']),
      name: asString(json['name']),
      desc: asString(json['desc']),
      // 接口返回的 price / oldPrice 可能是数字（如 69.9），统一转成两位小数金额
      price: asAmount(json['price']),
      oldPrice: asAmount(json['oldPrice']),
      mainPictures: asStringList(json['mainPictures']),
      salesCount: asInt(json['salesCount']),
      commentCount: asInt(json['commentCount']),
      brand: brand == null ? null : GoodsBrand.fromJson(brand),
      properties: asList(details['properties'], GoodsProperty.fromJson),
      detailPictures: asStringList(details['pictures']),
      skus: asList(json['skus'], GoodsSku.fromJson),
    );
  }
}

// 品牌信息
class GoodsBrand {
  String id;
  String name;
  String logo;

  GoodsBrand({required this.id, required this.name, required this.logo});

  factory GoodsBrand.fromJson(Map<String, dynamic> json) {
    return GoodsBrand(
      id: asString(json['id']),
      name: asString(json['name']),
      logo: asString(json['logo']),
    );
  }
}

// 商品参数（如适用年龄、材质）
class GoodsProperty {
  String name;
  String value;

  GoodsProperty({required this.name, required this.value});

  factory GoodsProperty.fromJson(Map<String, dynamic> json) {
    return GoodsProperty(
      name: asString(json['name']),
      value: asString(json['value']),
    );
  }
}

// 商品规格（如颜色、尺码）
class GoodsSku {
  String id;
  String price;
  int inventory;
  String picture;
  List<GoodsSkuSpec> specs;

  GoodsSku({
    required this.id,
    required this.price,
    required this.inventory,
    required this.picture,
    required this.specs,
  });

  factory GoodsSku.fromJson(Map<String, dynamic> json) {
    return GoodsSku(
      id: asString(json['id']),
      price: asAmount(json['price']),
      inventory: asInt(json['inventory']),
      picture: asString(json['picture']),
      specs: asList(json['specs'], GoodsSkuSpec.fromJson),
    );
  }

  // 规格描述，如「颜色:米白 尺码:73/18M」
  String get specText =>
      specs.map((spec) => '${spec.name}:${spec.valueName}').join(' ');
}

// 商品规格项
class GoodsSkuSpec {
  String name;
  String valueName;

  GoodsSkuSpec({required this.name, required this.valueName});

  factory GoodsSkuSpec.fromJson(Map<String, dynamic> json) {
    return GoodsSkuSpec(
      name: asString(json['name']),
      valueName: asString(json['valueName']),
    );
  }
}
