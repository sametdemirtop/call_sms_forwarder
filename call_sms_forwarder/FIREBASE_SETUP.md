# Firebase Kurulum Rehberi

Bu rehber, Call SMS Forwarder uygulaması için Firebase yapılandırmasını adım adım anlatmaktadır.

## 1. Firebase Projesi Oluşturma

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. "Proje Ekle" butonuna tıklayın
3. Proje adı girin (örn: "call-sms-forwarder")
4. Google Analytics'i istediğiniz gibi yapılandırın
5. "Proje Oluştur" butonuna tıklayın

## 2. Firestore Veritabanı Kurulumu

1. Firebase Console'da projenizi açın
2. Sol menüden "Firestore Database" seçin
3. "Veritabanı Oluştur" butonuna tıklayın
4. Test modunda başlatın (daha sonra güvenlik kurallarını değiştirebilirsiniz)
5. Sunucu konumunu seçin (örn: europe-west3)

## 3. Firebase Cloud Messaging (FCM) Kurulumu

1. Firebase Console'da "Project Settings" (Proje Ayarları) açın
2. "Cloud Messaging" sekmesine gidin
3. "Cloud Messaging API"yi etkinleştirin

## 4. Android Uygulaması Ekleme

1. Firebase Console'da "Uygulamanıza Firebase'i ekleyin" bölümünden Android ikonu tıklayın
2. Paket adını girin: `com.callsmsforwarder.call_sms_forwarder`
3. "Uygulamayı kaydet" butonuna tıklayın
4. `google-services.json` dosyasını indirin
5. İndirdiğiniz dosyayı şu konuma kopyalayın:
   ```
   android/app/google-services.json
   ```

## 5. Web Uygulaması Ekleme

1. Firebase Console'da "Uygulamanıza Firebase'i ekleyin" bölümünden Web ikonu (</>) tıklayın
2. Uygulama adını girin (örn: "Call SMS Forwarder Web")
3. "Firebase Hosting'i de kur" seçeneğini işaretleyin
4. "Uygulamayı kaydet" butonuna tıklayın
5. Verilen yapılandırma bilgilerini kopyalayın

## 6. Yapılandırma Dosyalarını Güncelleme

### lib/firebase_options.dart

`lib/firebase_options.dart` dosyasını açın ve aşağıdaki değerleri Firebase Console'dan aldığınız bilgilerle değiştirin:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'BURAYA_WEB_API_KEY_YAZIN',
  appId: 'BURAYA_WEB_APP_ID_YAZIN',
  messagingSenderId: 'BURAYA_MESSAGING_SENDER_ID_YAZIN',
  projectId: 'BURAYA_PROJECT_ID_YAZIN',
  authDomain: 'BURAYA_PROJECT_ID_YAZIN.firebaseapp.com',
  storageBucket: 'BURAYA_PROJECT_ID_YAZIN.appspot.com',
);

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'BURAYA_ANDROID_API_KEY_YAZIN',
  appId: 'BURAYA_ANDROID_APP_ID_YAZIN',
  messagingSenderId: 'BURAYA_MESSAGING_SENDER_ID_YAZIN',
  projectId: 'BURAYA_PROJECT_ID_YAZIN',
  storageBucket: 'BURAYA_PROJECT_ID_YAZIN.appspot.com',
);
```

### web/index.html

`web/index.html` dosyasındaki firebaseConfig bölümünü güncelleyin:

```javascript
const firebaseConfig = {
  apiKey: "BURAYA_WEB_API_KEY_YAZIN",
  authDomain: "BURAYA_PROJECT_ID_YAZIN.firebaseapp.com",
  projectId: "BURAYA_PROJECT_ID_YAZIN",
  storageBucket: "BURAYA_PROJECT_ID_YAZIN.appspot.com",
  messagingSenderId: "BURAYA_MESSAGING_SENDER_ID_YAZIN",
  appId: "BURAYA_WEB_APP_ID_YAZIN"
};
```

### web/firebase-messaging-sw.js

`web/firebase-messaging-sw.js` dosyasını da aynı şekilde güncelleyin.

## 7. Firebase Hosting Kurulumu

1. Terminal'i açın ve proje klasörüne gidin:
   ```bash
   cd /Users/samet/call_sms_forwarder/call_sms_forwarder
   ```

2. Firebase CLI'yi kurun (eğer kurulu değilse):
   ```bash
   npm install -g firebase-tools
   ```

3. Firebase'e giriş yapın:
   ```bash
   firebase login
   ```

4. Firebase projesini başlatın:
   ```bash
   firebase init hosting
   ```
   - Mevcut projenizi seçin
   - Public directory: `build/web`
   - Single-page app: Yes
   - Automatic builds: No

5. Web uygulamasını build edin:
   ```bash
   flutter build web
   ```

6. Firebase'e deploy edin:
   ```bash
   firebase deploy --only hosting
   ```

## 8. Firestore Güvenlik Kuralları (Opsiyonel)

Firebase Console'da Firestore > Rules bölümüne giderek güvenlik kurallarını güncelleyin:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /notifications/{document=**} {
      allow read, write: if true; // Geliştirme için - Üretimde güvenlik ekleyin
    }
  }
}
```

## 9. Android Uygulaması için Ek Ayarlar

`android/build.gradle` dosyasını açın ve dependencies bölümüne şunu ekleyin:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

`android/app/build.gradle` dosyasının sonuna şunu ekleyin:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## 10. Test

1. Android uygulamasını çalıştırın:
   ```bash
   flutter run
   ```

2. Web uygulamasını test edin:
   ```bash
   flutter run -d chrome
   ```

3. Canlı web sitesini test edin:
   - Firebase Hosting URL'inizi tarayıcıda açın
   - Format: `https://PROJECT_ID.web.app` veya `https://PROJECT_ID.firebaseapp.com`

## Sorun Giderme

- **google-services.json bulunamadı**: Dosyanın doğru konumda olduğundan emin olun
- **Firebase başlatma hatası**: Yapılandırma bilgilerinin doğru olduğunu kontrol edin
- **Web push notification çalışmıyor**: HTTPS kullandığınızdan emin olun (Firebase Hosting otomatik HTTPS sağlar)

## Notlar

- Firebase'in ücretsiz Spark planı çoğu kullanım için yeterlidir
- Firestore'da 50,000 okuma/gün ve 20,000 yazma/gün limiti vardır
- Firebase Hosting 10GB depolama ve 360MB/gün transfer sağlar

