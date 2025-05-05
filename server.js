require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');
const nodemailer = require('nodemailer');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({
  origin: function(origin, callback) {
    if (!origin) return callback(null, true);
    if (/vercel\.app$/.test(origin)) {
      return callback(null, true);
    }
    callback(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// Endpoint pour l'appel à GroqCloud
app.post('/api/predictions', async (req, res) => {
  const { input } = req.body;
  const apiKey = process.env.GROQ_API_KEY || "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";
  if (!apiKey) {
    return res.status(500).json({ error: "Clé API GroqCloud manquante." });
  }
  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          { role: "system", content: "Tu es un assistant hôtelier professionnel, réponds toujours en français, poliment et efficacement." },
          { role: "user", content: input.prompt }
        ],
        temperature: 1,
        max_tokens: 1024,
        top_p: 1,
        stream: false
      })
    });
    const data = await response.json();
    console.log('Réponse GroqCloud:', data);
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

// Endpoint pour envoyer un email de notification
app.post('/api/sendNotification', async (req, res) => {
  const { title, body, emails } = req.body;
  try {
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
      console.error('❌ EMAIL_USER ou EMAIL_PASS manquant dans les variables d\'environnement.');
      return res.status(500).json({ error: "EMAIL_USER ou EMAIL_PASS manquant dans le serveur. Vérifiez le .env et redémarrez le serveur." });
    }
    let transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });
    for (const email of emails) {
      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: email,
        subject: title,
        text: body
      });
    }
    res.json({ success: true, sent: emails.length });
  } catch (error) {
    console.error("Erreur lors de l'envoi des emails:", error);
    res.status(500).json({ error: "Erreur lors de l'envoi des emails: " + error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Serveur lancé sur le port ${PORT}`);
}); 