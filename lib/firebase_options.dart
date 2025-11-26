import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {

    return const FirebaseOptions(

      apiKey: 'AIzaSyDebzZzgNk2cRKoWjStv4C9EIuJ9liP5-k',

      projectId: 'assesment-3-boy',

      messagingSenderId: '342889469290',

      appId: '1:342889469290:android:0c395472da435bfcefc113',

      databaseURL: 'https://assesment-3-boy-default-rtdb.firebaseio.com/',
    );
  }
}