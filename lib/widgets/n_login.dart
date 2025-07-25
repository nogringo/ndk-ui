import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_ui/controllers/n_login_controller.dart';
import 'package:ndk_ui/l10n/app_localizations.dart';
import 'package:ndk_ui/ndk_ui.dart';
import 'package:nip01/nip01.dart';
import 'package:nip07_event_signer/nip07_event_signer.dart';
import 'package:nip19/nip19.dart';
import 'package:url_launcher/url_launcher.dart';

class NLogin extends StatelessWidget {
  static const _storage = FlutterSecureStorage();

  final Ndk ndk;
  final void Function()? onLoggedIn;
  final bool enableAccountCreation;
  final bool enableNip05Login;
  final bool enableNpubLogin;
  final bool enableNsecLogin;
  final bool enableNip07Login;

  const NLogin({
    super.key,
    required this.ndk,
    this.onLoggedIn,
    this.enableAccountCreation = true,
    this.enableNip05Login = true,
    this.enableNpubLogin = true,
    this.enableNsecLogin = true,
    this.enableNip07Login = true,
  });

  @override
  Widget build(BuildContext context) {
    Get.put(NLoginController());

    const double bottomPadding = 16;

    final createAccountView = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.newToNostr,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await launchUrl(Uri.parse('https://nstart.me/'));
            },
            child: Text(AppLocalizations.of(context)!.getStarted),
          ),
        ],
      ),
    );

    final nip05View = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.nostrAddress,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Obx(
            () => TextField(
              controller: NLoginController.to.nip05FieldController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.nostrAddressHint,
                suffixIcon: NLoginController.to.isFetchingNip05.isFalse
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: IconButton(
                          onPressed: () => loginWithNip05(
                            NLoginController.to.nip05FieldController.text,
                          ),
                          icon: Icon(Icons.arrow_forward),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                errorText: [
                  null,
                  AppLocalizations.of(context)!.invalidAddress,
                  AppLocalizations.of(context)!.unableToConnect,
                ][NLoginController.to.nip05LoginError.value],
              ),
              onChanged: nip05Change,
              onSubmitted: loginWithNip05,
            ),
          ),
        ],
      ),
    );

    final npubView = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.publicKey,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.publicKeyHint,
            ),
            onChanged: loginWithNpub,
          ),
        ],
      ),
    );

    final nsecView = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.privateKey,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.privateKeyHint,
            ),
            onChanged: loginWithNsec,
          ),
        ],
      ),
    );

    final nip07View = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.browserExtension,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          SizedBox(height: 8),
          FilledButton.icon(
            onPressed: loginWithNip07,
            label: Text(
              Nip07EventSigner().canSign()
                  ? AppLocalizations.of(context)!.connect
                  : AppLocalizations.of(context)!.install,
            ),
            icon: Icon(Icons.extension_outlined),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (enableNip05Login) nip05View,
        if (enableNpubLogin) npubView,
        if (enableNsecLogin) nsecView,
        if (enableNip07Login && kIsWeb) nip07View,
        if (enableAccountCreation) createAccountView,
      ],
    );
  }

  Future<void> loginWithNpub(String npub) async {
    String? pubkey;
    try {
      pubkey = Nip19.npubToHex(npub);
    } catch (e) {
      return;
    }

    await nLogout(ndk);
    ndk.accounts.loginPublicKey(pubkey: pubkey);

    await _storage.write(key: "ndk_ui_login_with", value: "npub");
    await _storage.write(key: "ndk_ui_pubkey", value: pubkey);

    loggedIn();
  }

  Future<void> loginWithNsec(String nsec) async {
    KeyPair? keyPair;
    try {
      keyPair = Nip19KeyPair.fromNsec(nsec);
    } catch (e) {
      return;
    }

    await nLogout(ndk);
    ndk.accounts.loginPrivateKey(
      pubkey: keyPair.publicKey,
      privkey: keyPair.privateKey,
    );

    await _storage.write(key: "ndk_ui_login_with", value: "nsec");
    await _storage.write(key: "ndk_ui_privkey", value: keyPair.privateKey);

    loggedIn();
  }

  void nip05Change(String _) {
    NLoginController.to.nip05LoginError.value = 0;
  }

  Future<void> loginWithNip05(String nip05) async {
    if (!GetUtils.isEmail(nip05)) {
      NLoginController.to.nip05LoginError.value = 1;
      return;
    }

    NLoginController.to.isFetchingNip05.value = true;
    final nip05Result = await fetchNip05(nip05);
    NLoginController.to.isFetchingNip05.value = false;

    final pubkey = nip05Result.pubkey;
    if (pubkey == null) {
      NLoginController.to.nip05LoginError.value = 2;
      return;
    }

    await nLogout(ndk);
    ndk.accounts.loginPublicKey(pubkey: pubkey);

    await _storage.write(key: "ndk_ui_login_with", value: "nip05");

    loggedIn();
  }

  Future<void> loginWithNip07() async {
    final signer = Nip07EventSigner();

    if (!signer.canSign()) {
      await launchUrl(
        Uri.parse(
          'https://chromewebstore.google.com/detail/nos2x/kpgefcfmnafjgpblomihpgmejjdanjjp',
        ),
      );
      return;
    }

    await signer.getPublicKeyAsync();

    await nLogout(ndk);
    ndk.accounts.loginExternalSigner(signer: signer);

    await _storage.write(key: "ndk_ui_login_with", value: "nip07");

    loggedIn();
  }

  void loggedIn() {
    if (onLoggedIn != null) onLoggedIn!();
  }
}
