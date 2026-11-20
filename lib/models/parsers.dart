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

/// 转成布尔值；兼容 `true` / `"true"` / `1` / `"1"`，其余返回 [fallback]。
bool asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
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
      .whereType<Map<Object?, Object?>>()
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

/// 把接口返回值收窄成对象；结构不符时抛 [FormatException]。
///
/// 与 [asList] 的「宽容」策略不同：接口最外层的结构约定一旦被破坏，
/// 说明前后端契约出了问题，应当让调用方看到错误而不是展示空数据。
Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw FormatException('期望接口返回对象，实际为 ${value.runtimeType}');
}

/// 把接口返回的数组收窄成模型列表；结构不符时抛 [FormatException]。
List<T> asModelList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) {
    throw FormatException('期望接口返回数组，实际为 ${value.runtimeType}');
  }
  return value
      .whereType<Map<Object?, Object?>>()
      .map((item) => fromJson(item.cast<String, dynamic>()))
      .toList();
}

/// 把可选嵌套对象安全转成 Map；null 与非对象返回空 Map。
///
/// 用于「字段可缺省、缺失时按空对象处理」的场景，避免写
/// `json['x'] as Map<String, dynamic>? ?? const {}`（遇到非 Map 会抛 TypeError）。
Map<String, dynamic> asMapOrEmpty(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

/// 把可选嵌套对象安全转成 Map；null 与非对象返回 null。
Map<String, dynamic>? asMapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}
