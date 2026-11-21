import 'package:hm_shop/models/parsers.dart';

/// 订单状态码与文案的唯一来源
///
/// 接口用 `orderState` 区分订单状态，取值含义（实测）：
/// 1 待付款、2 待发货、3 待收货、4 待评价、5 已完成、6 已取消；
/// 查询列表时传 0 或不传表示「全部」。
class OrderState {
  const OrderState._();

  static const int all = 0;
  static const int unpaid = 1;
  static const int unshipped = 2;
  static const int unreceived = 3;
  static const int unevaluated = 4;
  static const int finished = 5;
  static const int cancelled = 6;

  /// 订单列表页顶部的 tab 顺序
  static const List<int> tabs = [
    all,
    unpaid,
    unshipped,
    unreceived,
    unevaluated,
  ];

  static const Map<int, String> _labels = {
    all: '全部',
    unpaid: '待付款',
    unshipped: '待发货',
    unreceived: '待收货',
    unevaluated: '待评价',
    finished: '已完成',
    cancelled: '已取消',
  };

  static String labelOf(int state) => _labels[state] ?? '未知状态';

  /// 该状态下的主操作按钮文案；空串表示不展示主操作
  static String primaryActionOf(int state) {
    switch (state) {
      case unpaid:
        return '去支付';
      case unshipped:
        return '提醒发货';
      case unreceived:
        return '确认收货';
      case unevaluated:
        return '去评价';
      case finished:
      case cancelled:
        return '再次购买';
      default:
        return '';
    }
  }

  /// 状态说明，展示在详情页顶部
  static String hintOf(int state) {
    switch (state) {
      case unpaid:
        return '请尽快完成支付，超时订单将自动关闭';
      case unshipped:
        return '商家正在备货，请耐心等待';
      case unreceived:
        return '商品已发出，注意查收';
      case unevaluated:
        return '交易已完成，期待你的评价';
      case finished:
        return '交易已完成，感谢你的支持';
      case cancelled:
        return '订单已取消';
      default:
        return '';
    }
  }
}

/// 订单里的一个商品行（接口的 `skus` 数组项）
class OrderSku {
  const OrderSku({
    required this.id,
    required this.name,
    required this.image,
    required this.attrsText,
    required this.price,
    required this.quantity,
  });

  /// 规格 id，用于「再次购买」加购
  final String id;
  final String name;
  final String image;

  /// 规格描述，例如「规格:日本梅乃宿柚子酒8度720mL」
  final String attrsText;

  /// 成交单价
  final String price;
  final int quantity;

  factory OrderSku.fromJson(Map<String, dynamic> json) {
    return OrderSku(
      id: asString(json['id']),
      name: asString(json['name']),
      image: asString(json['image']),
      attrsText: asString(json['attrsText']),
      // 订单列表只保证 curPrice，订单详情可能只有 realPay
      price: asAmount(json['curPrice'] ?? json['realPay']),
      quantity: asInt(json['quantity'], fallback: 1),
    );
  }
}

/// 订单列表里的一条订单
class OrderItem {
  const OrderItem({
    required this.id,
    required this.createTime,
    required this.orderState,
    required this.payLatestTime,
    required this.postFee,
    required this.payMoney,
    required this.totalMoney,
    required this.totalNum,
    required this.skus,
  });

  final String id;
  final String createTime;
  final int orderState;

  /// 最晚支付时间，待付款状态用于展示倒计时
  final String payLatestTime;

  /// 运费
  final String postFee;

  /// 实付金额（含运费）
  final String payMoney;

  /// 商品总额（不含运费）
  final String totalMoney;

  /// 接口给的商品总件数，可能缺失
  final int totalNum;

  final List<OrderSku> skus;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: asString(json['id']),
      createTime: asString(json['createTime']),
      orderState: asInt(json['orderState']),
      payLatestTime: asString(json['payLatestTime']),
      postFee: asAmount(json['postFee']),
      payMoney: asAmount(json['payMoney']),
      totalMoney: asAmount(json['totalMoney']),
      totalNum: asInt(json['totalNum']),
      skus: asList(json['skus'], OrderSku.fromJson),
    );
  }

  /// 商品总件数：接口字段缺失时按明细累加
  int get goodsCount =>
      totalNum > 0 ? totalNum : skus.fold(0, (sum, sku) => sum + sku.quantity);

  /// 订单号后 8 位，卡片上只展示这段避免长串数字换行
  String get shortId => id.length <= 8 ? id : id.substring(id.length - 8);
}

/// 订单列表分页结果（`/member/order` 返回的 result）
class OrderListResult {
  const OrderListResult({
    required this.counts,
    required this.pages,
    required this.page,
    required this.items,
  });

  /// 当前筛选条件下的订单总数
  final int counts;
  final int pages;
  final int page;
  final List<OrderItem> items;

  factory OrderListResult.fromJson(Map<String, dynamic> json) {
    return OrderListResult(
      counts: asInt(json['counts']),
      pages: asInt(json['pages']),
      page: asInt(json['page'], fallback: 1),
      items: asList(json['items'], OrderItem.fromJson),
    );
  }

  bool get hasMore => page < pages;
}

/// 订单详情（`/member/order/{id}` 返回的 result）
///
/// 比列表项多出收货信息、各节点时间与支付方式，其余字段复用 [OrderItem]。
class OrderDetail extends OrderItem {
  const OrderDetail({
    required super.id,
    required super.createTime,
    required super.orderState,
    required super.payLatestTime,
    required super.postFee,
    required super.payMoney,
    required super.totalMoney,
    required super.totalNum,
    required super.skus,
    required this.receiverContact,
    required this.receiverMobile,
    required this.receiverAddress,
    required this.payChannel,
    required this.payState,
    required this.countdown,
    required this.payTime,
    required this.consignTime,
    required this.endTime,
    required this.closeTime,
  });

  final String receiverContact;
  final String receiverMobile;
  final String receiverAddress;

  /// 支付方式：1 在线支付、2 货到付款
  final int payChannel;

  /// 支付状态，接口内部使用，界面上按 [orderState] 展示即可
  final int payState;

  /// 待付款剩余秒数，-1 表示没有倒计时
  final int countdown;

  final String payTime;
  final String consignTime;
  final String endTime;
  final String closeTime;

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: asString(json['id']),
      createTime: asString(json['createTime']),
      orderState: asInt(json['orderState']),
      payLatestTime: asString(json['payLatestTime']),
      postFee: asAmount(json['postFee']),
      payMoney: asAmount(json['payMoney']),
      totalMoney: asAmount(json['totalMoney']),
      totalNum: asInt(json['totalNum']),
      skus: asList(json['skus'], OrderSku.fromJson),
      receiverContact: asString(json['receiverContact']),
      receiverMobile: asString(json['receiverMobile']),
      receiverAddress: asString(json['receiverAddress']),
      payChannel: asInt(json['payChannel']),
      payState: asInt(json['payState']),
      countdown: asInt(json['countdown'], fallback: -1),
      payTime: asString(json['payTime']),
      consignTime: asString(json['consignTime']),
      endTime: asString(json['endTime']),
      closeTime: asString(json['closeTime']),
    );
  }

  /// 支付方式文案
  String get payChannelLabel => payChannel == 2 ? '货到付款' : '在线支付';
}
