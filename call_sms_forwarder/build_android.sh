#!/bin/bash

echo "🔨 Android APK Oluşturuluyor..."
echo ""

cd /Users/samet/call_sms_forwarder/call_sms_forwarder

# Clean
echo "1️⃣ Temizleniyor..."
flutter clean

# Get packages
echo "2️⃣ Paketler indiriliyor..."
flutter pub get

# Build APK
echo "3️⃣ APK oluşturuluyor..."
flutter build apk --release

# Check if successful
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo ""
    echo "✅ APK başarıyla oluşturuldu!"
    echo "📍 Konum: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "📱 APK'yı Android telefonunuza yüklemek için:"
    echo "   - USB ile bağlayın ve dosyayı kopyalayın"
    echo "   - veya Email/Drive ile gönderin"
    echo "   - veya 'adb install build/app/outputs/flutter-apk/app-release.apk' komutu ile yükleyin"
else
    echo ""
    echo "❌ APK oluşturulamadı!"
    echo "Hata mesajlarını kontrol edin."
fi
