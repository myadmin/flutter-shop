/// 业务异常：接口返回了 code != 成功码，或响应结构与约定不符。
///
/// 与网络层异常（[NetworkException]）区分开，调用方可以据此决定
/// 是提示"网络不好"还是"服务端拒绝了这次操作"。
class ApiException implements Exception {
  ApiException(this.message, {this.code});

  /// 面向用户的中文提示
  final String message;

  /// 业务错误码，接口未返回时为 null
  final String? code;

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}

/// 网络异常：超时、断网、DNS 失败等，即请求没有拿到有效响应。
class NetworkException implements Exception {
  NetworkException(this.message);

  /// 面向用户的中文提示
  final String message;

  @override
  String toString() => 'NetworkException(message: $message)';
}

/// 从任意异常中提取面向用户的提示文案。
///
/// 未识别的异常一律回退到通用文案，避免把英文堆栈直接暴露给用户。
String resolveErrorMessage(Object error, {String? fallback}) {
  if (error is ApiException) return error.message;
  if (error is NetworkException) return error.message;
  // 接口返回结构与模型约定不符（字段类型突变等）
  if (error is FormatException) return '数据格式异常，请稍后重试';
  return fallback ?? '网络或服务异常，请稍后重试';
}
