import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_ui/ndk_ui.dart';

class NdkController extends GetxController {
  late final Ndk ndk;
  final isLoggedIn = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    ndk = Ndk.defaultConfig();
    _initializeLogin();
  }
  
  Future<void> _initializeLogin() async {
    await nRestoreLastSession(ndk);
    isLoggedIn.value = ndk.accounts.isLoggedIn;
  }
  
  String? get publicKey => ndk.accounts.getPublicKey();
}