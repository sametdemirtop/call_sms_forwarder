import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class QueueService {
  // Singleton pattern
  static final QueueService _instance = QueueService._internal();
  factory QueueService() => _instance;
  QueueService._internal();

  static const String _queueKey = 'pending_notifications';
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache SharedPreferences instance
  SharedPreferences? _prefs;
  bool _isProcessing = false;
  Timer? _debounceTimer;

  // Get SharedPreferences instance (cached)
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Kuyruğa ekle
  Future<void> addToQueue(Map<String, dynamic> data) async {
    try {
      final prefs = await _getPrefs();
      final queue = await getQueue();
      queue.add(data);
      await prefs.setString(_queueKey, jsonEncode(queue));
    } catch (e) {
      print('Add to queue error: $e');
    }
  }

  // Kuyruğu getir
  Future<List<Map<String, dynamic>>> getQueue() async {
    try {
      final prefs = await _getPrefs();
      final queueString = prefs.getString(_queueKey);
      if (queueString == null || queueString.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(queueString);
      return decoded.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is Map) {
          return Map<String, dynamic>.from(item);
        } else {
          return <String, dynamic>{};
        }
      }).toList();
    } catch (e) {
      print('Queue parsing error: $e');
      // Clear corrupted data
      try {
        final prefs = await _getPrefs();
        await prefs.remove(_queueKey);
      } catch (_) {}
      return [];
    }
  }

  // Kuyruğu temizle
  Future<void> clearQueue() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_queueKey);
    } catch (e) {
      print('Clear queue error: $e');
    }
  }

  // Kuyruktan sil
  Future<void> removeFromQueue(int index) async {
    try {
      final prefs = await _getPrefs();
      final queue = await getQueue();
      if (index < queue.length) {
        queue.removeAt(index);
        await prefs.setString(_queueKey, jsonEncode(queue));
      }
    } catch (e) {
      print('Remove from queue error: $e');
    }
  }

  // Kuyruğu işle
  Future<void> processQueue() async {
    // Prevent multiple simultaneous processing
    if (_isProcessing) {
      print('Queue is already being processed, skipping...');
      return;
    }

    _isProcessing = true;
    try {
      // İnternet bağlantısını kontrol et
      final connectivityResult = await Connectivity().checkConnectivity();
      // connectivity_plus 5.0.2 returns a single ConnectivityResult, not a List
      if (connectivityResult == ConnectivityResult.none) {
        return; // İnternet yoksa işleme
      }

      final queue = await getQueue();
      if (queue.isEmpty) return;

      print('Processing queue: ${queue.length} items');

      // Kuyruktaki her öğeyi gönder
      for (int i = queue.length - 1; i >= 0; i--) {
        try {
          // Firestore'a kaydet
          await _firestore.collection('notifications').add({
            ...queue[i],
            'createdAt': FieldValue.serverTimestamp(),
          });
          await removeFromQueue(i);
        } catch (e) {
          print('Kuyruk işleme hatası: $e');
          // Hata olursa bu öğeyi kuyrukta bırak
        }
      }

      print('Queue processing completed');
    } catch (e) {
      print('Process queue error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // İnternet durumunu izle ve kuyruğu işle
  void startQueueProcessor() {
    // Önceki listener varsa iptal et
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();

    // Yeni listener başlat
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      if (result != ConnectivityResult.none) {
        // Debounce: Wait 2 seconds before processing to avoid rapid repeated calls
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 2), () {
          processQueue();
        });
      }
    });
  }

  // Listener'ı durdur
  void stopQueueProcessor() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _isProcessing = false;
  }
}
