/// 一个相册：包含若干作品 id，支持自定义名字与封面。
class Album {
  Album({
    required this.id,
    required this.name,
    String? coverWorkId,
    List<String>? workIds,
    DateTime? createdAt,
  })  : coverWorkId = coverWorkId ?? '',
        workIds = workIds ?? <String>[],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String coverWorkId;
  List<String> workIds;
  DateTime createdAt;

  int get count => workIds.length;

  String get displayName => name.trim().isEmpty ? '未命名相册' : name.trim();

  bool contains(String workId) => workIds.contains(workId);

  void addWork(String workId) {
    if (!workIds.contains(workId)) workIds.add(workId);
  }

  void removeWork(String workId) => workIds.remove(workId);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'coverWorkId': coverWorkId,
      'workIds': workIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '未命名相册',
      coverWorkId: json['coverWorkId'] as String? ?? '',
      workIds: (json['workIds'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
