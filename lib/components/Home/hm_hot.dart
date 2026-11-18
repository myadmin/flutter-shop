import 'package:flutter/material.dart';
import 'package:hm_shop/models/home.dart';

/// 通用商品聚合模块配置。
/// 通过替换配置即可复用同一套渲染逻辑，适配爆款推荐、一站全买等业务场景。
class HmHotConfig {
  /// 模块标识，用于区分不同业务场景
  final String moduleId;

  /// 模块主标题
  final String title;

  /// 模块副标题
  final String subtitle;

  /// 卡片背景色
  final Color backgroundColor;

  /// 价格标签背景色
  final Color accentColor;

  /// 最多展示的商品数量
  final int maxCount;

  /// 商品图片高度
  final double imageHeight;

  /// 使用数据源中的第几个子类型
  final int subTypeIndex;

  const HmHotConfig({
    required this.moduleId,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    this.accentColor = const Color(0xFFF47D62),
    this.maxCount = 2,
    this.imageHeight = 100,
    this.subTypeIndex = 0,
  });

  /// 爆款推荐场景配置（对应接口 /hot/inVogue）
  static const HmHotConfig inVogue = HmHotConfig(
    moduleId: 'hot',
    title: '爆款推荐',
    subtitle: '最受欢迎',
    backgroundColor: Color(0xFFDDEBF7),
    maxCount: 2,
  );

  /// 一站全买场景配置（对应接口 /hot/oneStop）
  static const HmHotConfig oneStop = HmHotConfig(
    moduleId: 'oneStop',
    title: '一站全买',
    subtitle: '精心优选',
    backgroundColor: Color(0xFFFDF3D8),
    maxCount: 2,
  );
}

/// 通用商品聚合展示组件。
/// 负责商品卡片渲染、价格标签展示与点击交互，模块差异全部通过 [config] 注入。
class HmHot extends StatelessWidget {
  /// 当前业务场景配置
  final HmHotConfig config;

  /// 模块数据源，接口未返回时可为空
  final SpecialRecommendResult? result;

  /// 商品点击回调，可按业务场景接入加入购物车、结算等逻辑
  final ValueChanged<GoodsItem>? onGoodsTap;

  const HmHot({super.key, required this.config, this.result, this.onGoodsTap});

  /// 从数据源中提取当前模块需要展示的商品
  List<GoodsItem> _getDisplayItems() {
    final result = this.result;
    if (result == null || result.subTypes.isEmpty) {
      return const [];
    }
    if (config.subTypeIndex < 0 ||
        config.subTypeIndex >= result.subTypes.length) {
      return const [];
    }
    return result.subTypes[config.subTypeIndex].goodsItems.items
        .take(config.maxCount)
        .toList();
  }

  /// 构建模块标题区域
  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          config.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 86, 24, 20),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            config.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color.fromARGB(255, 124, 63, 58),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建单个商品卡片
  Widget _buildGoods(GoodsItem goods) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onGoodsTap == null ? null : () => onGoodsTap!(goods),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: config.imageHeight,
              color: Colors.white,
              child: Image.network(
                goods.picture,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade300,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: config.accentColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '￥${goods.price}元',
                maxLines: 1,
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _getDisplayItems();
    return Container(
      key: ValueKey('hm-hot-${config.moduleId}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          Row(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            // 商品图片宽度为 infinity，必须由 Expanded 提供有限宽度
            children: items
                .map((goods) => Expanded(child: _buildGoods(goods)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
