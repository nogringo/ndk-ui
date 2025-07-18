import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk_ui/l10n/app_localizations.dart';
import 'controllers/ndk_controller.dart';
import 'pages/login_page.dart';
import 'pages/account_page.dart';

void main() {
  Get.put(NdkController());
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ndkController = Get.find<NdkController>();

    return GetMaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Obx(
        () => ndkController.isLoggedIn.value
            ? const AccountPage()
            : const LoginPage(),
      ),
    );
  }
}
