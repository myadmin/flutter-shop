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

  /// 滚动加载更多在途标记，避免同一页重复请求
  bool _loading = false;

  /// 整页刷新在途标记：刷新期间不接受滚动加载，否则会与首页首屏请求抢 limit
  bool _refreshing = false;

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

  /// 加载首页全部数据，全部完成后一次性刷新 UI
  ///
  /// 六个模块并发发出请求，但只调用一次 setState：此前每个模块各自 setState，
  /// 一次刷新最多触发 6 帧整页重建。单个模块失败只影响自身，只有全部模块都
  /// 失败时才展示整页错误态。
  Future<void> _loadHomeData() async {
    if (_refreshing) {
      return;
    }
    _refreshing = true;

    String? firstError;
    int successCount = 0;

    /// 并发执行单个模块：失败时记录错误并返回 null，不向外抛异常
    Future<T?> run<T>(Future<T> Function() task, String label) async {
      try {
        final result = await task();
        successCount++;
        return result;
      } catch (e) {
        debugPrint('$label失败: $e');
        firstError ??= resolveErrorMessage(e);
        return null;
      }
    }

    try {
      final (
        bannerList,
        categoryList,
        specialRecommendResult,
        inVogueRecommendResult,
        oneStopRecommendResult,
        recommendList,
      ) = await (
        run(getBannerListAPI, '获取轮播图'),
        run(getCategoryListAPI, '获取分类列表'),
        run(getProductListAPI, '获取特惠推荐'),
        run(getInVogueListAPI, '获取爆款推荐'),
        run(getOneStopListAPI, '获取一站全买'),
        run(() => getRecommendListAPI({'limit': _pageSize}), '获取推荐列表'),
      ).wait;

      if (!mounted) return;
      setState(() {
        // 失败的模块保留上一次的数据，不打断已有内容
        if (bannerList != null) {
          _bannerList = bannerList;
        }
        if (categoryList != null) {
          _categoryList = categoryList;
        }
        if (specialRecommendResult != null) {
          _specialRecommendResult = specialRecommendResult;
        }
        if (inVogueRecommendResult != null) {
          _inVogueRecommendResult = inVogueRecommendResult;
        }
        if (oneStopRecommendResult != null) {
          _oneStopRecommendResult = oneStopRecommendResult;
        }
        if (recommendList != null) {
          _recommendList = recommendList;
          _page = 1;
          _hasMore = recommendList.length >= _pageSize;
          if (_hasMore) {
            _page++;
          }
        }
        _isLoading = false;
        // 一个模块都没成功，基本可判定为网络问题，展示整页重试
        _errorMessage = successCount == 0 ? (firstError ?? '首页加载失败') : '';
      });
    } finally {
      _refreshing = false;
    }
  }

  /// 滚动到底部时加载下一页；防重入由 _refreshing / _loading 共同保证
  void _registerEvent() {
    _scrollController.addListener(() {
      if (_refreshing || _loading) {
        return;
      }
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        // 滚动触发的加载没有调用方 await 它，异常必须在 _getRecommendList
        // 内部消化，否则会变成未捕获的异步错误。
        unawaited(_getRecommendList());
      }
    });
  }

  /// 获取推荐列表（滚动到底部时追加下一页）
  ///
  /// 后端 /home/recommend 只支持 limit（不支持 page / pageSize）：返回始终是
  /// 全量结果的前 limit 条且顺序稳定，因此这里用递增 limit 的方式拉取，等价于
  /// 「每次多取一页」。返回条数少于请求的 limit 时说明已经到底。
  Future<void> _getRecommendList() async {
    if (_loading || !_hasMore) {
      return;
    }
    _loading = true;
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
      // 滚动加载的调用方不对异常做处理，这里必须吞掉并保留已有列表
      debugPrint('获取推荐列表失败: $e');
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
