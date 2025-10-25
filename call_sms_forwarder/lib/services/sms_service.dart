import 'dart:async';
import 'package:flutter/services.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/sms_model.dart';
import 'firebase_service.dart';
import 'queue_service.dart';

class SmsService {
  // Singleton pattern
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final Telephony telephony = Telephony.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final QueueService _queueService = QueueService();

  // Native SMS EventChannel
  static const EventChannel _smsChannel = EventChannel(
    'com.callsmsforwarder/sms',
  );
  StreamSubscription? _smsSubscription;

  // Telefon numarasını normalize et (sadece rakamlar)
  String _normalizePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    // Sadece rakamları al
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // Rehberden isim çek
  Future<String?> _getContactName(String? phoneNumber) async {
    if (phoneNumber == null ||
        phoneNumber.isEmpty ||
        phoneNumber == 'Bilinmeyen') {
      return null;
    }

    try {
      // Rehber iznini kontrol et
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        print('Rehber izni verilmedi');
        return null;
      }

      // Numarayı normalize et
      final normalizedNumber = _normalizePhoneNumber(phoneNumber);
      if (normalizedNumber.isEmpty) return null;

      // Tüm kişileri al
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      // Numaraya göre kişi ara
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final contactNumber = _normalizePhoneNumber(phone.number);
          // Son 10 hanesi eşleşiyorsa (ülke kodu farklılıklarını tolere et)
          if (contactNumber.length >= 10 && normalizedNumber.length >= 10) {
            final contactLast10 = contactNumber.substring(
              contactNumber.length - 10,
            );
            final numberLast10 = normalizedNumber.substring(
              normalizedNumber.length - 10,
            );
            if (contactLast10 == numberLast10) {
              return contact.displayName;
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Rehberden isim çekme hatası: $e');
      return null;
    }
  }

  // SMS izinlerini kontrol et
  Future<bool> requestPermissions() async {
    print('SMS izinleri isteniyor...');
    final bool? permissionsGranted =
        await telephony.requestPhoneAndSmsPermissions;
    print('SMS izin sonucu: $permissionsGranted');

    // İzin durumlarını ayrı ayrı kontrol et
    if (permissionsGranted == true) {
      final smsPermission = await telephony.isSmsCapable;
      print('SMS yeteneği: $smsPermission');

      // Test: Son SMS'i oku
      try {
        final messages = await telephony.getInboxSms(
          columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        );
        print('📱 Gelen kutusu okunabildi! Son SMS sayısı: ${messages.length}');
        if (messages.isNotEmpty) {
          print(
            'Son SMS: ${messages.first.address} - ${messages.first.body?.substring(0, 20)}...',
          );
        }
      } catch (e) {
        print('❌ Gelen kutusu okuma hatası: $e');
      }
    }

    return permissionsGranted ?? false;
  }

  // SMS dinleyici başlat
  void startListening() {
    print('🚀 ========================================');
    print('🚀 SMS DİNLEYİCİ BAŞLATILIYOR (Native)...');
    print('🚀 ========================================');

    try {
      // Önceki subscription'ı iptal et
      _smsSubscription?.cancel();

      // Native EventChannel'dan SMS'leri dinle
      _smsSubscription = _smsChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          print('📨 Native SMS event alındı: $event');
          _handleNativeSms(event);
        },
        onError: (dynamic error) {
          print('❌ SMS stream hatası: $error');
        },
      );

      print('✅ Native SMS dinleyici başarıyla kuruldu!');
      print('📱 Background ve foreground SMS bekleniyor...');
    } catch (e) {
      print('❌ SMS dinleyici kurma hatası: $e');
    }

    print('🚀 ========================================');
  }

  // SMS dinleyiciyi durdur
  void stopListening() {
    _smsSubscription?.cancel();
    _smsSubscription = null;
  }

  // Native'den gelen SMS'i işle
  void _handleNativeSms(dynamic event) async {
    try {
      final Map<dynamic, dynamic> smsData = event as Map<dynamic, dynamic>;
      final String phoneNumber = smsData['address']?.toString() ?? 'Bilinmeyen';
      final String messageBody = smsData['body']?.toString() ?? '';

      print('==========================================');
      print('📩 NATIVE SMS ALINDI!');
      print('Gönderen: $phoneNumber');
      print('Mesaj: $messageBody');
      print('Tarih: ${DateTime.now()}');
      print('==========================================');

      // Rehberden isim çek
      print('👤 Rehberden isim aranıyor...');
      final contactName = await _getContactName(phoneNumber);

      // İsim varsa onu kullan, yoksa numarayı kullan
      final displayName = contactName ?? phoneNumber;
      print(
        '👤 Görünen isim: $displayName ${contactName != null ? '(rehberden)' : '(numara)'}',
      );

      final sms = SmsModel(
        sender: displayName,
        message: messageBody,
        timestamp: DateTime.now(),
      );

      print('SMS modeli oluşturuldu: ${sms.toJson()}');

      // Firebase'e gönder (başarısızsa kuyruğa ekle)
      try {
        print('Firebase\'e gönderiliyor...');
        await _firebaseService.sendNotification(
          sms.toJson(),
          onQueueAdd: (data) {
            print('Kuyruğa ekleniyor...');
            _queueService.addToQueue(data);
          },
        );
        print('✅ SMS Firebase\'e gönderildi!');
      } catch (e) {
        print('❌ SMS gönderme hatası: $e');
      }
    } catch (e) {
      print('❌ Native SMS işleme hatası: $e');
    }
  }

  // SMS geldiğinde çağrılır
  void _onSmsReceived(SmsMessage message) async {
    final phoneNumber = message.address ?? 'Bilinmeyen';
    final messageBody = message.body ?? '';

    print('==========================================');
    print('📩 SMS ALINDI!');
    print('Gönderen: $phoneNumber');
    print('Mesaj: $messageBody');
    print('Tarih: ${DateTime.now()}');
    print('==========================================');

    // Rehberden isim çek
    print('👤 Rehberden isim aranıyor...');
    final contactName = await _getContactName(phoneNumber);

    // İsim varsa onu kullan, yoksa numarayı kullan
    final displayName = contactName ?? phoneNumber;
    print(
      '👤 Görünen isim: $displayName ${contactName != null ? '(rehberden)' : '(numara)'}',
    );

    final sms = SmsModel(
      sender: displayName,
      message: messageBody,
      timestamp: DateTime.now(),
    );

    print('SMS modeli oluşturuldu: ${sms.toJson()}');

    // Firebase'e gönder (başarısızsa kuyruğa ekle)
    try {
      print('Firebase\'e gönderiliyor...');
      await _firebaseService.sendNotification(
        sms.toJson(),
        onQueueAdd: (data) {
          print('Kuyruğa ekleniyor...');
          _queueService.addToQueue(data);
        },
      );
      print('✅ SMS Firebase\'e gönderildi!');
    } catch (e) {
      print('❌ SMS gönderme hatası: $e');
    }
  }
}
