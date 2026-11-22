import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/footprint.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地足迹读写
///
/// 后端没有足迹接口（`/member/footprint` 返回 404），浏览记录只能存在本机：
/// - 只保留最近 [maxItems] 条，超出丢弃最旧的；
/// - 同一商品再次浏览只更新时间并提到最前，不产生重复项。
class FootprintStore {
  const FootprintStore._();

  /// 本地最多保留的足迹条数
  static const int maxItems = 50;

  /// 读取足迹，按浏览时间倒序
  ///
  /// 存储内容损坏（被手工改过、旧版本格式）时返回空列表而不是抛异常，
  /// 避免一个坏字段把整页拖成错误态。
  static Future<List<FootprintItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(GlobalConstants.footprintKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      final items = decoded
          .whereType<Map<Object?, Object?>>()
          .map((item) => FootprintItem.fromJson(item.cast<String, dynamic>()))
          .where((item) => item.goodsId.isNotEmpty)
          .toList();
      items.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
      return items;
    } on FormatException catch (error) {
      debugPrint('足迹数据解析失败，已按空列表处理: $error');
      return [];
    }
  }

  /// 记录一次浏览，返回写入后的完整足迹列表
  ///
  /// [item] 按 `goodsId` 去重：已存在时用新条目覆盖旧条目并提到最前。
  static Future<List<FootprintItem>> record(FootprintItem item) async {
    if (item.goodsId.isEmpty) {
      return load();
    }
    final items = await load();
    final next = [
      item,
      ...items.where((existing) => existing.goodsId != item.goodsId),
    ];
    final trimmed = next.take(maxItems).toList();
    await _save(trimmed);
    return trimmed;
  }

  /// 清空本地足迹
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(GlobalConstants.footprintKey);
  }

  static Future<void> _save(List<FootprintItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(GlobalConstants.footprintKey, raw);
  }
}
