# 项目约定

美荟商城（HM Shop）：Flutter 商城演示项目，支持 Web / Android / iOS。功能清单、接口表、已知问题都写在 [README.md](README.md)，这里只记必须遵守的流程约定。

## 发版约定（每次更新都要发版）

一轮功能或修复做完后，**必须发一个新版本**，不能只推 `master`：

1. `pubspec.yaml` 的 `version` 最后一位 +1，`+` 后的 `versionCode` 也 +1（例：`1.0.2+3` → `1.0.3+4`）；
2. `CHANGELOG.md` 顶部补 `## [<versionName>] - YYYY-MM-DD`，分条写清改动；
3. `git tag v<versionName> && git push origin v<versionName>`，`Build Mobile` 会自动打包并发布 GitHub Release（Release 说明从 CHANGELOG 抽取）。

只有纯文档改动可以跳过发版，提交信息加 `[skip ci]`。

## 提交前门禁

```bash
dart format lib test          # 必须 0 changed
flutter analyze --fatal-infos # 必须 No issues
flutter test --coverage       # 必须全绿，覆盖率门槛 80%
```

覆盖率基线记在 `.github/workflows/dart.yml` 的注释里，改动测试后同步更新。

## 代码约定

- 颜色、圆角、间距一律取 `lib/constants/app_theme.dart` 的 `AppColors` / `AppRadius` / `AppSpacing`，不在页面里写 `Color(0x…)`。
- JSON 解析统一走 `lib/models/parsers.dart`（`asString` / `asInt` / `asAmount` / `asMap` …），接口错误统一抛 `ApiException`，页面用 `resolveErrorMessage` 转文案。
- 页面四态（加载 / 未登录 / 错误 / 空）用 `HmEmptyView`、`AppErrorView` 等公共组件，宽屏内容用 `HmBottomBar.maxContentWidth`（600）收窄。
- 路由参数编进查询串（`AppRoutes.goods(id)` 之类），不用 `arguments`，保证深链可刷新。
- 注释与文案用中文；测试放 `test/`，HTTP 用 `test/helpers/mock_http.dart` 的 `installMock`。
