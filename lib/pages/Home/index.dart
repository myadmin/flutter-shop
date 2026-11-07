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
    // 获取轮播图列表
    _getBannerList();
    // 获取分类列表
    _getCategoryList();
    // 获取特惠推荐列表
    _getSpecialRecommendList();
    // 获取爆款推荐列表
    _getVogueRecommendList();
    // 获取一站全买列表
    _getOneStopRecommendList();
  }

  // 获取轮播图列表
  void _getBannerList() async {
    final bannerList = await getBannerListAPI();
    setState(() {
      _bannerList = bannerList;
    });
  }

  // 获取分类列表
  void _getCategoryList() async {
    final categoryList = await getCategoryListAPI();
    setState(() {
      _categoryList = categoryList;
    });
  }

  // 获取特惠推荐列表
  void _getSpecialRecommendList() async {
    final specialRecommendResult = await getProductListAPI();
    setState(() {
      _specialRecommendResult = specialRecommendResult;
    });
  }

  // 获取爆款推荐列表
  void _getVogueRecommendList() async {
    final inVogueRecommendResult = await getInVogueListAPI();
    setState(() {
      _inVogueRecommendResult = inVogueRecommendResult;
    });
  }

  // 获取一站全买列表
  void _getOneStopRecommendList() async {
    final oneStopRecommendResult = await getOneStopListAPI();
    setState(() {
      _oneStopRecommendResult = oneStopRecommendResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: _getScrollChildren());
  }
}
