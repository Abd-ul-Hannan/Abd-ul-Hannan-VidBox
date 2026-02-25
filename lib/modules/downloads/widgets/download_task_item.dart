import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../data/models/download_task_model.dart';
import '../controllers/downloads_controller.dart';

class DownloadTaskItem extends StatelessWidget {
  final DownloadTaskModel task;

  const DownloadTaskItem({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildThumbnail(),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfo(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressBar(),
            const SizedBox(height: 8),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (task.thumbnail.isEmpty) {
      return Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: Get.theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FaIcon(
            task.type == DownloadType.audio
                ? FontAwesomeIcons.music
                : FontAwesomeIcons.video,
            size: 24,
            color: Get.theme.primaryColor,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: task.thumbnail,
        width: 80,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: Get.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Get.theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.typeString.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Get.theme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              task.quality,
              style: Get.textTheme.bodySmall,
            ),
          ],
        ),
        if (task.isFailed && task.error != null) ...[
          const SizedBox(height: 4),
          Text(
            task.error!,
            style: Get.textTheme.bodySmall?.copyWith(
              color: Get.theme.colorScheme.error,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              task.statusString,
              style: Get.textTheme.bodySmall,
            ),
            Text(
              '${task.progress}%',
              style: Get.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: task.progress / 100,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              task.isFailed
                  ? Get.theme.colorScheme.error
                  : Get.theme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final controller = Get.find<DownloadsController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (task.isDownloading) ...[
          TextButton.icon(
            onPressed: () => controller.pauseDownload(task.id),
            icon: const FaIcon(FontAwesomeIcons.pause, size: 14),
            label: const Text('Pause'),
          ),
        ],
        if (task.isPaused) ...[
          TextButton.icon(
            onPressed: () => controller.resumeDownload(task.id),
            icon: const FaIcon(FontAwesomeIcons.play, size: 14),
            label: const Text('Resume'),
          ),
        ],
        if (task.isFailed) ...[
          TextButton.icon(
            onPressed: () => controller.retryDownload(task.id),
            icon: const FaIcon(FontAwesomeIcons.arrowRotateRight, size: 14),
            label: const Text('Retry'),
          ),
        ],
        if (!task.isCompleted) ...[
          TextButton.icon(
            onPressed: () => controller.cancelDownload(task.id),
            icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Get.theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
