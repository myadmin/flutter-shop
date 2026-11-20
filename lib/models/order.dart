import 'package:hm_shop/models/parsers.dart';

// 立即购买结算信息（/member/order/pre/now 接口返回的 result 数据）
class PreOrderResult {
  List<OrderAddress> userAddresses;
  List<PreOrderGoods> goods;
  OrderSummary summary;

  PreOrderResult({
    required this.userAddresses,
    required this.goods,
    required this.summary,
  });

  factory PreOrderResult.fromJson(Map<String, dynamic> json) {
    return PreOrderResult(
      userAddresses: asList(json['userAddresses'], OrderAddress.fromJson),
      goods: asList(json['goods'], PreOrderGoods.fromJson),
      summary: OrderSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  // 默认收货地址：优先取默认地址，否则取第一个
  OrderAddress? get defaultAddress {
    for (final address in userAddresses) {
      if (address.isDefault == 1) {
        return address;
      }
    }
    return userAddresses.isEmpty ? null : userAddresses.first;
  }
}

// 收货地址
class OrderAddress {
  String id;
  String receiver;
  String contact;
  String fullLocation;
  String address;
  int isDefault;

  OrderAddress({
    required this.id,
    required this.receiver,
    required this.contact,
    required this.fullLocation,
    required this.address,
    required this.isDefault,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      id: asString(json['id']),
      receiver: asString(json['receiver']),
      contact: asString(json['contact']),
      fullLocation: asString(json['fullLocation']),
      address: asString(json['address']),
      isDefault: asInt(json['isDefault']),
    );
  }

  // 完整地址，如「北京市 北京市 东城区23」
  String get fullAddress => '$fullLocation$address';
}

// 订单商品
class PreOrderGoods {
  String id;
  String name;
  String picture;
  int count;
  String attrsText;
  String price;
  String totalPayPrice;

  PreOrderGoods({
    required this.id,
    required this.name,
    required this.picture,
    required this.count,
    required this.attrsText,
    required this.price,
    required this.totalPayPrice,
  });

  factory PreOrderGoods.fromJson(Map<String, dynamic> json) {
    return PreOrderGoods(
      id: asString(json['id']),
      name: asString(json['name']),
      picture: asString(json['picture']),
      count: asInt(json['count'], fallback: 1),
      attrsText: asString(json['attrsText']),
      price: asAmount(json['price']),
      totalPayPrice: asAmount(json['totalPayPrice']),
    );
  }
}

// 订单金额汇总
class OrderSummary {
  int goodsCount;
  String totalPrice;
  String totalPayPrice;
  String postFee;
  String discountPrice;

  OrderSummary({
    required this.goodsCount,
    required this.totalPrice,
    required this.totalPayPrice,
    required this.postFee,
    required this.discountPrice,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      goodsCount: asInt(json['goodsCount']),
      totalPrice: asAmount(json['totalPrice']),
      totalPayPrice: asAmount(json['totalPayPrice']),
      postFee: asAmount(json['postFee']),
      discountPrice: asAmount(json['discountPrice']),
    );
  }
}
