/* eslint-disable */
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

const firestore = admin.firestore();

// Commenter les anciennes fonctions d'envoi FCM
/*
exports.sendNotificationToReceptionists = functions.firestore
  .document("conversations/{conversationId}")
  .onUpdate(async (change, context) => {
    // ancienne logique FCM
});
exports.lockConversationForReceptionist = functions.firestore
  .document("conversations/{conversationId}")
  .onUpdate(async (change, context) => {
    // ancienne logique FCM lock
});
*/

// Fonction d'envoi FCM aux réceptionnistes lors de l'escalade
exports.sendNotificationToReceptionists = functions.firestore
  .document('conversations/{conversationId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before.isEscalated && after.isEscalated) {
      const snapshot = await firestore.collection('receptionists').get();
      if (snapshot.empty) {
        console.log('Aucun réceptionniste trouvé.');
        return null;
      }
      const tokens = snapshot.docs.map(doc => doc.data().fcmToken).filter(token => token);
      if (tokens.length > 0) {
        await admin.messaging().sendMulticast({
          notification: {
            title: 'Client en attente de votre assistance',
            body: `Un client attend dans la conversation ${context.params.conversationId}.`,
          },
          tokens: tokens,
        });
        console.log(`Notifications FCM envoyées à ${tokens.length} réceptionnistes.`);
      } else {
        console.log('Aucun token FCM trouvé pour les réceptionnistes.');
      }
    }
    return null;
  });

// Lock conversation for receptionist (ensures only one can access at a time)
exports.lockConversationForReceptionist = functions.firestore
  .document("conversations/{conversationId}")
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const activeReceptionist = after.activeReceptionist;
    const snapshot = await firestore.collection('receptionists').get();
    // Filtrer tokens : si un réceptionniste est actif, on exclut son token
    const tokens = snapshot.docs
      .filter(doc => activeReceptionist ? doc.data().email !== activeReceptionist : true)
      .map(doc => doc.data().fcmToken)
      .filter(token => token);
    if (tokens.length > 0) {
      const notification = activeReceptionist
        ? {
            title: 'Conversation verrouillée',
            body: `La conversation ${context.params.conversationId} est verrouillée par un autre réceptionniste.`,
          }
        : {
            title: 'Aucun réceptionniste assigné',
            body: `Veuillez assigner un réceptionniste à la conversation ${context.params.conversationId}.`,
          };
      await admin.messaging().sendMulticast({ notification, tokens });
      console.log(`Notifications de lock envoyées à ${tokens.length} réceptionnistes.`);
    } else {
      console.log('Aucun token FCM trouvé pour lockConversationForReceptionist.');
    }
    return null;
  });
