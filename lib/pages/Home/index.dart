import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hm_shop/api/brand.dart';
import 'package:hm_shop/api/home.dart';
import 'package:hm_shop/api/home_extra.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/Home/hm_brand_strip.dart';
import 'package:hm_shop/components/Home/hm_category.dart';
import 'package:hm_shop/components/Home/hm_home_floor.dart';
import 'package:hm_shop/components/Home/hm_hot.dart';
import 'package:hm_shop/components/Home/hm_more_list.dart';
import 'package:hm_shop/components/Home/hm_new_goods.dart';
import 'package:hm_shop/components/Home/hm_rank_list.dart';
import 'package:hm_shop/components/Home/hm_service_promise.dart';
import 'package:hm_shop/components/Home/hm_slider.dart';
import 'package:hm_shop/components/Home/hm_special_topic.dart';
import 'package:hm_shop/components/Home/hm_suggestion.dart';
import 'package:hm_shop/models/brand.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/models/home_extra.dart';
import 'package:hm_shop/pages/Home/skeleton.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/utils/api_exception.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 首页视图
///
/// 负责并行拉取首页各模块数据（轮播图、分类、推荐等），
/// 加载期间展示骨架屏，加载完成后渲染真实内容。
class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.onCategoryTap,
    this.onBannerTap,
    this.isActive = true,
  });

  /// 点击顶部一级分类的回调
  ///
  /// 首页本身没有跳分类页的能力（分类页挂在底部 tab 容器里），
  /// 由 [MainPage] 传进来负责切 tab 并选中对应分类。
  final ValueChanged<CategoryItem>? onCategoryTap;

  /// 点击轮播图的回调
  ///
  /// banner 自带 `hrefUrl` 与 `type`，跳转目标由 [MainPage] 决定：
  /// 分类类 banner 切到「分类」tab 并选中该分类，商品类 banner 进详情页。
  final ValueChanged<BannerItem>? onBannerTap;

  /// 首页当前是否可见
  ///
  /// 底部 tab 用 IndexedStack 保活，首页切走后仍在树上；轮播的自动播放
  /// 定时器需要跟着这个标记暂停，否则切到购物车后它还在后台翻页。
  final bool isActive;

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

  /// 新品首发（`/home/new`）
  List<GoodsItem> _newGoodsList = [];

  /// 人气好物榜（`/hot/new`，结构与爆款推荐相同）
  SpecialRecommendResult _newRankResult = SpecialRecommendResult(
    id: '',
    title: '',
    subTypes: [],
  );

  /// 品牌好店（`/home/brand`）
  List<BrandItem> _brandList = [];

  /// 专题精选（`/home/special`）
  List<SpecialTopicItem> _specialTopicList = [];

  /// 分类楼层（`/home/goods`）
  List<HomeFloor> _floorList = [];

  List<GoodDetailItem> _recommendList = [];
  int _page = 1;

  /// 滚动加载更多在途标记，避免同一页重复请求
  bool _loading = false;

  /// 整页刷新在途标记：刷新期间不接受滚动加载，否则会与首页首屏请求抢 limit
  bool _refreshing = false;

  /// 第二批模块（新品 / 榜单 / 品牌）在途标记，避免刷新时叠加请求
  bool _secondaryLoading = false;

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
      SliverToBoxAdapter(
        child: HmSlider(
          bannerList: _bannerList,
          autoPlay: widget.isActive,
          onBannerTap: _onBannerTap,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      const SliverToBoxAdapter(child: HmServicePromise()),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      SliverToBoxAdapter(
        child: HmCategory(
          categoryList: _categoryList,
          onCategoryTap: widget.onCategoryTap,
        ),
      ),
      if (_specialTopicList.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(
          child: HmSpecialTopic(
            topics: _specialTopicList,
            onTopicTap: _onSpecialTopicTap,
          ),
        ),
      ],
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
      // 下面三个模块排在无限滚动之上；某个模块没数据时整块不渲染，
      // 既不留空标题，也不白占 10px 间距
      if (_newGoodsList.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(
          child: HmNewGoods(goodsList: _newGoodsList, onGoodsTap: _onGoodsTap),
        ),
      ],
      if (_newRankResult.subTypes.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(
          child: HmRankList(result: _newRankResult, onGoodsTap: _onGoodsTap),
        ),
      ],
      if (_brandList.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(
          child: HmBrandStrip(brandList: _brandList, onBrandTap: _onBrandTap),
        ),
      ],
      // 分类楼层：每层一个一级分类，排在无限滚动之上
      for (final floor in _floorList) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(
          child: HmHomeFloor(
            floor: floor,
            onGoodsTap: _onGoodsTap,
            onCategoryTap: _openFloorCategory,
            onFloorTap: () => _openFloor(floor),
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      HmMoreList(recommendList: _recommendList, onItemTap: _onGoodsTap),
    ];
  }

  /// 点楼层「查看全部」：进该楼层分类的商品列表页
  void _openFloor(HomeFloor floor) {
    Navigator.pushNamed(context, AppRoutes.goodsList(floor.id, floor.name));
  }

  /// 点楼层里的二级分类：直接进该子分类的商品列表页
  ///
  /// 顶部金刚区的一级分类点进去是「切到分类 tab」，楼层里的二级分类
  /// 没有对应的 tab 位置，所以走商品列表页。
  void _openFloorCategory(CategoryItem category) {
    Navigator.pushNamed(
      context,
      AppRoutes.goodsList(category.id, category.name),
    );
  }

  /// 点专题卡：接口没有专题详情，只能提示，避免点了完全没反应
  void _onSpecialTopicTap(SpecialTopicItem topic) {
    ToastUtils.showToast(context, '专题「${topic.title}」详情正在建设中');
  }

  void _onGoodsTap(GoodsItem goods) {
    Navigator.pushNamed(context, AppRoutes.goods(goods.id));
  }

  /// 点品牌卡：进品牌详情页
  void _onBrandTap(BrandItem brand) {
    Navigator.pushNamed(context, AppRoutes.brand(brand.id));
  }

  /// 点轮播图：能解析出跳转目标就交给 [MainPage]，解析不出（外部链接、
  /// 或后端没配 hrefUrl）时给出提示，避免点了完全没反应。
  void _onBannerTap(BannerItem banner) {
    final ValueChanged<BannerItem>? handler = widget.onBannerTap;
    final bool hasTarget = banner.categoryId != null || banner.goodsId != null;
    if (handler == null || !hasTarget) {
      ToastUtils.showToast(context, '该活动暂未开放，敬请期待');
      return;
    }
    handler(banner);
  }

  /// 加载首页首屏数据，全部完成后一次性刷新 UI
  ///
  /// 首屏六个模块并发发出请求，但只调用一次 setState：此前每个模块各自
  /// setState，一次刷新最多触发六帧整页重建。单个模块失败只影响自身，只有
  /// 全部模块都失败时才展示整页错误态。
  ///
  /// 新品首发 / 人气好物榜 / 品牌好店这三个模块排在首屏之下，等这批请求
  /// 回来后再补（见 [_loadSecondaryModules]），不让它们拖慢首屏出图。
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
    // 首屏已经出图，再补下面三个模块，不让它们拖慢骨架屏；
    // 整页都失败时不补，省得再打三个注定失败的请求
    if (successCount > 0) {
      unawaited(_loadSecondaryModules());
    }
  }

  /// 加载排在首屏之下的三个模块：新品首发 / 人气好物榜 / 品牌好店
  ///
  /// 这三个接口与首屏无关，单独成一批：先让轮播、分类、特惠、推荐出图，
  /// 再把它们补上。单个接口失败只让对应模块不渲染，不影响其它内容。
  Future<void> _loadSecondaryModules() async {
    if (_secondaryLoading) {
      return;
    }
    _secondaryLoading = true;

    Future<T?> guard<T>(Future<T> Function() task, String label) async {
      try {
        return await task();
      } catch (e) {
        debugPrint('$label失败: $e');
        return null;
      }
    }

    try {
      final (
        newGoodsList,
        newRankResult,
        brandList,
        specialTopicList,
        floorList,
      ) = await (
        guard(getNewGoodsListAPI, '获取新品首发'),
        guard(getNewRankListAPI, '获取人气好物榜'),
        guard(getBrandListAPI, '获取品牌好店'),
        guard(getSpecialTopicListAPI, '获取专题精选'),
        guard(getHomeFloorListAPI, '获取分类楼层'),
      ).wait;

      if (!mounted) return;
      setState(() {
        if (newGoodsList != null) {
          _newGoodsList = newGoodsList;
        }
        if (newRankResult != null) {
          _newRankResult = newRankResult;
        }
        if (brandList != null) {
          _brandList = brandList;
        }
        if (specialTopicList != null) {
          _specialTopicList = specialTopicList;
        }
        if (floorList != null) {
          _floorList = floorList;
        }
      });
    } finally {
      _secondaryLoading = false;
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
