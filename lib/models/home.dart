// https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/1.jpg
// https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/2.png
// https://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/meituan/3.jpg
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
