// ==========================
// server.js : Backend Node.js pour l'IA et les notifications email
// ==========================

// Chargement des variables d'environnement depuis le fichier .env
require('dotenv').config();
// Importation du framework Express pour créer le serveur HTTP
const express = require('express');
// Importation de CORS pour autoriser les requêtes cross-origin
const cors = require('cors');
// Importation de node-fetch pour effectuer des requêtes HTTP externes
const fetch = require('node-fetch');
// Importation de nodemailer pour l'envoi d'emails
const nodemailer = require('nodemailer');
// Création de l'application Express
const app = express();
// Définition du port d'écoute du serveur (par défaut 3000 ou depuis .env)
const PORT = process.env.PORT || 3000;

// Liste des origines autorisées pour les requêtes CORS
const allowedOrigins = [
  "http://localhost:3000",
  "https://assistant-i1ojs8h3k-khalils-projects-014efdbb.vercel.app"
];

// Configuration du middleware CORS pour sécuriser les accès
app.use(cors({
  origin: function(origin, callback) {
    if (!origin) return callback(null, true);
    if (
      allowedOrigins.includes(origin) ||
      origin.endsWith('.vercel.app')
    ) {
      return callback(null, true);
    }
    callback(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
// Middleware pour parser le corps des requêtes en JSON
app.use(express.json());

// ==========================
// Endpoint pour l'appel à GroqCloud (IA)
// ==========================
app.post('/api/predictions', async (req, res) => {
  // Récupération du prompt utilisateur depuis la requête
  const { input } = req.body;
  // Récupération de la clé API GroqCloud depuis les variables d'environnement
  const apiKey = process.env.GROQ_API_KEY || "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";
  if (!apiKey) {
    return res.status(500).json({ error: "Clé API GroqCloud manquante." });
  }
  try {
    // Appel à l'API GroqCloud pour générer une réponse IA
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          { role: "system", content: "Tu es un assistant hôtelier professionnel, réponds toujours en meme langue du client, poliment et efficacement." },
          { role: "user", content: input.prompt }
        ],
        temperature: 1,
        max_tokens: 1024,
        top_p: 1,
        stream: false
      })
    });
    // Récupération de la réponse JSON
    const data = await response.json();
    console.log('Réponse GroqCloud:', data);
    // Vérifie que la réponse contient bien un message généré
    if (data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content) {
      res.json({
        status: 'succeeded',
        output: [data.choices[0].message.content]
      });
    } else {
      res.status(500).json({ error: data.error?.message || "Erreur lors de l'appel à GroqCloud" });
    }
  } catch (error) {
    console.error('Erreur lors de l\'appel à GroqCloud:', error);
    res.status(500).json({ error: "Erreur lors de l'appel à GroqCloud" });
  }
});

// ==========================
// Endpoint pour envoyer un email de notification
// ==========================
app.post('/api/sendNotification', async (req, res) => {
  // Récupération des informations de la notification depuis la requête
  const { title, body, emails, conversationLink } = req.body;
  try {
    // Vérifie que les identifiants email sont bien présents dans les variables d'environnement
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
      console.error('❌ EMAIL_USER ou EMAIL_PASS manquant dans les variables d\'environnement.');
      return res.status(500).json({ error: "EMAIL_USER ou EMAIL_PASS manquant dans le serveur. Vérifiez le .env et redémarrez le serveur." });
    }
    // Création du transporteur SMTP avec Gmail
    let transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });
    // Envoi d'un email à chaque destinataire
    for (const email of emails) {
      console.log(`[${new Date().toISOString()}] Début envoi mail à ${email}`);
      const start = Date.now();
      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: email,
        subject: title,
        text: body,
        html: `<div style="font-family:Arial,sans-serif;font-size:16px;">
          <p>${body.replace(/\n/g, '<br>')}</p>
          <a href="${conversationLink}" style="display:inline-block;padding:12px 24px;background:#1976d2;color:#fff;text-decoration:none;border-radius:6px;margin-top:16px;font-weight:bold;">Accéder à la conversation</a>
        </div>`
      });
      const end = Date.now();
      console.log(`[${new Date().toISOString()}] Mail envoyé à ${email} en ${end - start} ms`);
    }
    res.json({ success: true, sent: emails.length });
  } catch (error) {
    console.error("Erreur lors de l'envoi des emails:", error);
    res.status(500).json({ error: "Erreur lors de l'envoi des emails: " + error.message });
  }
});

// ==========================
// Démarrage du serveur Express
// ==========================
app.listen(PORT, () => {
  console.log(`Serveur lancé sur le port ${PORT}`);
}); 