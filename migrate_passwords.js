const admin = require('firebase-admin');
const CryptoJS = require('crypto-js');
const fs = require('fs');

// Nouvelle clé forte sans caractères spéciaux ambigus
const PASSWORD_SECRET = 'K4v9zQ2r8wX7pL6sT1bN0eY5uC3mA2';
if (!PASSWORD_SECRET) {
  console.error('❌ PASSWORD_SECRET manquant dans le script');
  process.exit(1);
}

// Vérifie que le fichier service-account.json existe
if (!fs.existsSync('./service-account.json')) {
  console.error('❌ Le fichier service-account.json est manquant à la racine du projet.');
  process.exit(1);
}

// Initialise Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(require('./service-account.json')),
});
const db = admin.firestore();

async function migrateReceptionists() {
  const hotels = await db.collection('hotels').get();
  for (const hotel of hotels.docs) {
    const recs = await db.collection('hotels').doc(hotel.id).collection('receptionists').get();
    for (const rec of recs.docs) {
      const data = rec.data();
      // On rechiffre même si déjà chiffré (pour être sûr que tout est cohérent)
      let plainPassword = data.password;
      // Si déjà chiffré, on tente de déchiffrer avec l'ancienne clé tronquée
      if (plainPassword && plainPassword.startsWith('U2Fsd')) {
        try {
          const bytes = CryptoJS.AES.decrypt(plainPassword, 'K4!v9@zQ2');
          const decrypted = bytes.toString(CryptoJS.enc.Utf8);
          if (decrypted) plainPassword = decrypted;
        } catch (e) {}
      }
      if (plainPassword) {
        const encrypted = CryptoJS.AES.encrypt(plainPassword, PASSWORD_SECRET).toString();
        await rec.ref.update({ password: encrypted });
        console.log(`✅ Réceptionniste "${data.name}" migré`);
      }
    }
  }
}

async function migrateAdmins() {
  const admins = await db.collection('admins').get();
  for (const adminDoc of admins.docs) {
    const data = adminDoc.data();
    let plainPassword = data.password;
    if (plainPassword && plainPassword.startsWith('U2Fsd')) {
      try {
        const bytes = CryptoJS.AES.decrypt(plainPassword, 'K4!v9@zQ2');
        const decrypted = bytes.toString(CryptoJS.enc.Utf8);
        if (decrypted) plainPassword = decrypted;
      } catch (e) {}
    }
    if (plainPassword) {
      const encrypted = CryptoJS.AES.encrypt(plainPassword, PASSWORD_SECRET).toString();
      await adminDoc.ref.update({ password: encrypted });
      console.log(`✅ Admin "${data.username}" migré`);
    }
  }
}

(async () => {
  console.log('--- Début de la migration des mots de passe avec la nouvelle clé ---');
  await migrateReceptionists();
  await migrateAdmins();
  console.log('--- Migration terminée ! ---');
  process.exit();
})(); 