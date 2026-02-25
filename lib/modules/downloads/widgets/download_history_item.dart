import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../../../data/models/download_model.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/downloads_controller.dart';

class DownloadHistoryItem extends StatelessWidget {
  final DownloadModel download;

  const DownloadHistoryItem({
    super.key,
    required this.download,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: download.status == 'completed' ? _openFile : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildThumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfo(),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (download.thumbnail.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Get.theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FaIcon(
            download.type == 'audio'
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
        imageUrl: download.thumbnail,
        width: 60,
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
          download.title,
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
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                download.type.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              download.quality,
              style: Get.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('MMM dd, yyyy - HH:mm').format(download.createdAt),
          style: Get.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        if (download.status == 'completed' && download.filePath != null) ...[
          FutureBuilder<int>(
            future: StorageService.getFileSize(download.filePath!),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data! > 0) {
                return Text(
                  StorageService.formatFileSize(snapshot.data!),
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'play' && download.status == 'completed') {
          _openFile();
        } else if (value == 'delete') {
          _deleteDownload();
        }
      },
      itemBuilder: (context) => [
        if (download.status == 'completed')
          const PopupMenuItem(
            value: 'play',
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.play, size: 16),
                SizedBox(width: 12),
                Text('Play'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              FaIcon(FontAwesomeIcons.trashCan, size: 16),
              SizedBox(width: 12),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (download.status) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      default:
        return Get.theme.primaryColor;
    }
  }

  Future<void> _openFile() async {
    if (download.filePath == null) return;

    try {
      final result = await OpenFilex.open(download.filePath!);

      if (result.type != ResultType.done) {
        Get.snackbar(
          'Error',
          'Could not open file: ${result.message}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open file',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _deleteDownload() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Download'),
        content: const Text(
          'Are you sure you want to delete this download?\nThe file will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Future.delayed(const Duration(milliseconds: 300), () {
                final controller = Get.find<DownloadsController>();
                controller.deleteFromHistory(download.id);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
