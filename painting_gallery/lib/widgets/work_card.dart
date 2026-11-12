import 'dart:io';

import 'package:flutter/material.dart';

import '../models/work.dart';
import '../theme/app_theme.dart';

/// 瀑布流中的单张作品卡片：原图比例缩略图 + 标题 + 浏览量 + 点赞数。
class WorkCard extends StatelessWidget {
  const WorkCard({
    super.key,
    required this.work,
    required this.imagePath,
    required this.onTap,
  });

  final Work work;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AspectRatio(
                aspectRatio: work.aspectRatio,
                child: Container(
                  color: AppColors.surfaceContainer,
                  child: _buildThumb(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      work.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.visibility_outlined,
                          size: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${work.views}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        Icon(
                          work.liked ? Icons.favorite : Icons.favorite_border,
                          size: 11,
                          color: work.liked
                              ? AppColors.like
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${work.likes}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumb() {
    if (imagePath.isEmpty) return const SizedBox.shrink();
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 22,
            color: AppColors.outline,
          ),
        );
      },
    );
  }
}
