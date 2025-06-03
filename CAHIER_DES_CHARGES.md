# Cahier des charges — Système d'Assistant Hôtelier Intelligent

## 1. Présentation générale du projet

Le projet consiste à développer une solution complète d'assistant virtuel pour hôtels, permettant d'automatiser la gestion des demandes clients, de faciliter la communication entre clients et réceptionnistes, et d'offrir une interface d'administration pour la gestion des hôtels, des utilisateurs et des notifications. Le système s'appuie sur une application Flutter (web et mobile) et un backend Node.js, avec intégration de l'IA (GroqCloud) et de la messagerie email.

---

## 2. Objectifs du projet

- Offrir un chatbot intelligent capable de répondre aux questions des clients 24/7.
- Permettre l'escalade automatique vers un réceptionniste humain en cas de besoin.
- Gérer plusieurs hôtels, réceptionnistes et administrateurs via une interface dédiée.
- Assurer la traçabilité et la sécurité des échanges.
- Proposer une expérience utilisateur moderne, fluide et responsive.

---

## 3. Fonctionnalités principales

### 3.1. Côté client (Flutter)
- Sélection du rôle (client ou admin) à l'ouverture de l'application.
- Saisie des informations client (nom, prénom, choix de l'hôtel).
- Interface de chat avec l'assistant virtuel (IA GroqCloud).
- Affichage en temps réel des messages (Firestore).
- Proposition d'escalade vers un réceptionniste humain si l'IA ne peut répondre.
- Notification et prise en charge par un réceptionniste disponible.
- Historique de la conversation accessible.
- Interface responsive (web/mobile).

### 3.2. Côté réceptionniste
- Authentification sécurisée par mot de passe.
- Accès à la conversation client à partir d'un lien de notification.
- Prise en charge de la conversation (affichage du badge, verrouillage de la session).
- Envoi de messages en temps réel.
- Libération de la conversation à la fin de l'échange.

### 3.3. Côté administrateur
- Authentification admin.
- Gestion des hôtels (ajout, modification, suppression).
- Gestion des réceptionnistes (ajout, modification, suppression, gestion des emails et mots de passe).
- Gestion des administrateurs (ajout, modification, suppression).
- Recherche et filtrage des utilisateurs.
- Interface d'administration sécurisée et ergonomique.

### 3.4. Backend Node.js
- API REST pour l'appel à l'IA (GroqCloud) et l'envoi de notifications email (Nodemailer).
- Sécurisation des endpoints (CORS, validation des entrées).
- Gestion des variables d'environnement sensibles.
- Logs détaillés pour le suivi des erreurs et des actions.

---

## 4. Architecture technique

- **Frontend** : Flutter (Dart), responsive web & mobile, Firebase (Firestore, Auth, Messaging), SharedPreferences.
- **Backend** : Node.js (Express), Nodemailer, node-fetch, gestion des variables d'environnement avec dotenv.
- **Base de données** : Firestore (NoSQL, temps réel).
- **Notifications** : Email (réceptionnistes), Firebase Cloud Messaging (optionnel).
- **IA** : Intégration GroqCloud (API LLM, prompt engineering).
- **Déploiement** : Vercel (frontend web), Render/Railway/Heroku (backend), Play Store (mobile, optionnel).

---

## 5. Sécurité

- Authentification par mot de passe pour les admins et réceptionnistes.
- Sécurisation des endpoints backend (CORS, validation des entrées, gestion des erreurs).
- Stockage sécurisé des mots de passe (à améliorer avec hashage en production).
- Gestion des permissions et des rôles (client, réceptionniste, admin).
- Nettoyage des données de session à la déconnexion.
- Variables d'environnement pour les clés sensibles (API, email, etc.).

---

## 6. Expérience utilisateur (UX/UI)

- Interfaces modernes, épurées, adaptées à tous les écrans.
- Navigation fluide entre les rôles et les écrans.
- Feedback utilisateur (loaders, messages d'erreur, confirmations).
- Accessibilité (contrastes, tailles de police, navigation clavier).
- Personnalisation possible (logos, couleurs, textes).

---

## 7. Tests et validation

- Tests unitaires et widgets sur Flutter (ex : chat_screen_test.dart).
- Tests manuels des parcours critiques (connexion, chat, escalade, gestion admin).
- Scénarios de test pour le backend (API, notifications, gestion des erreurs).
- Validation de la compatibilité web/mobile.

---

## 8. Déploiement et maintenance

- Documentation technique et utilisateur.
- Scripts d'installation et de déploiement (README, .env.example).
- Procédures de mise à jour et de sauvegarde des données.
- Monitoring des erreurs et des performances (logs backend, Firebase).
- Possibilité d'évolution (ajout de modules, intégration d'autres IA, etc.).

---

## 9. Contraintes et recommandations

- Respect de la RGPD (données personnelles, consentement, droit à l'oubli).
- Prévoir la scalabilité (multi-hôtels, multi-utilisateurs).
- Prévoir la gestion multilingue (français, anglais, espagnol, arabe).
- Prévoir la personnalisation par hôtel (logo, couleurs, messages).
- Prévoir la migration possible vers d'autres solutions cloud ou IA.

---

## 10. Livrables

- Code source complet (frontend, backend, scripts, tests).
- Documentation technique et utilisateur.
- Fichiers de configuration (.env.example, README, CAHIER_DES_CHARGES.md).
- Procédures d'installation et de déploiement.
- Présentation pour la soutenance (slides, démo, etc.).

---

## 11. Annexes

- Exemples de prompts IA, modèles de mails, captures d'écran, schémas d'architecture.
- Liens utiles (Firebase, GroqCloud, Vercel, Render, documentation Flutter/Node.js).

---

**Ce cahier des charges est conçu pour servir de référence complète à toutes les parties prenantes du projet, garantir la qualité, la maintenabilité et la réussite de la solution d'assistant hôtelier intelligent.** 