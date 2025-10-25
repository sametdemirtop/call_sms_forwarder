# Firebase Kurulum Rehberi

## Durum
- ✅ Firebase CLI yüklü
- ✅ Firebase hesabı aktif (demirtopsamet@gmail.com)
- ✅ FlutterFire CLI yüklü
- ❌ Firebase projesi henüz yapılandırılmamış

## Adım 1: Firebase Projesi Oluştur

### Seçenek A: Yeni Proje (ÖNERİLEN)

1. **Firebase Console'a git**: https://console.firebase.google.com

2. **"Add project"** butonuna tıkla

3. **Proje Adı Gir**: `CallSmsForwarder` veya `call-sms-forwarder`

4. **Google Analytics**: 
   - İsteğe bağlı, şimdilik kapatabilirsiniz
   - İlerleride açabilirsiniz

5. **"Create project"** tıkla ve bekle (30 saniye)

6. **Project ID'yi not al**: 
   - Genellikle `call-sms-forwarder-xxxxx` şeklinde olur
   - Settings > Project settings'den görebilirsiniz

### Seçenek B: Mevcut Proje Kullan

Hesabınızda 21 proje var. Bunlardan birini kullanabilirsiniz:
- `chat-cf257`
- `fitup-dd616`
- vb.

## Adım 2: FlutterFire Configuration

Proje oluşturduktan sonra, proje dizininde şu komutu çalıştırın:

```bash
cd /Users/samet/call_sms_forwarder/call_sms_forwarder

# Yeni proje oluşturduysanız (PROJECT_ID'yi kendi proje ID'nizle değiştirin):
flutterfire configure \
  --project=PROJECT_ID \
  --platforms=android,web \
  --out=lib/firebase_options.dart \
  --android-package-name=com.callsmsforwarder.call_sms_forwarder \
  --yes

# VEYA mevcut proje kullanıyorsanız (örnek: chat-cf257):
flutterfire configure \
  --project=chat-cf257 \
  --platforms=android,web \
  --out=lib/firebase_options.dart \
  --android-package-name=com.callsmsforwarder.call_sms_forwarder \
  --yes
```

## Adım 3: Firebase Servislerini Aktifleştir

Firebase Console'da projenizde şu servisleri aktifleştirin:

### 3.1. Firestore Database
1. Sol menüden **"Build"** > **"Firestore Database"**
2. **"Create database"** tıkla
3. **Production mode** seç
4. **Location**: `us-central` veya en yakın bölge
5. **"Enable"**

### 3.2. Cloud Messaging (FCM)
1. Sol menüden **"Build"** > **"Cloud Messaging"**
2. Otomatik aktif olacak, ekstra bir şey yapmanıza gerek yok

## Adım 4: Firestore Güvenlik Kuralları (Opsiyonel)

Geliştirme aşamasında test için:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // SADECE TEST İÇİN!
    }
  }
}
```

**ÖNEMLİ**: Production'da mutlaka güvenli kurallar kullanın!

## Adım 5: Uygulamayı Çalıştır

```bash
flutter clean
flutter pub get
flutter run -d adb-RZ8MB2CQJ1Y-GUhKZP._adb-tls-connect._tcp
```

## Sorun Giderme

### "Namespace not specified" Hatası
Zaten düzeltildi. `phone_state` ve `telephony` paketlerinin namespace'leri eklendi.

### "Firebase duplicate-app" Hatası
Zaten düzeltildi. `main.dart` dosyasında try-catch ile korundu.

### "Permission denied" Hatası
Firestore güvenlik kurallarını kontrol edin ve geliştirme için yukarıdaki test kurallarını kullanın.

## Notlar

- Firebase ücretsiz plan (Spark Plan) 10K okuma, 20K yazma/gün limiti vardır
- Production'a geçmeden önce güvenlik kurallarını güncelleyin
- Analytics isterseniz sonradan ekleyebilirsiniz

