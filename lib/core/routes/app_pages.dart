import 'package:get/get.dart';
import '../../modules/main/bindings/main_binding.dart';
import '../../modules/main/views/main_view.dart';
import '../../modules/home/bindings/home_binding.dart';
import '../../modules/downloads/bindings/downloads_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.MAIN;

  static final routes = [
    GetPage(
      name: Routes.MAIN,
      page: () => const MainView(),
      binding: MainBinding(),
      bindings: [
        HomeBinding(),
        DownloadsBinding(),
      ],
    ),
  ];
}
