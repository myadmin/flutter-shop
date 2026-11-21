/// 金额工具
///
/// 金额在接口里是字符串（如 `"69.90"`），直接转 `double` 相乘再相加会引入
/// 浮点误差（`0.1 + 0.2 != 0.3`，多条累加后可能差一分）。这里统一以「分」为
/// 单位的整数做运算，只在展示时格式化回两位小数字符串。
library;

/// 把金额字符串解析成「分」
///
/// 无法解析或为空时按 0 处理，保证合计金额不会因脏数据变成 NaN。
int parseCents(String amount) {
  final value = double.tryParse(amount.trim());
  if (value == null) {
    return 0;
  }
  return (value * 100).round();
}

/// 把「分」格式化成两位小数的金额字符串
String formatCents(int cents) => (cents / 100).toStringAsFixed(2);
