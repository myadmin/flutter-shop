# hm_shop

基于 Flutter 的商城类 App 示例项目，采用「页面 / 组件 / API / 模型 / 状态」分层组织代码。已接入黑马 meikou 接口，完成首页（轮播图、分类、特惠推荐、爆款推荐、一站全买、推荐列表分页）、登录（token 持久化与请求鉴权）、商品详情、订单确认与「我的」页面；分类、购物车仍为占位页面。

## 功能概览

### 首页

- **骨架屏**：数据加载期间展示 `HomeSkeleton`，带呼吸闪烁动画；全部接口返回后切换为真实内容
- **并行加载与容错**：`Future.wait` 同时请求 6 个首页接口，各模块子请求独立异常隔离，单个接口失败不影响其余模块展示
- **错误态与重试**：6 个模块全部失败（典型如断网）时展示 `AppErrorView` 与「重新加载」按钮；部分失败则静默降级，只展示成功模块
- **下拉刷新**：`RefreshIndicator` 重新拉取全部首页数据，自动重置分页参数（`_page = 1`）与加载状态；错误态下同样可下拉刷新
- **轮播图**：`/home/banner` 获取图片，自动播放（4 秒间隔），底部指示点可点击切换
- **顶部搜索框**：叠加在轮播图上方的半透明搜索入口，点击提示「搜索功能开发中」
- **分类快捷入口**：`/home/category/head` 获取分类，横向滚动列表展示图标与名称
- **特惠推荐**：`/hot/preference` 获取数据，展示第一个子类型的前 3 个商品，含本地背景图与价格标签
- **爆款推荐 / 一站全买**：`/hot/inVogue`、`/hot/oneStop` 获取数据，左右两栏布局，复用 `HmHot` 组件，通过 `HmHotConfig` 区分场景样式
- **推荐列表**：`/home/recommend` 获取数据，`HmMoreList` 以 `SliverGrid` 双列展示，滚动到底部时递增 `limit` 加载更多
- **生命周期安全**：滚动监听器单次绑定，并在组件销毁时及时释放 `ScrollController`

### 商品详情

- **主图轮播**：`HmGoodsGallery` 展示 `mainPictures`，底部分页指示点随滑动高亮；无主图时回退为占位图
- **价格与销量**：`HmGoodsPriceInfo` 展示售价、划线价（仅当划线价与售价不同时显示）、已售与评价数
- **品牌与参数**：`HmGoodsBrand`、`HmGoodsProperties` 分别展示品牌信息与商品参数
- **详情长图**：`SliverList.builder` 按需构建详情图，避免一次性解码全部长图
- **底部操作栏**：`HmActionBar` 展示价格与「加入购物车 / 立即购买」，固定在视口底部且不遮挡内容
- **前置校验**：加购与购买共用 `_requireDefaultSku`（规格缺失提示）与 `_checkLogin`（未登录跳转登录页）

### 订单确认

- **收货地址**：`HmOrderAddress` 优先展示默认地址，无地址时展示「暂无收货地址」
- **商品清单**：`HmOrderGoods` 逐项展示图片、名称、规格与数量
- **金额汇总**：`HmOrderSummary` 展示商品件数、商品金额、运费与应付金额（主色加粗突出）
- **提交防重**：提交期间按钮禁用并显示进度指示器，配合 `_isSubmitting` 守卫避免重复下单
- **错误态与重试**：结算信息加载失败时展示 `AppErrorView` 与「重新加载」按钮

### 我的

- **用户信息头部**：展示头像与账号；未登录时显示「立即登录」，点击跳转 `/login`
- **退出登录**：二次确认后清除本地 token 与用户信息
- **会员卡片**：展示美荟商城会员开通入口
- **快捷入口**：我的收藏、我的足迹、我的客服（统一由 `HmEntryItem` 渲染，点击提示功能开发中）
- **订单管理**：我的订单、待付款、待发货、待收货、待评价（同上）
- **猜你喜欢**：`HmGuess` 作为吸顶标题（`SliverPersistentHeaderDelegate`），复用 `HmMoreList` 双列网格，调用 `/home/goods/guessLike` 按 `page`、`pageSize` 分页

### 登录

- **账号密码表单**：手机号与密码正则校验，密码为 6-16 位字母、数字、下划线，输入控制器在 `dispose` 中释放
- **协议勾选**：未勾选隐私条款 / 用户协议时拦截登录并 Toast 提示
- **登录状态与弹窗控制**：请求期间展示 `LoadingDialog`，成功路径先关闭 Loading 再退出登录页，确保任何分支都不会残留加载弹窗

### 其他

- **底部导航**：首页 / 分类 / 购物车 / 我的，使用 `IndexedStack` 保持各页面状态
- **状态管理分工**：跨页面共享的用户态放在 GetX `UserController`（页面通过 `Obx` 响应式刷新），且仅在 `main()` 中注册一次；页面私有的列表数据、加载态与错误文案用 `State` + `setState`
- **登录态管理**：`TokenManager` 基于 `shared_preferences` 持久化 token（写盘 `await` 落盘完成）；启动时若已登录则请求 `/member/profile` 恢复用户信息，失效时自动清理并降级
- **网络层**：Dio 单例封装，统一超时与请求头注入；异常被翻译为 `ApiException`（业务错误，带 `code`）或 `NetworkException`（网络 / 超时 / 401），页面统一用 `resolveErrorMessage` 提取可展示文案
- **登录态失效**：拦截器识别 HTTP 401，自动清理 token 并触发 `DioRequest.onUnauthorized`，由 `MainPage` 统一跳转登录页
- **设计令牌**：颜色、圆角、间距集中在 `lib/constants/app_theme.dart`（`AppColors` / `AppRadius` / `AppSpacing`），页面不再散落颜色字面量
- **图片统一**：所有网络图片经 `AppNetworkImage` 加载，列表项按 `decodeWidth` 设置 `cacheWidth`，降低解码内存占用
- **加载弹窗**：`LoadingDialog` 持有 `DialogRoute` 引用，`hide()` 精确移除自身路由，不会误弹页面
- **Toast 工具**：`ToastUtils` 基于 `SnackBar`，宽度随文案自适应，并做重复弹出节流
- **自动化测试**：48 个用例，覆盖网络层拦截与业务码、模型反序列化容错与接口结构校验、全局用户态、骨架屏、商品聚合组件、订单组件与「我的」页面组件
- **代码规范**：`dart format`、`flutter analyze --fatal-infos`、`flutter test` 三项在 CI 中全部强制通过

## 技术栈

| 类别 | 说明 |
| --- | --- |
| 框架 | Flutter（stable channel），Dart SDK `^3.13.7` |
| 路由 | `MaterialApp` 命名路由 + 主题（`buildAppTheme`） |
| 状态管理 | [get](https://pub.dev/packages/get) `^4.7.3`（仅用于全局用户态） |
| 本地存储 | [shared_preferences](https://pub.dev/packages/shared_preferences) `^2.5.6` |
| 轮播组件 | [carousel_slider](https://pub.dev/packages/carousel_slider) `^5.1.2` |
| 网络请求 | [dio](https://pub.dev/packages/dio) `^5.11.1` |
| 测试框架 | `flutter_test`（单元测试与 Widget 测试） |
| 代码规范 | `flutter_lints` `^6.0.0` + 自定义规则（`unawaited_futures`、`prefer_const_constructors`、`avoid_dynamic_calls` 等） |
| 运行平台 | Web（主要）、Android、iOS、macOS、Linux、Windows |

## 目录结构

```text
lib/
├── api/                        # 接口调用
│   ├── home.dart               # 首页 6 个接口的请求函数
│   ├── goods.dart              # 商品详情
│   ├── order.dart              # 结算信息 / 提交订单
│   ├── cart.dart               # 加入购物车
│   ├── mine.dart               # 猜你喜欢分页接口
│   └── user.dart               # 登录 / 用户信息接口
├── components/
│   ├── common/                 # 跨页面通用组件
│   │   ├── hm_bottom_bar.dart  # 底部操作栏容器 / 价格 / 按钮
│   │   ├── app_network_image.dart # 统一网络图片（带解码尺寸与占位）
│   │   └── app_error_view.dart # 统一错误态 + 重试
│   ├── Home/                   # 首页业务组件
│   │   ├── hm_slider.dart      # 轮播图 + 搜索框 + 指示点
│   │   ├── hm_category.dart    # 分类横向列表
│   │   ├── hm_suggestion.dart  # 特惠推荐区
│   │   ├── hm_hot.dart         # 爆款推荐 / 一站全买通用组件
│   │   └── hm_more_list.dart   # 双列商品网格（首页推荐 / 猜你喜欢共用）
│   ├── GoodsDetail/            # 商品详情页组件
│   │   ├── hm_goods_gallery.dart    # 主图轮播
│   │   ├── hm_goods_price_info.dart # 价格 / 销量 / 标题
│   │   ├── hm_goods_brand.dart      # 品牌信息
│   │   ├── hm_goods_properties.dart # 商品参数 / 详情分隔标题
│   │   └── hm_action_bar.dart       # 底部加购 / 购买操作栏
│   ├── OrderConfirm/           # 订单确认页组件
│   │   ├── hm_order_card.dart      # 卡片容器
│   │   ├── hm_order_address.dart   # 收货地址
│   │   ├── hm_order_goods.dart     # 商品行
│   │   └── hm_order_summary.dart   # 金额汇总
│   └── Mine/
│       ├── hm_mine_header.dart      # 头像 / 昵称 / 登录与退出入口
│       ├── hm_mine_vip_card.dart    # 会员卡
│       ├── hm_mine_quick_actions.dart # 收藏 / 足迹 / 客服
│       ├── hm_mine_order_module.dart # 订单管理入口
│       ├── hm_entry_item.dart  # 快捷入口 / 订单入口通用项
│       └── hm_guess.dart       # 「猜你喜欢」吸顶标题
├── constants/
│   ├── index.dart              # 全局常量、接口地址
│   ├── app_assets.dart         # 图片资源路径常量
│   └── app_theme.dart          # 设计令牌（颜色 / 圆角 / 间距）
├── models/
│   ├── parsers.dart            #  反序列化取值工具（asString / asInt / asAmount / asList
│   │                           #  以及结构校验版 asMap / asModelList / asMapOrEmpty）
│   ├── home.dart               # 首页数据模型
│   ├── goods.dart              # 商品详情模型
│   ├── order.dart              # 结算与订单模型
│   └── user.dart               # 用户信息模型
├── pages/
│   ├── Main/index.dart         # 底部 Tab 容器
│   ├── Home/
│   │   ├── index.dart          # 首页数据加载与模块拼装
│   │   └── skeleton.dart       # 首页骨架屏
│   ├── GoodsDetail/index.dart  # 商品详情页
│   ├── OrderConfirm/index.dart # 订单确认页
│   ├── Category/index.dart     # 分类（占位）
│   ├── Cart/index.dart         # 购物车（占位）
│   ├── Mine/index.dart         # 我的：用户信息、会员卡、订单、猜你喜欢
│   └── Login/index.dart        # 登录页
├── routes/index.dart           # 路由、根 Widget 与主题
├── stores/
│   ├── token_manager.dart      # token 本地持久化
│   └── user_controller.dart    # GetX 全局用户态
├── utils/
│   ├── dio_request.dart        # Dio 单例封装（注入 token、401 处理）
│   ├── api_exception.dart      # ApiException / NetworkException / resolveErrorMessage
│   ├── loading_dialog.dart     # 统一加载中对话框
│   └── toast_utils.dart        # 自适应宽度 Toast
├── assets/                     # 底部导航图标、我的页图标、首页活动图等资源
└── main.dart                   # 程序入口（注册全局状态）
```

## 路由

| 路径 | 页面 | 参数 |
| --- | --- | --- |
| `/` | `MainPage` | 无 |
| `/login` | `LoginPage` | 无 |
| `/goods` | `GoodsDetailPage` | 商品 `id`（`String`） |
| `/order/confirm` | `OrderConfirmPage` | `{'skuId': String, 'count': int}` |

## 接口说明

- Base URL：`https://meikou-api.itheima.net`
- 超时时间：10 秒（连接 / 发送 / 接收）
- 成功判定：响应 `code == '1'`，取 `result` 字段返回
- 业务失败抛 `ApiException`（携带 `msg` 与 `code`）；网络异常、超时、401 抛 `NetworkException`
- 最外层结构由 `asMap` / `asModelList` 校验，契约被破坏时抛 `FormatException`，页面提示「数据格式异常，请稍后重试」而不是展示空数据

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/home/banner` | 首页轮播图列表，映射为 `BannerItem` |
| GET | `/home/category/head` | 首页分类快捷入口，映射为 `CategoryItem` |
| GET | `/hot/preference` | 特惠推荐，映射为 `SpecialRecommendResult` |
| GET | `/hot/inVogue` | 爆款推荐，映射为 `SpecialRecommendResult` |
| GET | `/hot/oneStop` | 一站全买，映射为 `SpecialRecommendResult` |
| GET | `/home/recommend` | 推荐列表，仅支持 `limit` 参数（**不支持 `page`/`pageSize`**），返回稳定前缀序，因此用递增 `limit` 累积加载 |
| GET | `/home/goods/guessLike` | 猜你喜欢分页列表，参数 `page`、`pageSize`，映射为 `GoodsDetailsItems` |
| GET | `/goods` | 商品详情，参数 `id` |
| POST | `/member/cart` | 加入购物车，参数 `skuId`、`count` |
| GET | `/member/order/pre/now` | 立即购买结算信息，参数 `skuId`、`count`，映射为 `PreOrderResult` |
| POST | `/member/order` | 提交订单，返回订单 id |
| POST | `/login` | 账号密码登录，返回用户信息（含 `token`），映射为 `UserInfo` |
| GET | `/member/profile` | 获取当前登录用户信息（携带 token），映射为 `UserInfo` |

## 快速开始

```bash
# 1. 安装依赖
flutter pub get

# 2. 启动 Web 版本
flutter run -d chrome

# 3. 代码格式检查
dart format --output=none --set-exit-if-changed lib test

# 4. 静态分析（含 info 级问题，当前 0 告警）
flutter analyze --fatal-infos

# 5. 运行单元与组件测试
flutter test
```

## 持续集成

`.github/workflows/dart.yml` 在 push / PR 时依次执行格式检查、静态分析（`--fatal-infos`）与测试；`.github/workflows/web.yml` 构建 Web 产物并通过 GitHub Pages 部署。

## 当前状态与已知问题

- 分类、购物车页面仅为占位文本，功能尚未开发。
- 顶部搜索框、会员卡开通、快捷入口与订单管理入口均为静态占位，点击提示「功能开发中」。
- 商品列表页（分类 / 搜索结果）尚未开发，商品详情仅能从首页推荐与猜你喜欢进入。
- 购物车接口已接入（加入购物车），但购物车页面与结算流程尚未联通。
