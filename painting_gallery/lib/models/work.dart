/// 一件作品的数据模型。
///
/// 图片文件本身保存在应用私有目录（见 WorkStore），这里只保存相对路径，
/// 避免 iOS 容器路径变化后找不到文件。
class Work {
  Work({
    required this.id,
    required this.title,
    required this.fileName,
    required this.width,
    required this.height,
    required this.createdAt,
    this.desc = '',
    this.views = 0,
    this.likes = 0,
    this.liked = false,
  });

  final String id;
  final String fileName;
  final int width;
  final int height;
  final DateTime createdAt;

  String title;
  String desc;
  int views;
  int likes;
  bool liked;

  /// 宽 / 高，用于瀑布流按原图比例排版
  double get aspectRatio =>
      (width <= 0 || height <= 0) ? 4 / 3 : width / height;

  /// 高 / 宽，用于详情页按原图比例计算展示高度
  double get ratio => (width <= 0 || height <= 0) ? 3 / 4 : height / width;

  String get displayTitle => title.trim().isEmpty ? '未命名作品' : title.trim();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'desc': desc,
      'views': views,
      'likes': likes,
      'liked': liked,
      'fileName': fileName,
      'width': width,
      'height': height,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Work.fromJson(Map<String, dynamic> json) {
    return Work(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '未命名作品',
      desc: json['desc'] as String? ?? '',
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      liked: json['liked'] as bool? ?? false,
      fileName: json['fileName'] as String? ?? '',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
