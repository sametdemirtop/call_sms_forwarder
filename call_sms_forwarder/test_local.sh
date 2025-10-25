#!/bin/bash

echo "🧪 Local Test Başlatılıyor..."
echo ""

cd /Users/samet/call_sms_forwarder/call_sms_forwarder

# Check for connected devices
echo "📱 Bağlı cihazlar kontrol ediliyor..."
flutter devices

echo ""
echo "Hangi platformda test etmek istersiniz?"
echo "1) Android (fiziksel cihaz veya emulator)"
echo "2) Web (Chrome)"
echo "3) İkisi de"
read -p "Seçiminiz (1-3): " choice

case $choice in
    1)
        echo "Android'de çalıştırılıyor..."
        flutter run
        ;;
    2)
        echo "Chrome'da çalıştırılıyor..."
        flutter run -d chrome
        ;;
    3)
        echo "Her iki platformda da çalıştırılıyor..."
        echo "İlk önce Android..."
        flutter run &
        sleep 5
        echo "Şimdi Web..."
        flutter run -d chrome
        ;;
    *)
        echo "Geçersiz seçim!"
        exit 1
        ;;
esac
