import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'review_model.dart';
import 'local_notification_service.dart';

/// Manages all Firebase Realtime Database listeners for live updates.
/// Uses internal caches so the UI always has the latest data, even
/// if the StreamBuilder subscribes after the first Firebase event.
class RealtimeSyncService {
  static final RealtimeSyncService _instance = RealtimeSyncService._internal();
  factory RealtimeSyncService() => _instance;
  RealtimeSyncService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://travelapp-ab318-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
  final LocalNotificationService _localNotif = LocalNotificationService();

  // Stream Controllers
  final _reviewsController = StreamController<ReviewModel>.broadcast();
  final _repliesController = StreamController<MapEntry<int, List<ReplyModel>>>.broadcast();
  final _reactionsController = StreamController<MapEntry<int, Map<String, int>>>.broadcast();
  final _notificationsController = StreamController<AppNotificationModel>.broadcast();

  Stream<ReviewModel> get reviewsStream => _reviewsController.stream;
  Stream<MapEntry<int, List<ReplyModel>>> get repliesStream => _repliesController.stream;
  Stream<MapEntry<int, Map<String, int>>> get reactionsStream => _reactionsController.stream;
  Stream<AppNotificationModel> get notificationsStream => _notificationsController.stream;

  // --- CACHES: store latest value per reviewId ---
  final Map<int, Map<String, int>> _reactionsCache = {};
  final Map<int, List<ReplyModel>> _repliesCache = {};

  /// Get cached reactions for initial UI display.
  Map<String, int> getReactionsFor(int reviewId) =>
      _reactionsCache[reviewId] ?? {'likes': 0, 'dislikes': 0};

  /// Get cached replies for initial UI display.
  List<ReplyModel> getRepliesFor(int reviewId) =>
      _repliesCache[reviewId] ?? [];

  final Map<String, StreamSubscription> _subs = {};
  final Set<int> _listeningReviewIds = {};
  bool _notificationsInitialized = false;

  Future<void> initGlobalNotifications() async {
    if (_notificationsInitialized) return;
    _notificationsInitialized = true;

    // Initialize local notification system
    await _localNotif.init();

    // Listen for notifications from Firebase and show them on the phone
    _db.ref('notifications').onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final notif = AppNotificationModel.fromFirebase(data);
        _notificationsController.add(notif);

        // Show system push notification on the phone
        _localNotif.show(title: notif.title, body: notif.message);
      }
    });
  }

  /// Start listening to new reviews for a destination.
  void startDestinationSync(int destinationId) {
    final reviewsKey = 'reviews_$destinationId';
    if (!_subs.containsKey(reviewsKey)) {
      _subs[reviewsKey] = _db.ref('reviews_realtime/$destinationId').onChildAdded.listen((event) {
        if (event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          _reviewsController.add(ReviewModel.fromJson(Map<String, dynamic>.from(data)));
        }
      });
    }
  }

  void stopDestinationSync(int destinationId) {
    final reviewsKey = 'reviews_$destinationId';
    _subs[reviewsKey]?.cancel();
    _subs.remove(reviewsKey);
  }

  /// Listen to reactions and replies for a specific review.
  /// Safe to call multiple times — skips if already listening.
  void listenToReviewMeta(int reviewId) {
    if (_listeningReviewIds.contains(reviewId)) return;
    _listeningReviewIds.add(reviewId);

    final likesKey = 'likes_$reviewId';
    final repliesKey = 'replies_$reviewId';

    // Reactions (LIKE / DISLIKE counts)
    _subs[likesKey] = _db.ref('review_likes/$reviewId').onValue.listen((event) {
      int likes = 0;
      int dislikes = 0;
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        for (final val in data.values) {
          if (val == 'LIKE') {
            likes++;
          } else if (val == 'DISLIKE') {
            dislikes++;
          }
        }
      }
      final counts = {'likes': likes, 'dislikes': dislikes};
      _reactionsCache[reviewId] = counts;
      _reactionsController.add(MapEntry(reviewId, counts));
    });

    // All replies (onValue = full snapshot on every change)
    _subs[repliesKey] = _db.ref('replies/$reviewId').onValue.listen((event) {
      List<ReplyModel> replies = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        replies = data.entries.map((e) {
          return ReplyModel.fromFirebase(Map<dynamic, dynamic>.from(e.value as Map));
        }).toList();
      }
      _repliesCache[reviewId] = replies;
      _repliesController.add(MapEntry(reviewId, replies));
    });
  }

  void dispose() {
    _reviewsController.close();
    _repliesController.close();
    _reactionsController.close();
    _notificationsController.close();
    for (var sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    _listeningReviewIds.clear();
    _reactionsCache.clear();
    _repliesCache.clear();
  }
}
