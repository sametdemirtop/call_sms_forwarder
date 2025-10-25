import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Bildirim gönder
  Future<void> sendNotification(
    Map<String, dynamic> data, {
    Function(Map<String, dynamic>)? onQueueAdd,
  }) async {
    print('🔥 Firebase sendNotification çağrıldı!');
    print('Data: $data');

    // İnternet bağlantısını kontrol et
    print('İnternet bağlantısı kontrol ediliyor...');
    final connectivityResult = await Connectivity().checkConnectivity();
    print('Bağlantı durumu: $connectivityResult');

    // connectivity_plus 5.0.2 returns a single ConnectivityResult, not a List
    if (connectivityResult == ConnectivityResult.none) {
      print('⚠️ İnternet yok, kuyruğa ekleniyor...');
      // İnternet yoksa kuyruğa ekle
      if (onQueueAdd != null) {
        onQueueAdd(data);
      }
      return;
    }

    try {
      print('📤 Firestore\'a kaydediliyor...');
      // Firestore'a kaydet
      final docRef = await _firestore.collection('notifications').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore\'a başarıyla kaydedildi! Doc ID: ${docRef.id}');
    } catch (e) {
      print('❌ Bildirim gönderme hatası: $e');
      print('Hata detayı: ${e.toString()}');
      // Hata olursa kuyruğa ekle
      if (onQueueAdd != null) {
        print('Kuyruğa ekleniyor...');
        onQueueAdd(data);
      }
    }
  }

  // Bildirimleri dinle
  Stream<QuerySnapshot> getNotificationsStream() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  // Tüm bildirimleri getir
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Bildirim getirme hatası: $e');
      return [];
    }
  }
}
