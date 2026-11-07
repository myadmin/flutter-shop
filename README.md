# hm_shop

基于 Flutter 的商城类 App 示例项目，采用「页面 / 组件 / API / 模型」分层组织代码。当前以首页为核心，已接入黑马 meikou 接口完成轮播图、分类、特惠推荐、爆款推荐、一站全买的真实数据展示，并在加载期间展示骨架屏；分类、购物车、我的、登录等模块仍为占位页面。

## 功能概览

### 首页

- **骨架屏**：数据加载期间展示 `HomeSkeleton`，带呼吸闪烁动画；全部接口返回（或失败）后切换为真实内容
- **并行加载**：`Future.wait` 同时请求 5 个首页接口，单个接口失败不影响其余模块展示
- **轮播图**：`/home/banner` 获取图片，自动播放，底部指示点可点击切换
- **顶部搜索框**：叠加在轮播图上方的半透明搜索入口（静态展示，暂未接入搜索）
- **分类快捷入口**：`/home/category/head` 获取分类，横向滚动列表展示图标与名称
- **特惠推荐**：`/hot/preference` 获取数据，展示第一个子类型的前 3 个商品，含本地背景图与价格标签
- **爆款推荐 / 一站全买**：`/hot/inVogue`、`/hot/oneStop` 获取数据，左右两栏布局，复用 `HmHot` 组件，通过 `HmHotConfig` 区分场景样式
- **商品列表**：`SliverGrid` 双列布局（`HmMoreList` 仍为静态占位，分页接口待接入）

### 其他

- **底部导航**：首页 / 分类 / 购物车 / 我的，使用 `IndexedStack` 保持各页面状态
- **登录页**：已注册 `/login` 路由，页面内容待完善
- **网络层**：Dio 单例封装，统一超时、HTTP 状态拦截与业务状态码校验

## 技术栈

| 类别 | 说明 |
| --- | --- |
| 框架 | Flutter（stable channel），Dart SDK `^3.13.7` |
| 状态与路由 | `setState` + `MaterialApp` 命名路由 |
| 轮播组件 | [carousel_slider](https://pub.dev/packages/carousel_slider) `^5.1.2` |
| 网络请求 | [dio](https://pub.dev/packages/dio) `^5.11.1` |
| 代码规范 | `flutter_lints` `^6.0.0` |
| 运行平台 | Web（仓库当前仅包含 `web/` 平台目录） |

## 目录结构

```text
lib/
├── api/                    # 接口调用
│   └── home.dart           # 首页 5 个接口的请求函数
├── components/Home/        # 首页业务组件
│   ├── HmSlider.dart       # 轮播图 + 搜索框 + 指示点
│   ├── HmCategory.dart     # 分类横向列表
│   ├── HmSuggestion.dart   # 特惠推荐区
│   ├── HmHot.dart          # 爆款推荐 / 一站全买通用组件
│   └── HmMoreList.dart     # 双列商品列表（SliverGrid，静态占位）
├── constants/index.dart    # 全局常量、接口地址
├── models/home.dart        # 首页数据模型（Banner、分类、推荐、商品等）
├── pages/
│   ├── Main/index.dart     # 底部 Tab 容器
│   ├── Home/
│   │   ├── index.dart      # 首页数据加载与模块拼装
│   │   └── skeleton.dart   # 首页骨架屏
│   ├── Category/index.dart # 分类（占位）
│   ├── Cart/index.dart     # 购物车（占位）
│   ├── Mine/index.dart     # 我的（占位）
│   └── Login/index.dart    # 登录（占位）
├── routes/index.dart       # 路由与根 Widget
├── utils/DioRequest.dart   # Dio 单例封装
├── assets/                 # 底部导航图标、首页活动图等资源
└── main.dart               # 程序入口
```

## 路由

| 路径 | 页面 | 说明 |
| --- | --- | --- |
| `/` | `MainPage` | 底部 Tab 主容器 |
| `/login` | `LoginPage` | 登录页（占位） |

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

- 分类、购物车、我的、登录页面仅为占位文本，功能尚未开发。
- `HmMoreList` 商品列表为 10 条静态蓝色占位，分页接口尚未接入。
- 轮播图、商品卡片点击暂未接入跳转详情或加入购物车逻辑；顶部搜索框为静态展示。
- `test/widget_test.dart` 仍为计数器模板测试，与首页不匹配，`flutter test` 无法通过，需按首页交互重写。
- `models/home.dart` 中的 `HotInVogue*`、`OneStop*` 为独立数据模型，首页当前统一使用 `SpecialRecommendResult`，尚未启用。
