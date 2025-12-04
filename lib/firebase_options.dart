import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return android;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAEtnlCSUwfOd7-q-gRlCpekltH9Rrc-9w",
    authDomain: "pet-feed-192ef.firebaseapp.com",
    databaseURL: "https://pet-feed-192ef-default-rtdb.europe-west1.firebasedatabase.app",
    projectId: "pet-feed-192ef",
    storageBucket: "pet-feed-192ef.firebasestorage.app",
    messagingSenderId: "631795940534",
    appId: "1:631795940534:web:0b79f711beb83461a8ba17",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAEtnlCSUwfOd7-q-gRlCpekltH9Rrc-9w",
    authDomain: "pet-feed-192ef.firebaseapp.com",
    databaseURL: "https://pet-feed-192ef-default-rtdb.europe-west1.firebasedatabase.app",
    projectId: "pet-feed-192ef",
    storageBucket: "pet-feed-192ef.firebasestorage.app",
    messagingSenderId: "631795940534",
    appId: "1:631795940534:android:YOUR_ANDROID_APP_ID", 
  );
}
