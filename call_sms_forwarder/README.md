# Call SMS Forwarder

Android telefonunuza gelen SMS ve aramaları iPhone'unuza web push notification ile ileten Flutter uygulaması.

## 🎯 Özellikler

- ✅ Gelen SMS'leri otomatik algılama ve iletme
- ✅ Gelen aramaları otomatik algılama ve iletme
- ✅ Offline kuyruk sistemi (internet yoksa bekletir, gelince gönderir)
- ✅ Web push notification desteği
- ✅ Firebase Hosting ile ücretsiz hosting
- ✅ Basit ve kullanıcı dostu arayüz
- ✅ 2 tab: Aramalar ve SMS'ler

## 📱 Nasıl Çalışır?

1. **Android Telefon**: SMS ve aramaları dinler, Firebase'e gönderir
2. **Firebase**: Verileri saklar ve web uygulamasına bildirim gönderir
3. **Web Uygulaması**: iPhone'da açılır, bildirimleri alır ve gösterir

## 🚀 Kurulum

### 1. Gereksinimleri Yükleyin

```bash
# Flutter SDK (eğer kurulu değilse)
# https://docs.flutter.dev/get-started/install

# Firebase CLI
npm install -g firebase-tools
```

### 2. Projeyi İndirin

```bash
cd /Users/samet/call_sms_forwarder/call_sms_forwarder
```

### 3. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 4. Firebase Yapılandırması

Detaylı Firebase kurulum talimatları için `FIREBASE_SETUP.md` dosyasını okuyun.

Kısaca:
1. Firebase Console'da yeni proje oluşturun
2. Android ve Web uygulamaları ekleyin
3. `google-services.json` dosyasını `android/app/` klasörüne kopyalayın
4. `lib/firebase_options.dart` dosyasındaki bilgileri güncelleyin
5. `web/index.html` ve `web/firebase-messaging-sw.js` dosyalarını güncelleyin

### 5. Android Uygulamasını Çalıştırın

```bash
flutter run
```

Android telefonunuza APK yüklemek için:

```bash
flutter build apk --release
```

APK dosyası `build/app/outputs/flutter-apk/app-release.apk` konumunda oluşturulacak.

### 6. Web Uygulamasını Deploy Edin

```bash
# Web için build
flutter build web

# Firebase'e deploy
firebase deploy --only hosting
```

Deploy sonrası verilen URL'i iPhone'unuzda açın ve ana ekrana ekleyin.

## 📖 Kullanım

### Android Telefonda

1. Uygulamayı açın
2. İzinleri verin (SMS, Arama, Bildirim)
3. "Servisi Başlat" butonuna tıklayın
4. Artık gelen SMS ve aramalar otomatik olarak iPhone'unuza iletilecek

### iPhone'da

1. Firebase Hosting URL'ini Safari'de açın (örn: `https://your-project.web.app`)
2. Paylaş butonuna tıklayın
3. "Ana Ekrana Ekle" seçeneğini seçin
4. Bildirim izni verin
5. Gelen SMS ve aramaları görebilirsiniz

## 🔧 Yapılandırma

### Android İzinleri

Uygulama şu izinleri gerektirir:
- SMS okuma ve alma
- Telefon durumu okuma
- Arama kayıtlarını okuma
- İnternet erişimi
- Bildirim gönderme

### Offline Kuyruk

İnternet bağlantısı olmadığında:
- SMS ve aramalar yerel depolamada kuyruğa alınır
- İnternet geldiğinde otomatik olarak gönderilir
- Kuyruğu manuel olarak da işleyebilirsiniz

## 📁 Proje Yapısı

```
lib/
├── main.dart                 # Ana uygulama
├── models/                   # Veri modelleri
│   ├── sms_model.dart
│   └── call_model.dart
├── screens/                  # Ekranlar
│   ├── android_home_screen.dart
│   └── web_home_screen.dart
├── services/                 # Servisler
│   ├── sms_service.dart
│   ├── call_service.dart
│   ├── firebase_service.dart
│   └── queue_service.dart
└── firebase_options.dart     # Firebase yapılandırma
```

## 🐛 Sorun Giderme

### SMS/Arama Gelmiyor

- İzinlerin verildiğinden emin olun
- Servinin çalıştığını kontrol edin
- Android telefonun internet bağlantısını kontrol edin

### Web Push Notification Çalışmıyor

- HTTPS kullandığınızdan emin olun (Firebase Hosting otomatik HTTPS sağlar)
- Bildirim izni verdiğinizden emin olun
- Safari'de Ana Ekrana Eklediğinizden emin olun

### Kuyruk Doldu

- "Kuyruğu Gönder" butonuna tıklayın
- İnternet bağlantınızı kontrol edin
- Gerekirse "Kuyruğu Temizle" ile eski verileri silin

## 💰 Maliyet

Uygulama tamamen ücretsiz Firebase Spark planını kullanır:

- ✅ Firestore: 50,000 okuma/gün, 20,000 yazma/gün
- ✅ Firebase Hosting: 10GB depolama, 360MB/gün transfer
- ✅ Cloud Messaging: Sınırsız bildirim

Normal kullanımda bu limitler aşılmaz.

## 🔒 Güvenlik

⚠️ **DİKKAT**: Bu uygulama geliştirme amaçlıdır. Üretimde kullanmak için:

1. Firebase Firestore güvenlik kurallarını yapılandırın
2. Kullanıcı kimlik doğrulaması ekleyin
3. End-to-end şifreleme düşünün
4. Hassas verileri şifreleyin

## 📝 Lisans

Bu proje kişisel kullanım içindir.

## 🤝 Katkıda Bulunma

Bu uygulama sizin için özel olarak hazırlanmıştır. İstediğiniz gibi değiştirebilirsiniz.

## 📞 İletişim

Herhangi bir sorunuz varsa, bana ulaşabilirsiniz.

---

**Not**: IMEI'si kapalı cihazlar için geliştirilmiştir. Yasal kullanım sorumluluğu kullanıcıya aittir.
