# hm_shop

基于 Flutter 的商城类 App 示例项目，采用「页面 / 组件 / API / 模型 / 状态」分层组织代码。当前已接入黑马 meikou 接口完成首页（轮播图、分类、特惠推荐、爆款推荐、一站全买、推荐列表分页）、登录（含 token 持久化与请求鉴权）与「我的」页面（用户信息、会员卡、订单入口、退出登录、猜你喜欢分页）；分类、购物车仍为占位页面。

## 功能概览

### 首页

- **骨架屏**：数据加载期间展示 `HomeSkeleton`，带呼吸闪烁动画；全部接口返回（或失败）后切换为真实内容
- **并行加载**：`Future.wait` 同时请求 6 个首页接口，单个接口失败不影响其余模块展示
- **下拉刷新**：`RefreshIndicator` 重新拉取全部首页数据
- **轮播图**：`/home/banner` 获取图片，自动播放，底部指示点可点击切换
- **顶部搜索框**：叠加在轮播图上方的半透明搜索入口（静态展示，暂未接入搜索）
- **分类快捷入口**：`/home/category/head` 获取分类，横向滚动列表展示图标与名称
- **特惠推荐**：`/hot/preference` 获取数据，展示第一个子类型的前 3 个商品，含本地背景图与价格标签
- **爆款推荐 / 一站全买**：`/hot/inVogue`、`/hot/oneStop` 获取数据，左右两栏布局，复用 `HmHot` 组件，通过 `HmHotConfig` 区分场景样式
- **推荐列表**：`/home/recommend` 获取数据，`HmMoreList` 以 `SliverGrid` 双列展示，滚动到底部时通过递增 `limit` 自动加载更多

### 我的

- **用户信息头部**：展示头像与账号；未登录时显示「立即登录」，点击跳转 `/login`
- **退出登录**：已登录时右上角显示「退出」，二次确认后清除本地 token 与用户信息
- **会员卡片**：展示美荟商城会员开通入口（静态）
- **快捷入口**：我的收藏、我的足迹、我的客服（静态）
- **订单管理**：我的订单、待付款、待发货、待收货、待评价（静态）
- **猜你喜欢**：`HmGuess` 作为吸顶标题（`SliverPersistentHeaderDelegate`），复用 `HmMoreList` 双列网格，调用 `/home/goods/guessLike` 按 `page`、`pageSize` 分页，滚动到底部自动加载

### 登录

- **账号密码表单**：手机号与密码正则校验，密码为 6-16 位字母、数字、下划线
- **协议勾选**：未勾选隐私条款 / 用户协议时拦截登录并 Toast 提示
- **登录状态**：请求期间展示 `LoadingDialog`，成功后写入 `UserController`、持久化 token 并返回上一页，失败 Toast 展示错误信息

### 其他

- **底部导航**：首页 / 分类 / 购物车 / 我的，使用 `IndexedStack` 保持各页面状态
- **状态管理**：GetX（`UserController` 保存登录用户信息，页面通过 `Obx` 响应式刷新）
- **登录态管理**：`TokenManager` 基于 `shared_preferences` 持久化 token；应用启动时若已登录，自动请求 `/member/profile` 恢复用户信息；Dio 请求拦截器自动注入 `Authorization: Bearer <token>`
- **网络层**：Dio 单例封装，统一超时、HTTP 状态拦截与业务状态码校验
- **加载弹窗**：`LoadingDialog` 提供统一的加载中对话框（`show` / `hide`）
- **Toast 工具**：`ToastUtils` 基于 `SnackBar`，宽度随文案自适应，并做 2 秒防重复弹出

## 技术栈

| 类别 | 说明 |
| --- | --- |
| 框架 | Flutter（stable channel），Dart SDK `^3.13.7` |
| 状态与路由 | `setState` + `MaterialApp` 命名路由 |
| 状态管理 | [get](https://pub.dev/packages/get) `^4.7.3` |
| 本地存储 | [shared_preferences](https://pub.dev/packages/shared_preferences) `^2.5.6` |
| 轮播组件 | [carousel_slider](https://pub.dev/packages/carousel_slider) `^5.1.2` |
| 网络请求 | [dio](https://pub.dev/packages/dio) `^5.11.1` |
| 代码规范 | `flutter_lints` `^6.0.0` |
| 运行平台 | Web（仓库当前仅包含 `web/` 平台目录） |

## 目录结构

```text
lib/
├── api/                    # 接口调用
│   ├── home.dart           # 首页 6 个接口的请求函数
│   ├── mine.dart           # 猜你喜欢分页接口
│   └── user.dart           # 登录 / 用户信息接口
├── components/
│   ├── Home/               # 首页业务组件
│   │   ├── hm_slider.dart  # 轮播图 + 搜索框 + 指示点
│   │   ├── hm_category.dart# 分类横向列表
│   │   ├── hm_suggestion.dart # 特惠推荐区
│   │   ├── hm_hot.dart     # 爆款推荐 / 一站全买通用组件
│   │   └── hm_more_list.dart # 双列商品网格（首页推荐 / 猜你喜欢共用）
│   └── Mine/
│       └── hm_guess.dart   # 「猜你喜欢」吸顶标题（SliverPersistentHeaderDelegate）
├── constants/index.dart    # 全局常量、接口地址
├── models/
│   ├── home.dart           # 首页数据模型（Banner、分类、推荐、商品等）
│   └── user.dart           # 用户信息模型
├── pages/
│   ├── Main/index.dart     # 底部 Tab 容器
│   ├── Home/
│   │   ├── index.dart      # 首页数据加载与模块拼装
│   │   └── skeleton.dart   # 首页骨架屏
│   ├── Category/index.dart # 分类（占位）
│   ├── Cart/index.dart     # 购物车（占位）
│   ├── Mine/index.dart     # 我的：用户信息、会员卡、订单、猜你喜欢
│   └── Login/index.dart    # 登录页
├── routes/index.dart       # 路由与根 Widget
├── stores/
│   ├── token_manager.dart  # token 本地持久化（shared_preferences）
│   └── user_controller.dart# GetX 用户状态（登录用户信息）
├── utils/
│   ├── dio_request.dart    # Dio 单例封装（自动注入 token）
│   ├── loading_dialog.dart # 统一加载中对话框
│   └── toast_utils.dart    # 自适应宽度 Toast
├── assets/                 # 底部导航图标、我的页图标、首页活动图等资源
└── main.dart               # 程序入口
```

## 路由

| 路径 | 页面 | 说明 |
| --- | --- | --- |
| `/` | `MainPage` | 底部 Tab 主容器 |
| `/login` | `LoginPage` | 账号密码登录页 |

## 接口说明

- Base URL：`https://meikou-api.itheima.net`
- 超时时间：10 秒（连接 / 发送 / 接收）
- 成功判定：响应 `code == '1'`，取 `result` 字段返回

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/home/banner` | 首页轮播图列表，`id`、`imgUrl` 映射为 `BannerItem.id`、`BannerItem.imageUrl` |
| GET | `/home/category/head` | 首页分类快捷入口，映射为 `CategoryItem` |
| GET | `/hot/preference` | 特惠推荐，映射为 `SpecialRecommendResult` |
| GET | `/hot/inVogue` | 爆款推荐，映射为 `SpecialRecommendResult` |
| GET | `/hot/oneStop` | 一站全买，映射为 `SpecialRecommendResult` |
| GET | `/home/recommend` | 推荐列表，`limit` 控制返回数量，滚动加载时递增 |
| GET | `/home/goods/guessLike` | 猜你喜欢分页列表，参数 `page`、`pageSize`，映射为 `GoodsDetailsItems` |
| POST | `/login` | 账号密码登录，返回用户信息（含 `token`），映射为 `UserInfo` |
| GET | `/member/profile` | 获取当前登录用户信息（携带 token），映射为 `UserInfo` |

## 快速开始

```bash
# 1. 安装依赖
flutter pub get

# 2. 启动 Web 版本
flutter run -d chrome

# 3. 静态分析
flutter analyze
```

## 当前状态与已知问题

- 分类、购物车页面仅为占位文本，功能尚未开发。
- 轮播图、商品卡片点击暂未接入详情页或加入购物车逻辑；顶部搜索框为静态展示。
- 我的页面会员卡、快捷入口、订单管理暂未接入交互。
