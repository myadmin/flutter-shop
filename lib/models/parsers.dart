/// 模型反序列化的公共取值工具
///
/// 后端接口同一字段的类型并不稳定（`id` 可能是字符串也可能是数字，
/// `price` 可能是 `69.9` 也可能是 `"69.90"`），直接 `?? fallback`
/// 只挡得住 null，挡不住类型不匹配，会在运行时抛 TypeError。
/// 这里统一做一次「任意值 -> 目标类型」的安全转换。
library;

/// 转成字符串；null 与空串统一返回 [fallback]。
String asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

/// 转成整数；非法值与 null 返回 [fallback]。
int asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '') ?? fallback;
}

/// 转成两位小数的金额字符串；非法值与 null 返回 `'0.00'`。
///
/// 保留两位小数是为了让接口返回的数字 `89` 展示成 `89.00`，
/// 与其它已经是字符串的金额字段保持一致。
String asAmount(dynamic value) {
  if (value is num) return value.toDouble().toStringAsFixed(2);
  final amount = double.tryParse(value?.toString().trim() ?? '');
  return amount?.toStringAsFixed(2) ?? '0.00';
}

/// 把 json 里的数组安全转成模型列表；null 与非数组统一返回空列表。
List<T> asList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => fromJson(item.cast<String, dynamic>()))
      .toList();
}

/// 把 json 里的数组安全转成字符串列表（图片地址等）；null 与非数组返回空列表。
List<String> asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .where((item) => item != null)
      .map((item) => item.toString())
      .toList();
}
