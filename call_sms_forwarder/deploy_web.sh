#!/bin/bash

echo "🌐 Web Uygulaması Deploy Ediliyor..."
echo ""

cd /Users/samet/call_sms_forwarder/call_sms_forwarder

# Build web
echo "1️⃣ Web uygulaması build ediliyor..."
flutter build web

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo ""
    echo "❌ Firebase CLI bulunamadı!"
    echo "Yüklemek için: npm install -g firebase-tools"
    exit 1
fi

# Deploy
echo "2️⃣ Firebase Hosting'e deploy ediliyor..."
firebase deploy --only hosting

echo ""
echo "✅ Web uygulaması başarıyla deploy edildi!"
echo ""
echo "🌍 Uygulamanızı şu adreste görebilirsiniz:"
echo "   https://YOUR-PROJECT-ID.web.app"
echo ""
echo "📱 iPhone'unuzda:"
echo "   1. Safari'de yukarıdaki URL'i açın"
echo "   2. Paylaş butonuna tıklayın"
echo "   3. 'Ana Ekrana Ekle' seçin"
