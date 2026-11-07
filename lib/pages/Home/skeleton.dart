import 'package:flutter/material.dart';

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
