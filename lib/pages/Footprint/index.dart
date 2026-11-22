import 'package:flutter/material.dart';
import 'package:hm_shop/components/Footprint/hm_footprint_tile.dart';
import 'package:hm_shop/components/common/hm_empty_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/footprint.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/stores/footprint_store.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 我的足迹页
///
/// 后端没有足迹接口，数据来自本机存储（见 [FootprintStore]）：
/// 按「今天 / 昨天 / 更早」分组展示，支持清空，点卡片回到商品详情。
class FootprintPage extends StatefulWidget {
  const FootprintPage({super.key});

  @override
  State<FootprintPage> createState() => _FootprintPageState();
}

class _FootprintPageState extends State<FootprintPage> {
  List<FootprintItem> _items = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await FootprintStore.load();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  /// 二次确认后清空本机足迹
  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('清空浏览足迹？'),
          content: const Text('足迹只保存在本机，清空后无法恢复'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await FootprintStore.clear();
    if (!mounted) return;
    setState(() {
      _items = const [];
    });
    ToastUtils.showToast(context, '已清空足迹');
  }

  /// 回到商品详情；返回后重新读一次，让浏览时间与排序刷新
  Future<void> _openGoods(FootprintItem item) async {
    await Navigator.pushNamed(context, AppRoutes.goods(item.goodsId));
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('我的足迹'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _clear,
              child: const Text(
                '清空',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return HmEmptyView(
        icon: Icons.history,
        title: '还没有足迹',
        description: '浏览过的商品会出现在这里',
        actionText: '去逛逛',
        onAction: () => Navigator.pushNamed(context, AppRoutes.home),
      );
    }
    final groups = groupFootprints(_items);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: HmBottomBar.maxContentWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          children: [
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
                child: Text(
                  group.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              for (final item in group.items) ...[
                HmFootprintTile(item: item, onTap: () => _openGoods(item)),
                const SizedBox(height: 10),
              ],
            ],
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '足迹仅保存在本机，最多保留 ${FootprintStore.maxItems} 条',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
