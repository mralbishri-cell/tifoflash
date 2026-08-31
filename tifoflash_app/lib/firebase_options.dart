import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDftMnZer4Fjsq90VX2GMa3U0LUcaSyiNw',
    appId: '1:554205703255:web:f06d0efbf433cc78660712',
    messagingSenderId: '554205703255',
    projectId: 'tifoflash',
    authDomain: 'tifoflash.firebaseapp.com',
    databaseURL: 'https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'tifoflash.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDftMnZer4Fjsq90VX2GMa3U0LUcaSyiNw',
    appId: '1:554205703255:android:d480efbf433cc78660712',
    messagingSenderId: '554205703255',
    projectId: 'tifoflash',
    databaseURL: 'https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'tifoflash.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDftMnZer4Fjsq90VX2GMa3U0LUcaSyiNw',
    appId: '1:554205703255:ios:c370efbf433cc78660712',
    messagingSenderId: '554205703255',
    projectId: 'tifoflash',
    databaseURL: 'https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'tifoflash.firebasestorage.app',
  );
}
