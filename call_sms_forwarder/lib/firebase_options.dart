// Bu dosya Firebase CLI ile oluşturulacak
// flutter pub add firebase_core
// flutterfire configure komutlarını çalıştırın

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
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
    apiKey: 'AIzaSyBgNNwWzvxdwH1APedg9mhpq1xX98eLzWA',
    appId: '1:857751704265:web:99ca42ef6d0a11f3fd3318',
    messagingSenderId: '857751704265',
    projectId: 'chat-cf257',
    authDomain: 'chat-cf257.firebaseapp.com',
    storageBucket: 'chat-cf257.appspot.com',
    measurementId: 'G-TFHMNBNYYC',
  );

  // Firebase Console'dan alınacak bilgiler

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC-dcKOmlulGxFa0wXIOw3_181KmRpdqic',
    appId: '1:857751704265:android:0e057ab821ce208efd3318',
    messagingSenderId: '857751704265',
    projectId: 'chat-cf257',
    storageBucket: 'chat-cf257.appspot.com',
  );

}