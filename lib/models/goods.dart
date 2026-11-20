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
    final details = json['details'] as Map<String, dynamic>? ?? {};
    return GoodsDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      // 接口返回的 price / oldPrice 可能是数字（如 69.9），统一转成字符串展示
      price: json['price']?.toString() ?? '',
      oldPrice: json['oldPrice']?.toString() ?? '',
      mainPictures: json['mainPictures'] == null
          ? []
          : (json['mainPictures'] as List).map((e) => e.toString()).toList(),
      salesCount: int.tryParse(json['salesCount']?.toString() ?? '') ?? 0,
      commentCount: int.tryParse(json['commentCount']?.toString() ?? '') ?? 0,
      brand: json['brand'] == null
          ? null
          : GoodsBrand.fromJson(json['brand'] as Map<String, dynamic>),
      properties: details['properties'] == null
          ? []
          : (details['properties'] as List)
                .map((e) => GoodsProperty.fromJson(e as Map<String, dynamic>))
                .toList(),
      detailPictures: details['pictures'] == null
          ? []
          : (details['pictures'] as List).map((e) => e.toString()).toList(),
      skus: json['skus'] == null
          ? []
          : (json['skus'] as List)
                .map((e) => GoodsSku.fromJson(e as Map<String, dynamic>))
                .toList(),
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
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
      name: json['name']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
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
      id: json['id']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      inventory: int.tryParse(json['inventory']?.toString() ?? '') ?? 0,
      picture: json['picture']?.toString() ?? '',
      specs: json['specs'] == null
          ? []
          : (json['specs'] as List)
                .map((e) => GoodsSkuSpec.fromJson(e as Map<String, dynamic>))
                .toList(),
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
      name: json['name']?.toString() ?? '',
      valueName: json['valueName']?.toString() ?? '',
    );
  }
}
