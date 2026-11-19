# 绘画作品集 · Painting Gallery

一款纯本地存储的个人绘画作品集 Flutter 应用，所有作品数据与图片都保存在设备上，无需任何后端服务。

> 大二移动开发软件课程作业 · 2026 秋季

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter) ![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart) ![License](https://img.shields.io/badge/license-MIT-blue)

---

## ✨ 功能特性

| 功能 | 说明 |
|------|------|
| 🏠 首页瀑布流 | 双列瀑布流展示全部作品，按原图比例自动排版 |
| 🔍 搜索 | 顶部搜索栏按标题实时过滤 |
| 🗂️ 筛选 | 全部作品 / 只看未分类 / 只看已分类 |
| ⬆️ 上传 | 从相册多选导入作品，自动读取原图尺寸 |
| ❤️ 个人收藏 | 红心标注喜欢的作品（不显示数字，私人使用） |
| 💾 下载到相册 | 详情页一键保存作品到系统相册 |
| 🏷️ 相册分类 | 创建相册、编辑名字、设置封面、把作品归类进去 |
| 🗑️ 删除 + 撤销 | 删除动画 + SnackBar 撤销（3 秒内可恢复）+ 手动关闭按钮 |
| 🔒 纯本地存储 | 图片存文件、元数据存 JSON，卸载会清除数据 |

## 📱 界面结构

```
启动页 (SplashPage)
  └─ 首页 Tab (HomePage)
       ├─ 顶部搜索栏 + 筛选按钮
       ├─ 双列瀑布流
       ├─ 底部「上传图片」按钮
       └─ 底部导航栏 [首页 | 相册]
  └─ 相册 Tab (AlbumsPage)
       ├─ 右上角 + 创建新相册
       ├─ 方形相册网格
       └─ 点击进入 → AlbumDetailPage
            ├─ 编辑相册名 / 设置封面
            ├─ 已分类图片网格（长按操作）
            ├─ 添加图片（多选已上传作品）
            └─ 删除相册

详情页 (DetailPage) — 从首页瀑布流点卡片进入
```

## 🛠️ 技术栈

- **Flutter** (Material 3) — UI 框架
- **image_picker** — 从相册选择图片
- **path_provider** — 获取应用私有目录
- **gal** — 保存图片到系统相册
- 数据持久化：JSON 文件 + 文件系统（无后端）

## 📂 项目结构

```
painting_gallery/
├── lib/
│   ├── data/
│   │   ├── work_store.dart      # 作品仓库（单例 + ChangeNotifier）
│   │   └── album_store.dart     # 相册仓库
│   ├── models/
│   │   ├── work.dart            # 作品数据模型
│   │   └── album.dart           # 相册数据模型
│   ├── pages/
│   │   ├── splash_page.dart     # 启动页
│   │   ├── home_page.dart       # 首页（含底部导航）
│   │   ├── albums_page.dart     # 相册列表
│   │   ├── album_detail_page.dart  # 单个相册详情
│   │   └── detail_page.dart     # 作品详情
│   ├── widgets/
│   │   ├── bow_logo.dart        # 启动页蝴蝶结 Logo（CustomPainter）
│   │   ├── gradient_button.dart # 渐变主按钮
│   │   └── work_card.dart       # 瀑布流卡片
│   ├── theme/
│   │   └── app_theme.dart       # 颜色 / 渐变 / 主题
│   └── main.dart
├── android/
├── ios/
└── pubspec.yaml
```

## 🚀 快速开始

### 环境要求

- Flutter SDK `>= 3.0.0`
- Dart SDK `>= 3.0.0 < 4.0.0`
- Android Studio / VS Code + Flutter 插件
- Android 真机（开启 USB 调试）或模拟器

### 运行项目

```bash
# 1. 进入项目目录
cd painting_gallery

# 2. 安装依赖
flutter pub get

# 3. 查看可用设备
flutter devices

# 4. 运行到设备
flutter run
```

### 构建 APK

```bash
# 开发调试包（体积较大）
flutter build apk --debug

# Release 正式包（推荐）
flutter build apk --release

# 产物位置
# build/app/outputs/flutter-apk/app-release.apk
```

### 安装到手机

```bash
# 方式 A：直接用 flutter run（最方便，有热重载）
flutter run

# 方式 B：把 APK 文件传到手机，点击安装
#   1. 数据线连接手机
#   2. 手机上开启「USB 文件传输」
#   3. 复制 build/app/outputs/flutter-apk/app-release.apk 到手机
#   4. 手机文件管理器里点击安装
```

## 📦 Releases

每个版本的 APK 构建产物保存在本地 `releases/vX.Y.Z/` 目录中，**不会被提交到 Git**（已在 `.gitignore` 中忽略）。

发布新版本时：
1. 更新 `pubspec.yaml` 中的 `version: X.Y.Z+buildNumber`
2. 构建：`flutter build apk --release`
3. 重命名 APK 放到 `releases/vX.Y.Z/` 目录
4. GitHub 网页端 → Releases → Draft a new release → 上传 APK

## 💾 数据存储说明

所有数据保存在应用私有目录 `painting_gallery/` 下：

```
painting_gallery/
├── works.json        # 作品元数据（标题、描述、浏览量、收藏状态）
├── albums.json       # 相册列表
└── images/xxx.jpg    # 作品原图
```

⚠️ 卸载应用会清除全部存储数据（Android/iOS 容器机制）。

## 📜 License

MIT License
