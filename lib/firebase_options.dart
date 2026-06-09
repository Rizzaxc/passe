// File generated to match `flutterfire configure` output, derived from the
// committed android/app/google-services.json and ios/Runner/GoogleService-Info.plist
// (Firebase project `passe-498715`). These are public client identifiers — the
// same values already shipped in those native config files.
//
// If you re-run `flutterfire configure`, let it overwrite this file.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCSKqe-dXNs35SGdht5g6GHPLtOmtWrQrg',
    appId: '1:618362334941:android:936faf61dd29f6e6993534',
    messagingSenderId: '618362334941',
    projectId: 'passe-498715',
    storageBucket: 'passe-498715.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArS7kQnIb0c0cb94Vv50PYio2hXlxV5wk',
    appId: '1:618362334941:ios:23ff44b0e893def6993534',
    messagingSenderId: '618362334941',
    projectId: 'passe-498715',
    storageBucket: 'passe-498715.firebasestorage.app',
    iosClientId:
        '618362334941-9c6p21hlie4iatg7nadtka3fdrc7vt70.apps.googleusercontent.com',
    iosBundleId: 'passe.vn.passe',
  );
}
