import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const String _jobChannelId = 'hizmat_worker_jobs';
  static const String _jobChannelName = 'Job Notifications';
  static const String _jobChannelDesc =
      'New job requests and active job updates';

  static const String _generalChannelId = 'hizmat_worker_general';
  static const String _generalChannelName = 'General Notifications';
  static const String _generalChannelDesc = 'General app notifications';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  int _nextId = 0;

  int get _id => _nextId++;

  /// Initialises the notification plugin and creates Android channels.
  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channels.
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _jobChannelId,
          _jobChannelName,
          description: _jobChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _generalChannelId,
          _generalChannelName,
          description: _generalChannelDesc,
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  /// Shows a job notification. When [isUrgent] is `true` the Android
  /// notification is set to maximum importance with a full-screen intent.
  Future<void> showJobNotification({
    required String title,
    required String body,
    required String bookingRef,
    bool isUrgent = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _jobChannelId,
      _jobChannelName,
      channelDescription: _jobChannelDesc,
      importance: isUrgent ? Importance.max : Importance.high,
      priority: isUrgent ? Priority.max : Priority.high,
      fullScreenIntent: isUrgent,
      ticker: title,
      styleInformation: BigTextStyleInformation(body),
    );

    final notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      _id,
      title,
      body,
      notifDetails,
      payload: bookingRef,
    );
  }

  /// Shows a standard general-purpose notification.
  Future<void> showGeneralNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _generalChannelId,
      _generalChannelName,
      channelDescription: _generalChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
    );

    await _plugin.show(_id, title, body, notifDetails);
  }

  /// Cancels all scheduled and displayed notifications.
  Future<void> cancelAll() => _plugin.cancelAll();
}
