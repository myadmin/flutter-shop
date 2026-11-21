import 'package:flutter/material.dart';
import 'package:hm_shop/api/category.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/components/common/hm_goods_card.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/category_goods.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/utils/api_exception.dart';

/// 分类商品列表页：顶部同级分类切换 + 商品网格。
///
/// 数据来自 `/category/sub/filter?id=<分类 id>`：一次返回该分类下全部商品
/// （不分页）以及同级分类，所以页面不需要分页逻辑，切换同级分类时整页重取。
class GoodsListPage extends StatefulWidget {
  const GoodsListPage({
    super.key,
    required this.categoryId,
    required this.title,
  });

  /// 进入页面时的分类 id
  final String categoryId;

  /// 进入页面时的分类名（作为标题占位，接口返回后以接口数据为准）
  final String title;

  @override
  State<GoodsListPage> createState() => _GoodsListPageState();
}

class _GoodsListPageState extends State<GoodsListPage> {
  late String _categoryId = widget.categoryId;
  late String _title = widget.title;

  CategoryGoodsResult? _result;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_categoryId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '分类信息缺失，请返回重新选择';
      });
      return;
    }
    try {
      final CategoryGoodsResult result = await getCategoryGoodsAPI(_categoryId);
      if (!mounted) return;
      setState(() {
        _result = result;
        // 深链直接进来时标题只有 id，接口返回后用真实分类名覆盖
        if (result.name.isNotEmpty) {
          _title = result.name;
        }
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      debugPrint('获取分类商品失败: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = resolveErrorMessage(e, fallback: '商品列表加载失败');
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    _load();
  }

  /// 切换同级分类：清空旧数据再重取，避免短暂展示上一个分类的商品
  void _switchCategory(CategorySibling sibling) {
    if (sibling.id == _categoryId) return;
    setState(() {
      _categoryId = sibling.id;
      _title = sibling.name;
      _result = null;
      _isLoading = true;
      _errorMessage = '';
    });
    _load();
  }

  void _openGoods(GoodsItem item) {
    Navigator.pushNamed(context, AppRoutes.goods(item.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_title),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return AppErrorView(message: _errorMessage, onRetry: _retry);
    }
    final CategoryGoodsResult? result = _result;
    if (result == null) {
      return AppErrorView(message: '暂无商品数据', onRetry: _retry);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // 宽屏时把内容收进 600 的阅读宽度，与购物车、规格弹层保持一致
        final double side = constraints.maxWidth > HmBottomBar.maxContentWidth
            ? (constraints.maxWidth - HmBottomBar.maxContentWidth) / 2
            : 12;
        return RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (result.siblings.length > 1)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    AppSpacing.module,
                    side,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildSiblingChips(result.siblings),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, AppSpacing.module, side, 0),
                sliver: SliverToBoxAdapter(child: _buildSummary(result)),
              ),
              if (result.goods.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 0, side, AppSpacing.large),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 210,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: result.goods.length,
                    itemBuilder: (context, index) {
                      final GoodsItem item = result.goods[index];
                      return HmGoodsCard(
                        item: item,
                        onTap: () => _openGoods(item),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 同级分类快捷切换
  Widget _buildSiblingChips(List<CategorySibling> siblings) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: siblings.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final CategorySibling sibling = siblings[index];
          final bool selected = sibling.id == _categoryId;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _switchCategory(sibling),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primarySurface
                    : AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: selected ? Border.all(color: AppColors.primary) : null,
              ),
              child: Text(
                sibling.name,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(CategoryGoodsResult result) {
    final String parent = result.parentName;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.module),
      child: Row(
        children: [
          Text(
            '共 ${result.goods.length} 件商品',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (parent.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.small),
            Text(
              '· $parent',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.divider),
          SizedBox(height: AppSpacing.module),
          Text(
            '该分类下还没有商品',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
          SizedBox(height: AppSpacing.small),
          Text(
            '换个分类看看吧',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
