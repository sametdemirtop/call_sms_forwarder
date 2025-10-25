# Hızlı Başlangıç Rehberi

Bu rehber, uygulamayı en hızlı şekilde çalıştırmanız için hazırlanmıştır.

## 📋 Kontrol Listesi

### 1. Firebase Projesi Oluşturun (5 dakika)

1. [Firebase Console](https://console.firebase.google.com/) → "Proje Ekle"
2. Proje adı girin (örn: "call-sms-forwarder")
3. Google Analytics'i isterseniz açın
4. "Proje Oluştur"

### 2. Firestore Veritabanı (2 dakika)

1. Sol menü → "Firestore Database"
2. "Veritabanı Oluştur"
3. **Test modunda başlat** (önemli!)
4. Sunucu: europe-west3 (veya size yakın)

### 3. Android Uygulaması Ekleyin (3 dakika)

1. Firebase Console → "Uygulamanıza Firebase'i ekleyin" → Android ikonu
2. Paket adı: `com.callsmsforwarder.call_sms_forwarder`
3. "Uygulamayı kaydet"
4. **google-services.json** dosyasını indirin
5. İndirdiğiniz dosyayı şuraya taşıyın:
   ```bash
   mv ~/Downloads/google-services.json /Users/samet/call_sms_forwarder/call_sms_forwarder/android/app/
   ```

### 4. Web Uygulaması Ekleyin (3 dakika)

1. Firebase Console → Web ikonu (</>) → "Firebase Hosting'i de kur" seçin
2. Uygulama adı: "Call SMS Forwarder Web"
3. Firebase yapılandırma kodunu kopyalayın (örnek):
   ```javascript
   const firebaseConfig = {
     apiKey: "AIza...",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abc..."
   };
   ```

### 5. Yapılandırma Dosyalarını Güncelleyin (5 dakika)

#### A) lib/firebase_options.dart

Dosyayı açın ve şu değerleri Firebase Console'dan kopyaladığınız bilgilerle değiştirin:

```bash
# Dosyayı açın:
nano /Users/samet/call_sms_forwarder/call_sms_forwarder/lib/firebase_options.dart
```

Web için:
- `YOUR_WEB_API_KEY` → `apiKey`
- `YOUR_WEB_APP_ID` → `appId`
- `YOUR_MESSAGING_SENDER_ID` → `messagingSenderId`
- `YOUR_PROJECT_ID` → `projectId`

Android için aynı bilgileri kullanın (google-services.json'dan da bakabilirsiniz).

#### B) web/index.html

```bash
nano /Users/samet/call_sms_forwarder/call_sms_forwarder/web/index.html
```

`firebaseConfig` kısmındaki `YOUR_*` değerlerini güncelleyin.

#### C) web/firebase-messaging-sw.js

```bash
nano /Users/samet/call_sms_forwarder/call_sms_forwarder/web/firebase-messaging-sw.js
```

Aynı yapılandırma bilgilerini buraya da kopyalayın.

#### D) .firebaserc

```bash
nano /Users/samet/call_sms_forwarder/call_sms_forwarder/.firebaserc
```

`your-project-id` yerine Firebase proje ID'nizi yazın.

### 6. Android APK Oluşturun (2 dakika)

```bash
cd /Users/samet/call_sms_forwarder/call_sms_forwarder
flutter build apk --release
```

APK yolu: `build/app/outputs/flutter-apk/app-release.apk`

### 7. Web Deploy (2 dakika)

```bash
cd /Users/samet/call_sms_forwarder/call_sms_forwarder

# Firebase'e giriş (ilk kez ise)
firebase login

# Web build
flutter build web

# Deploy
firebase deploy --only hosting
```

Deploy sonrası size bir URL verilecek: `https://your-project.web.app`

## 🚀 Kullanım

### Android Telefonda

1. APK'yı Android telefonunuza atın (USB, Email, Drive vb.)
2. APK'yı yükleyin (Bilinmeyen kaynaklara izin vermeniz gerekebilir)
3. Uygulamayı açın
4. Tüm izinleri verin (SMS, Arama, Bildirim)
5. "Servisi Başlat" butonuna tıklayın

### iPhone'da

1. Safari'de Firebase Hosting URL'inizi açın: `https://your-project.web.app`
2. Ekranın altındaki Paylaş butonuna tıklayın (yukarı ok)
3. "Ana Ekrana Ekle" seçin
4. Ana ekrandaki ikonu açın
5. Bildirim izni isteğini onaylayın
6. Artık gelen SMS ve aramaları görebilirsiniz!

## 🔍 Test

### Test SMS Gönderme

1. Android telefonunuza bir SMS gönderin
2. SMS Android uygulamada "Çalışıyor" durumundaysa otomatik gönderilir
3. iPhone'daki web uygulamasında SMS'i görmelisiniz
4. Web push notification da gelmelidir

### Test Arama

1. Android telefonunuzu arayın
2. Arama bilgisi otomatik gönderilir
3. iPhone'da arama kaydını görebilirsiniz

## 🐛 Sorun Çözümleri

### "google-services.json not found" Hatası

```bash
# Dosyanın doğru yerde olduğunu kontrol edin:
ls -la /Users/samet/call_sms_forwarder/call_sms_forwarder/android/app/google-services.json
```

### Web Push Notification Çalışmıyor

- Safari'de "Ana Ekrana Ekle" yaptığınızdan emin olun
- Bildirim izni verdiğinizi kontrol edin
- HTTPS kullanıldığından emin olun (Firebase Hosting otomatik HTTPS sağlar)

### SMS/Arama Gelmiyor

- Android uygulamada "Servisi Başlat" yaptınız mı?
- Tüm izinleri verdiniz mi?
- Android telefonun internet bağlantısı var mı?
- Firebase Console → Firestore'da yeni kayıtlar görünüyor mu?

### Build Hatası

```bash
cd /Users/samet/call_sms_forwarder/call_sms_forwarder
flutter clean
flutter pub get
flutter build apk --release
```

## 📝 Önemli Notlar

- Firebase'in **ücretsiz Spark planı** yeterlidir
- Test modunda başlattığınız için herkes veritabanınıza yazabilir
- Üretimde kullanacaksanız Firestore güvenlik kurallarını güncelleyin
- Android APK'yı her güncellemede yeniden yüklemeniz gerekir
- Web otomatik güncellenir (yeniden deploy edin)

## ⏱️ Toplam Süre: ~20-25 dakika

Tüm adımları takip ederseniz 25 dakikada sistem çalışır hale gelecektir.

## 🎯 Sonraki Adımlar

1. Firestore güvenlik kurallarını yapılandırın (opsiyonel)
2. Özel bildirim sesleri ekleyin (opsiyonel)
3. SMS filtreleme ekleyin (opsiyonel)
4. Arama geçmişini temizleme özelliği ekleyin (opsiyonel)

---

**Başarılar! 🎉**

