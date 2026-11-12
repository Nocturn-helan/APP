import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../data/work_store.dart';
import '../models/work.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

/// 作品详情：大图 + 浏览量 + 可编辑标题/描述 + 下载 / 点赞 / 删除。
class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.work});

  final Work work;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  final WorkStore _store = WorkStore.instance;

  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final AnimationController _flyController;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  bool _deleting = false;
  bool _saving = false;

  Work get _work => widget.work;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _work.title);
    _descController = TextEditingController(text: _work.desc);
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _titleFocus.addListener(_onFocusChange);
    _descFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleFocus.removeListener(_onFocusChange);
    _descFocus.removeListener(_onFocusChange);
    _titleFocus.dispose();
    _descFocus.dispose();
    _titleController.dispose();
    _descController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.page),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  _buildAppBar(),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      children: <Widget>[
                        _buildHero(),
                        const SizedBox(height: 16),
                        _buildViewsChip(),
                        const SizedBox(height: 16),
                        _buildField(
                          label: '标题',
                          controller: _titleController,
                          focusNode: _titleFocus,
                          minLines: 1,
                          maxLines: 1,
                          onChanged: (String value) {
                            _work.title = value;
                            _store.touch();
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: '作品描述',
                          controller: _descController,
                          focusNode: _descFocus,
                          minLines: 3,
                          maxLines: 6,
                          hintText: '写下这幅作品的创作想法…',
                          onChanged: (String value) {
                            _work.desc = value;
                            _store.touch();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildActionBar(bottomInset),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- 顶部返回栏 ----------------

  Widget _buildAppBar() {
    return SizedBox(
      height: 64,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _deleting ? null : () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.chevron_left,
                size: 28,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const Text(
            '作品详情',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- 大图（含删除时的飞走动画） ----------------

  Widget _buildHero() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = math.min(420.0, width * _work.ratio);

        return AnimatedBuilder(
          animation: _flyController,
          builder: (BuildContext context, Widget? child) {
            final double eased = Curves.easeIn.transform(_flyController.value);
            final double screenHeight = MediaQuery.of(context).size.height;

            return Opacity(
              opacity: (1 - eased).clamp(0.0, 1.0).toDouble(),
              child: Transform.translate(
                offset: Offset(0, -screenHeight * 0.72 * eased),
                child: Transform.scale(
                  scale: 1 - 0.6 * eased,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 3 * eased,
                      sigmaY: 3 * eased,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.white62,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(child: _buildImage(BoxFit.contain)),
          ),
        );
      },
    );
  }

  Widget _buildImage(BoxFit fit) {
    final String path = _store.imagePath(_work);
    if (path.isEmpty) return const SizedBox.shrink();

    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: AppColors.outline,
          ),
        );
      },
    );
  }

  // ---------------- 浏览量 ----------------

  Widget _buildViewsChip() {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppGradients.chip,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.visibility_outlined,
                size: 14,
                color: Color(0xFF3B2F4C),
              ),
              const SizedBox(width: 5),
              const Text(
                '浏览量 ',
                style: TextStyle(fontSize: 12, color: Color(0xFF3B2F4C)),
              ),
              Text(
                '${_work.views}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- 可编辑字段 ----------------

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int minLines,
    required int maxLines,
    required ValueChanged<String> onChanged,
    String? hintText,
  }) {
    final bool focused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: focused ? Colors.white : AppColors.white72,
        borderRadius: BorderRadius.circular(14),
        boxShadow: focused
            ? const <BoxShadow>[
                BoxShadow(color: AppColors.primary, spreadRadius: 2),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.6,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: minLines,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 15,
              height: 22 / 15,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 15,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- 底部操作栏 ----------------

  Widget _buildActionBar(double bottomInset) {
    final bool liked = _work.liked;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.page86,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.dividerShadow,
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 12,
            child: GradientButton(
              label: _saving ? '保存中…' : '下载图片',
              height: 48,
              radius: 24,
              fontSize: 13,
              letterSpacing: 0.4,
              onPressed: _saving ? null : _saveToGallery,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(flex: 9, child: _buildLikeButton(liked)),
          const SizedBox(width: 10),
          Expanded(flex: 10, child: _buildDeleteButton()),
        ],
      ),
    );
  }

  Widget _buildLikeButton(bool liked) {
    final Color foreground = liked ? Colors.white : AppColors.like;

    return GestureDetector(
      onTap: _toggleLike,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          gradient: liked ? AppGradients.likeActive : AppGradients.likeIdle,
          borderRadius: BorderRadius.circular(24),
          border: liked
              ? null
              : Border.all(color: const Color(0x47D24A7A), width: 1.5),
          boxShadow: liked
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x59F177AE),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: foreground,
            ),
            const SizedBox(width: 5),
            Text(
              '${_work.likes}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _deleting ? null : _confirmDelete,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white62,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.danger, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Text(
          '删除作品',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }

  // ---------------- 点赞 ----------------

  void _toggleLike() {
    setState(() => _store.toggleLike(_work));
  }

  // ---------------- 下载（保存到系统相册） ----------------

  Future<void> _saveToGallery() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final String path = _store.imagePath(_work);
      if (path.isEmpty) throw Exception('图片文件不存在');

      if (!await Gal.hasAccess()) {
        final bool granted = await Gal.requestAccess();
        if (!granted) throw Exception('未获得相册权限');
      }

      await Gal.putImage(path, album: '绘画作品集');
      _showSnack('已保存「${_work.displayTitle}」到相册');
    } catch (e) {
      _showSnack('保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------- 删除：二次确认 + 飞走动画 + 撤销 ----------------

  Future<void> _confirmDelete() async {
    if (_deleting) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => _buildConfirmDialog(dialogContext),
    );
    if (confirmed != true || !mounted) return;

    await _runDelete();
  }

  Future<void> _runDelete() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final Work work = _work;

    setState(() => _deleting = true);
    await _flyController.forward();
    if (!mounted) return;

    final int index = _store.removeWork(work);
    navigator.pop();

    final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller =
        messenger.showSnackBar(
      SnackBar(
        content: Text('已删除「${work.displayTitle}」'),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => _store.restoreWork(work, index),
        ),
      ),
    );

    // 用户没有点「撤销」时，才真正删除图片文件
    controller.closed.then((SnackBarClosedReason reason) {
      if (reason != SnackBarClosedReason.action) {
        _store.purgeWork(work);
      }
    });
  }

  Widget _buildConfirmDialog(BuildContext dialogContext) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                '确认删除？',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '删除后可以撤销操作，确定要移除这幅作品吗？',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildDialogButton(
                      label: '取消',
                      background: AppColors.surfaceContainerHigh,
                      color: AppColors.onSurface,
                      onTap: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDialogButton(
                      label: '删除',
                      background: Colors.white,
                      color: AppColors.danger,
                      borderColor: AppColors.danger,
                      onTap: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required Color background,
    required Color color,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(21),
          border: borderColor == null
              ? null
              : Border.all(color: borderColor, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        ),
      );
  }
}
