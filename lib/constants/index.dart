// 全局常量
class GlobalConstants {
  static const String baseUrl = 'https://meikou-api.itheima.net';
  static const int timeout = 10;
  static const String successCode = '1';
  static const String tokenKey = 'hm_shop_token';
  // 本地足迹（后端无足迹接口，浏览记录只存在本机）
  static const String footprintKey = 'hm_shop_footprint';

  // 仓库地址：版本更新检查直接读 GitHub Release，与商城接口无关
  static const String repoOwner = 'myadmin';
  static const String repoName = 'flutter-shop';

  /// 最新 Release 接口（未登录调用，每小时 60 次的限额按出口 IP 算）
  static const String latestReleaseUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  /// Release 页面地址（iOS / Web 的更新入口）
  static const String releasesPageUrl =
      'https://github.com/$repoOwner/$repoName/releases/latest';

  /// 距离上次检查更新的最小间隔，避免每次启动都请求 GitHub
  static const int updateCheckHours = 6;
}

// 请求接口地址常量
class HttpConstants {
  // 轮播图
  static const String bannerList = '/home/banner';
  // 分类
  static const String categoryList = '/home/category/head';
  // 分类下的商品（`/category/sub/filter?id=<分类 id>`）
  static const String categoryGoods = '/category/sub/filter';
  // 特惠推荐
  static const String productList = '/hot/preference';
  // 爆款推荐
  static const String inVogueList = '/hot/inVogue';
  // 一站全买
  static const String oneStopList = '/hot/oneStop';
  // 新品首发（首页横滑商品卡）
  static const String newGoodsList = '/home/new';
  // 人气好物榜（结构与 /hot/inVogue 相同）
  static const String newRankList = '/hot/new';
  // 品牌好店（列表）
  static const String brandList = '/home/brand';
  // 品牌详情（`/brand/<品牌 id>`）
  static const String brandDetail = '/brand';
  // 专题精选（首页大图专题卡，只有列表、没有详情接口）
  static const String specialList = '/home/special';
  // 分类楼层（首页按一级分类分层的商品）
  static const String homeFloors = '/home/goods';
  // 推荐列表
  static const String recommendList = '/home/recommend';
  // 猜你喜欢
  static const String guessList = '/home/goods/guessLike';
  // 商品详情
  static const String goodsDetail = '/goods';
  // 购物车（GET 列表、POST 加入、DELETE 删除）
  static const String cart = '/member/cart';
  // 购物车商品件数（用于 tab 角标）
  static const String cartCount = '/member/cart/count';
  // 我的收藏（`/member/collect?collectType=1|2`，collectType 必填）
  static const String collect = '/member/collect';
  // 立即购买-预付订单
  static const String preOrder = '/member/order/pre/now';
  // 提交订单
  static const String order = '/member/order';
  // 登录
  static const String login = '/login';
  // 用户信息
  static const String userProfile = '/member/profile';
}
