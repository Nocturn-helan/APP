import 'dart:io';

import 'package:flutter/material.dart';

import '../data/album_store.dart';
import '../data/work_store.dart';
import '../models/album.dart';
import '../models/work.dart';
import '../theme/app_theme.dart';
import 'album_detail_page.dart';

/// 相册列表页：方形网格 + 左上角创建入口。
class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  final AlbumStore _albumStore = AlbumStore.instance;
  final WorkStore _workStore = WorkStore.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_albumStore, _workStore]),
      builder: (BuildContext context, Widget? child) {
        return Column(
          children: <Widget>[
            _buildTitleBar(),
            Expanded(child: _buildContent()),
          ],
        );
      },
    );
  }

  // ---------------- 标题栏 ----------------

  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: <Widget>[
          const Text(
            '相册',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _promptCreate,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- 主体内容 ----------------

  Widget _buildContent() {
    final List<Album> list = List<Album>.of(_albumStore.albums);

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              const Text(
                '还没有任何相册',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点右上角 + 创建一个属于你的第一个相册吧',
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
        // 两列布局：左右各 16 外边距，列间距 12
        final double columnWidth = (constraints.maxWidth - 32 - 12) / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _buildColumn(list, 0, columnWidth)),
              const SizedBox(width: 12),
              Expanded(child: _buildColumn(list, 1, columnWidth)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumn(List<Album> list, int startIndex, double width) {
    final List<Widget> children = <Widget>[];
    for (int i = startIndex; i < list.length; i += 2) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AlbumCard(
            album: list[i],
            workStore: _workStore,
            albumStore: _albumStore,
            onTap: () => _openAlbum(list[i]),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  void _openAlbum(Album album) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlbumDetailPage(albumId: album.id),
      ),
    );
  }

  // ---------------- 创建新相册 ----------------

  Future<void> _promptCreate() async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => _buildCreateDialog(
        dialogContext,
        controller,
      ),
    );
    if (name == null || !mounted) return;

    final Album album = _albumStore.createAlbum(name);
    // 创建后直接打开
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlbumDetailPage(albumId: album.id),
      ),
    );
  }

  Widget _buildCreateDialog(
    BuildContext dialogContext,
    TextEditingController controller,
  ) {
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
              '创建新相册',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                hintText: '给相册起个名字…',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => Navigator.of(dialogContext).pop(
                controller.text.trim().isEmpty ? '未命名相册' : controller.text.trim(),
              ),
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
                    onTap: () => Navigator.of(dialogContext).pop(
                      controller.text.trim().isEmpty
                          ? '未命名相册'
                          : controller.text.trim(),
                    ),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.button,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '创建',
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
  }
}

// =======================================================================
// 相册卡片
// =======================================================================

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.album,
    required this.workStore,
    required this.albumStore,
    required this.onTap,
  });

  final Album album;
  final WorkStore workStore;
  final AlbumStore albumStore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Work? coverWork = workStore.works
        .where((Work w) => w.id == album.coverWorkId)
        .firstOrNull;
    final String coverPath =
        coverWork != null ? workStore.imagePath(coverWork) : '';
    // 如果没有封面，用第一张图做兜底
    final Work? fallback = coverWork ??
        workStore.works.where((Work w) => album.contains(w.id)).firstOrNull;
    final String fallbackPath = fallback != null ? workStore.imagePath(fallback) : '';
    final String finalPath = coverPath.isNotEmpty ? coverPath : fallbackPath;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 方形封面
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: finalPath.isNotEmpty
                    ? Image.file(
                        File(finalPath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // 底部文字
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    album.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${album.count} 项',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Icon(
        Icons.photo_library_outlined,
        size: 48,
        color: AppColors.outline,
      ),
    );
  }
}
