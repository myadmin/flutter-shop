// https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/1.jpg
// https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/2.png
// https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/3.jpg
// BannerItem(
//   id: '1',
//   imageUrl:
//       'https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/1.jpg',
// ),
// BannerItem(
//   id: '2',
//   imageUrl:
//       'https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/2.png',
// ),
// BannerItem(
//   id: '3',
//   imageUrl:
//       'https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/3.jpg',
// ),
// https://meikou-api.itheima.net
// https://meikou-api.itheima.net/home/banner

class BannerItem {
  String id;
  String imageUrl;

  BannerItem({required this.id, required this.imageUrl});

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(id: json['id'], imageUrl: json['imgUrl']);
  }
}

// 根据json编写class对象和工厂转化函数
class CategoryItem {
  String id;
  String name;
  String picture;
  List<CategoryItem>? children;
  List<CategoryItem>? goods;

  CategoryItem({
    required this.id,
    required this.name,
    required this.picture,
    this.children,
    this.goods,
  });

  // 工厂转化函数
  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    // 必须返回CategoryItem对象，否则会报错
    return CategoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      picture: json['picture'] ?? '',
      children: json['children'] == null
          ? null
          : (json['children'] as List)
                .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
                .toList(),
      goods: json['goods'] == null
          ? null
          : (json['goods'] as List)
                .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
                .toList(),
    );
  }
}
