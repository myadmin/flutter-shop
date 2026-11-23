import 'package:hm_shop/models/parsers.dart';

/// 品牌好店列表项（对应接口 `/home/brand`）
class BrandItem {
  String id;
  String name;
  String nameEn;
  String logo;

  /// 品牌简介，列表里不展示，详情页才用
  String desc;

  /// 品牌所在地
  String place;

  BrandItem({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.logo,
    required this.desc,
    required this.place,
  });

  factory BrandItem.fromJson(Map<String, dynamic> json) {
    return BrandItem(
      id: asString(json['id']),
      name: asString(json['name']),
      nameEn: asString(json['nameEn']),
      // 接口同时给了 logo 与 picture，二者通常一致，取不到 logo 时退回 picture
      logo: asString(json['logo']).isNotEmpty
          ? asString(json['logo'])
          : asString(json['picture']),
      desc: asString(json['desc']),
      place: asString(json['place']),
    );
  }

  /// 卡片上展示的名字：中文名优先，没有中文名时用英文名
  String get displayName => name.isNotEmpty ? name : nameEn;
}

/// 品牌详情（对应接口 `/brand/<品牌 id>`）
class BrandDetail {
  String id;
  String name;
  String nameEn;
  String logo;
  String brandImage;

  /// 品牌口号，接口里目前是占位文案，可能为空
  String slogan;

  /// 产地
  String productionPlace;

  /// 品牌故事
  String brandStory;

  int collectNum;
  bool isCollect;

  BrandDetail({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.logo,
    required this.brandImage,
    required this.slogan,
    required this.productionPlace,
    required this.brandStory,
    required this.collectNum,
    required this.isCollect,
  });

  factory BrandDetail.fromJson(Map<String, dynamic> json) {
    return BrandDetail(
      id: asString(json['id']),
      name: asString(json['name']),
      nameEn: asString(json['nameEn']),
      logo: asString(json['logo']),
      brandImage: asString(json['brandImage']),
      slogan: asString(json['slogan']),
      productionPlace: asString(json['productionPlace']),
      brandStory: asString(json['brandStory']),
      collectNum: asInt(json['collectNum']),
      isCollect: asBool(json['isCollect']),
    );
  }

  /// 展示用的名字：中文名优先
  String get displayName => name.isNotEmpty ? name : nameEn;

  /// 头图：没有品牌大图时退回 logo
  String get coverImage => brandImage.isNotEmpty ? brandImage : logo;
}
