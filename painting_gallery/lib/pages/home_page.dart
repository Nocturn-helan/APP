import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/work_store.dart';
import '../models/work.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/work_card.dart';
import 'detail_page.dart';

/// 首页：顶部搜索栏 + 双列瀑布流 + 底部上传入口。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WorkStore _store = WorkStore.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _query = '';
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.page),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _store,
            builder: (BuildContext context, Widget? child) {
              return Column(
                children: <Widget>[
                  _buildTopBar(),
                  if (_store.loadFailed) _buildStorageBanner(),
                  Expanded(child: _buildFeed()),
                  _buildUploadBar(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------- 顶部搜索栏 ----------------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: <Widget>[
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onFilterTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.white62,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final bool focused = _searchFocus.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: focused ? Colors.white : AppColors.white78,
        borderRadius: BorderRadius.circular(26),
        boxShadow: focused
            ? const <BoxShadow>[
                BoxShadow(color: AppColors.primary, spreadRadius: 2),
              ]
            : null,
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 16),
          const Icon(
            Icons.search,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: '搜索作品标题',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              onChanged: (String value) {
                setState(() => _query = value);
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ---------------- 本机存储失败提示条 ----------------

  Widget _buildStorageBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white86,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x42B44876), width: 1.5),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              _store.loadError,
              style: const TextStyle(
                fontSize: 12,
                height: 17 / 12,
                color: AppColors.danger,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _store.isLoading ? null : _store.load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppGradients.button,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _store.isLoading ? '加载中' : '重试',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- 瀑布流 ----------------

  Widget _buildFeed() {
    if (_store.isLoading && !_store.isLoaded) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.primary,
          ),
        ),
      );
    }

    final List<Work> list = _visibleWorks();
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '按 + 号开始展示自己的作品吧！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // 卡片左右各 16 外边距，两列间距 12
        final double columnWidth = (constraints.maxWidth - 32 - 12) / 2;
        final List<List<Work>> columns = _splitColumns(list, columnWidth);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _buildColumn(columns[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildColumn(columns[1])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumn(List<Work> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Work work in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WorkCard(
              work: work,
              imagePath: _store.imagePath(work),
              onTap: () => _openDetail(work),
            ),
          ),
      ],
    );
  }

  /// 与原型 JS 一样：每张卡片放进当前较矮的一列，实现瀑布流错位
  List<List<Work>> _splitColumns(List<Work> list, double columnWidth) {
    final List<List<Work>> columns = <List<Work>>[<Work>[], <Work>[]];
    final List<double> heights = <double>[0, 0];

    for (final Work work in list) {
      final int target = heights[0] <= heights[1] ? 0 : 1;
      columns[target].add(work);
      // 缩略图高度 + 卡片文字区高度（约 74）
      heights[target] += columnWidth / work.aspectRatio + 74;
    }
    return columns;
  }

  List<Work> _visibleWorks() {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) return List<Work>.of(_store.works);
    return _store.works
        .where((Work work) => work.title.toLowerCase().contains(query))
        .toList();
  }

  void _openDetail(Work work) {
    _store.openWork(work); // 浏览量 +1
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DetailPage(work: work)),
    );
  }

  // ---------------- 底部上传入口 ----------------

  Widget _buildUploadBar() {
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
      child: GradientButton(
        label: '上传图片',
        icon: Icons.add,
        height: 52,
        radius: 26,
        fontSize: 15,
        onPressed: _picking ? null : _pickImages,
      ),
    );
  }

  Future<void> _pickImages() async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final List<XFile> picked = await ImagePicker().pickMultiImage();
      if (picked.isEmpty) return;

      final int count = await _store.importImages(
        picked.map((XFile file) => file.path).toList(),
      );

      if (!mounted) return;
      if (count == 0) {
        _showSnack('保存失败：图片无法读取');
        return;
      }

      _searchController.clear();
      setState(() => _query = '');
      _showSnack('已保存 $count 幅作品到本机');
    } catch (e) {
      if (mounted) _showSnack('保存失败：$e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _onFilterTap() {
    _showSnack('筛选功能将在后续版本接入');
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
