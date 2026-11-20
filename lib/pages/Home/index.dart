import 'package:flutter/material.dart'; // 引入 Flutter 基础 UI 组件库
import 'package:hm_shop/api/home.dart'; // 引入首页数据请求接口
import 'package:hm_shop/components/Home/hm_category.dart'; // 引入首页分类入口组件
import 'package:hm_shop/components/Home/hm_hot.dart'; // 引入首页爆款推荐组件
import 'package:hm_shop/components/Home/hm_more_list.dart'; // 引入首页无限滚动列表组件
import 'package:hm_shop/components/Home/hm_slider.dart'; // 引入首页轮播图组件
import 'package:hm_shop/components/Home/hm_suggestion.dart'; // 引入首页特惠推荐组件
import 'package:hm_shop/models/home.dart'; // 引入首页数据模型
import 'package:hm_shop/pages/Home/skeleton.dart';

/// 首页视图
///
/// 负责并行拉取首页各模块数据（轮播图、分类、推荐等），
/// 加载期间展示骨架屏，加载完成后渲染真实内容。
class HomeView extends StatefulWidget {
  // 首页视图组件
  const HomeView({super.key}); // 构造函数，透传 key

  @override // 重写创建状态对象的方法
  State<HomeView> createState() => _HomeViewState(); // 返回首页状态实例
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
  // 页码
  int _page = 1; // 当前页码，默认第一页
  // 当前正在加载状态
  bool _loading = false; // 默认不加载更多
  // 是否还有下一页
  bool _hasMore = true; // 默认还有下一页

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
          onGoodsTap: _onGoodsTap, // 点击商品跳转详情
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
                  onGoodsTap: _onGoodsTap, // 点击商品跳转详情
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
                  onGoodsTap: _onGoodsTap, // 点击商品跳转详情
                ),
              ),
            ],
          ),
        ),
      ),
      // 间隔
      SliverToBoxAdapter(child: SizedBox(height: 10)), // 爆款推荐与商品列表之间的间距
      // 无限滚动列表
      HmMoreList(
        recommendList: _recommendList,
        onItemTap: _onGoodsTap, // 点击商品跳转详情
      ), // 商品无限滚动列表模块
    ]; // sliver 列表结束
  } // _getScrollChildren 方法结束

  @override // 重写状态初始化方法
  void initState() {
    // 页面首次创建时执行
    super.initState(); // 调用父类初始化方法
    _registerEvent(); // 仅注册一次滚动监听
    // 首次进入页面时加载首页数据
    _loadHomeData(); // 触发首页数据加载
  } // initState 方法结束

  @override
  void dispose() {
    _scrollController.dispose(); // 释放滚动控制器，防止内存泄漏
    super.dispose();
  }

  // 点击商品跳转商品详情页
  void _onGoodsTap(GoodsItem goods) {
    Navigator.pushNamed(context, '/goods', arguments: goods.id);
  }

  // 加载首页全部数据，全部完成后关闭骨架屏
  Future<void> _loadHomeData() async {
    // 异步加载首页所有模块数据
    try {
      // 并行请求各模块数据，每个子模块独立捕获异常
      await Future.wait([
        _getBannerList(), // 轮播图请求
        _getCategoryList(), // 分类请求
        _getSpecialRecommendList(), // 特惠推荐请求
        _getVogueRecommendList(), // 爆款推荐请求
        _getOneStopRecommendList(), // 一站全买请求
        _getRecommendList(isRefresh: true), // 推荐列表首次或刷新请求
      ]);
    } catch (e) {
      debugPrint('首页数据加载失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 关闭骨架屏
        });
      }
    }
  } // _loadHomeData 方法结束

  // 监听滚动到底部的事件
  void _registerEvent() {
    _scrollController.addListener(() {
      // 滚动到底部时触发
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        // 加载下一页
        _getRecommendList(); // 触发加载更多数据
      }
    });
  } // _registerEvent 方法结束

  // 获取轮播图列表
  Future<void> _getBannerList() async {
    try {
      final bannerList = await getBannerListAPI();
      if (!mounted) return;
      setState(() {
        _bannerList = bannerList;
      });
    } catch (e) {
      debugPrint('获取轮播图失败: $e');
    }
  } // _getBannerList 方法结束

  // 获取分类列表
  Future<void> _getCategoryList() async {
    try {
      final categoryList = await getCategoryListAPI();
      if (!mounted) return;
      setState(() {
        _categoryList = categoryList;
      });
    } catch (e) {
      debugPrint('获取分类列表失败: $e');
    }
  } // _getCategoryList 方法结束

  // 获取特惠推荐列表
  Future<void> _getSpecialRecommendList() async {
    try {
      final specialRecommendResult = await getProductListAPI();
      if (!mounted) return;
      setState(() {
        _specialRecommendResult = specialRecommendResult;
      });
    } catch (e) {
      debugPrint('获取特惠推荐失败: $e');
    }
  } // _getSpecialRecommendList 方法结束

  // 获取爆款推荐列表
  Future<void> _getVogueRecommendList() async {
    try {
      final inVogueRecommendResult = await getInVogueListAPI();
      if (!mounted) return;
      setState(() {
        _inVogueRecommendResult = inVogueRecommendResult;
      });
    } catch (e) {
      debugPrint('获取爆款推荐失败: $e');
    }
  } // _getVogueRecommendList 方法结束

  // 获取一站全买列表
  Future<void> _getOneStopRecommendList() async {
    try {
      final oneStopRecommendResult = await getOneStopListAPI();
      if (!mounted) return;
      setState(() {
        _oneStopRecommendResult = oneStopRecommendResult;
      });
    } catch (e) {
      debugPrint('获取一站全买失败: $e');
    }
  } // _getOneStopRecommendList 方法结束

  // 获取推荐列表
  //
  // 后端 /home/recommend 只支持 limit（不支持 page/pageSize）：
  // 返回始终是全量结果的前 limit 条，顺序稳定。因此这里用递增 limit 的方式
  // 拉取，等价于"每次多取一页"。当返回条数少于请求的 limit 时说明已经到底。
  Future<void> _getRecommendList({bool isRefresh = false}) async {
    if (_loading || (!_hasMore && !isRefresh)) {
      return;
    }
    _loading = true;
    if (isRefresh) {
      _page = 1;
      _hasMore = true;
    }
    const int pageSize = 10;
    final int limit = _page * pageSize;
    try {
      final recommendList = await getRecommendListAPI({"limit": limit});
      if (!mounted) return;
      setState(() {
        _recommendList = recommendList;
        _hasMore = recommendList.length >= limit;
      });
      if (_hasMore) {
        _page++;
      }
    } catch (e) {
      debugPrint('获取推荐列表失败: $e');
    } finally {
      _loading = false;
    }
  } // _getRecommendList 方法结束

  final ScrollController _scrollController = ScrollController(); // 滚动控制器

  final GlobalKey<RefreshIndicatorState> _key =
      GlobalKey<RefreshIndicatorState>(); // 刷新指示器键值对

  @override // 重写构建方法
  Widget build(BuildContext context) {
    // 数据加载期间展示骨架屏，避免页面空白
    if (_isLoading) {
      return const HomeSkeleton(); // 展示骨架屏占位
    }
    return RefreshIndicator(
      key: _key, // 刷新指示器键值对
      onRefresh: _loadHomeData, // 刷新数据
      child: CustomScrollView(
        controller: _scrollController, // 滚动控制器
        slivers: _getScrollChildren(),
      ),
    ); // 加载完成，渲染真实内容
  } // build 方法结束
} // 状态类结束
