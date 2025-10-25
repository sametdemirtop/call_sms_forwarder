const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

// Yeni notification eklendiğinde push notification gönder
exports.sendNotificationOnCreate = onDocumentCreated(
    "notifications/{docId}",
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) {
        console.log("No data associated with the event");
        return;
      }

      const data = snapshot.data();
      console.log("New notification created:", data);

      // FCM token'larını al
      const db = getFirestore();
      const tokensSnapshot = await db.collection("fcm_tokens").get();

      if (tokensSnapshot.empty) {
        console.log("No FCM tokens found");
        return;
      }

      // Bildirim içeriği
      const notificationTitle = data.type === "sms" ?
        `📩 Yeni SMS: ${data.sender}` :
        `📞 Yeni Arama: ${data.caller}`;

      const notificationBody = data.type === "sms" ?
        data.message :
        data.callType;

      // Tüm token'lara bildirim gönder
      const tokens = [];
      tokensSnapshot.forEach((doc) => {
        tokens.push(doc.data().token);
      });

      console.log(`Sending notifications to ${tokens.length} devices`);

      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          type: data.type,
          sender: data.sender || data.caller || "",
          message: data.message || data.callType || "",
          timestamp: String(data.timestamp || Date.now()),
        },
        tokens: tokens,
      };

      try {
        const response = await getMessaging().sendEachForMulticast(message);
        console.log("Successfully sent messages:", response.successCount);
        console.log("Failed messages:", response.failureCount);

        // Başarısız token'ları temizle
        if (response.failureCount > 0) {
          const failedTokens = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              failedTokens.push(tokens[idx]);
            }
          });

          // Başarısız token'ları sil
          const batch = db.batch();
          const failedTokensSnapshot = await db.collection("fcm_tokens")
              .where("token", "in", failedTokens)
              .get();

          failedTokensSnapshot.forEach((doc) => {
            batch.delete(doc.ref);
          });

          await batch.commit();
          console.log(`Removed ${failedTokens.length} invalid tokens`);
        }
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    });
