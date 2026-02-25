import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../data/models/video_info_model.dart';
import '../../downloads/controllers/downloads_controller.dart';
import '../../../data/models/download_task_model.dart';

class VideoInfoBottomSheet extends StatefulWidget {
  final VideoInfoModel videoInfo;

  const VideoInfoBottomSheet({
    super.key,
    required this.videoInfo,
  });

  @override
  State<VideoInfoBottomSheet> createState() => _VideoInfoBottomSheetState();
}

class _VideoInfoBottomSheetState extends State<VideoInfoBottomSheet> {
  DownloadType selectedType = DownloadType.video;
  String? selectedQuality;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    selectedQuality = selectedType == DownloadType.video
        ? widget.videoInfo.videoQualities.firstOrNull
        : widget.videoInfo.audioQualities.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDragHandle(),
            const SizedBox(height: 16),
            _buildThumbnail(),
            const SizedBox(height: 20),
            _buildVideoInfo(),
            const SizedBox(height: 24),
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildQualitySelector(),
            const SizedBox(height: 24),
            _buildDownloadButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (widget.videoInfo.thumbnail.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Get.theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.video,
            size: 48,
            color: Get.theme.primaryColor,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: widget.videoInfo.thumbnail,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.videoInfo.title,
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.user,
              size: 14,
              color: Get.theme.textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.videoInfo.author,
                style: Get.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.videoInfo.duration > 0) ...[
              const SizedBox(width: 16),
              FaIcon(
                FontAwesomeIcons.clock,
                size: 14,
                color: Get.theme.textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 6),
              Text(
                widget.videoInfo.formattedDuration,
                style: Get.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Get.theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.videoInfo.platform,
            style: Get.textTheme.bodySmall?.copyWith(
              color: Get.theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Download Type',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeChip(
                label: 'Video',
                icon: FontAwesomeIcons.video,
                type: DownloadType.video,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeChip(
                label: 'Audio',
                icon: FontAwesomeIcons.music,
                type: DownloadType.audio,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required DownloadType type,
  }) {
    final isSelected = selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          selectedType = type;
          selectedQuality = type == DownloadType.video
              ? widget.videoInfo.videoQualities.firstOrNull
              : widget.videoInfo.audioQualities.firstOrNull;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Get.theme.primaryColor
              : Get.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Get.theme.primaryColor
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            FaIcon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : Get.theme.iconTheme.color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySelector() {
    final qualities = selectedType == DownloadType.video
        ? widget.videoInfo.videoQualities
        : widget.videoInfo.audioQualities;

    if (qualities.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Quality',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: qualities.map((quality) {
            final isSelected = selectedQuality == quality;
            return ChoiceChip(
              label: Text(quality),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedQuality = quality;
                });
              },
              selectedColor: Get.theme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return ElevatedButton.icon(
      onPressed: isDownloading ? null : _handleDownload,
      icon: isDownloading 
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : const FaIcon(FontAwesomeIcons.download, size: 18),
      label: Text(
        isDownloading ? 'Starting...' : 'Start Download',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  Future<void> _handleDownload() async {
    if (selectedQuality == null) {
      Get.snackbar(
        'Error',
        'Please select a quality',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => isDownloading = true);
    
    try {
      Get.back(); // Close bottom sheet first
      
      final downloadsController = Get.find<DownloadsController>();
      await downloadsController.startDownload(
        videoInfo: widget.videoInfo,
        type: selectedType,
        quality: selectedQuality!,
      );
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }
  }
}
