import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Server Key (Cloud Messaging)
  static const String _serverKey =
      'AAAAx7X8Usk:APA91bEKY2HZwujOolHlRlZGybRxyjL4anGj0lGltKRGigaD8mDlUqHl-7Xm5AYq2SNRHKRl7n4kpvtTboGvyAgYhEKz05a0gY3ORT0IDW_go6BJE3mhNPYPZheJWDi1xxV0KppYV5V';

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

      // Push notification gönder
      await _sendPushNotification(data);
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

  // Push notification gönder (FCM HTTP API)
  Future<void> _sendPushNotification(Map<String, dynamic> data) async {
    try {
      print('🔔 Push notification gönderiliyor...');

      // Tüm FCM token'larını al
      final tokensSnapshot = await _firestore.collection('fcm_tokens').get();

      if (tokensSnapshot.docs.isEmpty) {
        print('⚠️ Kayıtlı FCM token yok');
        return;
      }

      print('📱 ${tokensSnapshot.docs.length} cihaza bildirim gönderiliyor...');

      // Bildirim içeriği
      final String title = data['type'] == 'sms'
          ? '📩 Yeni SMS: ${data['sender']}'
          : '📞 Yeni Arama: ${data['caller']}';

      final String body = data['type'] == 'sms'
          ? data['message']
          : data['callType'];

      // Her token için bildirim gönder
      for (final doc in tokensSnapshot.docs) {
        final tokenData = doc.data();
        final token = tokenData['token'] as String;
        final platform = tokenData['platform'] as String? ?? 'unknown';

        // Web token'ları için bildirim desteği yok (Server Key ile)
        if (platform == 'web') {
          print(
            '🌐 Web token atlandı (Server Key ile web push desteklenmiyor): ${doc.id}',
          );
          continue; // Atla, silme!
        }

        try {
          final response = await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=$_serverKey',
            },
            body: jsonEncode({
              'to': token,
              'notification': {
                'title': title,
                'body': body,
                'icon': '/icons/Icon-192.png',
                'badge': '/icons/Icon-192.png',
                'click_action': 'https://chat-cf257.web.app',
              },
              'data': {
                'type': data['type'],
                'sender': data['sender'] ?? data['caller'] ?? '',
                'message': data['message'] ?? data['callType'] ?? '',
                'timestamp': data['timestamp'].toString(),
              },
              'priority': 'high',
            }),
          );

          if (response.statusCode == 200) {
            print('✅ Push notification gönderildi: ${doc.id}');
          } else {
            print(
              '❌ Push notification hatası: ${response.statusCode} - ${response.body}',
            );

            // Sadece kesin geçersiz token hatalarında sil
            if (response.body.contains('NotRegistered') ||
                response.body.contains('InvalidRegistration')) {
              await doc.reference.delete();
              print('🗑️ Geçersiz token silindi: ${doc.id}');
            } else {
              print('⚠️ Geçici hata, token korunuyor');
            }
          }
        } catch (e) {
          print('❌ Token ${doc.id} için hata: $e');
        }
      }

      print('✅ Tüm push notification işlemleri tamamlandı!');
    } catch (e) {
      print('❌ Push notification genel hatası: $e');
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
