import 'package:flutter/material.dart'; // 引入 Flutter 基础 UI 组件库

/// 首页骨架屏
///
/// 首页真实数据返回前展示的占位界面，整体带呼吸闪烁动画，
/// 各区块布局与真实页面保持一致，减少加载完成后的视觉跳变。
class HomeSkeleton extends StatefulWidget { // 首页骨架屏组件
  const HomeSkeleton({super.key}); // 常量构造函数，透传 key

  @override // 重写创建状态对象的方法
  State<HomeSkeleton> createState() => _HomeSkeletonState(); // 返回骨架屏状态实例
} // HomeSkeleton 类结束

class _HomeSkeletonState extends State<HomeSkeleton> // 骨架屏状态类
    with SingleTickerProviderStateMixin { // 混入单个动画控制器的 Ticker 支持
  // 呼吸动画控制器
  late final AnimationController _controller; // 控制骨架屏的循环闪烁动画
  // 透明度动画
  late final Animation<double> _opacity; // 控制骨架屏整体透明度

  @override // 重写状态初始化方法
  void initState() { // 组件首次创建时执行
    super.initState(); // 调用父类初始化方法
    // 创建并启动循环动画，reverse: true 使动画来回往复播放
    _controller = AnimationController( // 初始化动画控制器
      vsync: this, // 绑定当前状态作为 Ticker 提供者
      duration: const Duration(milliseconds: 900), // 单次动画时长 900 毫秒
    )..repeat(reverse: true); // 循环播放，reverse 使动画来回往复
    // 透明度在 0.35 ~ 0.8 之间平滑变化，形成呼吸效果
    _opacity = Tween<double>( // 创建透明度补间动画
      begin: 0.35, // 起始透明度
      end: 0.8, // 结束透明度
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)); // 使用缓入缓出曲线
  } // initState 方法结束

  @override // 重写资源释放方法
  void dispose() { // 组件销毁时执行
    _controller.dispose(); // 释放动画控制器，避免内存泄漏
    super.dispose(); // 调用父类释放方法
  } // dispose 方法结束

  // 通用灰色占位块
  Widget _box({double? width, double height = 12, double radius = 8}) { // 生成圆角灰色占位块
    return Container( // 占位块容器
      width: width, // 占位块宽度
      height: height, // 占位块高度
      decoration: BoxDecoration( // 容器样式配置
        color: Colors.grey.shade300, // 灰色背景
        borderRadius: BorderRadius.circular(radius), // 圆角半径
      ),
    );
  } // _box 方法结束

  // 轮播图占位
  Widget _buildBanner() { // 构建轮播图占位区域
    return _box(height: 300, radius: 0); // 300 高的直角灰色占位块
  } // _buildBanner 方法结束

  // 分类入口占位
  Widget _buildCategory() { // 构建分类入口占位区域
    return Padding( // 外层内边距容器
      padding: const EdgeInsets.symmetric(horizontal: 10), // 左右各留 10 的边距
      child: Row( // 横向排列多个分类占位块
        spacing: 10, // 子项之间的间距
        children: List.generate( // 动态生成分类占位块列表
          5, // 生成 5 个分类占位块
          (index) => Expanded(child: _box(height: 80, radius: 40)), // 圆形占位块，均分宽度
        ),
      ),
    );
  } // _buildCategory 方法结束

  // 特惠推荐占位
  Widget _buildSuggestion() { // 构建特惠推荐占位区域
    return Padding( // 外层内边距容器
      padding: const EdgeInsets.symmetric(horizontal: 10), // 左右各留 10 的边距
      child: Container( // 灰色卡片容器
        padding: const EdgeInsets.all(12), // 卡片内边距
        decoration: BoxDecoration( // 卡片样式配置
          color: Colors.grey.shade200, // 浅灰色背景
          borderRadius: BorderRadius.circular(12), // 卡片圆角半径
        ),
        child: Column( // 纵向排列卡片内容
          crossAxisAlignment: CrossAxisAlignment.start, // 子项左对齐
          children: [ // 子项列表
            Row( // 标题行
              spacing: 10, // 子项之间的间距
              children: [ // 标题占位块列表
                _box(width: 90, height: 18), // 主标题占位块
                _box(width: 60, height: 12), // 副标题占位块
              ],
            ),
            const SizedBox(height: 12), // 标题与内容之间的间距
            Row( // 商品占位块行
              spacing: 10, // 子项之间的间距
              children: List.generate( // 动态生成商品占位块列表
                4, // 生成 4 个商品占位块
                (index) => Expanded( // 每个商品占位块均分宽度
                  child: Column( // 纵向排列单个商品占位块
                    children: [ // 子项列表
                      _box(height: 140, radius: 8), // 商品图片占位块
                      const SizedBox(height: 8), // 图片与价格之间的间距
                      _box(width: 60, height: 18, radius: 9), // 价格占位块
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  } // _buildSuggestion 方法结束

  // 爆款推荐、一站全买占位
  Widget _buildHotRow() { // 构建两列爆款推荐占位区域
    return Padding( // 外层内边距容器
      padding: const EdgeInsets.symmetric(horizontal: 10), // 左右各留 10 的边距
      child: Row( // 横向排列两张占位卡片
        spacing: 10, // 卡片之间的间距
        children: [ // 卡片列表
          Expanded(child: _buildHotCard()), // 左侧爆款推荐占位卡片
          Expanded(child: _buildHotCard()), // 右侧一站全买占位卡片
        ],
      ),
    );
  } // _buildHotRow 方法结束

  // 单个爆款推荐卡片占位
  Widget _buildHotCard() { // 构建单张推荐占位卡片
    return Container( // 灰色卡片容器
      padding: const EdgeInsets.all(10), // 卡片内边距
      decoration: BoxDecoration( // 卡片样式配置
        color: Colors.grey.shade200, // 浅灰色背景
        borderRadius: BorderRadius.circular(10), // 卡片圆角半径
      ),
      child: Column( // 纵向排列卡片内容
        crossAxisAlignment: CrossAxisAlignment.start, // 子项左对齐
        children: [ // 子项列表
          _box(width: 80, height: 16), // 模块标题占位块
          const SizedBox(height: 10), // 标题与内容之间的间距
          Row( // 商品占位块行
            spacing: 10, // 子项之间的间距
            children: List.generate( // 动态生成商品占位块列表
              2, // 生成 2 个商品占位块
              (index) => Expanded( // 每个商品占位块均分宽度
                child: Column( // 纵向排列单个商品占位块
                  children: [ // 子项列表
                    _box(height: 100, radius: 8), // 商品图片占位块
                    const SizedBox(height: 8), // 图片与价格之间的间距
                    _box(width: 55, height: 16, radius: 8), // 价格占位块
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  } // _buildHotCard 方法结束

  // 商品瀑布流占位
  Widget _buildGrid() { // 构建商品瀑布流占位区域
    return Padding( // 外层内边距容器
      padding: const EdgeInsets.symmetric(horizontal: 10), // 左右各留 10 的边距
      child: Column( // 纵向排列商品行
        children: List.generate(2, (rowIndex) { // 生成 2 行商品占位
          return Padding( // 每行的上边距容器
            padding: EdgeInsets.only(top: rowIndex == 0 ? 0 : 10), // 首行无间距，其余行留 10
            child: Row( // 横向排列两个商品占位块
              spacing: 10, // 商品之间的间距
              children: [ // 商品占位块列表
                Expanded(child: _box(height: 170, radius: 8)), // 左侧商品占位块
                Expanded(child: _box(height: 170, radius: 8)), // 右侧商品占位块
              ],
            ),
          );
        }),
      ),
    );
  } // _buildGrid 方法结束

  @override // 重写构建方法
  Widget build(BuildContext context) { // 构建骨架屏界面
    // 用 FadeTransition 包裹整个骨架屏，实现呼吸闪烁效果
    return FadeTransition( // 透明度过渡动画组件
      opacity: _opacity, // 绑定透明度动画
      // 骨架屏不可滚动，避免加载过程中用户误滑动
      child: SingleChildScrollView( // 单子项滚动容器
        physics: const NeverScrollableScrollPhysics(), // 禁止滚动
        child: Column( // 纵向排列各占位区域
          children: [ // 占位区域列表
            _buildBanner(), // 轮播图占位
            const SizedBox(height: 10), // 模块间距
            _buildCategory(), // 分类入口占位
            const SizedBox(height: 10), // 模块间距
            _buildSuggestion(), // 特惠推荐占位
            const SizedBox(height: 10), // 模块间距
            _buildHotRow(), // 爆款推荐与一站全买占位
            const SizedBox(height: 10), // 模块间距
            _buildGrid(), // 商品瀑布流占位
          ],
        ),
      ),
    );
  } // build 方法结束
} // 状态类结束
