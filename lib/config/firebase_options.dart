// File generated from Firebase Console configuration
// Project: MiniSocialNetwork

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDeC1y4sakFBKLTvv6A_fFRmV33fxe3CVI',
    appId: '1:907888233978:web:a51d2511507ec40533e843',
    messagingSenderId: '907888233978',
    projectId: 'minisocialnetwork-17a34',
    authDomain: 'minisocialnetwork-17a34.firebaseapp.com',
    storageBucket: 'minisocialnetwork-17a34.firebasestorage.app',
    measurementId: 'G-FX2SB9JV3V',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDeC1y4sakFBKLTvv6A_fFRmV33fxe3CVI',
    appId: '1:907888233978:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '907888233978',
    projectId: 'minisocialnetwork-17a34',
    storageBucket: 'minisocialnetwork-17a34.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDeC1y4sakFBKLTvv6A_fFRmV33fxe3CVI',
    appId: '1:907888233978:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '907888233978',
    projectId: 'minisocialnetwork-17a34',
    storageBucket: 'minisocialnetwork-17a34.firebasestorage.app',
    iosBundleId: 'com.example.flutterSocialnetworkmini',
  );
}
