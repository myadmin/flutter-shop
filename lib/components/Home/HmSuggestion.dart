import 'package:flutter/material.dart'; // 引入 Flutter 的 Material UI 组件库
import 'package:hm_shop/models/home.dart'; // 引入首页数据模型（特惠推荐相关类）

class HmSuggestion extends StatefulWidget {
  // 声明特惠推荐组件，继承有状态组件
  // 特惠推荐结果
  final SpecialRecommendResult specialRecommendResult; // 保存接口返回的特惠推荐数据

  const HmSuggestion({
    Key? key,
    required this.specialRecommendResult,
  }) // 构造函数，接收必填的特惠推荐数据
  : super(key: key); // 调用父类构造函数并传递 key

  @override // 重写创建状态对象的方法
  _HmSuggestionState createState() => _HmSuggestionState(); // 创建对应的状态对象
} // 结束 HmSuggestion 类

class _HmSuggestionState extends State<HmSuggestion> {
  // 声明特惠推荐组件的状态类
  List<GoodsItem> _getDisplayItems() {
    // 定义获取待展示商品的方法
    if (widget.specialRecommendResult.subTypes.isEmpty) {
      // 判断子类型列表是否为空
      return []; // 为空时返回空列表
    } // 结束空数据判断

    return widget
        .specialRecommendResult
        .subTypes
        .first
        .goodsItems
        .items // 取第一个子类型的商品列表
        .take(3) // 只取前 3 个商品
        .toList(); // 转换为列表返回
  } // 结束 _getDisplayItems 方法

  Widget _buildHeader() {
    // 定义构建顶部标题区域的方法
    return Padding(
      // 给标题区域添加内边距
      padding: EdgeInsets.symmetric(horizontal: 10), // 左右各留 10 的内边距
      child: Row(
        // 标题内容横向排列
        children: [
          // 标题子组件列表开始
          Text(
            // 主标题文字组件
            '特惠推荐', // 主标题内容
            style: TextStyle(
              // 主标题文字样式
              fontSize: 18, // 字号 18
              fontWeight: FontWeight.bold, // 文字加粗
              color: Color.fromARGB(255, 86, 24, 20), // 深棕色文字颜色
            ), // 结束主标题样式
          ), // 结束主标题组件
          SizedBox(width: 10), // 主标题与副标题之间留 10 的间距
          Text(
            // 副标题文字组件
            '精选省攻略', // 副标题内容
            style: TextStyle(
              // 副标题文字样式
              fontSize: 12, // 字号 12
              color: Color.fromARGB(255, 124, 63, 58), // 浅棕色文字颜色
            ), // 结束副标题样式
          ), // 结束副标题组件
        ], // 结束标题子组件列表
      ), // 结束标题 Row
    ); // 结束标题 Padding
  } // 结束 _buildHeader 方法

  // 左侧结构
  Widget _buildLeft() {
    // 定义构建左侧活动图片的方法
    return Container(
      // 左侧活动图片容器
      width: 100, // 容器宽度 100
      height: 140, // 容器高度 140
      decoration: BoxDecoration(
        // 容器装饰配置开始
        borderRadius: BorderRadius.circular(10), // 设置 10 的圆角
        image: DecorationImage(
          // 设置容器背景图片
          image: AssetImage('lib/assets/home_cmd_inner.png'), // 加载本地活动图片资源
          fit: BoxFit.cover, // 图片等比裁剪并铺满容器
        ), // 结束背景图片配置
      ), // 结束容器装饰配置
    ); // 结束左侧活动图片容器
  } // 结束 _buildLeft 方法

  List<Widget> _getChildrenList() {
    // 定义构建右侧商品列表的方法
    List<GoodsItem> list = _getDisplayItems(); // 获取需要展示的商品数据
    return List.generate(list.length, (int index) {
      // 按商品数量循环生成组件
      return Column(
        // 每个商品使用纵向布局
        children: [
          // 商品内部子组件列表开始
          ClipRRect(
            // 用圆角裁剪包裹商品图片
            borderRadius: BorderRadius.circular(8), // 设置 8 的圆角
            child: Container(
              // 商品图片外层容器
              width: 100, // 容器宽度 100
              height: 140, // 容器高度 140
              color: Colors.white, // 设置白色背景，避免透明图片露出底色
              child: Image.network(
                // 加载商品网络图片
                errorBuilder: (context, error, stackTrace) {
                  // 图片加载失败时的回调
                  return Image.asset(
                    // 加载加载失败时的本地占位图
                    'lib/assets/home_cmd_inner.png', // 本地占位图路径
                    width: 100, // 占位图宽度 100
                    height: 140, // 占位图高度 140
                    fit: BoxFit.cover, // 占位图等比裁剪铺满
                  ); // 结束占位图组件
                }, // 结束图片加载失败回调
                list[index].picture, // 当前商品的图片地址
                width: 100, // 商品图片宽度 100
                height: 140, // 商品图片高度 140
                fit: BoxFit.cover, // 商品图片等比裁剪铺满
              ), // 结束商品网络图片组件
            ), // 结束商品图片外层容器
          ), // 结束 ClipRRect
          SizedBox(height: 10), // 商品图片与价格标签之间留 10 的间距
          Container(
            // 价格标签容器
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ), // 左右内边距 10、上下内边距 4
            decoration: BoxDecoration(
              // 价格标签装饰配置开始
              color: const Color.fromARGB(255, 244, 125, 98), // 设置橙红色背景
              borderRadius: BorderRadius.circular(10), // 设置 10 的圆角
            ), // 结束价格标签装饰配置
            child: Text(
              // 价格文字组件
              "￥${list[index].price}元", // 拼接当前商品的价格文字
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
              ), // 设置白色文字
            ), // 结束价格文字组件
          ), // 结束价格标签容器
        ], // 结束商品内部子组件列表
      ); // 结束每个商品的 Column
    }); // 结束 List.generate 循环
  } // 结束 _getChildrenList 方法

  @override // 重写父类构建界面的方法
  Widget build(BuildContext context) {
    // 根据状态构建组件界面
    return Padding(
      // 给整个特惠推荐区域添加内边距
      padding: EdgeInsets.symmetric(horizontal: 10), // 左右各留 10 的外边距
      child: Container(
        // 特惠推荐卡片容器
        alignment: Alignment.center, // 卡片内容居中对齐
        padding: EdgeInsets.all(12), // 卡片四周内边距 12
        decoration: BoxDecoration(
          // 卡片装饰配置开始
          color: Colors.blue, // 设置蓝色兜底背景色
          borderRadius: BorderRadius.circular(12), // 设置 12 的圆角
          image: DecorationImage(
            // 设置卡片背景图片
            image: AssetImage('lib/assets/home_cmd_sm.png'), // 加载本地卡片背景图
            fit: BoxFit.cover, // 背景图等比裁剪铺满卡片
          ), // 结束卡片背景图片配置
        ), // 结束卡片装饰配置
        child: Column(
          // 卡片内容纵向排列
          children: [
            // 卡片子组件列表开始
            // 顶部内容
            _buildHeader(), // 构建顶部标题区域
            SizedBox(height: 10), // 标题与下方内容之间留 10 的间距
            Row(
              // 横向排列左侧活动图和右侧商品
              children: [
                // Row 子组件列表开始
                // 左侧图片与右侧商品均分空间，保证左右及中间间距一致
                Expanded(child: Center(child: _buildLeft())), // 左侧活动图占一份空间并居中显示
                ..._getChildrenList().map(
                  // 将右侧商品组件展开到当前子组件列表中
                  (child) =>
                      Expanded(child: Center(child: child)), // 每个商品占一份空间并居中显示
                ), // 结束右侧商品组件的展开
              ], // 结束 Row 子组件列表
            ), // 结束 Row
          ], // 结束卡片子组件列表
        ), // 结束卡片 Column
      ), // 结束特惠推荐卡片容器
    ); // 结束外层 Padding
  } // 结束 build 方法
} // 结束 _HmSuggestionState 类
