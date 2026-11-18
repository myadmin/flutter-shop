// 全局常量
class GlobalConstants {
  static const String baseUrl = 'https://meikou-api.itheima.net';
  static const int timeout = 10;
  static const String successCode = '1';
  static const String tokenKey = 'hm_shop_token';
}

// 请求接口地址常量
class HttpConstants {
  // 轮播图
  static const String bannerList = '/home/banner';
  // 分类
  static const String categoryList = '/home/category/head';
  // 特惠推荐
  static const String productList = '/hot/preference';
  // 爆款推荐
  static const String inVogueList = '/hot/inVogue';
  // 一站全买
  static const String oneStopList = '/hot/oneStop';
  // 推荐列表
  static const String recommendList = '/home/recommend';
  // 猜你喜欢
  static const String guessList = '/home/goods/guessLike';
  // 登录
  static const String login = '/login';
  // 用户信息
  static const String userProfile = '/member/profile';
 }
