# 「我的」页面规划（自上而下）

> 目标：把「我的」页里目前点了只弹「功能开发中」的入口，逐个补成可用页面。
> 本文只做规划，不含代码；接口能力均为**实测**结果（2026-11-21，测试账号 `13800138000`）。

## 现状

| 区块 | 组件 | 现在点了会怎样 |
| --- | --- | --- |
| 用户头部 | `HmMineHeader` | 已登录显示昵称 + 退出（二次确认）；未登录可点进登录页 |
| 会员卡 | `HmMineVipCard` | toast「会员开通功能开发中」 |
| 快捷入口 | `HmMineQuickActions` | 我的收藏 / 我的足迹 / 我的客服 → toast |
| 订单管理 | `HmMineOrderModule` | 我的订单 / 待付款 / 待发货 / 待收货 / 待评价 → toast |
| 猜你喜欢 | `HmGuess` + `HmMoreList` | 已可用，可进商品详情 |

所有占位逻辑集中在 `lib/pages/Mine/index.dart` 的 `_showComingSoon(feature)`。

---

## 一、用户头部（保留，微调）

- **已登录**：头像、昵称、退出登录（已有）
- **未登录**：头像占位 + 「点击登录」，点击进入登录页（已有）
- **可选增强**：点头像/昵称进入「个人资料」页，展示昵称、性别、生日、城市、职业
  - 数据已在 `UserInfo` 里（`/member/profile` 返回），无需新接口
  - 优先级 P2，只读展示即可（无修改资料接口）

## 二、会员卡

- **后端能力**：无。`/member/vip`、`/member/member` 之类均不存在，只有卡片文案是静态的
- **规划**：新建「会员权益」页（纯静态）
  - 权益列表：无限免邮、会员专享价、生日礼包、优先客服
  - 底部「立即开通」→ 提示「暂未开放，敬请期待」
  - 不伪造会员状态（本地打标记会造成「假会员」误导，不做）
- 优先级 P2

## 三、快捷入口（3 个）

### 3.1 我的收藏

- **接口**：`GET /member/collect?collectType=1&page=&pageSize=` → 200，返回 `{counts, pages, items[]}`
  - 测试账号当前 0 条，`items` 字段结构待实装时按返回适配（预计与商品卡片同构：id/name/picture/price）
  - `collectType=2` 也返回 200（另一种收藏类型，语义待确认，本页只用 1）
- **页面**：网格列表，复用 `HmGoodsCard`，支持下拉刷新 + 分页，点击进商品详情
- **空态**：「还没有收藏的商品」+「去逛逛」按钮跳首页
- **限制**：新增/取消收藏接口存在（`POST /member/collect`，入参 `MemberCollectVo`），但实测多种字段组合均返回「参数错误」，暂不做「取消收藏」，二期逆向后再补
- 优先级 P1

### 3.2 我的足迹

- **后端能力**：无。`/member/footprint` 返回 **404**
- **方案**：本地足迹
  - `shared_preferences` 存最近 50 条 `{goodsId, name, picture, price, viewedAt}`
  - 埋点位置：商品详情页加载成功后写入（同一商品重复浏览只更新时间并提到最前）
  - 页面按「今天 / 昨天 / 更早」分组，卡片列表，右上角「清空」
  - UI 上注明「足迹仅保存在本机」
- 优先级 P2

### 3.3 我的客服

- **后端能力**：无接口
- **方案**：纯静态页
  - 常见问题手风琴：订单查询、配送时效、退换货、发票
  - 客服时间、客服电话（可点击复制）、「在线客服」按钮 → 提示
- 优先级 P1（工作量小）

## 四、订单管理（接口最全，价值最高）

### 4.1 订单列表页

- **路由**：`/orders?state=<orderState>`
- **顶部 tab**：全部 / 待付款 / 待发货 / 待收货 / 待评价 → `orderState` 0 / 1 / 2 / 3 / 4
  - 实测 `orderState` 取值与含义：1 待付款、2 待发货、3 待收货、4 待评价、5 已完成、6 已取消（测试账号：2 → 12 单、4 → 2 单、6 → 16 单，合计 30 单，与「全部」一致）
- **接口**：`GET /member/order?orderState=&page=&pageSize=`
- **订单卡片**
  - 头部：订单状态文案 + 下单时间 `createTime`
  - 商品行：`skus[]` 的图 / 名称 / 规格 `attrsText` / 数量 / 单价
  - 底部：共 `totalNum` 件，实付 `payMoney`
  - 操作按钮：删除订单（见 4.3）、再次购买（加购物车）
- 分页加载 + 下拉刷新 + 空态
- 优先级 P0

### 4.2 订单详情页

- **接口**：`GET /member/order/{id}`
- **区块（自上而下）**
  1. 状态头：`orderState` 文案；待付款时用 `countdown` 做倒计时
  2. 收货信息：`receiverContact` / `receiverMobile` / `receiverAddress`
  3. 商品清单：`skus[]`（含 `properties`、`attrsText`）
  4. 金额明细：商品总额 `totalMoney` + 运费 `postFee` = 实付 `payMoney`
  5. 订单信息：订单号 `id`、下单时间 `createTime`、支付时间 `payTime`、发货 `consignTime`、完成 `endTime`、关闭 `closeTime`
- 优先级 P0

### 4.3 订单操作（受接口限制）

| 操作 | 接口 | 结论 |
| --- | --- | --- |
| 删除订单 | `DELETE /member/order`，body `{ids:[...]}`（`BatchDeleteVo`） | ✅ 可用 |
| 再次购买 | 复用 `addCartAPI` | ✅ 可用 |
| 去支付 | 无（`/member/order/pay/*` 404） | ❌ 只提示 |
| 取消订单 | 无（`PUT /member/order` 不支持、`/cancel/*` 404） | ❌ 只提示 |
| 确认收货 | 无（`/consume/*` 404） | ❌ 只提示 |
| 评价 | 无 | ❌ 只提示 |

### 4.4 状态角标（可选）

- 进入「我的」页时并发 4 个 `GET /member/order?orderState=n&pageSize=1` 读 `counts`
- 在「待付款 / 待发货 / 待收货 / 待评价」入口右上角显示红点数字
- 优先级 P2（4 个额外请求，可用一次批量合并或延后加载）

## 五、猜你喜欢（保留）

已可用，不需要改动。

---

## 接口清单

| 用途 | 方法 | 路径 | 状态 |
| --- | --- | --- | --- |
| 订单列表 | GET | `/member/order?orderState=&page=&pageSize=` | ✅ 可用 |
| 订单详情 | GET | `/member/order/{id}` | ✅ 可用 |
| 删除订单 | DELETE | `/member/order`（body `{ids:[]}`） | ✅ 可用 |
| 收藏列表 | GET | `/member/collect?collectType=1&page=&pageSize=` | ✅ 可用（当前账号为空） |
| 新增收藏 | POST | `/member/collect` | ⚠️ 入参未知，暂不接 |
| 收货地址 | GET | `/member/address` | ✅ 可用（本页暂不用） |
| 用户资料 | GET | `/member/profile` | ✅ 已有 |
| 修改资料 | PUT | `/member/profile` | ✅ 可用（传了才改；后端几乎不校验，头像与所在地改不了） |
| 足迹 | — | `/member/footprint` | ❌ 404，改本地存储 |
| 会员 | — | — | ❌ 无接口，静态页 |

## 实施批次

1. **第一批（P0）**：订单列表页 + 订单详情页 + 路由接线（4 个状态入口分别带 `orderState`）
   - ✅ 已完成（`afa6605`）：`lib/pages/OrderList/`、`lib/pages/OrderDetail/`、`lib/components/Order/`、`lib/utils/order_actions.dart`
2. **第二批（P1）**：收藏列表页 + 客服静态页
   - ✅ 已完成：`lib/pages/Collect/`、`lib/pages/CustomerService/`、`lib/components/Collect/hm_collect_tile.dart`；收藏只读（写接口入参未知），客服为静态内容
3. **第三批（P2）**：本地足迹（含商品详情埋点）+ 会员权益页 + 订单状态角标
   - ✅ 已完成：`lib/models/footprint.dart`、`lib/stores/footprint_store.dart`、`lib/pages/Footprint/`、`lib/components/Footprint/hm_footprint_tile.dart`、`lib/pages/Vip/`；足迹只存本机（接口 404），会员权益为纯静态说明，订单角标用四次 `pageSize=1` 列表查询折算

### 追加：个人资料页（规划外需求）

- 触发：用户反馈「登录后用户信息不能点击进去修改」
- 方案：`lib/pages/Profile/`（`/profile`），「我的」页点头像 / 昵称进入；可改昵称、性别、生日、职业，保存走 `PUT /member/profile`（传了才改，只提交改动字段）
- 限制：后端对昵称空值 / 长度、性别取值几乎不校验，约束全在前端；头像上传接口不存在（`POST /member/profile/avatar` 500）、所在地无地区数据源，两项只读
- 已完成，待随本次提交入库

每批完成后统一跑 `dart format` / `flutter analyze --fatal-infos` / `flutter test` / `flutter build web`，并同步 README 与用例数。
