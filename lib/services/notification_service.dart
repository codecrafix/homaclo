import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notifications are now delivered as real OS push notifications by
/// OneSignal (backed by Firebase FCM on Android / APNs on iOS) — triggered
/// server-side by a Supabase Edge Function whenever a row is inserted into
/// `notifications` or `admin_broadcasts`. See supabase/functions/send-push-notification.
///
/// This service is now only responsible for:
///  - the in-app notification list (fetch / mark read / delete)
///  - keeping the in-app unread badge in sync in real time while the app is
///    open, via Supabase Realtime (it does NOT show a local notification —
///    OneSignal already delivers the actual system push, so doing both would
///    show the same notification twice).
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  RealtimeChannel? _channel;
  RealtimeChannel? _broadcastChannel;

  SupabaseClient get _client => Supabase.instance.client;

  // ─── Save to Supabase (triggers the push via DB webhook -> Edge Function) ─

  Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
      });
    } catch (e) {
      debugPrint('saveNotification error: $e');
    }
  }

  /// Inserts the notification row, which fans out to a real OneSignal push
  /// via the Edge Function webhook (there is no local "show" step anymore).
  ///
  /// [localId] is accepted only so existing callers keep compiling; it is
  /// ignored because push delivery is handled by OneSignal.
  Future<void> triggerNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    int localId = 0,
  }) async {
    await saveNotification(userId: userId, title: title, body: body, type: type);
  }

  // ─── Fetch notifications ──────────────────────────────────────────────────

  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    try {
      final data = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchNotifications error: $e');
      return [];
    }
  }

  Future<void> markAllRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('markAllRead error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('deleteNotification error: $e');
    }
  }

  // ─── Real-time subscription (in-app badge/list sync only — no local popup)

  void subscribeToUserNotifications(
    String userId,
    void Function(NotificationModel) onNew,
  ) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final model = NotificationModel.fromJson(payload.newRecord);
              onNew(model);
            } catch (e) {
              debugPrint('realtime notification parse error: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to admin_broadcasts table for in-app badge/list sync. The
  /// actual push to all users' devices is sent by the Edge Function.
  void subscribeToAdminBroadcasts(
    void Function(String title, String body) onBroadcast,
  ) {
    _broadcastChannel?.unsubscribe();
    _broadcastChannel = _client
        .channel('admin_broadcasts_global')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'admin_broadcasts',
          callback: (payload) {
            try {
              final title = payload.newRecord['title'] as String? ?? 'Homaclo';
              final body = payload.newRecord['body'] as String? ?? '';
              onBroadcast(title, body);
            } catch (e) {
              debugPrint('realtime broadcast parse error: $e');
            }
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
    _broadcastChannel?.unsubscribe();
    _broadcastChannel = null;
  }

  // ─── Admin: broadcast to all users ────────────────────────────────────────

  Future<bool> broadcastToAllUsers({
    required String title,
    required String body,
    required String sentBy,
  }) async {
    try {
      // Save broadcast record — the DB webhook fans this out as a real push
      // to every subscribed device via the Edge Function.
      await _client.from('admin_broadcasts').insert({
        'title': title,
        'body': body,
        'sent_by': sentBy,
      });

      // Fetch all user IDs from profiles
      final profiles = await _client.from('profiles').select('id');
      final userIds = (profiles as List).map((p) => p['id'] as String).toList();

      // Insert an in-app notification row for each user too, so it shows
      // up in their in-app notification list/history.
      if (userIds.isNotEmpty) {
        final notifications = userIds
            .map(
              (uid) => {
                'user_id': uid,
                'title': title,
                'body': body,
                'type': 'broadcast',
              },
            )
            .toList();
        await _client.from('notifications').insert(notifications);
      }
      return true;
    } catch (e) {
      debugPrint('broadcastToAllUsers error: $e');
      return false;
    }
  }
}
