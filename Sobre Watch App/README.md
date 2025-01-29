# Sobre Watch App - Projet Structure 🍺⌚

## 📂 Structure du Projet

### Répertoires Principaux

```
Sobre Watch App/
├── Assets.xcassets/          # Ressources graphiques et assets
├── Features/                 # Fonctionnalités modulaires de l'application
├── Preview Content/          # Contenu de prévisualisation pour Xcode
├── Services/                 # Services et gestionnaires de données
├── Shared/                   # Composants partagés entre différentes vues
```

### Fichiers Principaux

- `ContentView.swift`: Vue principale de l'application
- `Drink.swift`: Modèles de données pour les boissons
- `logo.png`: Logo de l'application
- `Sobre Watch App.entitlements`: Configuration des capacités de l'app
- `SobreApp.swift`: Point d'entrée de l'application

## 🛠 Prérequis pour Compilation

### Environnement de Développement

- Xcode 15 ou supérieur
- macOS Sonoma (14.0) ou supérieur
- Apple Watch compatibilité watchOS 10+

### Compatibilité Matérielle

- **Important :** Développé et testé sur Apple Watch SE
- **Compatibilité :** Apple Watch 4 et versions ultérieures
  - Apple Watch Series 4+
  - Apple Watch SE (1ère et 2ème génération)
  - Apple Watch Series 5, 6, 7, 8
  - Apple Watch Ultra

## ⚠️ Notes de Développement

### Avertissements et Annotations

- Certaines notations peuvent utiliser des méthodes d'anciennes versions
- Annotations @available ou @deprecated présentes dans le code
- Quelques méthodes peuvent nécessiter des adaptations pour les dernières versions de watchOS

## 🚀 Guide de Compilation

1. Clonez le dépôt

   ```bash
   git clone https://github.com/armandwegnez/Sobre-Public
   ```

2. Ouvrez le projet dans Xcode

   ```bash
   cd sobre-watch-app
   open Sobre.xcodeproj
   ```

3. Configurez le provisioning et les certificats

   - Assurez-vous d'avoir un compte développeur Apple
   - Configurez les identités de signature dans les paramètres du projet

4. Sélectionnez le bon schéma de compilation

   - Choisissez "Sobre Watch App" comme target
   - Sélectionnez un simulateur Apple Watch compatible ou votre appareil physique

5. Compilez et exécutez
   - Cmd + R ou bouton de lecture dans Xcode

## 🔧 Dépendances

- SwiftUI
- HealthKit
- CoreMotion
- WatchKit

## ⚠️ Limitations Connues

- Non disponible sur l'App Store (rejeté par Apple)
- Nécessite une Apple Watch compatible
- Permissions HealthKit requises

## 🤝 Contribution

- Ouvrez des issues pour des bugs ou suggestions
- Pull requests bienvenues
- Respectez les guidelines de codage Swift

## 📞 Support

- Telegram : [Rejoindre la Communauté](https://t.me/+Nspah7lRUggzMzA0)
- Twitter : [@\_armandwegnez](https://x.com/_armandwegnez)

---

_Développé avec ❤️ et précision_
