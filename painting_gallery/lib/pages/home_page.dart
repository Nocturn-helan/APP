import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/album_store.dart';
import '../data/work_store.dart';
import '../models/work.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/work_card.dart';
import 'albums_page.dart';
import 'detail_page.dart';

/// 首页：顶部搜索栏 + 双列瀑布流 + 底部上传入口。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WorkStore _store = WorkStore.instance;
  final AlbumStore _albumStore = AlbumStore.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _query = '';
  bool _picking = false;
  int _currentTab = 0; // 0 = 首页瀑布流, 1 = 相册列表
  int _filterMode = 0; // 0 = 全部, 1 = 未分类, 2 = 已分类

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
            animation: Listenable.merge(<Listenable>[_store, _albumStore]),
            builder: (BuildContext context, Widget? child) {
              return IndexedStack(
                index: _currentTab,
                children: <Widget>[
                  _buildHomeTab(),
                  const AlbumsPage(),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// Tab 0：首页内容（搜索栏 + 瀑布流 + 上传栏）
  Widget _buildHomeTab() {
    return Column(
      children: <Widget>[
        _buildTopBar(),
        if (_store.loadFailed) _buildStorageBanner(),
        Expanded(child: _buildFeed()),
        _buildUploadBar(),
      ],
    );
  }

  /// 底部导航：首页 / 相册
  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
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
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(child: _buildTabButton(0, Icons.home, '首页')),
            const SizedBox(width: 12),
            Expanded(child: _buildTabButton(1, Icons.photo_library, '相册')),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final bool selected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 48,
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.button : null,
          color: selected ? null : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x528C64D2),
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
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
          ],
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
    List<Work> list = List<Work>.of(_store.works);

    // 分类筛选：只对首页（Tab 0）生效
    if (_filterMode == 1) {
      list = list
          .where((Work w) => !_albumStore.isWorkCategorized(w.id))
          .toList();
    } else if (_filterMode == 2) {
      list = list.where((Work w) => _albumStore.isWorkCategorized(w.id)).toList();
    }

    final String query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((Work work) => work.title.toLowerCase().contains(query))
          .toList();
    }
    return list;
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
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
                  '筛选作品',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterOption(0, Icons.all_inclusive, '全部作品'),
                _buildFilterOption(1, Icons.inbox, '只看未分类'),
                _buildFilterOption(2, Icons.check_circle_outline, '只看已分类'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(int mode, IconData icon, String label) {
    final bool selected = _filterMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _filterMode = mode);
        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Expanded(child: Text(message)),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.white70),
              onPressed: messenger.hideCurrentSnackBar,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      ),
    );
  }
}
