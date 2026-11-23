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
///
/// 支持外部指定选中项：首页顶部的一级分类入口点击后，由 [MainPage] 切到本页
/// 并通过 [selectedCategoryId] + [selectionTicket] 传入选中的分类。
class CategoryView extends StatefulWidget {
  const CategoryView({
    super.key,
    this.selectedCategoryId,
    this.selectionTicket = 0,
  });

  /// 外部（首页分类入口）要求选中的一级分类 id
  final String? selectedCategoryId;

  /// 外部选中请求的版本号
  ///
  /// 每次从首页点分类都会自增。只比较 [selectedCategoryId] 无法区分
  /// 「用户手动切走后又点了同一个分类」，所以用版本号判定是否为一次新请求。
  final int selectionTicket;

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  /// 右侧面板滚动控制器，切换一级分类时用它回到顶部
  final ScrollController _panelController = ScrollController();

  /// 左侧一级分类列表的滚动控制器，外部指定选中项时把该项滚到可视区
  final ScrollController _railController = ScrollController();

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
  void didUpdateWidget(covariant CategoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectionTicket != oldWidget.selectionTicket) {
      _applyExternalSelection();
    }
  }

  @override
  void dispose() {
    _panelController.dispose();
    _railController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final List<CategoryItem> categories = await getCategoryListAPI();
      if (!mounted) return;
      // 首屏或重试前列表为空，说明这次是首次拿到数据，可能要补上外部指定的选中项
      final bool wasEmpty = _categories.isEmpty;
      setState(() {
        _categories = categories;
        // 首屏或重试后列表可能变短，选中项要收回有效范围
        _selectedIndex = categories.isEmpty
            ? 0
            : (_selectedIndex < categories.length ? _selectedIndex : 0);
        _isLoading = false;
        _errorMessage = '';
      });
      if (wasEmpty) {
        _applyExternalSelection();
      }
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
    _selectIndex(index);
  }

  /// 选中某个一级分类：右侧面板回到顶部，左栏保证该项可见
  void _selectIndex(int index) {
    if (index < 0 || index >= _categories.length) return;
    setState(() => _selectedIndex = index);
    // 切换分类后右侧内容整体换掉，滚动位置要归零，否则会停在上一类的中间
    if (_panelController.hasClients) {
      _panelController.jumpTo(0);
    }
    _ensureRailVisible(index);
  }

  /// 应用外部（首页分类入口）传来的选中项
  void _applyExternalSelection() {
    final String? categoryId = widget.selectedCategoryId;
    if (categoryId == null || categoryId.isEmpty) return;
    // 分类还没加载完时先记着，等数据回来再补选（见 _loadCategories）
    if (_categories.isEmpty) return;
    final int index = _categories.indexWhere(
      (CategoryItem category) => category.id == categoryId,
    );
    if (index < 0) {
      debugPrint('首页分类入口传入的分类不在列表里，忽略: $categoryId');
      return;
    }
    _selectIndex(index);
  }

  /// 把左栏的第 [index] 项滚到可视区中央
  ///
  /// 左栏是小屏上可滚动的 ListView，从首页跳进来时选中项可能在屏幕外，
  /// 不滚一下用户会以为没生效。
  void _ensureRailVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_railController.hasClients) return;
      final ScrollPosition position = _railController.position;
      const double itemHeight = HmCategoryRail.defaultItemHeight;
      final double target =
          (index * itemHeight - (position.viewportDimension - itemHeight) / 2)
              .clamp(0.0, position.maxScrollExtent);
      if ((position.pixels - target).abs() < 1) return;
      _railController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
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
          controller: _railController,
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
