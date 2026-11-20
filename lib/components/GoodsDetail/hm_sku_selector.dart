import 'package:flutter/material.dart';
import 'package:hm_shop/components/Cart/hm_cart_quantity_stepper.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/goods.dart';

/// 用户在规格弹层里做出的选择：具体规格 + 购买数量
class SkuSelection {
  const SkuSelection({required this.sku, required this.count});

  /// 选中的规格（含 skuId、价格、库存）
  final GoodsSku sku;

  /// 购买数量，范围 [1, sku.inventory]
  final int count;
}

/// 打开规格选择弹层
///
/// 返回 null 表示用户取消（点关闭按钮、点遮罩或按返回键）。
Future<SkuSelection?> showSkuSelector(
  BuildContext context, {
  required GoodsDetail detail,
  String confirmText = '确定',
}) {
  return showModalBottomSheet<SkuSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext sheetContext) {
      return HmSkuSelector(detail: detail, confirmText: confirmText);
    },
  );
}

/// 规格选择弹层
///
/// 从 [GoodsDetail.skus] 反推规格分组（如「颜色」「尺码」），
/// 选择每一组的取值后定位到唯一 SKU，并在此基础上选择购买数量。
/// 无库存的组合会被置灰且不可点，避免用户选到一个买不了的规格。
class HmSkuSelector extends StatefulWidget {
  /// 商品详情（只用其中的 skus / mainPictures / price）
  final GoodsDetail detail;

  /// 底部确认按钮的文案
  final String confirmText;

  const HmSkuSelector({
    super.key,
    required this.detail,
    this.confirmText = '确定',
  });

  @override
  State<HmSkuSelector> createState() => _HmSkuSelectorState();
}

class _HmSkuSelectorState extends State<HmSkuSelector> {
  /// 已选规格：规格名 → 规格值
  final Map<String, String> _selected = {};

  /// 规格分组（保持接口返回顺序）：规格名 → 可选值列表
  late final Map<String, List<String>> _groups;

  int _count = 1;

  @override
  void initState() {
    super.initState();
    _groups = _buildGroups();
    // 默认落在有库存的默认规格上，用户不选也能直接下单
    final sku = widget.detail.defaultSku;
    if (sku != null) {
      for (final spec in sku.specs) {
        _selected[spec.name] = spec.valueName;
      }
    }
    _clampCount();
  }

  Map<String, List<String>> _buildGroups() {
    final groups = <String, List<String>>{};
    for (final sku in widget.detail.skus) {
      for (final spec in sku.specs) {
        final values = groups.putIfAbsent(spec.name, () => <String>[]);
        if (!values.contains(spec.valueName)) {
          values.add(spec.valueName);
        }
      }
    }
    return groups;
  }

  Map<String, String> _specMapOf(GoodsSku sku) {
    return {for (final spec in sku.specs) spec.name: spec.valueName};
  }

  /// 当前选择对应的 SKU，没有匹配项时为 null
  GoodsSku? get _selectedSku {
    for (final sku in widget.detail.skus) {
      final specMap = _specMapOf(sku);
      final matched = _selected.entries.every(
        (entry) => specMap[entry.key] == entry.value,
      );
      if (matched) {
        return sku;
      }
    }
    return null;
  }

  /// 该取值在当前其他分组选择下是否还有货
  bool _isValueAvailable(String group, String value) {
    return widget.detail.skus.any((sku) {
      if (sku.inventory <= 0) {
        return false;
      }
      final specMap = _specMapOf(sku);
      if (specMap[group] != value) {
        return false;
      }
      for (final entry in _selected.entries) {
        if (entry.key == group) {
          continue;
        }
        if (specMap[entry.key] != entry.value) {
          return false;
        }
      }
      return true;
    });
  }

  /// 把数量收进 [1, 库存] 区间
  void _clampCount() {
    final stock = _selectedSku?.inventory ?? 0;
    if (stock <= 0) {
      _count = 1;
      return;
    }
    if (_count > stock) {
      _count = stock;
    }
    if (_count < 1) {
      _count = 1;
    }
  }

  void _onValueTap(String group, String value) {
    setState(() {
      _selected[group] = value;
      _clampCount();
    });
  }

  /// 形如「米白 / 73/18M」的已选摘要
  String get _selectedText {
    return _groups.keys
        .map((name) => _selected[name])
        .whereType<String>()
        .join(' / ');
  }

  String get _coverUrl {
    final sku = _selectedSku;
    if (sku != null && sku.picture.isNotEmpty) {
      return sku.picture;
    }
    return widget.detail.mainPictures.isEmpty
        ? ''
        : widget.detail.mainPictures.first;
  }

  @override
  Widget build(BuildContext context) {
    final sku = _selectedSku;
    final stock = sku?.inventory ?? 0;
    return Padding(
      // 键盘弹出时把弹层顶起来（当前没有输入框，保留以防后续加备注）
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            // 与底部操作栏、购物车列表保持同一内容宽度，宽屏下不至于拉满整屏
            constraints: const BoxConstraints(
              maxWidth: HmBottomBar.maxContentWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(sku, stock),
                _buildSpecs(),
                _buildQuantity(stock),
                _buildConfirm(sku, stock),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GoodsSku? sku, int stock) {
    final String stockText = sku == null
        ? '请选择规格'
        : (stock > 0 ? '库存 $stock 件' : '该规格暂时缺货');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.image),
            child: AppNetworkImage(
              url: _coverUrl,
              width: 88,
              height: 88,
              decodeWidth: 88,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '￥${sku?.price ?? widget.detail.price}',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stockText,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_selectedText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '已选 $_selectedText',
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecs() {
    if (_groups.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in _groups.entries) ...[
            Text(
              entry.key,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in entry.value)
                  _buildValueChip(entry.key, value),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildValueChip(String group, String value) {
    final bool selected = _selected[group] == value;
    final bool available = _isValueAvailable(group, value);
    final Color textColor = !available
        ? AppColors.textSecondary
        : (selected ? AppColors.primary : Colors.black);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: available ? () => _onValueTap(group, value) : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primarySurface
              : (available ? Colors.white : AppColors.inputFill),
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantity(int stock) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          const Text(
            '数量',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          HmCartQuantityStepper(
            count: _count,
            // 缺货时把上限设为 1，让「+」保持禁用
            stock: stock <= 0 ? 1 : stock,
            enabled: stock > 0,
            onChanged: (value) => setState(() {
              _count = value;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm(GoodsSku? sku, int stock) {
    final bool canBuy = sku != null && stock > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: HmBottomBarButton(
          text: widget.confirmText,
          primary: true,
          onPressed: canBuy
              ? () => Navigator.pop(
                  context,
                  SkuSelection(sku: sku, count: _count),
                )
              : null,
        ),
      ),
    );
  }
}
