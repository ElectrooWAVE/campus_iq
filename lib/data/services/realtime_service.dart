import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  RealtimeChannel? _notificationChannel;

  void subscribeToNotifications(String userId, Function(Map<String, dynamic>) onNew) {
    _notificationChannel = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onNew(payload.newRecord),
        )
        .subscribe();
  }

  void unsubscribe() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
  }
}
