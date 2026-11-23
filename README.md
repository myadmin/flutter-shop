# hm_shop

基于 Flutter 的商城类 App 示例项目，采用「页面 / 组件 / API / 模型 / 状态」分层组织代码。已接入黑马 meikou 接口，完成首页（轮播图、分类、特惠推荐、爆款推荐、一站全买、推荐列表分页）、分类（一级导航 + 二级宫格 + 分类商品列表 + 推荐）、登录（token 持久化与请求鉴权）、商品详情、购物车、订单确认、订单列表与详情、「我的」页面（含我的收藏、我的足迹、客服中心、会员权益）。

## 功能概览

### 首页

- **骨架屏**：数据加载期间展示 `HomeSkeleton`，带呼吸闪烁动画；全部接口返回后切换为真实内容
- **并行加载与容错**：6 个首页接口并发请求，各模块异常独立隔离，单个接口失败不影响其余模块展示；全部返回后**只调用一次 `setState`**（此前每个模块各刷新一次，一次下拉会触发最多 6 帧整页重建）
- **错误态与重试**：6 个模块全部失败（典型如断网）时展示 `AppErrorView` 与「重新加载」按钮；部分失败则静默降级，只展示成功模块
- **下拉刷新**：`RefreshIndicator` 重新拉取全部首页数据，自动重置分页参数（`_page = 1`）与加载状态；错误态下同样可下拉刷新
- **轮播图**：`/home/banner` 获取图片，自动播放（4 秒间隔），底部指示点可点击切换
- **顶部搜索框**：叠加在轮播图上方的半透明搜索入口，点击提示「搜索功能开发中」
- **分类快捷入口**：`/home/category/head` 获取分类，横向滚动列表展示图标与名称；点击某一项会切到底部的「分类」tab，并在分类页选中同一个一级分类（带水波纹反馈）
- **特惠推荐**：`/hot/preference` 获取数据，展示第一个子类型的前 3 个商品，含本地背景图与价格标签
- **爆款推荐 / 一站全买**：`/hot/inVogue`、`/hot/oneStop` 获取数据，左右两栏布局，复用 `HmHot` 组件，通过 `HmHotConfig` 区分场景样式
- **推荐列表**：`/home/recommend` 获取数据，`HmMoreList` 以 `SliverGrid` 双列展示，滚动到底部时递增 `limit` 加载更多
- **生命周期安全**：滚动监听器单次绑定，并在组件销毁时及时释放 `ScrollController`

### 分类

- **左侧一级分类导航**：`HmCategoryRail` 展示 `/home/category/head` 返回的 7 个一级分类，选中项白底、主色左边条、文字加粗，与右侧面板的白底连成一体
- **右侧二级分类宫格**：`HmCategoryPanel` 按可用宽度自适应列数（手机 3 列、Web 宽屏最多 6 列），图片固定为正方形并按实际显示尺寸解码，文字区高度固定避免溢出
- **切换与滚动**：切换一级分类后右侧面板自动回到顶部；点击二级分类进入该分类的商品列表页
- **外部指定选中项**：首页分类入口点击后切到本页，通过 `selectedCategoryId` + `selectionTicket` 传入选中的分类。用版本号而不只比 id，是为了让「用户手动切走后又点了同一个分类」也能重新选中；左栏在小屏上要滚动时会把选中项滚到可视区中央
- **底部猜你喜欢**：`HmCategoryRecommend` 复用 `/home/goods/guessLike` 与 `HmGoodsCard`，补齐分类项较少时的留白，并提供一条进入商品详情的路径；该区块加载失败时静默降级，不影响分类展示
- **状态与容错**：加载中展示进度指示器，分类接口失败时展示 `AppErrorView` 与「重新加载」按钮

### 分类商品列表

- **进入方式**：分类页点击任意二级分类，或直接访问深链 `/goods/list?categoryId=<分类 id>&title=<分类名>`
- **同级分类切换**：顶部胶囊 chips 来自接口返回的 `categories`（同级分类），点击即切换分类并重新拉取，无需返回上一页
- **商品网格**：`HmGoodsCard` 复用首页推荐卡片（图片按显示宽度解码、价格缩放不溢出），宽屏下内容收进 600 的阅读宽度并与手机端保持同样的列间距
- **数据量**：`/category/sub/filter?id=` 不分页，一次返回该分类全部商品（实测最多 16 件），因此页面不做分页、只提供下拉刷新
- **状态与容错**：加载中、接口失败（`AppErrorView` + 重试）、空分类（「该分类下还没有商品」）三种状态齐备；缺少 `categoryId` 时直接提示而不发请求

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

- **用户信息头部**：展示头像与账号；未登录时显示「立即登录」，点击跳转 `/login`；已登录时点头像或昵称进入个人资料页（见下方「个人资料」）
- **退出登录**：二次确认后清除本地 token 与用户信息
- **会员卡片**：展示美荟商城会员开通入口，点击进入会员权益页（纯静态，见下方「会员权益」）
- **快捷入口**：我的收藏、我的足迹、我的客服（统一由 `HmEntryItem` 渲染）；收藏未登录先跳登录页、已登录进入收藏列表，足迹进入本地足迹页（无需登录），客服进入客服中心
- **订单管理**：我的订单、待付款、待发货、待收货、待评价五个入口；未登录先跳登录页，已登录按对应状态进入订单列表（见下方「订单列表与详情」）
- **订单角标**：登录后对待付款 / 待发货 / 待收货 / 待评价四个状态各查一次 `pageSize=1` 的订单列表、只读 `counts` 显示红色数字角标（>99 显示 `99+`，为 0 不显示）；接口没有数量端点（`GET /member/order/count` 需要参数，试出 400），从订单列表页返回时重新拉取
- **猜你喜欢**：`HmGuess` 作为吸顶标题（`SliverPersistentHeaderDelegate`），复用 `HmMoreList` 双列网格，调用 `/home/goods/guessLike` 按 `page`、`pageSize` 分页

### 订单列表与详情

- **状态筛选**：`HmOrderStatusTabs` 五个 tab（全部 / 待付款 / 待发货 / 待收货 / 待评价）平分宽度，选中项主色加粗并在下方显示短下划线；切换 tab 时清空列表、回到顶部并重新拉取（`orderState` 作为请求参数）
- **分页加载**：`pageSize=10`，滚动到距底部 200px 时追加下一页；`_hasMore` 由 `page < pages` 判断，底部展示「加载中 / 没有更多订单了」
- **订单卡片**：`HmOrderCard` 展示订单号后 8 位、状态、下单时间、商品行（超过 3 行折叠为「还有 N 件商品」）、「共 N 件 / 实付金额」与操作按钮
- **删除订单**：卡片与详情页都支持删除，二次确认后调 `DELETE /member/order`（请求体 `{"ids": [...]}`）；列表内直接移除该条，详情页删除后带 `true` 返回列表并触发刷新
- **详情页**：状态横幅（状态 + 提示语）、收货地址、商品清单、金额明细（商品总额 / 运费 / 实付金额）、订单信息（编号 / 下单时间 / 支付方式 / 支付与发货时间等，为空的行自动隐藏）
- **主操作按钮**：按状态给出「去支付 / 提醒发货 / 确认收货 / 去评价 / 再次购买」；只有「再次购买」有接口支持（按明细逐条加入购物车并刷新角标），其余提示「演示接口未提供该操作」
- **状态与容错**：未登录展示「登录后查看订单」并可跳登录、空列表按是否筛选给出不同文案、接口失败展示 `AppErrorView` 与重试、支持下拉刷新；登录态变化时自动重新加载
- **宽屏适配**：tab 栏与列表内容统一收窄到 600 并居中，与购物车、订单确认页保持一致

### 我的收藏

- **进入方式**：「我的」页快捷入口（未登录先跳登录页）或直接访问 `/collect`
- **列表展示**：`HmCollectTile` 展示商品图、名称（两行截断）、价格与收藏时间，点击整行进入商品详情
- **分页加载**：`pageSize=10`，滚动到距底部 200px 时追加下一页，底部展示「加载中 / 没有更多收藏了」
- **只读设计**：接口公开的只有 `GET /member/collect`，收藏与取消收藏的入参试遍都返回 400（`code: 10017`），因此页面不放置「取消收藏」按钮，避免给出点了必然失败的入口
- **字段兜底**：演示账号的收藏为空，items 的字段名无法用真实数据验证，模型对 `goodsId|spuId|goods_id`、`name|goodsName|title`、`picture|image|goodsPicture`、`price|goodsPrice` 等常见命名做了多组兜底；字段缺失只影响展示（名称缺失显示「商品信息已失效」、图片缺失显示占位图、名称与价格都缺失时连 `￥0.00` 也不渲染、无商品 id 时卡片不可点），不会抛异常
- **状态与容错**：未登录展示「登录后查看收藏」并可跳登录、空列表展示「还没有收藏」并可去逛逛、接口失败展示 `AppErrorView` 与重试、支持下拉刷新；登录态变化时自动重新加载
- **宽屏适配**：列表内容收窄到 600 并居中

### 客服中心

- **在线客服**：展示服务时间（每天 09:00 - 21:00），点击「联系客服」提示演示接口未提供在线客服并给出客服热线
- **联系方式**：客服热线支持一键复制（`Clipboard` + Toast 反馈），并展示服务邮箱
- **常见问题**：`ExpansionTile` 折叠四项 FAQ（退换货、发货时效、运费、发票），展开查看回答
- 接口侧没有任何客服端点，本页是纯静态内容，路线为 `/customer-service`，因此在任意尺寸下都可直接访问

### 我的足迹

- **本地存储**：后端足迹接口 `/member/footprint` 返回 404，因此浏览记录只存在本机（`shared_preferences` 的 `hm_shop_footprint` 键，`FootprintStore` 负责读写），最多保留最近 50 条
- **埋点位置**：商品详情页加载成功后写入一条（`FootprintItem.fromGoodsDetail`），同一商品重复浏览只更新时间并提到最前，不产生重复项
- **分组展示**：按浏览时间切成「今天 / 昨天 / 更早」三段，`HmFootprintTile` 展示商品图、名称、价格与 `HH:mm 浏览`；点卡片回到商品详情，返回后重新读一次让时间与排序刷新
- **清空**：右上角「清空」二次确认后删除本机记录并回到空态
- **空态与降级**：没有记录时展示「还没有足迹」与「去逛逛」；存储内容损坏（被手工改过、旧格式）时按空列表处理，不抛异常
- 页面底部注明「足迹仅保存在本机，最多保留 50 条」，避免被误认为服务端数据

### 会员权益

- **纯静态页**：没有会员接口（`/member/vip` 等均不存在），页面只做权益说明，路线为 `/vip`
- **权益清单**：无限免邮、会员专享价、生日礼包、优先客服四项，每项一个图标 + 标题 + 说明
- **不伪造会员状态**：不写本地标记、不显示「已开通」，卡片上固定标「未开通」，底部「立即开通」只提示「会员开通暂未开放，敬请期待」
- **说明文案**：底部注明权益为演示内容、未接入真实开通流程，不会产生扣费

### 个人资料

- **进入方式**：「我的」页点头像或昵称进入，路线为 `/profile`，未登录时该区域仍跳登录页
- **数据来源**：`GET /member/profile` 回填昵称、性别、生日、职业、所在地与账号；加载中展示进度条，失败展示 `AppErrorView` 与「重新加载」
- **可改字段**：昵称（文本框，上限 20 字，去空格后不能为空）、性别（底部弹层单选）、生日（`showDatePicker`，范围 1900 年至今）、职业（文本框）
- **只提交改动**：`PUT /member/profile` 实测是「传了才改」的局部更新，因此保存前与拉取到的原始资料逐字段比对，只把改过的字段放进请求体；没有改动时直接提示「资料没有改动」，不发请求
- **前端自校验**：后端对昵称长度、空值、性别取值几乎不做校验（空昵称、单字昵称、任意性别都返回成功），这些约束全部由页面负责
- **保存结果**：返回体带新的 `token`，保存成功后写回 `TokenManager` 并更新 `UserController`，「我的」页头像与昵称随 `Obx` 立即刷新，随后关闭 Loading、Toast 提示并返回上一页
- **字段合并**：返回体不一定带全字段（如 `mobile`、`cityCode`），保存后用「非空才覆盖」的方式合并进本地用户信息，避免其它页面的展示丢数据
- **不可改项**：头像上传接口不存在（`POST /member/profile/avatar` 返回 500、`PUT` 返回 400），所在地也没有地区数据源，这两项只读并在页面底部说明

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

- **底部导航**：首页 / 分类 / 购物车 / 我的，使用 `IndexedStack` 保持各页面状态，但**首次切到某个 tab 才真正构建它**——四个页面一次性建出来时，登录态下冷启动会发 14 个请求（首页 6 + 分类 2 + 购物车 1 + 我的 5），懒加载后首屏只发首页的 6 个；购物车 tab 带件数角标；`PopScope` 让 Android 返回键在非首页 tab 时先回到首页，而不是直接退出
- **轮播随 tab 暂停**：首页被 `IndexedStack` 保活，`HmSlider` 通过 `HomeView(isActive: ...)` 拿到可见性，切到其它 tab 时把 `autoPlay` 置 false，`carousel_slider` 会在 `didUpdateWidget` 里取消定时器，回到首页再恢复
- **应用标识**：三端应用名统一为「美荟商城」，图标是品牌橙渐变 + 白色购物袋（母版 `docs/icon/app_icon_1024.png`，由 `tool/generate_icons.py` 生成三端全部尺寸），替换掉 Flutter 模板默认图标；详见「移动端打包」里的「应用名与图标」
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
- **自动化测试**：192 个用例，覆盖网络层拦截与业务码、模型反序列化容错与接口结构校验、金额整数累加、全局用户态与购物车件数、本地足迹存储（去重 / 上限 / 损坏数据）、足迹分组、骨架屏、商品聚合组件、规格选择弹层、订单组件、「我的」页面组件、分类页组件、购物车组件、收藏卡片、未知路由兜底与深链解析，以及首页 / 购物车 / 登录 / 分类 / 分类商品列表 / 商品详情 / 订单确认 / 订单列表 / 订单详情 / 我的收藏 / 客服中心 / 我的足迹 / 会员权益 / 个人资料十四个页面的页面级交互、「我的」页快捷入口接线与订单角标、首页分类入口切 tab 并选中分类、底部 tab 懒加载（首屏只发首页请求 / 切 tab 才加载对应页 / 来回切不重复请求 / 轮播随 tab 暂停与恢复）（用 `MockAdapter` 替换 Dio 适配器，不发真实请求）
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
│   ├── order.dart              # 结算信息 / 提交订单 / 订单列表与详情 / 删除订单
│   ├── collect.dart            # 我的收藏列表
│   ├── cart.dart               # 购物车列表 / 件数 / 增删改
│   ├── category.dart           # 分类下的商品
│   ├── mine.dart               # 猜你喜欢分页接口
│   └── user.dart               # 登录 / 用户信息接口
├── components/
│   ├── common/                 # 跨页面通用组件
│   │   ├── hm_bottom_bar.dart  # 底部操作栏容器 / 价格 / 按钮
│   │   ├── hm_goods_card.dart  # 商品卡片（图片 / 标题 / 价格 / 付款人数）
│   │   ├── hm_empty_view.dart  # 通用空态（图标 / 标题 / 说明 / 按钮）
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
│   ├── Order/                  # 订单列表 / 详情组件
│   │   ├── hm_order_status_tabs.dart # 状态筛选 tab
│   │   ├── hm_order_card.dart        # 订单卡片（商品行 / 金额 / 操作按钮）
│   │   ├── hm_order_sku_row.dart     # 订单内商品行
│   │   └── hm_order_info_row.dart    # 详情页「标签 - 值」行
│   ├── Collect/                # 收藏列表组件
│   │   └── hm_collect_tile.dart      # 收藏条目（图片 / 名称 / 价格 / 收藏时间）
│   ├── Footprint/              # 足迹列表组件
│   │   └── hm_footprint_tile.dart    # 足迹条目（图片 / 名称 / 价格 / 浏览时间）
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
│   ├── order_list.dart         # 订单列表 / 详情模型与状态枚举（OrderState）
│   ├── collect.dart            # 收藏列表模型（字段名多组兜底）
│   ├── footprint.dart          # 本地足迹模型与「今天 / 昨天 / 更早」分组
│   ├── cart.dart               # 购物车条目模型（含小计与结算条件）
│   ├── category_goods.dart     # 分类下的商品与同级分类
│   └── user.dart               # 用户信息模型
├── pages/
│   ├── Main/index.dart         # 底部 Tab 容器
│   ├── Home/
│   │   ├── index.dart          # 首页数据加载与模块拼装
│   │   └── skeleton.dart       # 首页骨架屏
│   ├── GoodsDetail/index.dart  # 商品详情页
│   ├── OrderConfirm/index.dart # 订单确认页
│   ├── OrderList/index.dart    # 订单列表：状态筛选 + 分页 + 删除
│   ├── OrderDetail/index.dart  # 订单详情：状态 / 地址 / 金额明细 / 删除
│   ├── Collect/index.dart      # 我的收藏：分页列表 / 未登录 / 空态
│   ├── CustomerService/index.dart # 客服中心：服务时间 / 联系方式 / 常见问题
│   ├── Footprint/index.dart    # 我的足迹：本地记录分组展示 / 清空
│   ├── Vip/index.dart          # 会员权益：纯静态权益说明
│   ├── Profile/index.dart      # 个人资料：昵称 / 性别 / 生日 / 职业编辑
│   ├── Category/index.dart     # 分类页：一级导航 + 二级宫格 + 推荐
│   ├── GoodsList/index.dart    # 分类商品列表：同级分类切换 + 商品网格
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
│   ├── cart_controller.dart    # GetX 全局购物车件数（底部角标）
│   └── footprint_store.dart    # 本地足迹读写（去重 / 50 条上限）
├── utils/
│   ├── dio_request.dart        # Dio 单例封装（注入 token、401 处理）
│   ├── api_exception.dart      # ApiException / NetworkException / resolveErrorMessage
│   ├── money.dart              # 金额按「分」整数累加（parseCents / formatCents）
│   ├── loading_dialog.dart     # 统一加载中对话框
│   ├── order_actions.dart      # 订单删除确认与主操作（再次购买）复用逻辑
│   ├── web_url_strategy.dart   # Web 真实路径策略的跨平台门面（条件导入）
│   └── toast_utils.dart        # 自适应宽度 Toast
├── assets/                     # 底部导航图标、我的页图标、首页装饰图（WebP）等资源
└── main.dart                   # 程序入口（注册全局状态、兜底未捕获异步异常）
```

```text
tool/
└── generate_icons.py           # 生成 Android / iOS / Web 三端全部尺寸的应用图标
docs/
├── mine-page-plan.md           # 「我的」页功能规划（三批已全部落地）
└── icon/app_icon_1024.png      # 应用图标母版
```

```text
test/
├── helpers/mock_http.dart      # MockAdapter 与响应 / 数据构造工具
├── dio_request_test.dart       # 网络层：业务码、超时、401、鉴权头
├── models_test.dart            # 反序列化工具与模型容错
├── user_controller_test.dart   # 全局用户态
├── sku_selector_test.dart      # 规格选择弹层
├── category_components_test.dart # 分类页组件
├── goods_list_test.dart        # 分类商品列表页：渲染 / 跳转 / 切换 / 重试 / 空态
├── mine_components_test.dart   # 「我的」页面组件
├── cart_test.dart              # 购物车模型 / 组件 / 全局件数
├── pages_test.dart             # 页面级交互（购物车 / 登录 / 分类）
├── pages_flow_test.dart        # 商品详情页与订单确认页的成功 / 失败 / 缺参
├── order_pages_test.dart       # 订单列表与详情页：筛选 / 删除 / 主操作 / 空态与未登录
├── collect_pages_test.dart     # 收藏页 / 客服中心页 / 「我的」页快捷入口接线
├── footprint_test.dart         # 本地足迹存储与分组 / 足迹页 / 会员权益页 / 订单角标
├── profile_test.dart           # 个人资料页：回填 / 只提交改动 / 校验 / 失败重试 / 入口
├── cart_api_test.dart          # 购物车接口层：方法、路径、入参与解析
├── loading_dialog_test.dart    # 加载弹窗的展示、重复展示与关闭
├── home_page_test.dart         # 首页并发加载、部分失败降级、整页错误重试
├── category_selection_test.dart # 首页分类入口 → 分类页选中（组件回调 / 外部选中 / 切 tab）
├── main_tabs_test.dart         # 底部 tab 懒加载 / 保活 / 轮播随 tab 暂停
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
| `/goods/list?categoryId=<分类 id>&title=<分类名>` | `GoodsListPage` | `categoryId`、`title` |
| `/order/confirm?skuId=<sku>&count=<数量>` | `OrderConfirmPage` | `skuId`、`count` |
| `/orders?state=<订单状态>` | `OrderListPage` | `state`（缺省为 0，即全部） |
| `/orders/detail?id=<订单 id>` | `OrderDetailPage` | `id` |
| `/collect` | `CollectPage` | 无 |
| `/customer-service` | `CustomerServicePage` | 无 |
| `/footprint` | `FootprintPage` | 无 |
| `/vip` | `VipBenefitsPage` | 无 |
| `/profile` | `ProfilePage` | 无 |

解析规则在 `buildRoute` 里：查询串会转成 `RouteSettings.arguments` 传给页面，站内 `pushNamed` 传入的 `arguments` 优先级更高；匹配不到的路由交给 `onUnknownRoute`，渲染 `UnknownRoutePage`（而不是白屏）。

初始路由栈由 `buildInitialRoutes` 自己拼：Flutter 默认会把 `/goods/list?...` 逐段拆成 `/` → `/goods` → `/goods/list?...`，中间那层是没有 id 的商品详情页（从深链按返回会落到「商品信息缺失」的错误态）。现在固定压成「首页 + 目标页」两层，深链直接落到目标页，返回键回到首页。

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
| GET | `/category/sub/filter` | 分类下的商品，参数 `id`（**传 `categoryId` 会 500**）；一次返回该分类全部商品与同级分类（`categories`），**不支持分页**，映射为 `CategoryGoodsResult` |
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
| GET | `/member/order` | 订单列表，参数 `page`、`pageSize`、`orderState`（0 表示全部，可不传），映射为 `OrderListResult` |
| GET | `/member/order/{id}` | 订单详情，比列表多收货人、支付方式与各环节时间，映射为 `OrderDetail` |
| DELETE | `/member/order` | 删除订单，请求体 `{"ids": [订单 id, ...]}`（放 query 会报缺少请求体） |
| GET | `/member/collect` | 我的收藏，参数 `collectType`（**必填，只接受 1 / 2**，缺失或其它值都会 500）、`page`、`pageSize`，映射为 `CollectListResult`；`POST /member/collect` 存在但入参试遍都返回 `400 code: 10017`，因此不提供收藏 / 取消收藏 |
| POST | `/login` | 账号密码登录，返回用户信息（含 `token`），映射为 `UserInfo` |
| GET | `/member/profile` | 获取当前登录用户信息（携带 token），映射为 `UserInfo` |
| PUT | `/member/profile` | 修改个人资料，**传了才改**（只发 `nickname` 时其余字段保持不变），返回完整资料与新 `token`；后端对昵称空值 / 长度、性别取值几乎不校验，约束由前端负责。`avatar` 字段会被忽略，头像上传接口不存在（`POST /member/profile/avatar` 500、`PUT` 400） |

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
4. 覆盖率阈值：整体可执行行覆盖率低于 **80%** 直接失败（当前 3071 / 3532 行 = 86.9%）。注意 lcov 只统计「被测试真正加载过」的文件，新增一个 import 就会改变分母——路由测试 import 了 `routes/index.dart`，把全部页面一起纳入统计
5. `flutter build web --release` 构建冒烟 —— 资源路径、条件导入这类问题 analyze 与 test 都发现不了

同一分支连续推送时，`concurrency` 会取消上一次仍在跑的检查，避免队列堆积。`.github/workflows/web.yml` 另行构建 Web 产物并通过 GitHub Pages 部署。

### 关于 SDK 版本

两个 workflow 都固定 `flutter-version: '3.47.9'`，而不是跟着 `channel: stable` 走。

原因是 Flutter 3.48 起给 `package:flutter/material.dart` 加了 `@Deprecated`，官方要求改用 `package:material_ui/material_ui.dart`。本项目所有源文件仍从 `package:flutter/material.dart` 引入，在 `--fatal-infos` 下这会让 CI 直接失败（实测 56 条 info）。暂时不迁移的理由是：`material_ui` 目前是独立实现，而 `get`、`carousel_slider` 仍从 `package:flutter/material.dart` 取类型，两边混用会出现同名但不同源的 `ThemeData`、`MaterialApp` 等类型。等依赖跟进后再一次性升级 SDK、替换全库 import，并重新跑一遍深链与规格弹层的浏览器验证。

### 关于 `--wasm`

试过 `flutter build web --release --wasm`，Chrome 150 下可以正常渲染、无控制台报错，体积也确实更小：`main.dart.wasm` 2392 KB，对比 `main.dart.js` 2832 KB（-15%）；首屏实测 6 个请求 / 2448 KB，对比 JS 版 9 个请求 / 2928 KB（禁用缓存）。

但默认构建仍然保留 JS，原因是：skwasm 要多线程渲染需要 `Cross-Origin-Opener-Policy` + `Cross-Origin-Embedder-Policy` 两个响应头，而 GitHub Pages 不支持自定义响应头；同时 wasm 产物会把 canvaskit 的各套变体和 JS 兜底一起带上，目录体积反而从 40.29 MB 涨到 42.65 MB。等换成支持自定义头部的托管再切，命令只需给 CI 的构建步骤加上 `--wasm`。

### 移动端打包（Android / iOS）

`.github/workflows/mobile.yml` 与 Web 流水线互不影响，单独产出移动端安装包：产物既在 Actions 运行页的 Artifacts 区，也会在**打 `v*` 标签时汇总发布到 GitHub Releases**（Releases 页面直接点 apk 就能下载安装）。

| Job | Runner | 产物 |
| --- | --- | --- |
| `build-android` | `ubuntu-latest` + JDK 17 | `app-arm64-v8a-release.apk`（18.4 MB）、`app-armeabi-v7a-release.apk`（15.9 MB）、`app-x86_64-release.apk`（19.8 MB）、`app-release.aab`（51.0 MB） |
| `build-ios` | `macos-15` | 未签名的 `Runner.app.zip`（只验证能否编译） |
| `build-ios-signed` | `macos-15` | 配好签名 Secrets 后产出的可安装 `Runner.ipa`（仅打标签 / 手动触发时运行） |

触发方式是 push 到 `master`、打 `v*` 标签或手动 `workflow_dispatch`；同一分支只跑最新一次（`concurrency` 取消排队中的旧任务）。三点前提必须知道：

1. **Gradle 必须 ≥ 9.3.1。** Flutter 3.47.9 模板里的 AGP 是 `9.1.0`，它在 apply 阶段就会校验 Gradle 版本，用 8.x 会直接失败（`Minimum supported Gradle version is 9.3.1. Current version is 8.14.`）。`android/gradle/wrapper/gradle-wrapper.properties` 已指向腾讯镜像的 `gradle-9.3.1-all.zip`（换成官方 `services.gradle.org` 同理，镜像只是国内下载快）。另外 `android/gradle.properties` 的 JVM 参数从 `-Xmx8G` 降到 `-Xmx4G`、并关掉 `kotlin.incremental`（Windows 上会遇到 `Could not close incremental caches` 导致 release 构建失败，关掉更稳）。
2. **签名材料全部走 Secrets，缺了自动降级。** `android/app/build.gradle.kts` 会读 `android/key.properties`：文件存在就用 release 签名（可上架），不存在就退回 debug 签名（可安装、不能上架）。CI 上只要配了 `ANDROID_KEYSTORE_BASE64` 就会自动写出这个文件，构建后再用 `apksigner --print-certs` 把实际证书打印出来，避免「以为配了正式签名、其实还在走 debug」这种静默错误。本地配置方式见 `android/key.properties.example`（`key.properties`、`*.jks`、`*.keystore` 都已在 `.gitignore` 里）。
3. **iOS 出 IPA 必须有 Apple 开发者账号。** 项目使用 Swift Package Manager（没有 `Podfile`），因此不需要 `pod install`；`build-ios` 走 `--no-codesign` 只验证编译，`build-ios-signed` 才会导入证书与描述文件、给工程补上 `DEVELOPMENT_TEAM`，再执行 `flutter build ipa`。

#### 应用名与图标

三端的应用名统一为「美荟商城」：Android 在 `android/app/src/main/AndroidManifest.xml` 的 `android:label`，iOS 在 `ios/Runner/Info.plist` 的 `CFBundleDisplayName`（`CFBundleName` 保留 `hm_shop` 作为内部短名），Web 在 `web/index.html` 的 `<title>` 与 `web/manifest.json` 的 `name` / `short_name`。改名前 Android 显示 `hm_shop`、iOS 显示 `Hm Shop`，和 Web 的「美荟商城」不一致。

图标是品牌橙渐变底 + 白色购物袋，母版在 `docs/icon/app_icon_1024.png`，由 `tool/generate_icons.py` 一次性生成全部尺寸：

- Android：`mipmap-mdpi` 到 `mipmap-xxxhdpi` 五档 `ic_launcher.png`（48 / 72 / 96 / 144 / 192），圆角方形（半径 22%）。
- iOS：`AppIcon.appiconset` 里 `Contents.json` 声明的 13 个尺寸，直角满幅且不带透明通道（iOS 自己裁圆角）。
- Web：`web/favicon.png`、`Icon-192/512.png` 与两个 `Icon-maskable-*.png`（maskable 变体把图形缩到 72%，留出系统裁切的安全区）。

要改图标就改脚本里的颜色 / 几何参数（或直接替换母版 PNG）后重跑 `python tool/generate_icons.py`；脚本需要 Pillow，这只是工具的一次性依赖，不在 `pubspec.yaml` 里。Android 目前没有做 adaptive icon（`mipmap-anydpi-v26`），部分 Android 8+ 桌面会把这张图套进系统蒙版里显示，需要时再补 foreground / background 两层。

需要的 Secrets（前四个管 Android，后四个管 iOS），都是可选的——没配就跳过对应能力：

| Secret | 说明 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | release keystore 的 base64：`base64 -w0 upload-keystore.jks` |
| `ANDROID_STORE_PASSWORD` / `ANDROID_KEY_PASSWORD` | 密钥库口令 / 密钥口令 |
| `ANDROID_KEY_ALIAS` | 密钥别名，缺省 `upload` |
| `IOS_CERTIFICATE_BASE64` / `IOS_CERTIFICATE_PASSWORD` | 发布证书 `.p12` 的 base64，以及导出时设置的口令 |
| `IOS_PROVISIONING_PROFILE_BASE64` | `.mobileprovision` 描述文件的 base64 |
| `IOS_TEAM_ID` | Apple 开发者 Team ID（10 位） |

另外两个可选 Repository variable（不是 Secret）：`IOS_BUNDLE_ID`（要替换成的 Bundle Identifier，缺省沿用 `com.example.hmShop`）、`IOS_EXPORT_METHOD`（`ad-hoc` 装指定设备，`app-store-connect` 传 App Store，缺省 `ad-hoc`）。

本机实测（Windows + Flutter 3.47.9 + AGP 9.1.0 / Gradle 9.3.1）：干净检出后 `flutter build apk --release` 52.3 MB、`--split-per-abi` 三个包如上表、`flutter build appbundle --release` 51.0 MB，全部构建成功；把测试 keystore 放进 `android/app/` 后 `apksigner verify --print-certs` 输出 `CN=HM Shop Test`，删掉 `key.properties` 重新构建则回到 `CN=Android Debug`——有/无密钥两条路径都验证过。CI 上也验证了降级路径：没配 Secrets 时 Android job 的「Decode release keystore」显示 skipped、「Verify APK signature」打印出 `CN=Android Debug`，iOS 签名 job 在 push 场景下整个 job 是 skipped。macOS 签名链路无法在本机验证，配上 Secrets 打 `v*` 标签即可验证。

#### 发布到 GitHub Releases

`publish-release` job 会把 `build-android`、`build-ios`（以及配了签名时的 `build-ios-signed`）的产物汇总成一个 Release，并自动生成说明（选哪个 apk、签名状态如何）：

| 触发方式 | 效果 |
| --- | --- |
| `git tag v1.0.1 && git push origin v1.0.1` | 用该 tag 建 Release，标题 `HM Shop v1.0.1` |
| Actions 页手动 Run workflow | 勾选 `publish_release`（默认勾上），tag 留空则用 `v<包内版本号>-build.<run number>`（如 `v1.0.1-build.12`），也可自己填 |
| push 到 `master` / PR | 只产出 Actions Artifacts，不发 Release（避免每次提交都刷一条 release） |

细节：

- Release 里带 `app-arm64-v8a-release.apk`（首选）、`app-armeabi-v7a-release.apk`、`app-x86_64-release.apk`、`app-release.aab`、`Runner.app.zip`，配了 iOS 签名时再加 `Runner.ipa`；
- 同一个 tag 重复发版时会走 `gh release upload --clobber` 覆盖资产，不会报错；
- 这个 job 需要 `contents: write` 权限（workflow 里已显式声明）。**注意仓库级开关**：Settings → Actions → General → Workflow permissions 如果是「Read repository contents」，`GITHUB_TOKEN` 会被钉死成只读，工作流里再怎么声明 `permissions: contents: write` 也提不上去，`gh release create` 直接 403。本仓库已调整为「Read and write permissions」；
- 两个容易踩的实现细节，都已在 workflow 里处理：① `actions/download-artifact` 下载时会**保留上传时的相对路径**（`flutter-apk/`、`bundle/release/`），所以收集文件必须用 `find dist -type f -name '*.apk'`，用 `dist/*.apk` 只能匹配到平铺的 `Runner.app.zip`；② `gh release` 必须在 git 仓库里执行，job 里要先 `actions/checkout`（或者给 gh 传 `--repo owner/name`），否则报 `fatal: not a git repository`。

#### 版本号与更新日志

- 版本号的唯一来源是 `pubspec.yaml` 的 `version: 1.0.1+2`：`+` 前是 `versionName`、后是 `versionCode`，两者都会写进 APK / AAB / IPA。
- 改版本号时同步在 [CHANGELOG.md](CHANGELOG.md) 顶部补一段 `## [1.0.1] - YYYY-MM-DD`，写清这个版本改了什么。
- 打 `v1.0.1` 标签后，`publish-release` 会用 `awk` 从 CHANGELOG 里抽出该版本段落，放在 Release 说明开头作为「本次更新」，后面再接安装包表格与安装提示。段落缺失时只在日志里打一条 notice，不会阻断发布。
- 手动触发时 tag 的缺省值也来自包内版本号（`v1.0.1-build.<run number>`），不再是写死的 `v1.0.0`。

## 当前状态与已知问题

- 顶部搜索框仍为静态占位，点击提示「功能开发中」（接口侧没有搜索端点）。
- 「我的足迹」与「会员权益」都是**纯前端**能力：`GET /member/footprint` 在接口侧不存在（404），足迹只存本机 `shared_preferences`（最多 50 条，换设备或清缓存即丢失）；会员没有开通接口，权益页只做说明，不写本地会员标记。
- 收藏只做只读列表：`GET /member/collect` 可用（`collectType` 必填且只接受 1 / 2），但写接口 `POST /member/collect` 用 `goodsId` / `spuId` / `skuId` / `id` 与 `collectType` 的各种组合都返回 `400 code: 10017`，无法确定入参，因此不提供收藏与取消收藏按钮。演示账号的收藏为空，items 的字段名也无法用真实数据验证，模型按常见命名做了多组兜底。
- 个人资料只能改「后端肯收」的字段：`PUT /member/profile` 是「传了才改」的局部更新，但后端对昵称空值 / 长度、性别取值几乎不校验（空昵称、单字昵称、任意性别都返回成功），这些约束全在前端；`avatar` 字段传了会被忽略，头像上传接口不存在（`POST /member/profile/avatar` 500、`PUT` 400），所在地也没有地区数据源，因此头像与所在地在资料页只读。
- 订单的「去支付 / 提醒发货 / 确认收货 / 去评价」没有对应接口（`PUT /member/order`、`/member/order/pay/*`、`/member/order/cancel/*`、`/member/order/consume/*`、`/member/order/status/*` 均不存在），点击只提示「演示接口未提供该操作」；只有「再次购买」通过逐条加入购物车实现。`GET /member/order/count` 存在但需要参数且实测仍返回 400，所以「我的」页的订单角标是拿四次 `pageSize=1` 的列表查询取 `counts` 折算出来的，订单列表页的状态 tab 上不显示数量。
- 分类商品接口 `/category/sub/filter?id=` **不支持分页**（`page`/`pageSize` 会被忽略），一次返回该分类全部商品；实测单个二级分类最多 16 件，因此商品列表页不做分页，只提供下拉刷新。33 个二级分类里有 8 个本身没有商品，进入后展示空态。
- 购物车结算复用「立即购买」链路（`/member/order/pre/now` + `/member/order`），**接口只支持单件商品结算**，因此多选时点击「结算」会提示只勾选一件。
- 接口没有「全选 / 批量勾选」的接口（`PUT /member/cart` 与 `PUT /member/cart/checked` 均不存在），「全选」是逐条 `PUT /member/cart/{skuId}` 串行完成的，条目很多时会较慢。
- Web 端已启用真实路径与未知路由兜底：`/goods?id=...` 这类深链可以直接访问、刷新后仍停在同一页；但深链只携带查询串，像 `/order/confirm` 这种强依赖 `skuId` 的页面在参数缺失时会落到页面的错误态，而不是给出「链接参数缺失」的专门提示。
- GitHub Pages 用 `404.html` 实现深链回退，代价是「不存在的路径」也返回 HTTP 200，对 SEO 不友好；这是静态托管的通用取舍，不是代码问题。
- 首页分类入口只能跳到「分类」页的对应一级分类，不能直达商品列表：分类商品接口 `/category/sub/filter?id=` 只接受**二级分类 id**，一级分类没有对应的商品列表接口。
- 覆盖率只统计「被测试真正加载过」的文件（lcov 的统计口径）。首页轮播、首页装饰区块、分类左栏、商品详情的品牌与参数区块等纯展示组件仍未被测试加载，`lib/pages/Main/index.dart` 现已由首页分类入口用例覆盖到 tab 切换与选中项下传、由底部 tab 用例覆盖到懒加载 / 保活 / 轮播暂停（`lib/pages/Mine/index.dart` 现已由快捷入口接线用例覆盖到列表加载、快捷入口与资料页入口）；CI 的 80% 阈值只约束已纳入统计的部分。
- `cupertino_icons` 在代码里没有被直接引用，但 GetX 内部组件引用其字体，删除后 `flutter build web` 会告警缺字体，因此保留（tree-shaking 后仅 1.4 KB）。
- 移动端的正式签名依赖仓库外凭证：默认（没配 Secrets）产出的是 debug 签名的 APK 与未签名的 `Runner.app`——能装进手机、不能上架；配好 `ANDROID_KEYSTORE_BASE64` 后 APK/AAB 自动变正式签名，配好 iOS 那四个 Secrets 后 `build-ios-signed` 才产出可安装的 IPA（`ad-hoc` 方式还需要把设备 UDID 加进描述文件）。签名脚手架已就位，缺的只是证书本身。详见「移动端打包（Android / iOS）」。
