import 'package:flutter/material.dart';
import 'package:hm_shop/api/home.dart';
import 'package:hm_shop/api/mine.dart';
import 'package:hm_shop/components/Category/hm_category_panel.dart';
import 'package:hm_shop/components/Category/hm_category_rail.dart';
import 'package:hm_shop/components/Category/hm_category_recommend.dart';
import 'package:hm_shop/components/Category/hm_category_search.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/utils/api_exception.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 分类页：左侧一级分类导航 + 右侧二级分类宫格 + 底部猜你喜欢。
///
/// 与 `/home/category/head` 返回的分类树对应（一级 7 个，每个下挂 1~7 个二级）。
/// 页面私有状态（选中项、加载态）用 setState 管理，符合项目里
/// 「跨页面共享 → GetX，页面私有 → setState」的约定。
class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  /// 右侧面板滚动控制器，切换一级分类时用它回到顶部
  final ScrollController _panelController = ScrollController();

  List<CategoryItem> _categories = const [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  /// 底部推荐商品；加载失败时静默降级，不影响分类本身的展示
  List<GoodDetailItem> _recommendList = const [];
  bool _isRecommendLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRecommend();
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final List<CategoryItem> categories = await getCategoryListAPI();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        // 首屏或重试后列表可能变短，选中项要收回有效范围
        _selectedIndex = categories.isEmpty
            ? 0
            : (_selectedIndex < categories.length ? _selectedIndex : 0);
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      debugPrint('获取分类列表失败: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = resolveErrorMessage(e, fallback: '分类加载失败');
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    _loadCategories();
  }

  /// 底部推荐商品：只取第一页，失败时静默降级为空列表
  Future<void> _loadRecommend() async {
    try {
      final GoodsDetailsItems result = await getGuessListAPI({
        'page': 1,
        'pageSize': 10,
      });
      if (!mounted) return;
      setState(() {
        _recommendList = result.items;
        _isRecommendLoading = false;
      });
    } catch (e) {
      debugPrint('获取分类页推荐失败: $e');
      if (!mounted) return;
      setState(() => _isRecommendLoading = false);
    }
  }

  void _onGoodsTap(GoodDetailItem item) {
    Navigator.pushNamed(context, AppRoutes.goods(item.id));
  }

  void _onCategorySelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    // 切换分类后右侧内容整体换掉，滚动位置要归零，否则会停在上一类的中间
    if (_panelController.hasClients) {
      _panelController.jumpTo(0);
    }
  }

  void _onSubCategoryTap(CategoryItem child) {
    Navigator.pushNamed(context, AppRoutes.goodsList(child.id, child.name));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HmCategorySearch(
          onTap: () => ToastUtils.showToast(context, '搜索功能开发中，敬请期待'),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return AppErrorView(message: _errorMessage, onRetry: _retry);
    }
    if (_categories.isEmpty) {
      return AppErrorView(message: '暂无分类数据', onRetry: _retry);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HmCategoryRail(
          categories: _categories,
          selectedIndex: _selectedIndex,
          onSelected: _onCategorySelected,
        ),
        Expanded(
          child: HmCategoryPanel(
            controller: _panelController,
            category: _categories[_selectedIndex],
            onSubCategoryTap: _onSubCategoryTap,
            recommend: HmCategoryRecommend(
              items: _recommendList,
              isLoading: _isRecommendLoading,
              onGoodsTap: _onGoodsTap,
            ),
          ),
        ),
      ],
    );
  }
}
