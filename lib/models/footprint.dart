import 'package:hm_shop/models/goods.dart';
import 'package:hm_shop/models/parsers.dart';

/// 浏览足迹条目
///
/// 后端没有足迹接口（`/member/footprint` 返回 404），因此足迹只存在本机，
/// 字段也由客户端自己定义，序列化格式见 [toJson]。
class FootprintItem {
  const FootprintItem({
    required this.goodsId,
    required this.name,
    required this.picture,
    required this.price,
    required this.viewedAt,
  });

  /// 商品 id，点击卡片时用于跳转详情页
  final String goodsId;

  /// 商品名称
  final String name;

  /// 商品主图（取详情页主图的第一张）
  final String picture;

  /// 商品价格，两位小数金额字符串
  final String price;

  /// 最近一次浏览时间
  final DateTime viewedAt;

  /// 由商品详情生成足迹，避免调用方自己拼字段
  factory FootprintItem.fromGoodsDetail(
    GoodsDetail detail, {
    DateTime? viewedAt,
  }) {
    return FootprintItem(
      goodsId: detail.id,
      name: detail.name,
      picture: detail.mainPictures.firstWhere(
        (picture) => picture.isNotEmpty,
        orElse: () => '',
      ),
      price: detail.price,
      viewedAt: viewedAt ?? DateTime.now(),
    );
  }

  factory FootprintItem.fromJson(Map<String, dynamic> json) {
    return FootprintItem(
      goodsId: asString(json['goodsId']),
      name: asString(json['name']),
      picture: asString(json['picture']),
      price: asAmount(json['price']),
      // 时间解析失败时退回纪元起点，列表里会被归入「更早」，不会抛异常
      viewedAt:
          DateTime.tryParse(asString(json['viewedAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goodsId': goodsId,
      'name': name,
      'picture': picture,
      'price': price,
      'viewedAt': viewedAt.toIso8601String(),
    };
  }

  /// 浏览时间 `HH:mm`，列表里作为副标题展示
  String get viewedTimeText {
    final hour = viewedAt.hour.toString().padLeft(2, '0');
    final minute = viewedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// 足迹分组，用于「今天 / 昨天 / 更早」三段式列表
class FootprintGroup {
  const FootprintGroup({required this.title, required this.items});

  final String title;
  final List<FootprintItem> items;
}

/// 按浏览日期把足迹切成「今天 / 昨天 / 更早」三组
///
/// 入参应已按浏览时间倒序排列；空分组会被丢弃，避免出现只有标题的空段。
List<FootprintGroup> groupFootprints(
  List<FootprintItem> items, {
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));

  final todayItems = <FootprintItem>[];
  final yesterdayItems = <FootprintItem>[];
  final earlierItems = <FootprintItem>[];

  for (final item in items) {
    final date = _dateOnly(item.viewedAt);
    if (!date.isBefore(today)) {
      todayItems.add(item);
    } else if (date == yesterday) {
      yesterdayItems.add(item);
    } else {
      earlierItems.add(item);
    }
  }

  return [
    if (todayItems.isNotEmpty) FootprintGroup(title: '今天', items: todayItems),
    if (yesterdayItems.isNotEmpty)
      FootprintGroup(title: '昨天', items: yesterdayItems),
    if (earlierItems.isNotEmpty)
      FootprintGroup(title: '更早', items: earlierItems),
  ];
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
