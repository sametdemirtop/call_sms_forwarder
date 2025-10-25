import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/call_model.dart';
import 'firebase_service.dart';
import 'queue_service.dart';
import 'dart:async';

class CallService {
  // Singleton pattern
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final QueueService _queueService = QueueService();
  StreamSubscription<PhoneState>? _phoneStateSubscription;

  // Duplicate engelleme için son çağrı bilgileri
  String? _lastPhoneNumber;
  DateTime? _lastCallTime;

  // Arama ve rehber izinlerini kontrol et
  Future<bool> requestPermissions() async {
    final phoneStatus = await Permission.phone.request();
    final contactsStatus = await Permission.contacts.request();
    return phoneStatus.isGranted && contactsStatus.isGranted;
  }

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

  // Arama dinleyici başlat
  void startListening() {
    print('📞 Arama dinleyici başlatılıyor...');
    // Önceki listener varsa iptal et
    _phoneStateSubscription?.cancel();

    // Yeni listener başlat
    _phoneStateSubscription = PhoneState.stream.listen((event) {
      _onCallStateChanged(event);
    });
    print('📞 Arama dinleyici başlatıldı!');
  }

  // Arama dinleyiciyi durdur
  void stopListening() {
    _phoneStateSubscription?.cancel();
    _phoneStateSubscription = null;
  }

  // Arama durumu değiştiğinde çağrılır
  void _onCallStateChanged(PhoneState event) async {
    print('==========================================');
    print('📞 ARAMA DURUMU DEĞİŞTİ!');
    print('Durum: ${event.status}');
    print('Numara: ${event.number ?? 'Bilinmeyen'}');
    print('==========================================');

    if (event.status == PhoneStateStatus.CALL_INCOMING) {
      final phoneNumber = event.number;

      // "Bilinmeyen" veya boş numaraları ignore et
      if (phoneNumber == null ||
          phoneNumber.isEmpty ||
          phoneNumber == 'Bilinmeyen') {
        print('⚠️ Numara bilinmiyor, atlanıyor...');
        return;
      }

      // Duplicate kontrolü - son 3 saniye içinde aynı numaradan gelen aramayı ignore et
      final now = DateTime.now();
      final normalizedNumber = _normalizePhoneNumber(phoneNumber);

      if (_lastPhoneNumber != null && _lastCallTime != null) {
        final timeDiff = now.difference(_lastCallTime!).inSeconds;
        final lastNormalized = _normalizePhoneNumber(_lastPhoneNumber);

        if (lastNormalized == normalizedNumber && timeDiff < 3) {
          print(
            '⚠️ Duplicate arama tespit edildi (${timeDiff}s önce), atlanıyor...',
          );
          return;
        }
      }

      // Bu aramayı kaydet
      _lastPhoneNumber = phoneNumber;
      _lastCallTime = now;

      print('✅ Gelen arama tespit edildi!');

      // Rehberden isim çek
      print('👤 Rehberden isim aranıyor...');
      final contactName = await _getContactName(phoneNumber);

      // İsim varsa onu kullan, yoksa numarayı kullan
      final displayName = contactName ?? phoneNumber;
      print(
        '👤 Görünen isim: $displayName ${contactName != null ? '(rehberden)' : '(numara)'}',
      );

      final call = CallModel(
        caller: displayName,
        callType: 'Gelen Arama',
        timestamp: DateTime.now(),
      );

      print('Arama modeli oluşturuldu: ${call.toJson()}');

      // Firebase'e gönder (başarısızsa kuyruğa ekle)
      try {
        print('Firebase\'e gönderiliyor...');
        await _firebaseService.sendNotification(
          call.toJson(),
          onQueueAdd: (data) {
            print('Kuyruğa ekleniyor...');
            _queueService.addToQueue(data);
          },
        );
        print('✅ Arama Firebase\'e gönderildi!');
      } catch (e) {
        print('❌ Arama gönderme hatası: $e');
      }
    }
  }
}
