/// Web 端 URL 策略的跨平台门面
///
/// `usePathUrlStrategy` 来自 `flutter_web_plugins`，只能在 Web 上编译；
/// 通过条件导出让移动端/桌面端拿到空实现，避免 `main.dart` 里出现平台判断。
library;

export 'web_url_strategy_stub.dart'
    if (dart.library.js_interop) 'web_url_strategy_web.dart';
