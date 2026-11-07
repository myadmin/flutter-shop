import 'package:flutter/material.dart';
import 'package:hm_shop/api/home.dart';
import 'package:hm_shop/components/Home/HmCategory.dart';
import 'package:hm_shop/components/Home/HmHot.dart';
import 'package:hm_shop/components/Home/HmMoreList.dart';
import 'package:hm_shop/components/Home/HmSlider.dart';
import 'package:hm_shop/components/Home/HmSuggestion.dart';
import 'package:hm_shop/models/home.dart';

class HomeView extends StatefulWidget {
  HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<BannerItem> _bannerList = [];
  List<CategoryItem> _categoryList = [];
  // 特惠推荐
  SpecialRecommendResult _specialRecommendResult = SpecialRecommendResult(
    id: '',
    title: '',
    subTypes: [],
  );
  // 爆款推荐
  SpecialRecommendResult _inVogueRecommendResult = SpecialRecommendResult(
    id: '',
    title: '',
    subTypes: [],
  );
  // 一站全买
  SpecialRecommendResult _oneStopRecommendResult = SpecialRecommendResult(
    id: '',
    title: '',
    subTypes: [],
  );

  // 首页数据是否仍在加载
  bool _isLoading = true;

  List<Widget> _getScrollChildren() {
    return [
      // 轮播图
      SliverToBoxAdapter(child: HmSlider(bannerList: _bannerList)),
      // 间隔
      SliverToBoxAdapter(child: SizedBox(height: 10)),
      // 分类
      SliverToBoxAdapter(child: HmCategory(categoryList: _categoryList)),
      // 间隔
      SliverToBoxAdapter(child: SizedBox(height: 10)),
      // 推荐
      SliverToBoxAdapter(
        child: HmSuggestion(specialRecommendResult: _specialRecommendResult),
      ),
      // 间隔
      SliverToBoxAdapter(child: SizedBox(height: 10)),
      // 爆款推荐
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 爆款推荐场景
              Expanded(
                child: HmHot(
                  config: HmHotConfig.inVogue,
                  result: _inVogueRecommendResult,
                ),
              ),
              SizedBox(width: 10),
              // 一站全买场景
              Expanded(
                child: HmHot(
                  config: HmHotConfig.oneStop,
                  result: _oneStopRecommendResult,
                ),
              ),
            ],
          ),
        ),
      ),
      // 间隔
      SliverToBoxAdapter(child: SizedBox(height: 10)),
      // 无限滚动列表
      HmMoreList(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  // 加载首页全部数据，全部完成后关闭骨架屏
  Future<void> _loadHomeData() async {
    try {
      await Future.wait([
        // 获取轮播图列表
        _getBannerList(),
        // 获取分类列表
        _getCategoryList(),
        // 获取特惠推荐列表
        _getSpecialRecommendList(),
        // 获取爆款推荐列表
        _getVogueRecommendList(),
        // 获取一站全买列表
        _getOneStopRecommendList(),
      ]);
    } catch (e) {
      // 某个接口失败时不影响其余模块展示
      debugPrint('首页数据加载失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 获取轮播图列表
  Future<void> _getBannerList() async {
    final bannerList = await getBannerListAPI();
    setState(() {
      _bannerList = bannerList;
    });
  }

  // 获取分类列表
  Future<void> _getCategoryList() async {
    final categoryList = await getCategoryListAPI();
    setState(() {
      _categoryList = categoryList;
    });
  }

  // 获取特惠推荐列表
  Future<void> _getSpecialRecommendList() async {
    final specialRecommendResult = await getProductListAPI();
    setState(() {
      _specialRecommendResult = specialRecommendResult;
    });
  }

  // 获取爆款推荐列表
  Future<void> _getVogueRecommendList() async {
    final inVogueRecommendResult = await getInVogueListAPI();
    setState(() {
      _inVogueRecommendResult = inVogueRecommendResult;
    });
  }

  // 获取一站全买列表
  Future<void> _getOneStopRecommendList() async {
    final oneStopRecommendResult = await getOneStopListAPI();
    setState(() {
      _oneStopRecommendResult = oneStopRecommendResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _HomeSkeleton();
    }
    return CustomScrollView(slivers: _getScrollChildren());
  }
}

/// 首页加载骨架屏
class _HomeSkeleton extends StatefulWidget {
  const _HomeSkeleton();

  @override
  State<_HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<_HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.35,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 通用灰色占位块
  Widget _box({double? width, double height = 12, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // 轮播图占位
  Widget _buildBanner() {
    return _box(height: 300, radius: 0);
  }

  // 分类入口占位
  Widget _buildCategory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        spacing: 10,
        children: List.generate(
          5,
          (index) => Expanded(child: _box(height: 80, radius: 40)),
        ),
      ),
    );
  }

  // 特惠推荐占位
  Widget _buildSuggestion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 10,
              children: [
                _box(width: 90, height: 18),
                _box(width: 60, height: 12),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              spacing: 10,
              children: List.generate(
                4,
                (index) => Expanded(
                  child: Column(
                    children: [
                      _box(height: 140, radius: 8),
                      const SizedBox(height: 8),
                      _box(width: 60, height: 18, radius: 9),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 爆款推荐、一站全买占位
  Widget _buildHotRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        spacing: 10,
        children: [
          Expanded(child: _buildHotCard()),
          Expanded(child: _buildHotCard()),
        ],
      ),
    );
  }

  Widget _buildHotCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(width: 80, height: 16),
          const SizedBox(height: 10),
          Row(
            spacing: 10,
            children: List.generate(
              2,
              (index) => Expanded(
                child: Column(
                  children: [
                    _box(height: 100, radius: 8),
                    const SizedBox(height: 8),
                    _box(width: 55, height: 16, radius: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 商品瀑布流占位
  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: List.generate(2, (rowIndex) {
          return Padding(
            padding: EdgeInsets.only(top: rowIndex == 0 ? 0 : 10),
            child: Row(
              spacing: 10,
              children: [
                Expanded(child: _box(height: 170, radius: 8)),
                Expanded(child: _box(height: 170, radius: 8)),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildBanner(),
            const SizedBox(height: 10),
            _buildCategory(),
            const SizedBox(height: 10),
            _buildSuggestion(),
            const SizedBox(height: 10),
            _buildHotRow(),
            const SizedBox(height: 10),
            _buildGrid(),
          ],
        ),
      ),
    );
  }
}
