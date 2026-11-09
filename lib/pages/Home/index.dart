import 'package:flutter/material.dart'; // 引入 Flutter 基础 UI 组件库
import 'package:hm_shop/api/home.dart'; // 引入首页数据请求接口
import 'package:hm_shop/components/Home/HmCategory.dart'; // 引入首页分类入口组件
import 'package:hm_shop/components/Home/HmHot.dart'; // 引入首页爆款推荐组件
import 'package:hm_shop/components/Home/HmMoreList.dart'; // 引入首页无限滚动列表组件
import 'package:hm_shop/components/Home/HmSlider.dart'; // 引入首页轮播图组件
import 'package:hm_shop/components/Home/HmSuggestion.dart'; // 引入首页特惠推荐组件
import 'package:hm_shop/models/home.dart'; // 引入首页数据模型
import 'package:hm_shop/pages/Home/skeleton.dart'; // 引入首页骨架屏组件

/// 首页视图
///
/// 负责并行拉取首页各模块数据（轮播图、分类、推荐等），
/// 加载期间展示骨架屏，加载完成后渲染真实内容。
class HomeView extends StatefulWidget {
  // 首页视图组件
  HomeView({Key? key}) : super(key: key); // 构造函数，透传 key

  @override // 重写创建状态对象的方法
  _HomeViewState createState() => _HomeViewState(); // 返回首页状态实例
} // HomeView 类结束

class _HomeViewState extends State<HomeView> {
  // 首页视图的状态类
  // 轮播图数据
  List<BannerItem> _bannerList = []; // 保存轮播图数据的列表
  // 分类入口数据
  List<CategoryItem> _categoryList = []; // 保存分类入口数据的列表
  // 特惠推荐
  SpecialRecommendResult _specialRecommendResult = SpecialRecommendResult(
    // 特惠推荐模块数据
    id: '', // 模块标识
    title: '', // 模块标题
    subTypes: [], // 模块下的子类型列表
  ); // 特惠推荐数据初始化完成
  // 爆款推荐
  SpecialRecommendResult _inVogueRecommendResult = SpecialRecommendResult(
    // 爆款推荐模块数据
    id: '', // 模块标识
    title: '', // 模块标题
    subTypes: [], // 模块下的子类型列表
  ); // 爆款推荐数据初始化完成
  // 一站全买
  SpecialRecommendResult _oneStopRecommendResult = SpecialRecommendResult(
    // 一站全买模块数据
    id: '', // 模块标识
    title: '', // 模块标题
    subTypes: [], // 模块下的子类型列表
  ); // 一站全买数据初始化完成
  // 推荐列表
  List<GoodDetailItem> _recommendList = []; // 保存推荐列表数据初始化完成

  // 首页数据是否仍在加载
  bool _isLoading = true; // 为 true 时页面展示骨架屏

  /// 构建 CustomScrollView 的 sliver 子项列表
  ///
  /// 按页面从上到下的顺序拼装各模块，并用 SizedBox 控制模块间距。
  List<Widget> _getScrollChildren() {
    // 按顺序拼装首页各模块
    return [
      // 返回 sliver 组件列表
      // 轮播图
      SliverToBoxAdapter(child: HmSlider(bannerList: _bannerList)), // 轮播图模块
      // 间隔
      SliverToBoxAdapter(child: SizedBox(height: 10)), // 轮播图与分类之间的间距
      // 分类
      SliverToBoxAdapter(
        child: HmCategory(categoryList: _categoryList),
      ), // 分类入口模块
      // 间隔
      SliverToBoxAdapter(child: SizedBox(height: 10)), // 分类与推荐之间的间距
      // 推荐
      SliverToBoxAdapter(
        // 特惠推荐模块容器
        child: HmSuggestion(
          specialRecommendResult: _specialRecommendResult,
        ), // 传入特惠推荐数据
      ),
      // 间隔
      SliverToBoxAdapter(child: SizedBox(height: 10)), // 推荐与爆款推荐之间的间距
      // 爆款推荐
      SliverToBoxAdapter(
        // 爆款推荐区域容器
        child: Padding(
          // 外层内边距容器
          padding: EdgeInsets.symmetric(horizontal: 10), // 左右各留 10 的边距
          child: Row(
            // 横向排列两个推荐模块
            crossAxisAlignment: CrossAxisAlignment.start, // 子项顶部对齐
            children: [
              // 子项列表
              // 爆款推荐场景
              Expanded(
                // 占据一半宽度
                child: HmHot(
                  // 爆款推荐组件
                  config: HmHotConfig.inVogue, // 指定为爆款推荐场景
                  result: _inVogueRecommendResult, // 传入爆款推荐数据
                ),
              ),
              SizedBox(width: 10), // 两个模块之间的水平间距
              // 一站全买场景
              Expanded(
                // 占据另一半宽度
                child: HmHot(
                  // 一站全买组件
                  config: HmHotConfig.oneStop, // 指定为一站全买场景
                  result: _oneStopRecommendResult, // 传入一站全买数据
                ),
              ),
            ],
          ),
        ),
      ),
      // 间隔
      SliverToBoxAdapter(child: SizedBox(height: 10)), // 爆款推荐与商品列表之间的间距
      // 无限滚动列表
      HmMoreList(recommendList: _recommendList), // 商品无限滚动列表模块
    ]; // sliver 列表结束
  } // _getScrollChildren 方法结束

  @override // 重写状态初始化方法
  void initState() {
    // 页面首次创建时执行
    super.initState(); // 调用父类初始化方法
    // 首次进入页面时加载首页数据
    _loadHomeData(); // 触发首页数据加载
  } // initState 方法结束

  // 加载首页全部数据，全部完成后关闭骨架屏
  Future<void> _loadHomeData() async {
    // 异步加载首页所有模块数据
    try {
      // 开始捕获接口异常
      await Future.wait([
        // 并行等待所有请求完成
        // 获取轮播图列表
        _getBannerList(), // 轮播图请求
        // 获取分类列表
        _getCategoryList(), // 分类请求
        // 获取特惠推荐列表
        _getSpecialRecommendList(), // 特惠推荐请求
        // 获取爆款推荐列表
        _getVogueRecommendList(), // 爆款推荐请求
        // 获取一站全买列表
        _getOneStopRecommendList(), // 一站全买请求
        // 获取推荐列表
        _getRecommendList(), // 推荐列表请求
      ]); // 所有请求完成
    } catch (e) {
      // 捕获接口异常
      // 某个接口失败时不影响其余模块展示
      debugPrint('首页数据加载失败: $e'); // 输出错误日志便于排查问题
    } finally {
      // 无论成功失败都会执行
      if (mounted) {
        // 页面仍挂载时才更新状态
        setState(() {
          // 通知框架刷新界面
          _isLoading = false; // 关闭骨架屏
        });
      }
    }
  } // _loadHomeData 方法结束

  // 获取轮播图列表
  Future<void> _getBannerList() async {
    // 请求轮播图数据
    final bannerList = await getBannerListAPI(); // 调用轮播图接口获取数据
    setState(() {
      // 请求成功后刷新界面
      _bannerList = bannerList; // 更新轮播图数据
    });
  } // _getBannerList 方法结束

  // 获取分类列表
  Future<void> _getCategoryList() async {
    // 请求分类入口数据
    final categoryList = await getCategoryListAPI(); // 调用分类接口获取数据
    setState(() {
      // 请求成功后刷新界面
      _categoryList = categoryList; // 更新分类入口数据
    });
  } // _getCategoryList 方法结束

  // 获取特惠推荐列表
  Future<void> _getSpecialRecommendList() async {
    // 请求特惠推荐数据
    final specialRecommendResult = await getProductListAPI(); // 调用特惠推荐接口获取数据
    setState(() {
      // 请求成功后刷新界面
      _specialRecommendResult = specialRecommendResult; // 更新特惠推荐数据
    });
  } // _getSpecialRecommendList 方法结束

  // 获取爆款推荐列表
  Future<void> _getVogueRecommendList() async {
    // 请求爆款推荐数据
    final inVogueRecommendResult = await getInVogueListAPI(); // 调用爆款推荐接口获取数据
    setState(() {
      // 请求成功后刷新界面
      _inVogueRecommendResult = inVogueRecommendResult; // 更新爆款推荐数据
    });
  } // _getVogueRecommendList 方法结束

  // 获取一站全买列表
  Future<void> _getOneStopRecommendList() async {
    // 请求一站全买数据
    final oneStopRecommendResult = await getOneStopListAPI(); // 调用一站全买接口获取数据
    setState(() {
      // 请求成功后刷新界面
      _oneStopRecommendResult = oneStopRecommendResult; // 更新一站全买数据
    });
  } // _getOneStopRecommendList 方法结束

  // 获取推荐列表
  Future<void> _getRecommendList() async {
    // 请求推荐列表数据
    final recommendList = await getRecommendListAPI({
      "limit": 10,
    }); // 调用推荐列表接口获取数据
    print('推荐列表数据: $recommendList'); // 打印推荐列表数据便于调试
    setState(() {
      // 请求成功后刷新界面
      _recommendList = recommendList; // 更新推荐列表数据
    });
  } // _getRecommendList 方法结束

  @override // 重写构建方法
  Widget build(BuildContext context) {
    // 构建页面内容
    // 数据加载期间展示骨架屏，避免页面空白
    if (_isLoading) {
      // 仍在加载中
      return const HomeSkeleton(); // 展示骨架屏占位
    }
    return CustomScrollView(slivers: _getScrollChildren()); // 加载完成，渲染真实内容
  } // build 方法结束
} // 状态类结束
