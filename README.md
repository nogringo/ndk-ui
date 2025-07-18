This package helps you to easily produce Nostr apps by providing generics Widgets and methods.

## Features

- Nostr widgets
- Login persistence

## Getting started

```bash
flutter pub add ndk
flutter pub add ndk_ui
```

## Usage

```dart
import 'package:ndk_ui/ndk_ui.dart';

// login page with all login methods
final loginPage = Center(
    child: NLogin(ndk),
);

// user info
final userPage = Stack(
    children: [
        NBanner(ndk, "<pubkey>"),
        Row(
            children: [
                CircleAvatar(
                    child: NPicture(ndk, "<pubkey>"),
                ),
                NName(ndk, "<pubkey>"),
            ]
        ),
    ]
);

// call this to connect user from local storage
nRestoreLastSession(ndk);

// logout the user and delete his local storage
nLogout(ndk);
```
