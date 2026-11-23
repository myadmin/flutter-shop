# 更新日志

版本号写在 `pubspec.yaml` 的 `version` 字段（`1.0.2+3` 里 `1.0.2` 是 `versionName`，`3` 是 `versionCode`）。

打 `v*` 标签时，[Build Mobile](.github/workflows/mobile.yml) 会把这里对应版本的「本次更新」自动写进 GitHub Release 说明，所以新增版本时记得在本文件补一段。

## [1.0.2] - 2026-11-23

启动性能与应用标识：

- 底部 tab 改为「首次打开才构建」：`IndexedStack` 之前会把四个页面一次性建出来，登录态下冷启动就发 14 个请求（首页 6 + 分类 2 + 购物车 1 + 我的 5）。现在首屏只发首页的 6 个，分类 / 购物车 / 我的等首次切过去才加载，打开过的页面继续保活。
- 首页轮播在切到其它 tab 时暂停自动播放。此前 `IndexedStack` 保活导致定时器在后台一直翻页，Web 上持续占 CPU。
- 应用名统一为「美荟商城」：Android 的 `android:label` 从 `hm_shop` 改过来，iOS 的 `CFBundleDisplayName` 从 `Hm Shop` 改过来，与 Web 的标题 / PWA 名称一致。
- 应用图标替换为品牌图标（品牌橙渐变 + 白色购物袋）：Android 5 档 mipmap、iOS 13 个尺寸、Web favicon 与两个 PWA 图标全部重新生成，不再使用 Flutter 模板图标。图标母版见 `docs/icon/app_icon_1024.png`，重新生成用 `tool/generate_icons.py`。
- 版本号提升到 `1.0.2+3`；`pubspec.yaml` 的描述补全到当前页面清单（之前还停在 5 个页面）。
- 新增 5 个底部 tab 容器用例：启动只加载首页、切 tab 才加载对应页、来回切不重复请求、轮播随 tab 暂停与恢复。
- 购物车条目可以点击进入商品详情页了：点图片或文字跳 `/goods?id=<商品 id>`，从详情页返回后自动刷新购物车；失效商品不跳转，只提示「商品已失效」。补了 2 个用例覆盖这两条路径。

## [1.0.1] - 2026-11-23

打包与发布链路完善，界面功能与 1.0.0 一致：

- 版本号提升到 `1.0.1+2`，APK 的 `versionName` / `versionCode` 随之更新（`1.0.1` / `2`）。
- 修复 Android 打包：`android/gradle/wrapper/gradle-wrapper.properties` 指回 Gradle 9.3.1。Flutter 3.47.9 模板里的 AGP 是 9.1.0，要求 Gradle ≥ 9.3.1，用 8.14 会在 apply 阶段直接失败（`Minimum supported Gradle version is 9.3.1`）。
- 新增 `Build Mobile` 工作流：Android 产出按 ABI 拆分的三个 APK 与一个 AAB，iOS 产出未签名的 `Runner.app.zip`；同一分支只跑最新一次。
- 新增签名脚手架：Android 读 `android/key.properties`，有正式 keystore 就签正式包、没有就退回 debug 签名；iOS 在配置好证书 Secrets 后产出可安装的 `.ipa`，缺 Secrets 时自动降级不报错。
- 新增 `publish-release` job：打 `v*` 标签（或手动触发）时把安装包汇总发布到 GitHub Releases，直接点就能下载，并自动生成「选哪个 apk」的说明。
- 文档补齐：README 增加「移动端打包（Android / iOS）」小节，含产物表、签名 Secrets 清单、发版方式与本文件。

## [1.0.0] - 2026-11-23

首个可安装版本：

- 首页：轮播图、一级分类快捷入口（点击切到分类页并选中同一分类）、热门推荐、特惠推荐、推荐商品分页加载。
- 分类：左侧一级分类与右侧二级分类、推荐商品联动，支持从外部指定选中项。
- 商品详情：图片轮播、规格（SKU）选择、加入购物车、猜你喜欢。
- 购物车：登录态联动、数量增减、删除、结算进入订单确认。
- 订单确认：收货地址、商品清单、金额明细、提交下单。
- 订单：列表（全部 / 待付款 / 待发货 / 待收货 / 待评价）、订单详情、删除订单、再次购买。
- 我的：登录与退出、个人资料（昵称 / 性别 / 生日 / 职业，只提交改动字段）、会员权益页、我的收藏、我的足迹（本地存储，最多 50 条）、客服中心、订单状态角标。
- 全局：统一主题色板与圆角 / 间距常量、Dio 拦截器统一注入 token 与错误提示、支持深链（`/goods/list`、`/orders`、`/profile` 等可直接打开）、12 个页面级 widget 测试共 187 个用例。
