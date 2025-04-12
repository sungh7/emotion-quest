// File: firebase_options_template.dart
// This is a template file. Rename to firebase_options.dart and fill in your Firebase configuration.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "YOUR_API_KEY_HERE",
    authDomain: "YOUR_AUTH_DOMAIN_HERE",
    projectId: "YOUR_PROJECT_ID_HERE",
    storageBucket: "YOUR_STORAGE_BUCKET_HERE",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID_HERE",
    appId: "YOUR_APP_ID_HERE",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "YOUR_API_KEY_HERE",
    appId: "YOUR_APP_ID_HERE",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID_HERE",
    projectId: "YOUR_PROJECT_ID_HERE",
    storageBucket: "YOUR_STORAGE_BUCKET_HERE",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "YOUR_API_KEY_HERE",
    appId: "YOUR_APP_ID_HERE",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID_HERE",
    projectId: "YOUR_PROJECT_ID_HERE",
    storageBucket: "YOUR_STORAGE_BUCKET_HERE",
    iosClientId: "YOUR_IOS_CLIENT_ID_HERE",
    iosBundleId: "YOUR_IOS_BUNDLE_ID_HERE",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "YOUR_API_KEY_HERE",
    appId: "YOUR_APP_ID_HERE",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID_HERE",
    projectId: "YOUR_PROJECT_ID_HERE",
    storageBucket: "YOUR_STORAGE_BUCKET_HERE",
    macosClientId: "YOUR_MACOS_CLIENT_ID_HERE",
    macosBundleId: "YOUR_MACOS_BUNDLE_ID_HERE",
  );
} 