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
      userAddresses: json['userAddresses'] == null
          ? []
          : (json['userAddresses'] as List)
                .map((e) => OrderAddress.fromJson(e as Map<String, dynamic>))
                .toList(),
      goods: json['goods'] == null
          ? []
          : (json['goods'] as List)
                .map((e) => PreOrderGoods.fromJson(e as Map<String, dynamic>))
                .toList(),
      summary: OrderSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
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
      id: json['id']?.toString() ?? '',
      receiver: json['receiver']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      fullLocation: json['fullLocation']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      isDefault: int.tryParse(json['isDefault']?.toString() ?? '') ?? 0,
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      picture: json['picture']?.toString() ?? '',
      count: int.tryParse(json['count']?.toString() ?? '') ?? 1,
      attrsText: json['attrsText']?.toString() ?? '',
      price: _formatAmount(json['price']),
      totalPayPrice: _formatAmount(json['totalPayPrice']),
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
      goodsCount: int.tryParse(json['goodsCount']?.toString() ?? '') ?? 0,
      totalPrice: _formatAmount(json['totalPrice']),
      totalPayPrice: _formatAmount(json['totalPayPrice']),
      postFee: _formatAmount(json['postFee']),
      discountPrice: _formatAmount(json['discountPrice']),
    );
  }
}

// 金额统一保留两位小数，避免数字类型的 89.0 直接展示
String _formatAmount(dynamic value) {
  final amount = double.tryParse(value?.toString() ?? '');
  return amount?.toStringAsFixed(2) ?? '0.00';
}
