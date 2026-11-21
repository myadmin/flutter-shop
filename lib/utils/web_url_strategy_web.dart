/// Web 平台的 URL 策略实现
library;

import 'package:flutter_web_plugins/url_strategy.dart';

/// 改用真实路径（`/goods`）替代默认的 hash 路径（`#/goods`）
///
/// 这样地址栏里的 URL 更干净，也能被直接分享。代价是静态服务器需要支持
/// 「深链回退到 index.html」：部署到 GitHub Pages 时由 `web.yml` 额外生成
/// 一份 `404.html`（内容与 `index.html` 相同）来兜底，否则直接访问
/// `/goods` 会拿到 404 页面。
void configureWebUrlStrategy() {
  usePathUrlStrategy();
}
