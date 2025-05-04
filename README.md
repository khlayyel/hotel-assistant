# Hotel Assistant Chatbot

Une application Flutter d'assistance virtuelle dédiée aux hôtels.

## Fonctionnalités

- Chatbot intelligent
- Intégration avec Firebase pour la gestion des conversations
- Interface utilisateur moderne et intuitive
- Gestion des erreurs robuste
- Configuration flexible via fichiers de configuration

## Configuration

1. Clonez le dépôt
2. Installez les dépendances :
```bash
flutter pub get
```

3. Lancez l'application :
```bash
flutter run
```

## Structure du projet

```
lib/
├── config/
│   └── environment.dart
├── services/
├── test/
└── main.dart
```

## Tests

Pour exécuter les tests :
```bash
flutter test
```

## Dépendances principales

- `http` : Pour les appels API
- `firebase_core` : Pour l'intégration Firebase
- `cloud_firestore` : Pour la base de données
- `shared_preferences` : Pour le stockage local

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## Licence

MIT
