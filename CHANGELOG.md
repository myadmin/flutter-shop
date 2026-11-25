# 更新日志

版本号写在 `pubspec.yaml` 的 `version` 字段（`1.0.13+14` 里 `1.0.13` 是 `versionName`，`14` 是 `versionCode`）。

打 `v*` 标签时，[Build Mobile](.github/workflows/mobile.yml) 会把这里对应版本的「本次更新」自动写进 GitHub Release 说明，所以新增版本时记得在本文件补一段。

## [1.0.13] - 2026-11-25

首页内容再扩充，并加上「打开时检查新版本」：

- 首页在推荐列表（无限滚动）之上新增三个内容模块：**服务保障条**（正品保障 / 极速发货 / 七天无理由 / 售后无忧，纯静态）、**专题精选**（`/home/special`，横滑卡片展示封面、标题、起价与收藏人数）、**分类楼层**（`/home/goods`，4 个楼层各含楼层名、促销语、二级分类胶囊与横滑商品）。推荐列表仍在最下面，五个补充模块依旧在首屏出图后并发补拉、单个失败静默降级。
- 新增 `lib/models/home_extra.dart`（`SpecialTopicItem` / `HomeFloor`）、`lib/api/home_extra.dart`、`lib/components/common/hm_goods_compact_card.dart`（紧凑商品卡，新品首发与楼层共用）、`lib/components/Home/{hm_service_promise,hm_special_topic,hm_home_floor}.dart`；`hm_new_goods.dart` 改用统一的紧凑商品卡（131 → 76 行）。
- 楼层卡价格被截断（`￥298....`）修复：价格行由 `Text` + ellipsis 改成 `FittedBox(scaleDown)` 缩放，`已售 N` 加左内边距并禁止换行——110 宽的卡片也能完整显示 `￥1566.00`。
- **打开时检查新版本**：`AppUpdateService` 读当前版本（`package_info_plus`）→ 拉 GitHub `releases/latest` → 分段比较版本号；Web / iOS 在页面顶部显示 `HmUpdateBanner`，Android 弹 `showAppUpdateDialog`（版本号 + 安装包体积 + 更新说明），「立即更新」用 `url_launcher` 打开 APK 下载地址，「跳过此版本」写进本地后同一版本不再提示；两次检查间隔 6 小时（GitHub 未登录接口按 IP 限流），请求失败 / 仓库未发版 / debug 构建都静默跳过。
- 新增 `test/app_update_test.dart`（27 个用例）：版本号归一化与比较、Release 与 APK 资产选择、TTL 与 `force`、跳过版本、横幅与弹窗回调、Android / 非安卓两种提示、GitHub 接口的 404 与 500、`PackageInfo` 版本读取；首页新模块的用例补在 `test/home_modules_test.dart`（服务保障 / 专题精选 / 分类楼层，含空数据与点击跳转）。
- 整体覆盖率 91.5% → **91.6%**（3885 / 4239 行），用例数 259 → **295**；README 补「版本更新」说明与接口表，`.github/workflows/dart.yml` 的基线注释同步。
- 版本号提升到 `1.0.13+14`。

## [1.0.12] - 2026-11-24

补齐审查报告里覆盖率最薄弱的两块（路由层与购物车页），顺带收紧两处返回类型：

- `buildRoute` 与 `buildUnknownRoute` 的返回类型从 `Route<dynamic>?` 改成 `Route<dynamic>`：路径查不到时一定会生成兜底页路由，原来的 `home == null ? const [] : [home]` 分支根本走不到，去掉后 `buildInitialRoutes` 不再需要判空。
- 新增 `test/routes_test.dart`（18 个用例）：`getRootWidget` 的装配（路由表 / 深链解析 / 兜底页 / 主题）、13 条路由逐条接线（`/goods`、`/goods/list`、`/brand`、`/order/confirm`、`/orders`、`/orders/detail` 的参数解析与缺参默认值，以及 5 个无参页面各自打开对应页面）、订单列表与订单详情地址构造。`lib/routes/index.dart` 覆盖率 33.3% → 97.0%，`lib/routes/app_routes.dart` 64.3% → 92.9%。
- 新增 `test/cart_actions_test.dart`（20 个用例）：改数量、数量下界禁用、改数量失败回滚、删除二次确认与取消、全选串行提交与失败重拉、结算的三种分支（未勾选 / 多选 / 单件跳转）、下拉刷新、未登录跳登录、详情页返回后刷新、失效商品不可勾选、勾选与删除失败回滚、缺商品 id 只提示、在途去重、切 tab 与登录态变化重新拉取。`lib/pages/Cart/index.dart` 覆盖率 58.9% → 98.5%。
- 整体覆盖率 88.2% → **91.5%**（3554 / 3884 行），用例数 221 → **259**；`.github/workflows/dart.yml` 的基线注释与 README 同步。

## [1.0.11] - 2026-11-24

修掉 Web 流水线在多个 PR 并存时成片 `cancelled` 的问题：

- `web.yml` 的 `concurrency.group` 从写死的 `pages` 改成 `pages-${{ github.ref }}`：以前所有 PR 共用一个组，`cancel-in-progress: false` 只保留一个 pending，后到的会把排队中的构建取消掉——依赖机器人一次开 6 个 PR 时，`Build and Deploy Web` 出现 5 个 `cancelled`。现在 PR 各用各的组，master 上的部署仍然串行。
- README 同步说明 `concurrency` 的分组方式。
- 版本号提升到 `1.0.11+12`。

## [1.0.10] - 2026-11-24

继续压低 CI 消耗，不改应用行为：

- `mobile.yml` 不再在 `pull_request` 上触发：依赖机器人一次会开好几个 PR，每个都排一遍 Android + macOS 构建太浪费；Android 打包正确性由每次发版的标签运行兜住。
- `dependabot.yml` 把同一周的 Action 版本更新合并成一个 PR（`groups`），`open-pull-requests-limit` 从 5 收到 3——否则 `checkout` / `upload-artifact` / `configure-pages` 各开一个 PR，各自触发一轮 CI。
- README 同步 `build-ios` 的触发条件（打标签 / 手动触发）。
- 版本号提升到 `1.0.10+11`。

## [1.0.9] - 2026-11-24

工程卫生与 CI 成本优化，不改应用行为：

- 新增 `.gitattributes`：文本文件统一 `eol=lf`，Windows 检出也不再转 CRLF——此前每次提交都会刷一串 `warning: LF will be replaced by CRLF`，且换行符变化容易造成整文件 diff。`*.bat` / `*.cmd` / `*.ps1` 保留 CRLF，图片、字体、`*.jks` / `*.apk` / `*.aab` / `*.ipa` 按二进制处理。
- 新增 `.editorconfig`：2 空格缩进、UTF-8、LF、文件末尾换行、去尾随空格（Markdown 保留行尾空格，那是硬换行）。
- 新增 `.github/dependabot.yml`：每周一检查 `github-actions` 与 `pub` 依赖，只对 minor / patch 开 PR；Flutter SDK 版本仍由各 workflow 写死，不自动跟。
- 新增 `LICENSE`（MIT）。
- `dart.yml` 与 `web.yml` 的 `push` / `pull_request` 加 `paths-ignore`（`**.md`、`docs/**`、`LICENSE`、`.gitignore`、`.gitattributes`、`.editorconfig`）：纯文档改动不再白跑一轮 CI，也不用再手工加 `[skip ci]`。
- 三个 workflow 的 job 补齐 `timeout-minutes`（CI 20 分钟、Web 构建 20 分钟、部署 10 分钟、`mobile.yml` 原本已有），卡住时不会占满 GitHub 默认的 6 小时上限。
- README 补充上述配置文件说明与「纯文档改动不触发 CI」的行为，目录结构补 `.github/` 与根目录配置；AGENTS.md 的发版约定同步。
- 版本号提升到 `1.0.9+10`。

## [1.0.8] - 2026-11-24

继续收敛移动端流水线的红叉：

- `build-ios` 改为只在「打标签 / PR / 手动触发」时运行，分支 push 只跑 Android——避免每次 push 都去抢 macOS runner，抢不到就把 `Build Mobile`（master）染红。
- 发版路径不受影响：每次更新都会打 `v*` 标签，标签运行仍会编译 iOS 并产出 `Runner.app.zip`。
- README 同步说明「分支 push 只跑 Android」。
- 只改 CI 与文档，未改动应用代码；版本号提升到 `1.0.8+9`。

## [1.0.7] - 2026-11-24

修掉发版流水线「动不动就变红、Release 被 skip」的问题：

- 新增 `detect-signing` job：先判断签名 Secrets 是否齐全。缺 iOS 签名时 `build-ios-signed` 整个 job 直接 skip，不再去申请 macOS runner——之前 v1.0.5 / v1.0.6 的 `Build Mobile` 都是因为这个 job 排队排不到被 `cancelled`（`Due to capacity constraints, jobs targeting macOS arm64 runners may experience longer queue times.`）而把整次运行染红。
- `publish-release` 改为 `always() && build-android == success`：iOS job 被 cancelled 时仍发布 Android 产物，不再让 `Publish GitHub Release` 跟着 skip（v1.0.6 首次运行就是这样没发出 Release 的）。
- Release 说明新增一行「iOS 未签名产物（Runner.app.zip）：已包含 / 未包含」，缺产物时如实标注并提示重跑。
- README 补充 macOS runner 容量限制的说明与两层兜底逻辑、以及 `detect-signing` 这一行。
- 只改 CI 与文档，未改动应用代码；版本号提升到 `1.0.7+8`。

## [1.0.6] - 2026-11-23

首页内容更丰富，无限滚动的推荐列表仍放在最下面：

- 新增「新品首发」模块：`/home/new` + `HmNewGoods` 横滑商品卡（名称固定两行、价格与销量同一行），点击进商品详情。
- 新增「人气好物榜」模块：`/hot/new` + `HmRankList` 取第一个子类型前 4 件商品按名次排列，前三名主色区分，点击进商品详情。
- 新增「品牌好店」模块：`/home/brand` + `HmBrandStrip` 横滑展示品牌 logo 与名称。
- 新增品牌详情页 `/brand?id=<品牌 id>`：展示 logo、中英文名、产地、口号、关注人数与品牌故事，含加载中 / 失败重试 / 缺少 id 三种状态。后端没有「按品牌查商品」的接口，因此该页不放商品列表。
- 三个新模块属于「首屏之外的补充内容」，不占用首屏 6 个并发请求：首屏出图后由 `_loadSecondaryModules()` 并发补拉（`_secondaryLoading` 防重入、单个失败静默降级），首屏全部失败时不发这批请求。
- 新增 `HmSectionHeader` 统一「标题 + 副标题」，`HmHot` 一并改用，去掉一处重复实现。
- 新增 11 个用例（三个模块的空数据 / 渲染 / 点击、首页接入、品牌详情页三态），用例数 210 → 221，覆盖率 87.4% → 88.2%。
- 版本号提升到 `1.0.6+7`。

## [1.0.5] - 2026-11-23

首页轮播图现在可以点击了：

- `BannerItem` 增加 `hrefUrl`（跳转地址）与 `type`（1 商品分类 / 2 商品详情 / 3 外部链接）两个字段，并提供 `categoryId`、`goodsId` 两个解析 getter。
- `HmSlider` 增加 `onBannerTap` 回调，每张轮播图用 `HitTestBehavior.opaque` 的 `GestureDetector` 包住，图片留白处也能点。
- 点分类类 banner 会切到「分类」tab 并选中该一级分类（与首页分类入口共用同一套「请求选中」逻辑，`hrefUrl` 里下发的正是一级分类 id）；点商品类 banner 直接进商品详情页。
- 外部链接 banner 或后端没配 `hrefUrl` 时提示「该活动暂未开放，敬请期待」，不再点了毫无反应。
- 新增 7 个用例（模型解析 3 个 + 轮播回调 / 首页转发 / 无跳转提示 / 切 tab 选中分类 4 个），用例数 203 → 210，覆盖率 87.4%。
- 版本号提升到 `1.0.5+6`。

## [1.0.4] - 2026-11-23

代码重构，界面与接口行为不变：

- 新增 `lib/utils/paged_list.dart`：`PageResult<T>` + `PagedListController<T>` 统一分页列表的「首次加载 / 下拉刷新 / 上拉加载更多」状态机（`isLoading` / `loadingMore` / `hasMore` / `errorMessage`），加载更多自带重入保护、列表为空时不会去请求第二页、加载更多失败只回调 toast 不清已有数据。
- 新增 `lib/components/common/hm_list_footer.dart`：分页列表底部状态条（加载中转圈 / 还有下一页 / 没有更多了）。
- 订单列表、我的收藏、「我的」页猜你喜欢三个页面改用统一状态机，删掉各自那套 `_page` / `_isLoading` / `_loadingMore` / `_hasMore` / `_errorMessage` 与重复的底部状态条代码。首页推荐仍是「递增 limit」逻辑，未改动。
- 顺带修掉一个资源泄漏：收藏页与订单列表页监听全局用户态的 `ever(...)` 之前没有 `dispose`，离开页面后仍在监听；现在与控制器一起释放。
- 新增 9 个用例（7 个状态机 + 2 个底部状态条），用例数 194 → 203，覆盖率 86.9% → 87.4%。
- 版本号提升到 `1.0.4+5`。

## [1.0.3] - 2026-11-23

Web 产物体积与构建脚本：

- Web 产物从 **40.41 MB 降到 32.22 MB**（-8.19 MB / -20%）：`web.yml` 新增 `Strip engine symbol files` 步骤，删掉 `canvaskit/` 下 6 个 `*.js.symbols`。这些文件只在 `flutter symbolize` / DevTools 还原引擎堆栈时用，部署产物不会请求它们；删完在无头浏览器里验证首页、分类、详情、购物车均正常渲染。
- 构建命令加 `--no-wasm-dry-run`：末尾的 wasm 兼容性 dry-run 只把提示写到 stderr，本地 PowerShell 会把它当失败（exit 1），CI 日志里也只是一条警告。
- 版本号提升到 `1.0.3+4`；README 新增「Web 产物体积」小节，写清 32 MB 的构成，以及为什么不能删 canvaskit 变体目录、为什么不启用 `--web-resources-cdn`（gstatic 在国内不可达会导致白屏）。
- 本轮没有 Dart 代码改动，用例数 194 与覆盖率 86.9% 不变。

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
