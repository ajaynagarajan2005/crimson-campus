import 'package:firebase_core/firebase_core.dart';

/// Firebase project "crimson-campus-inti" (web app "Crimson Campus Web").
///
/// These values identify the app to Firebase and are safe to ship in the
/// client; access to data is controlled by firestore.rules.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAWf-fqyaUervP7Z-WMqb_ZtNu3rsDbn1s',
    appId: '1:957055718566:web:6264cd3098735e91199067',
    messagingSenderId: '957055718566',
    projectId: 'crimson-campus-inti',
    authDomain: 'crimson-campus-inti.firebaseapp.com',
    storageBucket: 'crimson-campus-inti.firebasestorage.app',
  );
}
