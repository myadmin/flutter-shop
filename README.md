# hm_shop

基于 Flutter 的商城类 App 示例项目，采用「页面 / 组件 / API / 模型」分层组织代码。当前以首页为核心，接入黑马 meikou 接口完成轮播图数据展示，后续可在此基础上继续扩展分类、购物车、个人中心等模块。

## 功能概览

- **首页**
  - 轮播图：远程接口获取 Banner 数据，支持自动播放、指示点切换、点击跳转
  - 顶部搜索框：叠加在轮播图上方的半透明搜索入口
  - 分类快捷入口：横向滚动列表
  - 推荐区、爆款推荐：左右两栏布局
  - 商品列表：`SliverGrid` 双列无限滚动
- **底部导航**：首页 / 分类 / 购物车 / 我的，使用 `IndexedStack` 保持页面状态
- **登录页**：已注册 `/login` 路由，页面内容待完善
- **网络层**：Dio 单例封装，统一超时、拦截器与业务状态码校验

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
│   └── home.dart           # 首页 Banner 接口
├── components/Home/        # 首页业务组件
│   ├── HmSlider.dart       # 轮播图 + 搜索框 + 指示点
│   ├── HmCategory.dart     # 分类横向列表
│   ├── HmSuggestion.dart   # 推荐区
│   ├── HmHot.dart          # 爆款推荐
│   └── HmMoreList.dart     # 双列商品列表（SliverGrid）
├── constants/index.dart    # 全局常量、接口地址
├── models/home.dart        # Banner 数据模型
├── pages/
│   ├── Main/index.dart     # 底部 Tab 容器
│   ├── Home/index.dart     # 首页
│   ├── Category/index.dart # 分类（占位）
│   ├── Cart/index.dart     # 购物车（占位）
│   ├── Mine/index.dart     # 我的（占位）
│   └── Login/index.dart    # 登录（占位）
├── routes/index.dart       # 路由与根 Widget
├── utils/DioRequest.dart   # Dio 单例封装
├── assets/                 # 底部导航图标
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
- 成功判定：响应 `code == '1'`，返回 `result` 字段

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/home/banner` | 获取首页轮播图列表，字段 `id`、`imgUrl` 映射为 `BannerItem.id`、`BannerItem.imageUrl` |

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
- 首页的分类、推荐、爆款推荐、商品列表使用纯色块占位，数据接口待接入。
- `test/widget_test.dart` 仍为模板测试，引用了不存在的 `MyApp`，需更新后 `flutter test` 才能通过。
