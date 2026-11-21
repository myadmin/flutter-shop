# hm_shop

基于 Flutter 的商城类 App 示例项目，采用「页面 / 组件 / API / 模型 / 状态」分层组织代码。已接入黑马 meikou 接口，完成首页（轮播图、分类、特惠推荐、爆款推荐、一站全买、推荐列表分页）、分类（一级导航 + 二级宫格 + 推荐）、登录（token 持久化与请求鉴权）、商品详情、购物车、订单确认与「我的」页面。

## 功能概览

### 首页

- **骨架屏**：数据加载期间展示 `HomeSkeleton`，带呼吸闪烁动画；全部接口返回后切换为真实内容
- **并行加载与容错**：6 个首页接口并发请求，各模块异常独立隔离，单个接口失败不影响其余模块展示；全部返回后**只调用一次 `setState`**（此前每个模块各刷新一次，一次下拉会触发最多 6 帧整页重建）
- **错误态与重试**：6 个模块全部失败（典型如断网）时展示 `AppErrorView` 与「重新加载」按钮；部分失败则静默降级，只展示成功模块
- **下拉刷新**：`RefreshIndicator` 重新拉取全部首页数据，自动重置分页参数（`_page = 1`）与加载状态；错误态下同样可下拉刷新
- **轮播图**：`/home/banner` 获取图片，自动播放（4 秒间隔），底部指示点可点击切换
- **顶部搜索框**：叠加在轮播图上方的半透明搜索入口，点击提示「搜索功能开发中」
- **分类快捷入口**：`/home/category/head` 获取分类，横向滚动列表展示图标与名称
- **特惠推荐**：`/hot/preference` 获取数据，展示第一个子类型的前 3 个商品，含本地背景图与价格标签
- **爆款推荐 / 一站全买**：`/hot/inVogue`、`/hot/oneStop` 获取数据，左右两栏布局，复用 `HmHot` 组件，通过 `HmHotConfig` 区分场景样式
- **推荐列表**：`/home/recommend` 获取数据，`HmMoreList` 以 `SliverGrid` 双列展示，滚动到底部时递增 `limit` 加载更多
- **生命周期安全**：滚动监听器单次绑定，并在组件销毁时及时释放 `ScrollController`

### 分类

- **左侧一级分类导航**：`HmCategoryRail` 展示 `/home/category/head` 返回的 7 个一级分类，选中项白底、主色左边条、文字加粗，与右侧面板的白底连成一体
- **右侧二级分类宫格**：`HmCategoryPanel` 按可用宽度自适应列数（手机 3 列、Web 宽屏最多 6 列），图片固定为正方形并按实际显示尺寸解码，文字区高度固定避免溢出
- **切换与滚动**：切换一级分类后右侧面板自动回到顶部；二级分类点击提示「商品列表开发中」（接口侧没有按分类取商品的接口，详见接口说明）
- **底部猜你喜欢**：`HmCategoryRecommend` 复用 `/home/goods/guessLike` 与 `HmGoodsCard`，补齐分类项较少时的留白，并提供一条进入商品详情的路径；该区块加载失败时静默降级，不影响分类展示
- **状态与容错**：加载中展示进度指示器，分类接口失败时展示 `AppErrorView` 与「重新加载」按钮

### 商品详情

- **主图轮播**：`HmGoodsGallery` 展示 `mainPictures`，底部分页指示点随滑动高亮；无主图时回退为占位图
- **价格与销量**：`HmGoodsPriceInfo` 展示售价、划线价（仅当划线价与售价不同时显示）、已售与评价数
- **品牌与参数**：`HmGoodsBrand`、`HmGoodsProperties` 分别展示品牌信息与商品参数
- **详情长图**：`SliverList.builder` 按需构建详情图，避免一次性解码全部长图
- **底部操作栏**：`HmActionBar` 展示价格与「加入购物车 / 立即购买」，固定在视口底部且不遮挡内容
- **规格与数量选择**：加购与购买都会弹出 `HmSkuSelector` 底部弹层，按 `skus[].specs` 反推「颜色 / 尺寸」等规格组；不可选的规格值置灰禁用，切换规格后价格、库存、已选文案与数量上限实时联动（数量收敛到 `1~库存`）
- **前置校验**：`_selectSku` 处理规格缺失提示，`_checkLogin` 处理未登录跳转登录页

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
- **输入体验**：手机号框 `keyboardType.phone` 且「下一项」跳到密码框，密码框支持「完成」直接提交，并提供明文 / 密文切换按钮（`AutofillGroup` 支持系统级账号密码填充）
- **协议勾选**：未勾选隐私条款 / 用户协议时拦截登录并 Toast 提示
- **登录状态与弹窗控制**：请求期间展示 `LoadingDialog`，成功路径先关闭 Loading 再退出登录页，确保任何分支都不会残留加载弹窗

### 购物车

- **商品清单**：`HmCartTile` 展示图片、名称、规格、现价与数量步进器；同一商品不同规格按 `skuId` 区分成独立条目
- **勾选与全选**：单个条目直接 `PUT /member/cart/{skuId}`；「全选」逐条串行请求（接口没有批量选中接口），失败后重新拉取列表兜底
- **数量调整**：`HmCartQuantityStepper` 限制在 1~库存之间，触达边界或请求在途时按钮禁用
- **乐观更新**：勾选、改数量、删除都先更新界面再请求，失败回滚并 Toast 提示；删除走 `DELETE /member/cart`
- **结算入口**：`HmCartSummaryBar` 展示已选件数与合计（不含运费），点击「结算」进入订单确认页
- **角标同步**：`CartController` 维护件数，底部导航的购物车角标通过 `Obx` 响应更新，加购成功与登录态变化后自动刷新
- **状态与容错**：未登录展示「登录后查看购物车」，空车展示「去逛逛」，接口失败展示 `AppErrorView` 与重试入口，支持下拉刷新
- **宽屏适配**：正文与结算栏内容宽度统一收窄到 600 并居中，避免 Web 宽屏下条目被拉长

### 其他

- **底部导航**：首页 / 分类 / 购物车 / 我的，使用 `IndexedStack` 保持各页面状态；购物车 tab 带件数角标；`PopScope` 让 Android 返回键在非首页 tab 时先回到首页，而不是直接退出
- **状态管理分工**：跨页面共享的用户态与购物车件数放在 GetX 控制器（`UserController` / `CartController`，页面通过 `Obx` 响应式刷新），且仅在 `main()` 中注册一次；页面私有的列表数据、加载态与错误文案用 `State` + `setState`
- **登录态管理**：`TokenManager` 基于 `shared_preferences` 持久化 token（写盘 `await` 落盘完成）；启动时若已登录则请求 `/member/profile` 恢复用户信息，失效时自动清理并降级
- **网络层**：Dio 单例封装，统一超时与请求头注入；异常被翻译为 `ApiException`（业务错误，带 `code`）或 `NetworkException`（网络 / 超时 / 401），页面统一用 `resolveErrorMessage` 提取可展示文案
- **金额计算**：`lib/utils/money.dart` 把金额以「分」为单位的整数累加（`parseCents` / `formatCents`），避免多条商品按 `double` 相加后差一分
- **登录态失效**：拦截器识别 HTTP 401，自动清理 token 并触发 `DioRequest.onUnauthorized`，由 `MainPage` 统一跳转登录页
- **设计令牌**：颜色、圆角、间距集中在 `lib/constants/app_theme.dart`（`AppColors` / `AppRadius` / `AppSpacing`），页面不再散落颜色字面量与圆角字面量（卡片统一 `AppRadius.card`）
- **图片统一**：所有网络图片经 `AppNetworkImage` 加载，列表项按 `decodeWidth`（或 `LayoutBuilder` 实测宽度）设置 `cacheWidth`，降低解码内存占用；首页两张装饰图改用 WebP，体积从 287 KB 降到 18 KB
- **并发与容错**：购物车件数与购物车列表请求都做了在途去重（同一时刻只发一次）；首页整页刷新期间不接受滚动加载（`_refreshing`），避免与首屏请求抢 `limit`；401 跳转登录页带重入保护；滚动触发的加载在本地吞掉异常，不会冒泡成未捕获异步错误；`PlatformDispatcher.onError` 兜底记录漏网的异步异常
- **加载弹窗**：`LoadingDialog` 持有 `DialogRoute` 引用，`hide()` 精确移除自身路由，不会误弹页面
- **Toast 工具**：`ToastUtils` 基于 `SnackBar`，宽度随文案自适应；只有**相同文案**在 2 秒内重复时才节流，不同提示不会被吞掉，新提示会顶掉正在展示的旧提示
- **自动化测试**：109 个用例，覆盖网络层拦截与业务码、模型反序列化容错与接口结构校验、金额整数累加、全局用户态与购物车件数、骨架屏、商品聚合组件、规格选择弹层、订单组件、「我的」页面组件、分类页组件、购物车组件、未知路由兜底与深链解析，以及首页 / 购物车 / 登录 / 分类四个页面的页面级交互（用 `MockAdapter` 替换 Dio 适配器，不发真实请求）
- **代码规范与 CI**：`dart format`、`flutter analyze --fatal-infos`（已开启 `strict-casts` / `strict-inference` / `strict-raw-types`）、`flutter test --coverage`（覆盖率低于 80% 直接失败）、`flutter build web --release`（构建冒烟）在 CI 中全部强制通过

## 技术栈

| 类别 | 说明 |
| --- | --- |
| 框架 | Flutter `3.47.9`（stable），Dart SDK `^3.13.7`；CI 固定同一版本，不跟随 stable 漂移 |
| 路由 | `MaterialApp` 命名路由 + 深链（`usePathUrlStrategy` / `onUnknownRoute`）+ 主题（`buildAppTheme`） |
| 状态管理 | [get](https://pub.dev/packages/get) `^4.7.3`（仅用于全局用户态） |
| 本地存储 | [shared_preferences](https://pub.dev/packages/shared_preferences) `^2.5.6` |
| 轮播组件 | [carousel_slider](https://pub.dev/packages/carousel_slider) `^5.1.2` |
| 网络请求 | [dio](https://pub.dev/packages/dio) `^5.11.1` |
| 测试框架 | `flutter_test`（单元测试与 Widget 测试） |
| 代码规范 | `flutter_lints` `^6.0.0` + 自定义规则（`unawaited_futures`、`prefer_const_constructors`、`avoid_dynamic_calls` 等），并开启 `strict-casts` / `strict-inference` / `strict-raw-types` |
| 运行平台 | Web（主要）、Android、iOS、macOS、Linux、Windows |

## 目录结构

```text
lib/
├── api/                        # 接口调用
│   ├── home.dart               # 首页 6 个接口的请求函数
│   ├── goods.dart              # 商品详情
│   ├── order.dart              # 结算信息 / 提交订单
│   ├── cart.dart               # 购物车列表 / 件数 / 增删改
│   ├── mine.dart               # 猜你喜欢分页接口
│   └── user.dart               # 登录 / 用户信息接口
├── components/
│   ├── common/                 # 跨页面通用组件
│   │   ├── hm_bottom_bar.dart  # 底部操作栏容器 / 价格 / 按钮
│   │   ├── hm_goods_card.dart  # 商品卡片（图片 / 标题 / 价格 / 付款人数）
│   │   ├── app_network_image.dart # 统一网络图片（带解码尺寸与占位）
│   │   └── app_error_view.dart # 统一错误态 + 重试
│   ├── Home/                   # 首页业务组件
│   │   ├── hm_slider.dart      # 轮播图 + 搜索框 + 指示点
│   │   ├── hm_category.dart    # 分类横向列表
│   │   ├── hm_suggestion.dart  # 特惠推荐区
│   │   ├── hm_hot.dart         # 爆款推荐 / 一站全买通用组件
│   │   └── hm_more_list.dart   # 双列商品网格（首页推荐 / 猜你喜欢共用）
│   ├── Category/               # 分类页组件
│   │   ├── hm_category_search.dart    # 顶部搜索入口
│   │   ├── hm_category_rail.dart      # 左侧一级分类导航
│   │   ├── hm_category_panel.dart     # 右侧二级分类宫格
│   │   └── hm_category_recommend.dart # 底部猜你喜欢
│   ├── GoodsDetail/            # 商品详情页组件
│   │   ├── hm_goods_gallery.dart    # 主图轮播
│   │   ├── hm_goods_price_info.dart # 价格 / 销量 / 标题
│   │   ├── hm_goods_brand.dart      # 品牌信息
│   │   ├── hm_goods_properties.dart # 商品参数 / 详情分隔标题
│   │   ├── hm_sku_selector.dart     # 规格与数量选择底部弹层
│   │   └── hm_action_bar.dart       # 底部加购 / 购买操作栏
│   ├── OrderConfirm/           # 订单确认页组件
│   │   ├── hm_order_card.dart      # 卡片容器
│   │   ├── hm_order_address.dart   # 收货地址
│   │   ├── hm_order_goods.dart     # 商品行
│   │   └── hm_order_summary.dart   # 金额汇总
│   ├── Cart/                   # 购物车页组件
│   │   ├── hm_cart_tile.dart          # 条目行（勾选 / 图片 / 规格 / 步进器 / 删除）
│   │   ├── hm_cart_quantity_stepper.dart # 数量增减控件
│   │   ├── hm_cart_summary_bar.dart   # 全选 / 合计 / 结算栏
│   │   └── hm_cart_empty.dart         # 空态与未登录态
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
│   ├── cart.dart               # 购物车条目模型（含小计与结算条件）
│   └── user.dart               # 用户信息模型
├── pages/
│   ├── Main/index.dart         # 底部 Tab 容器
│   ├── Home/
│   │   ├── index.dart          # 首页数据加载与模块拼装
│   │   └── skeleton.dart       # 首页骨架屏
│   ├── GoodsDetail/index.dart  # 商品详情页
│   ├── OrderConfirm/index.dart # 订单确认页
│   ├── Category/index.dart     # 分类页：一级导航 + 二级宫格 + 推荐
│   ├── Cart/index.dart         # 购物车：清单、勾选、改数量、删除、结算入口
│   ├── Mine/index.dart         # 我的：用户信息、会员卡、订单、猜你喜欢
│   ├── Login/index.dart        # 登录页
│   └── Unknown/index.dart      # 未知路由兜底页
├── routes/
│   ├── app_routes.dart         # 路由名与带参跳转地址的统一构造
│   └── index.dart              # 路由表、深链解析、根 Widget 与主题
├── stores/
│   ├── token_manager.dart      # token 本地持久化
│   ├── user_controller.dart    # GetX 全局用户态
│   └── cart_controller.dart    # GetX 全局购物车件数（底部角标）
├── utils/
│   ├── dio_request.dart        # Dio 单例封装（注入 token、401 处理）
│   ├── api_exception.dart      # ApiException / NetworkException / resolveErrorMessage
│   ├── money.dart              # 金额按「分」整数累加（parseCents / formatCents）
│   ├── loading_dialog.dart     # 统一加载中对话框
│   ├── web_url_strategy.dart   # Web 真实路径策略的跨平台门面（条件导入）
│   └── toast_utils.dart        # 自适应宽度 Toast
├── assets/                     # 底部导航图标、我的页图标、首页装饰图（WebP）等资源
└── main.dart                   # 程序入口（注册全局状态、兜底未捕获异步异常）
```

```text
test/
├── helpers/mock_http.dart      # MockAdapter 与响应 / 数据构造工具
├── dio_request_test.dart       # 网络层：业务码、超时、401、鉴权头
├── models_test.dart            # 反序列化工具与模型容错
├── user_controller_test.dart   # 全局用户态
├── sku_selector_test.dart      # 规格选择弹层
├── category_components_test.dart # 分类页组件
├── mine_components_test.dart   # 「我的」页面组件
├── cart_test.dart              # 购物车模型 / 组件 / 全局件数
├── pages_test.dart             # 页面级交互（购物车 / 登录 / 分类）
├── home_page_test.dart         # 首页并发加载、部分失败降级、整页错误重试
├── unknown_route_test.dart     # 未知路由兜底、深链解析、地址构造
└── widget_test.dart            # 首页骨架屏、订单组件、商品聚合组件
```

## 路由

Web 端启用了 `usePathUrlStrategy`，地址栏是真实路径（`/goods?id=4026450`）而不是 hash（`#/goods`），因此地址可以直接分享、刷新后能还原到同一页面。参数统一以查询串出现在地址里，跳转地址由 `AppRoutes` 构造，避免各处手拼字符串。

| 路径 | 页面 | 参数（查询串） |
| --- | --- | --- |
| `/` | `MainPage` | 无 |
| `/login` | `LoginPage` | 无 |
| `/goods?id=<商品 id>` | `GoodsDetailPage` | `id` |
| `/order/confirm?skuId=<sku>&count=<数量>` | `OrderConfirmPage` | `skuId`、`count` |

解析规则在 `buildRoute` 里：查询串会转成 `RouteSettings.arguments` 传给页面，站内 `pushNamed` 传入的 `arguments` 优先级更高；匹配不到的路由交给 `onUnknownRoute`，渲染 `UnknownRoutePage`（而不是白屏）。

> 真实路径策略要求静态服务器支持「深链回退到 index.html」。部署到 GitHub Pages 时由 `.github/workflows/web.yml` 额外生成一份 `404.html`（内容与 `index.html` 相同）兜底；本地调试可用任意 SPA 回退的静态服务。

## 接口说明

- Base URL：`https://meikou-api.itheima.net`
- 超时时间：10 秒（连接 / 发送 / 接收）
- 成功判定：响应 `code == '1'`，取 `result` 字段返回
- 业务失败抛 `ApiException`（携带 `msg` 与 `code`）；网络异常、超时、401 抛 `NetworkException`
- 最外层结构由 `asMap` / `asModelList` 校验，契约被破坏时抛 `FormatException`，页面提示「数据格式异常，请稍后重试」而不是展示空数据

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/home/banner` | 首页轮播图列表，映射为 `BannerItem` |
| GET | `/home/category/head` | 分类树（一级分类含 `children` 二级分类），首页分类快捷入口与分类页共用，映射为 `CategoryItem` |
| GET | `/hot/preference` | 特惠推荐，映射为 `SpecialRecommendResult` |
| GET | `/hot/inVogue` | 爆款推荐，映射为 `SpecialRecommendResult` |
| GET | `/hot/oneStop` | 一站全买，映射为 `SpecialRecommendResult` |
| GET | `/home/recommend` | 推荐列表，仅支持 `limit` 参数（**不支持 `page`/`pageSize`**），返回稳定前缀序，因此用递增 `limit` 累积加载 |
| GET | `/home/goods/guessLike` | 猜你喜欢分页列表，参数 `page`、`pageSize`，映射为 `GoodsDetailsItems` |
| GET | `/goods` | 商品详情，参数 `id` |
| POST | `/member/cart` | 加入购物车，参数 `skuId`、`count`；同 `skuId` 会合并累加，返回该条目 |
| GET | `/member/cart` | 购物车列表，映射为 `CartItem` 数组（条目的唯一标识是 `skuId`，同一商品不同规格会重复出现） |
| GET | `/member/cart/count` | 购物车件数，返回 `{"count": 13}`（各条目 `count` 之和） |
| PUT | `/member/cart/{skuId}` | 修改单条购物车，可只传 `count`、只传 `selected`，或两者同传 |
| DELETE | `/member/cart` | 批量删除，请求体 `{"ids": [skuId, ...]}`（放 query 会报缺少请求体） |
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

# 5. 运行单元与组件测试（附带覆盖率）
flutter test --coverage
```

## 持续集成

`.github/workflows/dart.yml` 在 push / PR 时依次执行五项检查，任何一项失败都会挡住合并：

1. `dart format --output=none --set-exit-if-changed lib test`
2. `flutter analyze --fatal-infos`（info 级问题同样视为失败）
3. `flutter test --coverage`
4. 覆盖率阈值：整体可执行行覆盖率低于 **80%** 直接失败（当前约 86%）
5. `flutter build web --release` 构建冒烟 —— 资源路径、条件导入这类问题 analyze 与 test 都发现不了

同一分支连续推送时，`concurrency` 会取消上一次仍在跑的检查，避免队列堆积。`.github/workflows/web.yml` 另行构建 Web 产物并通过 GitHub Pages 部署。

### 关于 SDK 版本

两个 workflow 都固定 `flutter-version: '3.47.9'`，而不是跟着 `channel: stable` 走。

原因是 Flutter 3.48 起给 `package:flutter/material.dart` 加了 `@Deprecated`，官方要求改用 `package:material_ui/material_ui.dart`。本项目所有源文件仍从 `package:flutter/material.dart` 引入，在 `--fatal-infos` 下这会让 CI 直接失败（实测 56 条 info）。暂时不迁移的理由是：`material_ui` 目前是独立实现，而 `get`、`carousel_slider` 仍从 `package:flutter/material.dart` 取类型，两边混用会出现同名但不同源的 `ThemeData`、`MaterialApp` 等类型。等依赖跟进后再一次性升级 SDK、替换全库 import，并重新跑一遍深链与规格弹层的浏览器验证。

### 关于 `--wasm`

试过 `flutter build web --release --wasm`，Chrome 150 下可以正常渲染、无控制台报错，体积也确实更小：`main.dart.wasm` 2392 KB，对比 `main.dart.js` 2832 KB（-15%）；首屏实测 6 个请求 / 2448 KB，对比 JS 版 9 个请求 / 2928 KB（禁用缓存）。

但默认构建仍然保留 JS，原因是：skwasm 要多线程渲染需要 `Cross-Origin-Opener-Policy` + `Cross-Origin-Embedder-Policy` 两个响应头，而 GitHub Pages 不支持自定义响应头；同时 wasm 产物会把 canvaskit 的各套变体和 JS 兜底一起带上，目录体积反而从 40.29 MB 涨到 42.65 MB。等换成支持自定义头部的托管再切，命令只需给 CI 的构建步骤加上 `--wasm`。

## 当前状态与已知问题

- 顶部搜索框、会员卡开通、快捷入口与订单管理入口均为静态占位，点击提示「功能开发中」。
- 接口侧没有「按分类取商品」的接口（`/category/goods`、`/category/list`、`/category/tree` 等路径均返回 4xx/5xx），因此二级分类点击只提示「商品列表开发中」；分类页的「猜你喜欢」用的是 `/home/goods/guessLike`。
- 购物车结算复用「立即购买」链路（`/member/order/pre/now` + `/member/order`），**接口只支持单件商品结算**，因此多选时点击「结算」会提示只勾选一件。
- 接口没有「全选 / 批量勾选」的接口（`PUT /member/cart` 与 `PUT /member/cart/checked` 均不存在），「全选」是逐条 `PUT /member/cart/{skuId}` 串行完成的，条目很多时会较慢。
- Web 端已启用真实路径与未知路由兜底：`/goods?id=...` 这类深链可以直接访问、刷新后仍停在同一页；但深链只携带查询串，像 `/order/confirm` 这种强依赖 `skuId` 的页面在参数缺失时会落到页面的错误态，而不是给出「链接参数缺失」的专门提示。
- GitHub Pages 用 `404.html` 实现深链回退，代价是「不存在的路径」也返回 HTTP 200，对 SEO 不友好；这是静态托管的通用取舍，不是代码问题。
- 商品**列表页**（分类 → 商品列表）尚未开发，是当前最后一个占位场景。
- 覆盖率只统计「被测试真正加载过」的文件（lcov 的统计口径），首页轮播、首页装饰区块、我的会员卡、商品详情品牌/参数等纯展示组件仍未被测试加载；CI 的 80% 阈值只约束已纳入统计的部分。
- `cupertino_icons` 在代码里没有被直接引用，但 GetX 内部组件引用其字体，删除后 `flutter build web` 会告警缺字体，因此保留（tree-shaking 后仅 1.4 KB）。
