import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/work.dart';

/// 本机作品仓库：图片存文件，作品信息存 JSON，替代原型里的 IndexedDB。
///
/// 目录结构（应用私有目录下）：
///   painting_gallery/
///     ├─ works.json          作品标题、描述、浏览量、点赞等
///     └─ images/xxx.jpg      作品原图
class WorkStore extends ChangeNotifier {
  WorkStore._();

  /// 全局单例：首页和详情页共用同一份数据
  static final WorkStore instance = WorkStore._();

  static const String _metaFileName = 'works.json';
  static const String _imageDirName = 'images';

  final List<Work> works = <Work>[];

  Directory? _root;
  Timer? _saveTimer;

  bool _loading = false;
  bool _loaded = false;
  bool loadFailed = false;
  String loadError = '本机存储读取失败，作品未能加载';

  bool get isLoading => _loading;
  bool get isLoaded => _loaded;

  /// 作品的图片绝对路径（未加载完成时返回空串）
  String imagePath(Work work) {
    final Directory? root = _root;
    if (root == null || work.fileName.isEmpty) return '';
    return '${root.path}/${work.fileName}';
  }

  Future<Directory> _ensureRoot() async {
    final Directory? cached = _root;
    if (cached != null) return cached;

    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory root = Directory('${docs.path}/painting_gallery');
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    final Directory images = Directory('${root.path}/$_imageDirName');
    if (!await images.exists()) {
      await images.create(recursive: true);
    }
    _root = root;
    return root;
  }

  /// 启动时读取本机作品；失败时由首页显示「读取失败 + 重试」提示条
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    loadFailed = false;
    notifyListeners();

    try {
      final Directory root = await _ensureRoot();
      final File file = File('${root.path}/$_metaFileName');
      final List<Work> loaded = <Work>[];

      if (await file.exists()) {
        final String raw = await file.readAsString();
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final dynamic item in decoded) {
            if (item is Map<String, dynamic>) {
              loaded.add(Work.fromJson(item));
            }
          }
        }
      }

      loaded.sort((Work a, Work b) => b.createdAt.compareTo(a.createdAt));
      works
        ..clear()
        ..addAll(loaded);
      _loaded = true;
    } catch (e) {
      loadFailed = true;
      loadError = '本机存储读取失败：$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 导入多张图片：复制到私有目录 + 读取原图尺寸（用于瀑布流比例）
  Future<int> importImages(List<String> sourcePaths) async {
    if (sourcePaths.isEmpty) return 0;

    final Directory root = await _ensureRoot();
    final List<Work> added = <Work>[];

    for (final String path in sourcePaths) {
      try {
        final File source = File(path);
        final Uint8List bytes = await source.readAsBytes();

        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        final int width = frame.image.width;
        final int height = frame.image.height;
        frame.image.dispose();
        codec.dispose();

        final String id = '${DateTime.now().microsecondsSinceEpoch}_${added.length}';
        final String relative = '$_imageDirName/$id.${_extensionOf(path)}';
        await File('${root.path}/$relative').writeAsBytes(bytes, flush: true);

        added.add(Work(
          id: id,
          title: _titleOf(path),
          fileName: relative,
          width: width,
          height: height,
          createdAt: DateTime.now(),
        ));
      } catch (_) {
        // 单张失败（损坏 / 无权限）时跳过，不影响其他作品
      }
    }

    if (added.isNotEmpty) {
      works.insertAll(0, added);
      notifyListeners();
      await _persistNow();
    }
    return added.length;
  }

  /// 打开详情页时浏览量 +1
  void openWork(Work work) {
    work.views += 1;
    _schedulePersist();
    notifyListeners();
  }

  void toggleLike(Work work) {
    work.liked = !work.liked;
    work.likes += work.liked ? 1 : -1;
    if (work.likes < 0) work.likes = 0;
    _schedulePersist();
    notifyListeners();
  }

  /// 标题 / 描述改动后调用，触发界面刷新与延迟落盘
  void touch() {
    _schedulePersist();
    notifyListeners();
  }

  /// 删除（先只从列表移除，配合「撤销」），返回原位置
  int removeWork(Work work) {
    final int index = works.indexOf(work);
    if (index >= 0) works.removeAt(index);
    notifyListeners();
    _schedulePersist();
    return index;
  }

  void restoreWork(Work work, int index) {
    final int position =
        index < 0 ? 0 : (index > works.length ? works.length : index);
    works.insert(position, work);
    notifyListeners();
    _persistNow();
  }

  /// 撤销超时后真正删除图片文件
  Future<void> purgeWork(Work work) async {
    final String path = imagePath(work);
    if (path.isNotEmpty) {
      try {
        final File file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // 文件已不存在时忽略
      }
    }
    _schedulePersist();
  }

  void _schedulePersist() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _persistNow);
  }

  Future<void> _persistNow() async {
    final Directory? root = _root;
    if (root == null) return;
    try {
      final File file = File('${root.path}/$_metaFileName');
      final String raw = jsonEncode(
        works.map((Work work) => work.toJson()).toList(),
      );
      await file.writeAsString(raw, flush: true);
    } catch (_) {
      // 写入失败不打断界面操作
    }
  }

  static String _titleOf(String path) {
    final String name = path.split(RegExp(r'[/\\]')).last;
    final int dot = name.lastIndexOf('.');
    final String title = dot > 0 ? name.substring(0, dot) : name;
    return title.isEmpty ? '我的作品' : title;
  }

  static String _extensionOf(String path) {
    final String name = path.split(RegExp(r'[/\\]')).last;
    final int dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'jpg';
    final String ext = name.substring(dot + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{1,5}$').hasMatch(ext) ? ext : 'jpg';
  }
}
