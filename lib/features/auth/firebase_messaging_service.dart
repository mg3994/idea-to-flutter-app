import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging;

  FirebaseMessagingService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  Future<void> initialize({
    required Function(String token) onTokenReceived,
    required Function(RemoteMessage message) onMessageReceived,
  }) async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await _messaging.getToken();
        if (token != null) {
          onTokenReceived(token);
        }

        FirebaseMessaging.onMessage.listen((message) {
          onMessageReceived(message);
        });
      }
    } catch (_) {
      // Graceful fallback for non-supported desktop platforms or uninitialized Firebase
    }
  }
}
