import 'dart:io';

import 'package:flutter/material.dart';

import '../data/album_store.dart';
import '../data/work_store.dart';
import '../models/album.dart';
import '../models/work.dart';
import '../theme/app_theme.dart';

/// 单个相册的详情页：封面 + 名字 + 内部图片网格 + 添加 / 编辑 / 删除。
class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({super.key, required this.albumId});

  final String albumId;

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final AlbumStore _albumStore = AlbumStore.instance;
  final WorkStore _workStore = WorkStore.instance;

  late final TextEditingController _nameController;
  late final ScrollController _scrollController;

  bool _editMode = false;

  Album? get _album => _albumStore.albums
      .where((Album a) => a.id == widget.albumId)
      .firstOrNull;

  List<Work> get _worksInAlbum {
    final Album? album = _album;
    if (album == null) return const <Work>[];
    final List<Work> result = <Work>[];
    for (final String id in album.workIds) {
      for (final Work w in _workStore.works) {
        if (w.id == id) {
          result.add(w);
          break;
        }
      }
    }
    return result;
  }

  List<Work> get _availableWorks {
    // 所有已上传但不在当前相册中的作品
    final Album? album = _album;
    if (album == null) return List<Work>.of(_workStore.works);
    return _workStore.works
        .where((Work w) => !album.contains(w.id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _scrollController = ScrollController();
    _albumStore.addListener(_onAlbumChanged);
    _workStore.addListener(_onAlbumChanged);
  }

  @override
  void dispose() {
    _albumStore.removeListener(_onAlbumChanged);
    _workStore.removeListener(_onAlbumChanged);
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAlbumChanged() {
    if (!mounted) return;
    // 相册被删除了，返回上一页
    if (_album == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Album? album = _album;
    if (album == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.page),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(album),
              Expanded(
                child: _buildGrid(album),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- 顶部栏 + 相册信息 ----------------

  Widget _buildHeader(Album album) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.chevron_left, size: 28, color: AppColors.onSurface),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _editAlbumName,
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      album.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // 编辑模式切换
          GestureDetector(
            onTap: () => setState(() => _editMode = !_editMode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _editMode ? AppColors.primary : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _editMode ? '完成' : '编辑',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _editMode ? Colors.white : AppColors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- 图片网格 ----------------

  Widget _buildGrid(Album album) {
    final List<Work> works = _worksInAlbum;

    if (works.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.image_outlined,
                size: 64,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              const Text(
                '相册里还没有图片',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点下方「添加图片」把已上传的作品分类进来吧',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // 3 列
        const int crossAxisCount = 3;
        const double spacing = 4;
        final double width = constraints.maxWidth;
        final double itemWidth = (width - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final double itemHeight = itemWidth; // 方形

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: works.map((Work work) {
              final String path = _workStore.imagePath(work);
              final bool isCover = album.coverWorkId == work.id;
              return _editMode
                  ? _buildEditableTile(work, path, isCover, itemWidth, itemHeight)
                  : _buildNormalTile(work, path, itemWidth, itemHeight);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildNormalTile(Work work, String path, double width, double height) {
    return GestureDetector(
      onLongPress: () => _setCoverOrRemove(work),
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          child: path.isNotEmpty
              ? Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _tilePlaceholder(),
                )
              : _tilePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildEditableTile(
      Work work, String path, bool isCover, double width, double height) {
    return GestureDetector(
      onTap: () => _setCoverOrRemove(work),
      child: Stack(
        children: <Widget>[
          SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              child: path.isNotEmpty
                  ? Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _tilePlaceholder(),
                    )
                  : _tilePlaceholder(),
            ),
          ),
          if (isCover)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.star, size: 10, color: Colors.white),
                    SizedBox(width: 2),
                    Text('封面',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tilePlaceholder() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Icon(Icons.image_outlined, size: 28, color: AppColors.outline),
    );
  }

  // ---------------- 底部操作栏 ----------------

  Widget _buildBottomBar() {
    final List<Work> available = _availableWorks;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.page82,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.dividerShadow,
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: available.isEmpty ? null : _promptAddWorks,
                child: Opacity(
                  opacity: available.isEmpty ? 0.5 : 1,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppGradients.button,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x528C64D2),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      available.isEmpty ? '已无图片可添加' : '添加图片',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _confirmDeleteAlbum,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.danger, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '删除相册',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- 操作方法 ----------------

  Future<void> _editAlbumName() async {
    final Album? album = _album;
    if (album == null) return;
    _nameController.text = album.name;

    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  '编辑相册名',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    hintText: '相册名字',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => Navigator.of(dialogContext)
                      .pop(_nameController.text.trim()),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext)
                            .pop(_nameController.text.trim()),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppGradients.button,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '保存',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (newName != null && mounted) {
      _albumStore.renameAlbum(album, newName.isEmpty ? '未命名相册' : newName);
    }
  }

  void _setCoverOrRemove(Work work) {
    final Album? album = _album;
    if (album == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.star_border, color: AppColors.primary),
                  title: const Text('设为相册封面'),
                  onTap: () {
                    _albumStore.setCoverWorkId(album, work.id);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                  title: const Text('从相册移除'),
                  onTap: () {
                    _albumStore.removeWorksFromAlbum(album, <String>[work.id]);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                  title: const Text('取消'),
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptAddWorks() async {
    final List<Work> available = _availableWorks;
    if (available.isEmpty) return;
    final Album? album = _album;
    if (album == null) return;

    final Set<String> selected = <String>{};

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext sheetCtx, StateSetter setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      '选择要添加的作品',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: ListView.separated(
                        itemCount: available.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (BuildContext ctx, int index) {
                          final Work work = available[index];
                          final String path = _workStore.imagePath(work);
                          final bool chosen = selected.contains(work.id);
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                if (chosen) {
                                  selected.remove(work.id);
                                } else {
                                  selected.add(work.id);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: chosen
                                    ? AppColors.primaryContainer
                                    : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: chosen
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: path.isNotEmpty
                                          ? Image.file(File(path), fit: BoxFit.cover)
                                          : Container(
                                              color: AppColors.surfaceContainer,
                                              child: const Icon(Icons.image_outlined),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      work.displayTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    chosen
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: chosen
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(sheetContext).pop(),
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Text(
                                '取消',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _albumStore.addWorksToAlbum(
                                album,
                                selected.toList(),
                              );
                              Navigator.of(sheetContext).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      selected.isEmpty
                                          ? '未选择任何作品'
                                          : '已添加 ${selected.length} 幅作品',
                                    ),
                                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppGradients.button,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                selected.isEmpty
                                    ? '选一些'
                                    : '添加 ${selected.length}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteAlbum() async {
    final Album? album = _album;
    if (album == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                '删除相册？',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '只会删除相册本身，里面的作品不会被移除。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(true),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(color: AppColors.danger, width: 1.5),
                        ),
                        child: const Text(
                          '删除',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      _albumStore.deleteAlbum(album);
      Navigator.of(context).pop();
    }
  }
}
