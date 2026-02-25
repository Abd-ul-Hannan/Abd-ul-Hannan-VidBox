import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/home_controller.dart';
import '../widgets/video_info_bottom_sheet.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VidBox'),
        actions: [
          IconButton(
            icon: Obx(() => Icon(
              controller.isDarkMode.value
                ? Icons.light_mode
                : Icons.dark_mode,
            )),
            onPressed: controller.toggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 40),
            _buildUrlInput(),
            const SizedBox(height: 20),
            _buildPasteButton(),
            const SizedBox(height: 40),
            _buildSupportedPlatforms(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Get.theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            FontAwesomeIcons.video,
            size: 48,
            color: Get.theme.primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Download Videos & Music',
          style: Get.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'From YouTube, Instagram, TikTok & more',
          style: Get.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUrlInput() {
    return Obx(() => TextField(
      controller: controller.urlController,
      decoration: InputDecoration(
        hintText: 'Paste video URL here',
        prefixIcon: const Icon(Icons.link),
        suffixIcon: controller.urlController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: controller.clearUrl,
            )
          : null,
        errorText: controller.urlError.value.isEmpty
          ? null
          : controller.urlError.value,
      ),
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      onChanged: (value) => controller.urlController.text = value,
      onSubmitted: (_) => controller.fetchVideoInfo(),
    ));
  }

  Widget _buildPasteButton() {
    return Obx(() => ElevatedButton.icon(
      onPressed: controller.isLoading.value
        ? null
        : controller.pasteAndFetch,
      icon: controller.isLoading.value
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : const FaIcon(FontAwesomeIcons.paste, size: 18),
      label: Text(
        controller.isLoading.value ? 'Loading...' : 'Paste & Fetch Info',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
      ),
    ));
  }

  Widget _buildSupportedPlatforms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supported Platforms',
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPlatformChip('YouTube', FontAwesomeIcons.youtube, Colors.red),
            _buildPlatformChip('Instagram', FontAwesomeIcons.instagram, Colors.pink),
            _buildPlatformChip('TikTok', FontAwesomeIcons.tiktok, Colors.black),
            _buildPlatformChip('Facebook', FontAwesomeIcons.facebook, Colors.blue),
            _buildPlatformChip('Twitter', FontAwesomeIcons.twitter, Colors.lightBlue),
            _buildPlatformChip('Vimeo', FontAwesomeIcons.vimeo, Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildPlatformChip(String name, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(name, style: Get.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
