import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/album.dart';

/// 相册仓库：数据存在 `painting_gallery/albums.json`。
///
/// 单个作品可以同时属于多个相册（和真实相册行为一致），
/// 所以「已分类」定义为：作品在至少一个相册里。
class AlbumStore extends ChangeNotifier {
  AlbumStore._();

  static final AlbumStore instance = AlbumStore._();

  static const String _fileName = 'albums.json';
  static const String _imageDirName = 'images';

  final List<Album> albums = <Album>[];

  Directory? _root;
  Timer? _saveTimer;

  bool _loading = false;
  bool _loaded = false;
  bool loadFailed = false;
  String loadError = '本机相册读取失败';

  bool get isLoading => _loading;
  bool get isLoaded => _loaded;

  Future<Directory> _ensureRoot() async {
    final Directory? cached = _root;
    if (cached != null) return cached;

    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory root = Directory('${docs.path}/painting_gallery');
    if (!await root.exists()) await root.create(recursive: true);
    final Directory images = Directory('${root.path}/$_imageDirName');
    if (!await images.exists()) await images.create(recursive: true);
    _root = root;
    return root;
  }

  /// 启动时读取相册列表。
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    loadFailed = false;
    notifyListeners();

    try {
      final Directory root = await _ensureRoot();
      final File file = File('${root.path}/$_fileName');
      final List<Album> loaded = <Album>[];

      if (await file.exists()) {
        final String raw = await file.readAsString();
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final dynamic item in decoded) {
            if (item is Map<String, dynamic>) {
              loaded.add(Album.fromJson(item));
            }
          }
        }
      }

      loaded.sort((Album a, Album b) => b.createdAt.compareTo(a.createdAt));
      albums
        ..clear()
        ..addAll(loaded);
      _loaded = true;
    } catch (e) {
      loadFailed = true;
      loadError = '本机相册读取失败：$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String imagePath(String fileName) {
    final Directory? root = _root;
    if (root == null || fileName.isEmpty) return '';
    return '${root.path}/$fileName';
  }

  // ---------------- 增删改查 ----------------

  Album createAlbum(String name, {String? coverWorkId}) {
    final Album album = Album(
      id: 'album_${DateTime.now().microsecondsSinceEpoch}',
      name: name.isEmpty ? '未命名相册' : name,
      coverWorkId: coverWorkId ?? '',
    );
    albums.insert(0, album);
    notifyListeners();
    _persistNow();
    return album;
  }

  void renameAlbum(Album album, String newName) {
    album.name = newName;
    _schedulePersist();
    notifyListeners();
  }

  void setCoverWorkId(Album album, String? workId) {
    album.coverWorkId = workId ?? '';
    _schedulePersist();
    notifyListeners();
  }

  void addWorksToAlbum(Album album, List<String> workIds) {
    for (final String id in workIds) {
      album.addWork(id);
    }
    _schedulePersist();
    notifyListeners();
  }

  void removeWorksFromAlbum(Album album, List<String> workIds) {
    for (final String id in workIds) {
      album.removeWork(id);
    }
    // 如果封面图被移除，清空封面
    if (album.coverWorkId.isNotEmpty && !album.contains(album.coverWorkId)) {
      album.coverWorkId = '';
    }
    _schedulePersist();
    notifyListeners();
  }

  void deleteAlbum(Album album) {
    albums.removeWhere((Album a) => a.id == album.id);
    notifyListeners();
    _persistNow();
  }

  /// 某作品是否已被分类（出现在至少一个相册里）。
  bool isWorkCategorized(String workId) {
    return albums.any((Album a) => a.contains(workId));
  }

  /// 拿到包含该作品的所有相册 id。
  List<String> containingAlbumIds(String workId) {
    return albums
        .where((Album a) => a.contains(workId))
        .map((Album a) => a.id)
        .toList();
  }

  /// 当一个作品被彻底删除时，把它从所有相册中移除。
  void purgeWorkFromAllAlbums(String workId) {
    bool changed = false;
    for (final Album a in albums) {
      final bool had = a.contains(workId);
      a.removeWork(workId);
      if (had) changed = true;
      if (a.coverWorkId == workId) {
        a.coverWorkId = '';
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      _persistNow();
    }
  }

  // ---------------- 持久化 ----------------

  void _schedulePersist() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), _persistNow);
  }

  Future<void> _persistNow() async {
    final Directory? root = _root;
    if (root == null) return;
    try {
      final File file = File('${root.path}/$_fileName');
      final String raw = jsonEncode(
        albums.map((Album a) => a.toJson()).toList(),
      );
      await file.writeAsString(raw, flush: true);
    } catch (_) {
      // 写入失败不打断界面
    }
  }
}
