import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hm_shop/api/home.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/Home/hm_category.dart';
import 'package:hm_shop/components/Home/hm_hot.dart';
import 'package:hm_shop/components/Home/hm_more_list.dart';
import 'package:hm_shop/components/Home/hm_slider.dart';
import 'package:hm_shop/components/Home/hm_suggestion.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/pages/Home/skeleton.dart';
import 'package:hm_shop/utils/api_exception.dart';

/// 首页视图
///
/// 负责并行拉取首页各模块数据（轮播图、分类、推荐等），
/// 加载期间展示骨架屏，加载完成后渲染真实内容。
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// 每次加载更多时请求的商品条数
  static const int _pageSize = 10;

  List<BannerItem> _bannerList = [];
  List<CategoryItem> _categoryList = [];

  SpecialRecommendResult _specialRecommendResult = SpecialRecommendResult(
    id: '',
    title: '',
    subTypes: [],
  );
  SpecialRecommendResult _inVogueRecommendResult = SpecialRecommendResult(
    id: '',
    title: '',
    subTypes: [],
  );
  SpecialRecommendResult _oneStopRecommendResult = SpecialRecommendResult(
    id: '',
    title: '',
    subTypes: [],
  );

  List<GoodDetailItem> _recommendList = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;

  /// 为 true 时页面展示骨架屏
  bool _isLoading = true;

  /// 整页加载失败时的提示文案，为空表示没有整页错误
  String _errorMessage = '';

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _key =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _registerEvent();
    _loadHomeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 按页面从上到下的顺序拼装各模块 sliver，并用 SizedBox 控制模块间距
  List<Widget> _getScrollChildren() {
    return [
      SliverToBoxAdapter(child: HmSlider(bannerList: _bannerList)),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      SliverToBoxAdapter(child: HmCategory(categoryList: _categoryList)),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      SliverToBoxAdapter(
        child: HmSuggestion(
          specialRecommendResult: _specialRecommendResult,
          onGoodsTap: _onGoodsTap,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HmHot(
                  config: HmHotConfig.inVogue,
                  result: _inVogueRecommendResult,
                  onGoodsTap: _onGoodsTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HmHot(
                  config: HmHotConfig.oneStop,
                  result: _oneStopRecommendResult,
                  onGoodsTap: _onGoodsTap,
                ),
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      HmMoreList(recommendList: _recommendList, onItemTap: _onGoodsTap),
    ];
  }

  void _onGoodsTap(GoodsItem goods) {
    Navigator.pushNamed(context, '/goods', arguments: goods.id);
  }

  /// 加载首页全部数据，全部完成后关闭骨架屏
  ///
  /// 单个模块失败只影响自身，只有全部模块都失败时才展示整页错误态。
  Future<void> _loadHomeData() async {
    String? firstError;
    int successCount = 0;

    Future<void> run(Future<void> Function() task) async {
      try {
        await task();
        successCount++;
      } catch (e) {
        debugPrint('首页模块加载失败: $e');
        firstError ??= resolveErrorMessage(e);
      }
    }

    await Future.wait([
      run(_getBannerList),
      run(_getCategoryList),
      run(_getSpecialRecommendList),
      run(_getVogueRecommendList),
      run(_getOneStopRecommendList),
      run(() => _getRecommendList(isRefresh: true)),
    ]);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      // 一个模块都没成功，基本可判定为网络问题，展示整页重试
      _errorMessage = successCount == 0 ? (firstError ?? '首页加载失败') : '';
    });
  }

  /// 滚动到底部时加载下一页；防重入由 _getRecommendList 内部保证
  void _registerEvent() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        // 滚动触发的加载没有调用方 await 它，必须在这里吞掉异常：
        // _getRecommendList 失败时会 rethrow 给首屏并发的调用方，
        // 而这条路径没人接，否则会变成未捕获的异步错误。
        unawaited(
          _getRecommendList().catchError((Object error) {
            debugPrint('加载更多推荐失败: $error');
          }),
        );
      }
    });
  }

  Future<void> _getBannerList() async {
    try {
      final bannerList = await getBannerListAPI();
      if (!mounted) return;
      setState(() {
        _bannerList = bannerList;
      });
    } catch (e) {
      debugPrint('获取轮播图失败: $e');
      rethrow;
    }
  }

  Future<void> _getCategoryList() async {
    try {
      final categoryList = await getCategoryListAPI();
      if (!mounted) return;
      setState(() {
        _categoryList = categoryList;
      });
    } catch (e) {
      debugPrint('获取分类列表失败: $e');
      rethrow;
    }
  }

  Future<void> _getSpecialRecommendList() async {
    try {
      final specialRecommendResult = await getProductListAPI();
      if (!mounted) return;
      setState(() {
        _specialRecommendResult = specialRecommendResult;
      });
    } catch (e) {
      debugPrint('获取特惠推荐失败: $e');
      rethrow;
    }
  }

  Future<void> _getVogueRecommendList() async {
    try {
      final inVogueRecommendResult = await getInVogueListAPI();
      if (!mounted) return;
      setState(() {
        _inVogueRecommendResult = inVogueRecommendResult;
      });
    } catch (e) {
      debugPrint('获取爆款推荐失败: $e');
      rethrow;
    }
  }

  Future<void> _getOneStopRecommendList() async {
    try {
      final oneStopRecommendResult = await getOneStopListAPI();
      if (!mounted) return;
      setState(() {
        _oneStopRecommendResult = oneStopRecommendResult;
      });
    } catch (e) {
      debugPrint('获取一站全买失败: $e');
      rethrow;
    }
  }

  /// 获取推荐列表
  ///
  /// 后端 /home/recommend 只支持 limit（不支持 page / pageSize）：返回始终是
  /// 全量结果的前 limit 条且顺序稳定，因此这里用递增 limit 的方式拉取，等价于
  /// 「每次多取一页」。返回条数少于请求的 limit 时说明已经到底。
  Future<void> _getRecommendList({bool isRefresh = false}) async {
    if (_loading || (!_hasMore && !isRefresh)) {
      return;
    }
    _loading = true;
    if (isRefresh) {
      _page = 1;
      _hasMore = true;
    }
    final int limit = _page * _pageSize;
    try {
      final recommendList = await getRecommendListAPI({'limit': limit});
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
      rethrow;
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const HomeSkeleton();
    }
    if (_errorMessage.isNotEmpty) {
      return _buildError();
    }
    return RefreshIndicator(
      key: _key,
      onRefresh: _loadHomeData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: _getScrollChildren(),
      ),
    );
  }

  /// 整页加载失败提示，与商品详情页、订单确认页共用同一套样式
  Widget _buildError() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          // 保证内容可滚动，这样 RefreshIndicator 依然能响应下拉刷新
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: AppErrorView(message: _errorMessage, onRetry: _retry),
          ),
        );
      },
    );
  }

  /// 重试：回到骨架屏状态后重新拉取全部模块
  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    _loadHomeData();
  }
}
