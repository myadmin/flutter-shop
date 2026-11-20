import 'package:flutter/material.dart';

/// 首页骨架屏
///
/// 首页真实数据返回前展示的占位界面，整体带呼吸闪烁动画，
/// 各区块布局与真实页面保持一致，减少加载完成后的视觉跳变。
class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key});

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
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
    // 透明度在 0.35 ~ 0.8 之间往复变化，形成呼吸效果
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

  /// 圆角灰色占位块，骨架屏所有区块的基础元素
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

  /// 灰色卡片容器，用于特惠推荐与爆款推荐区块
  Widget _card({
    required Widget child,
    double padding = 12,
    double radius = 12,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }

  Widget _buildBanner() => _box(height: 300, radius: 0);

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

  Widget _buildSuggestion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: _card(
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
                      _box(height: 140),
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
    return _card(
      padding: 10,
      radius: 10,
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
                    _box(height: 100),
                    const SizedBox(height: 8),
                    _box(width: 55, height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                Expanded(child: _box(height: 170)),
                Expanded(child: _box(height: 170)),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 骨架屏不可滚动，避免加载过程中用户误滑动
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
