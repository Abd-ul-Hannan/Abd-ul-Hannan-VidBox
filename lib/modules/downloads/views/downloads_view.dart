import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/downloads_controller.dart';
import '../widgets/download_task_item.dart';
import '../widgets/download_history_item.dart';

class DownloadsView extends GetView<DownloadsController> {
  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          Obx(() {
            if (controller.downloadHistory.isNotEmpty) {
              return IconButton(
                icon: const FaIcon(FontAwesomeIcons.trashCan, size: 20),
                onPressed: controller.showClearHistoryDialog,
              );
            }
            return const SizedBox();
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshDownloads,
        child: Obx(() {
          final hasActiveTasks = controller.activeDownloads.isNotEmpty;
          final hasHistory = controller.downloadHistory.isNotEmpty;

          if (!hasActiveTasks && !hasHistory) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            slivers: [
              if (hasActiveTasks) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'Active Downloads',
                      style: Get.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = controller.activeDownloads[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DownloadTaskItem(task: task),
                        );
                      },
                      childCount: controller.activeDownloads.length,
                    ),
                  ),
                ),
              ],
              if (hasHistory) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'Download History',
                      style: Get.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final download = controller.downloadHistory[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DownloadHistoryItem(download: download),
                        );
                      },
                      childCount: controller.downloadHistory.length,
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Get.theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              FontAwesomeIcons.download,
              size: 64,
              color: Get.theme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Downloads Yet',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your downloads will appear here',
            style: Get.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
